classdef WDRCTuner < handle
    properties (Access = private, Constant)
        centerFrequencies = [200, 250, 315, 400, 500, 630, 800, 1000, 1250, 1600, 2000, 2500, 3150, 4000, 5000, 6300, 8000]
        octaveFrequencies = [250, 500, 1000, 2000, 4000]
        SENNCorrection = [1.2, 1.2, 2.29, 3.72, 5.4, 5.04, 4.86, 5.5, 6.75, 8.94, 12.7, 12.95, 12.6, 9.2, 5.95, 4.26, 13.1] + 3
    end
    
    properties (Access = private)
        Nchannel
        DSLRawOutput
        thresholds
    end
    
    methods
        function self = WDRCTuner( ...
                Nchannel, ...
                thresholds, ...
                DSLFile)
            assert(thresholds.isKey(6000) || thresholds.isKey(8000), ...
                ['A threshold must be entered for 6000 or 8000 Hz. ', ...
                'If no response, please enter 120 dB HL.']);
            DSLRawOutput = self.readDSLfile(DSLFile);
            self.verifyDSLThresholdEntries(thresholds, DSLRawOutput.ThreshSPL);
            self.verifyMinimumChannelCountMet(Nchannel, DSLRawOutput.TK);
            self.adjustTargetAverages(thresholds, DSLRawOutput);
            self.Nchannel = Nchannel;
            self.DSLRawOutput = DSLRawOutput;
            self.thresholds = thresholds;
        end
        
        function DSL = generateDSL(self, attackMilliseconds, releaseMilliseconds)
            parameters = DSLPrescriber.WDRCParameters(self.Nchannel);
            Select_channel = zeros(1, self.Nchannel);
            bandwidth = (log10(self.centerFrequencies(end)) - log10(self.centerFrequencies(1))) / self.Nchannel;
            for i = 1:self.Nchannel-1
                parameters.crossFrequencies(i) = 10^(bandwidth*i + log10(self.centerFrequencies(1)));
                Select_channel(i) = find((self.centerFrequencies/parameters.crossFrequencies(i)) <= 1, 1, 'last');
            end
            Select_channel(end) = length(self.centerFrequencies);
            Select_channel = [0, Select_channel];
            vTargetAvg = zeros(1, self.Nchannel);
            vSENNcorr = zeros(1, self.Nchannel);
            preAdjustedBOLT = zeros(1, self.Nchannel);
            for n = 1:self.Nchannel
                channels = Select_channel(n)+1:Select_channel(n+1);
                frequencies = self.centerFrequencies(channels);
                parameters.TK(n) = self.averageOverSelectedFrequencies(self.DSLRawOutput.TK, frequencies);
                parameters.CR(n) = self.averageOverSelectedFrequencies(self.DSLRawOutput.CR, frequencies);
                preAdjustedBOLT(n) = self.averageOverSelectedFrequencies(self.DSLRawOutput.TargetBOLT, frequencies);
                parameters.TKGain(n) = self.averageOverSelectedFrequencies(self.DSLRawOutput.TKgain, frequencies);
                vTargetAvg(n) = self.averageOverSelectedFrequencies(self.DSLRawOutput.TargetAvg, frequencies);
                vSENNcorr(n) = mean(self.SENNCorrection(channels));
                parameters.BOLT(n) = preAdjustedBOLT(n) - vSENNcorr(n);
            end
            minGain = -vSENNcorr;
            indices = 1:round(self.Nchannel/4);
            minGain(indices) = minGain(indices) - 10*log10(self.Nchannel); % Correct for channel overlap
            maxGain = 55;
            parameters.maxdB = 119;
            parameters.rmsdB = 60;
            parameters.attackMilliseconds = attackMilliseconds;
            parameters.releaseMilliseconds = releaseMilliseconds;
            [x, Fs] = audioread('Carrots.wav');
            for k = 1:2
                compressor = DSLPrescriber.WDRCompressor(parameters);
                y = compressor.compress(x, Fs);
                avg_out = self.speechmap2(parameters.maxdB, y, Fs) + self.SENNCorrection;
                for n = 1:self.Nchannel
                    vavg_out= mean(avg_out(Select_channel(n)+1:Select_channel(n+1)));
                    diff = vTargetAvg(n) - vavg_out;
                    parameters.TKGain(n) = parameters.TKGain(n) + diff;
                    if parameters.TKGain(n) < minGain(n)
                        parameters.TKGain(n) = minGain(n);
                    end
                    if parameters.TKGain(n) > maxGain
                        parameters.TKGain(n) = maxGain;
                    end
                end
            end
            DSL.attack = attackMilliseconds;
            DSL.release = releaseMilliseconds;
            DSL.Nchannel = self.Nchannel;
            DSL.Cross_freq = parameters.crossFrequencies;
            DSL.TKgain = parameters.TKGain;
            DSL.CR = parameters.CR;
            DSL.TK = parameters.TK;
            DSL.BOLT = preAdjustedBOLT;
        end
    end
    
    methods (Access = private)
        function fileOutput = readDSLfile(self, filename)
            a = csvread(filename, 1, 1);
            frequencies = [200, 250, 315, 400, 500, 630, 800, 1000, 1250, 1600, 2000, 2500, 3150, 4000, 5000, 6300, 8000];
            columnRange = 1:numel(frequencies);
            fileOutput = DSLPrescriber.DSLFileOutput();
            fileOutput.ThreshSPL = containers.Map(frequencies, a(8, columnRange));
            fileOutput.TK = containers.Map(frequencies, a(15, columnRange));
            fileOutput.TargetBOLT = containers.Map(frequencies, a(10, columnRange));
            fileOutput.CR = containers.Map(frequencies, a(17, columnRange));
            fileOutput.TKgain = containers.Map(frequencies, a(13, columnRange) - a(15, columnRange));
            fileOutput.TargetAvg = containers.Map(frequencies, a(23, columnRange));
        end

        function verifyDSLThresholdEntries(self, thresholds, DSLRawThresholds)
            for i = 1:numel(self.octaveFrequencies)
                frequency = self.octaveFrequencies(i);
                correctedThreshold = round(thresholds(frequency) + DSLPrescriber.TDHCorrections.levels(frequency), 1);
                assert(correctedThreshold == DSLRawThresholds(frequency), ...
                    sprintf( ...
                    'You entered %g in the DSL program instead of %g at %g Hz', ...
                    DSLRawThresholds(frequency), ...
                    correctedThreshold, ...
                    frequency));
            end
        end
        
        function verifyMinimumChannelCountMet(self, Nchannel, kneePoints)
            minchannel = 1;
            sortedFrequencies = sort(cell2mat(kneePoints.keys()));
            for i = 1:numel(sortedFrequencies)-1
                if kneePoints(sortedFrequencies(i)) ~= kneePoints(sortedFrequencies(i+1))
                    minchannel = minchannel + 1;
                end
            end
            assert(Nchannel >= minchannel, ...
                sprintf( ...
                'The minimum # of channels for the selected file must be at least %d', ...
                minchannel));
        end
        
        function adjustTargetAverages(self, thresholds, DSLRawOutput)
            frequencies = cell2mat(thresholds.keys());
            correctedThresholds = zeros(1, numel(frequencies));
            for i = 1:numel(frequencies)
                frequency = frequencies(i);
                correctedThresholds(i) = thresholds(frequency) + DSLPrescriber.TDHCorrections.levels(frequency);
            end
            thirdOctaveThresholds = containers.Map(self.centerFrequencies, ...
                interp1(frequencies, correctedThresholds, self.centerFrequencies));
            if isnan(thirdOctaveThresholds(200))
                thirdOctaveThresholds(200) = thirdOctaveThresholds(250); 
            end
            if isnan(thirdOctaveThresholds(8000))
                thirdOctaveThresholds(8000) = thirdOctaveThresholds(6300); 
            end
            DSLRawOutput.TargetAvg(8000) = DSLRawOutput.TargetAvg(6300) - thirdOctaveThresholds(6300) + thirdOctaveThresholds(8000);
            if DSLRawOutput.TargetAvg(8000) - DSLRawOutput.TargetAvg(6300) > 10
                DSLRawOutput.TargetAvg(8000) = DSLRawOutput.TargetAvg(6300) + 10;
            end
        end
        
        function result = averageOverSelectedFrequencies(self, container, frequencies)
            sum = 0;
            for i = 1:numel(frequencies)
                sum = sum + container(frequencies(i));
            end
            result = sum / numel(frequencies);
        end
        
        function banana = speechmap2(self, maxdB, x, Fs)
            N = 3; 					% Order of analysis filters.
            nF = 17;
            ff = 1000*((2^(1/3)).^(-7:nF-8)); 	% Exact center freq.
            % Design filters and compute RMS powers in 1/3-oct. bands
            % 10000 Hz band to 1600 Hz band, direct implementation of filters.
            B = zeros(nF, 7);
            A = zeros(nF, 7);
            for i = nF:-1:10
                [B(i, :), A(i, :)] = self.oct3dsgn(ff(i), Fs, N);
            end
            for j = 0:2
                rowOffset = j * 3;
                B(rowOffset+1, :) = B(10, :);
                B(rowOffset+2, :) = B(11, :);
                B(rowOffset+3, :) = B(12, :);
                A(rowOffset+1, :) = A(10, :);
                A(rowOffset+2, :) = A(11, :);
                A(rowOffset+3, :) = A(12, :);
            end
            winsize = round(Fs * 0.128);
            stepsize = winsize / 2;
            Nsamples = floor(length(x) / stepsize) - 1;
            w = hann(winsize);
            for n = 1:Nsamples
                startpt = ((n-1).*stepsize)+1;
                y = w.*x(startpt:(startpt+winsize-1));
                for i = nF:-1:10
                    z = filter(B(i, :), A(i, :), y);
                    P(n, i) = sum(z.^2) / length(z);
                end
                for j = 2:-1:0
                    y = decimate(y, 2);
                    for k = 3:-1:1
                        i = j * 3 + k;
                        z = filter(B(i, :), A(i, :), y);
                        P(n, i) = sum(z.^2) / length(z);
                    end
                end
            end
            banana = zeros(1, nF);
            for n = 1:nF
                banana(n) = maxdB + 10*log10((mean(P(:,n))));
            end
        end
        
        function [B, A] = oct3dsgn(self, Fc, Fs, N)
            % OCT3DSGN  Design of a one-third-octave filter.
            %    [B,A] = OCT3DSGN(Fc,Fs,N) designs a digital 1/3-octave filter with
            %    center frequency Fc for sampling frequency Fs.
            %    The filter is designed according to the Order-N specification
            %    of the ANSI S1.1-1986 standard. Default value for N is 3.
            %    Warning: for meaningful design results, center frequency used
            %    should preferably be in range Fs/200 < Fc < Fs/5.
            %    Usage of the filter: Y = FILTER(B,A,X).
            %
            %    Requires the Signal Processing Toolbox.
            %
            %    See also OCT3SPEC, OCTDSGN, OCTSPEC.

            % Author: Christophe Couvreur, Faculte Polytechnique de Mons (Belgium)
            %         couvreur@thor.fpms.ac.be
            % Last modification: Aug. 25, 1997, 2:00pm.

            % References:
            %    [1] ANSI S1.1-1986 (ASA 65-1986): Specifications for
            %        Octave-Band and Fractional-Octave-Band Analog and
            %        Digital Filters, 1993.

            if (Fc > 0.88*(Fs/2))
                error('Design not possible. Check frequencies.');
            end

            % Design Butterworth 2Nth-order one-third-octave filter
            % Note: BUTTER is based on a bilinear transformation, as suggested in [1].
            f1 = Fc/(2^(1/6));
            f2 = Fc*(2^(1/6));
            Qr = Fc/(f2-f1);
            Qd = (pi/2/N)/(sin(pi/2/N))*Qr;
            alpha = (1 + sqrt(1+4*Qd^2))/2/Qd;
            W1 = Fc/(Fs/2)/alpha;
            W2 = Fc/(Fs/2)*alpha;
            [B, A] = butter(N, [W1, W2]);
        end
    end
end

