classdef WDRCTuner < handle
    properties (Access = private, Constant)
        centerFrequencies = [200 250 315 400 500 630 800 1000 1250 1600 2000 2500 3150 4000 5000 6300 8000]
        octaveFrequencies = [250, 500, 1000, 2000, 4000]
        SENNcorrection = [1.2, 1.2, 2.29, 3.72, 5.4, 5.04, 4.86, 5.5, 6.75, 8.94, 12.7, 12.95, 12.6, 9.2, 5.95, 4.26, 13.1]+3
    end
    
    properties (Access = private)
        attack
        release
        Nchannel
        DSLRawOutput
        thresholds
    end
    
    methods
        function self = WDRCTuner( ...
                attack, ...
                release, ...
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
            self.attack = attack;
            self.release = release;
            self.Nchannel = Nchannel;
            self.DSLRawOutput = DSLRawOutput;
            self.thresholds = thresholds;
        end
        
        function DSL = generateDSL(self)
            [Cross_freq, Select_channel] = DSLPrescriber.HA_channelselect(self.centerFrequencies, self.Nchannel);
            Select_channel = [0,Select_channel];
            TK = zeros(1, self.Nchannel);
            CR = zeros(1, self.Nchannel);
            BOLT = zeros(1, self.Nchannel);
            TKgain = zeros(1, self.Nchannel);
            adjBOLT = zeros(1, self.Nchannel);
            vTargetAvg = zeros(1, self.Nchannel);
            vSENNcorr = zeros(1, self.Nchannel);
            for n = 1:self.Nchannel
                frequencies = self.centerFrequencies(Select_channel(n)+1:Select_channel(n+1));
                TK(n) = self.averageOverSelectedFrequencies(self.DSLRawOutput.TK, frequencies);
                CR(n) = self.averageOverSelectedFrequencies(self.DSLRawOutput.CR, frequencies);
                BOLT(n) = self.averageOverSelectedFrequencies(self.DSLRawOutput.TargetBOLT, frequencies);
                TKgain(n) = self.averageOverSelectedFrequencies(self.DSLRawOutput.TKgain, frequencies);
                vTargetAvg(n) = self.averageOverSelectedFrequencies(self.DSLRawOutput.TargetAvg, frequencies);
                vSENNcorr(n) = mean(self.SENNcorrection(Select_channel(n)+1:Select_channel(n+1)));
                adjBOLT(n) = BOLT(n)-vSENNcorr(n);
            end
            minGain = -vSENNcorr;
            minGain(1:round(self.Nchannel/4)) = minGain(1:round(self.Nchannel/4))-10*log10(self.Nchannel); % Correct for channel overlap
            maxGain = 55;
            rmsdB = 60;
            maxdB = 119;
            [x,Fs] = audioread('Carrots.wav');
            for k = 1:2
                y = DSLPrescriber.WDRC(Cross_freq,x,Fs,rmsdB,maxdB,TKgain,CR,TK,adjBOLT,self.attack,self.release);
                avg_out = DSLPrescriber.speechmap2(maxdB,y,Fs)+self.SENNcorrection;
                for n = 1:self.Nchannel
                    vavg_out= mean(avg_out(Select_channel(n)+1:Select_channel(n+1)));
                    diff = vTargetAvg(n) - vavg_out;
                    TKgain(n) = TKgain(n)+diff;
                    if TKgain(n) < minGain(n), TKgain(n) = minGain(n); end
                    if TKgain(n) > maxGain, TKgain(n) = maxGain; end
                end
            end
            DSL.attack = self.attack;
            DSL.release = self.release;
            DSL.Nchannel = self.Nchannel;
            DSL.Cross_freq = Cross_freq;
            DSL.TKgain = TKgain;
            DSL.CR = CR;
            DSL.TK = TK;
            DSL.BOLT = BOLT;
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
    end
end

