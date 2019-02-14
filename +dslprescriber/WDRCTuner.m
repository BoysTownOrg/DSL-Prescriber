classdef WDRCTuner < handle
    properties (Access = private, Constant)
        centerFrequenciesHz = ...
            [200, 250, 315, 400, 500, 630, 800, 1000, 1250, ...
            1600, 2000, 2500, 3150, 4000, 5000, 6300, 8000]
        octaveFrequenciesHz = [250, 500, 1000, 2000, 4000]
        SennCorrection_dB = ...
            [1.2, 1.2, 2.29, 3.72, 5.4, 5.04, 4.86, 5.5, 6.75, ...
            8.94, 12.7, 12.95, 12.6, 9.2, 5.95, 4.26, 13.1] + 3
    end
    
    properties (Access = private)
        channels
        dslFileContents
        thresholds_dB_HL
    end
    
    methods
        function self = WDRCTuner( ...
                channels, ...
                thresholds_dB_HL, ...
                dslFilePath...
            )
            assert(...
                thresholds_dB_HL.isKey(6000) || thresholds_dB_HL.isKey(8000), ...
                ['A threshold must be entered for 6000 or 8000 Hz. ', ...
                    'If no response, please enter 120 dB HL.']);
            dslFileContents = self.readDSLfile(dslFilePath);
            self.verifyDSLThresholdEntries(thresholds_dB_HL, dslFileContents.threshold_dB_SPL);
            self.verifyMinimumChannelCountMet(channels, dslFileContents.kneepoint_dB_SPL);
            self.adjustTargetAverages(thresholds_dB_HL, dslFileContents);
            self.channels = channels;
            self.dslFileContents = dslFileContents;
            self.thresholds_dB_HL = thresholds_dB_HL;
        end
    end
    
    methods (Access = private)
        function fileOutput = readDSLfile(self, filename)
            a = csvread(filename, 1, 1);
            frequenciesHz = ...
                [200, 250, 315, 400, 500, 630, 800, 1000, 1250, ...
                1600, 2000, 2500, 3150, 4000, 5000, 6300, 8000];
            columnRange = 1:numel(frequenciesHz);
            fileOutput.threshold_dB_SPL = containers.Map(frequenciesHz, a(8, columnRange));
            fileOutput.kneepoint_dB_SPL = containers.Map(frequenciesHz, a(15, columnRange));
            fileOutput.targetBOLT_dB_SPL = containers.Map(frequenciesHz, a(10, columnRange));
            fileOutput.ratio = containers.Map(frequenciesHz, a(17, columnRange));
            fileOutput.kneepointGain_dB = ...
                containers.Map(frequenciesHz, a(13, columnRange) - a(15, columnRange));
            fileOutput.targetLow_dB_SPL = containers.Map(frequenciesHz, a(22, columnRange));
            fileOutput.targetAverage_dB_SPL = containers.Map(frequenciesHz, a(23, columnRange));
            fileOutput.targetHigh_dB_SPL = containers.Map(frequenciesHz, a(24, columnRange));
        end

        function verifyDSLThresholdEntries(self, thresholds_dB_HL, dslThresholds_dB_SPL)
            for i = 1:numel(self.octaveFrequenciesHz)
                frequencyHz = self.octaveFrequenciesHz(i);
                correctedThreshold = thresholds_dB_HL(frequencyHz) + ...
                    dslprescriber.TDHCorrections.levels(frequencyHz);
                correctedThreshold = round(correctedThreshold, 1);
                assert(...
                    correctedThreshold == dslThresholds_dB_SPL(frequencyHz), ...
                    sprintf( ...
                        'You entered %g in the DSL program instead of %g at %g Hz', ...
                        dslThresholds_dB_SPL(frequencyHz), ...
                        correctedThreshold, ...
                        frequencyHz...
                    )...
                );
            end
        end
        
        function verifyMinimumChannelCountMet(self, channels, kneePoints)
            minchannel = 1;
            sortedFrequencies = sort(cell2mat(kneePoints.keys()));
            for i = 1:numel(sortedFrequencies)-1
                if kneePoints(sortedFrequencies(i)) ~= kneePoints(sortedFrequencies(i+1))
                    minchannel = minchannel + 1;
                end
            end
            assert(...
                channels >= minchannel, ...
                sprintf( ...
                    'The minimum # of channels for the selected file must be at least %d', ...
                    minchannel...
                )...
            );
        end
        
        function adjustTargetAverages(self, thresholds_dB_HL, dslFileContents)
            thirdOctaveThresholds = self.getThirdOctaveThresholds(thresholds_dB_HL);
            dslFileContents.targetAverage_dB_SPL(8000) = ...
                dslFileContents.targetAverage_dB_SPL(6300) ...
                - thirdOctaveThresholds(6300) ...
                + thirdOctaveThresholds(8000);
            dslFileContents.targetAverage_dB_SPL(8000) = min( ...
                dslFileContents.targetAverage_dB_SPL(8000), ...
                dslFileContents.targetAverage_dB_SPL(6300) + 10 ...
            );
        end
        
        function thirdOctaveThresholds = getThirdOctaveThresholds(self, thresholds_dB_HL)
            frequencies = cell2mat(thresholds_dB_HL.keys());
            correctedThresholds = zeros(1, numel(frequencies));
            for i = 1:numel(frequencies)
                frequency = frequencies(i);
                correctedThresholds(i) = ...
                    thresholds_dB_HL(frequency) ...
                    + dslprescriber.TDHCorrections.levels(frequency);
            end
            thirdOctaveThresholds = containers.Map( ...
                self.centerFrequenciesHz, ...
                interp1(frequencies, correctedThresholds, self.centerFrequenciesHz));
            if isnan(thirdOctaveThresholds(200))
                thirdOctaveThresholds(200) = thirdOctaveThresholds(250); 
            end
            if isnan(thirdOctaveThresholds(8000))
                thirdOctaveThresholds(8000) = thirdOctaveThresholds(6300); 
            end
        end
    end
    
    methods
        function DSL = generateDSL(self, attack_ms, release_ms)
            import dslprescriber.*
            compression = WDRCParameters(self.channels);
            compression.crossFrequenciesHz = self.getCrossFrequencies();
            selectedChannels = self.getSelectedChannels(compression.crossFrequenciesHz);
            vSennCorrection_dB = zeros(1, self.channels);
            preAdjustedBOLT_dB_SPL = zeros(1, self.channels);
            for n = 1:self.channels
                channelRange = selectedChannels(n)+1:selectedChannels(n+1);
                averages = AverageOfKeys(self.centerFrequenciesHz(channelRange));
                compression.kneepoint_dB_SPL(n) = averages.average(self.dslFileContents.kneepoint_dB_SPL);
                compression.ratio(n) = averages.average(self.dslFileContents.ratio);
                preAdjustedBOLT_dB_SPL(n) = averages.average(self.dslFileContents.targetBOLT_dB_SPL);
                compression.kneepointGain_dB(n) = averages.average(self.dslFileContents.kneepointGain_dB);
                vSennCorrection_dB(n) = mean(self.SennCorrection_dB(channelRange));
            end
            compression.BOLT_dB_SPL = preAdjustedBOLT_dB_SPL - vSennCorrection_dB;
            compression.fullscale_dB_SPL = 119;
            compression.attack_ms = attack_ms;
            compression.release_ms = release_ms;
            [x, Fs] = audioread('Carrots.wav');
            x = x * 10^((60 - compression.fullscale_dB_SPL)/20) / rms(x);
            compression = self.tune(x, Fs, compression);
            DSL.attack = attack_ms;
            DSL.release = release_ms;
            DSL.channels = self.channels;
            DSL.cross_frequencies_Hz = compression.crossFrequenciesHz;
            DSL.kneepoint_gains_dB = compression.kneepointGain_dB;
            DSL.compression_ratios = compression.ratio;
            DSL.kneepoints_dB_SPL = compression.kneepoint_dB_SPL;
            DSL.BOLT_dB_SPL = preAdjustedBOLT_dB_SPL;
            DSL.target_low = cell2mat(self.dslFileContents.targetLow_dB_SPL.values());
            DSL.target_average = cell2mat(self.dslFileContents.targetAverage_dB_SPL.values());
            DSL.target_high = cell2mat(self.dslFileContents.targetHigh_dB_SPL.values());
            DSL.threshold_dB_SPL = cell2mat(self.getThirdOctaveThresholds(self.thresholds_dB_HL).values());
            
            t = (0:round(0.128.*Fs)) / Fs;
            MPO = zeros(1, numel(self.centerFrequenciesHz));
            for n = 1:length(self.centerFrequenciesHz)
                MPOsignal = sin(2*pi*self.centerFrequenciesHz(n)*t);
                MPOsignal = MPOsignal * 10^((90 - compression.fullscale_dB_SPL)/20) / rms(MPOsignal);
                processedMpo = HearingAidProcessor(compression).process(MPOsignal, Fs);
                MPO(n) = self.SennCorrection_dB(n) + compression.fullscale_dB_SPL + 20*log10(rms(processedMpo));
            end
            
            DSL.MPO = MPO;
        end
    end
    
    methods (Access = private)
        function frequencies = getCrossFrequencies(self)
            something = (1:self.channels-1) / self.channels;
            frequencies = ...
                self.centerFrequenciesHz(end) .^ something ...
                .* self.centerFrequenciesHz(1) .^ (1 - something);
        end
        
        function channels = getSelectedChannels(self, crossFrequenciesHz)
            channels = zeros(1, self.channels + 1);
            for i = 1:self.channels-1
                channels(i+1) = find(self.centerFrequenciesHz / crossFrequenciesHz(i) <= 1, 1, 'last');
            end
            channels(end) = length(self.centerFrequenciesHz);
        end
        
        function compression = tune(self, x, Fs, compression)
            import dslprescriber.*
            vTargetAverage_dB_SPL = zeros(1, self.channels);
            vSennCorrection_dB = zeros(1, self.channels);
            selectedChannels = self.getSelectedChannels(compression.crossFrequenciesHz);
            for n = 1:self.channels
                channelRange = selectedChannels(n)+1:selectedChannels(n+1);
                averages = AverageOfKeys(self.centerFrequenciesHz(channelRange));
                vTargetAverage_dB_SPL(n) = averages.average(self.dslFileContents.targetAverage_dB_SPL);
                vSennCorrection_dB(n) = mean(self.SennCorrection_dB(channelRange));
            end
            minimumGain_dB = -vSennCorrection_dB;
            overlap = 1:round(self.channels/4);
            minimumGain_dB(overlap) = minimumGain_dB(overlap) - 10*log10(self.channels); % Correct for channel overlap
            maximumGain_dB = 55;
            for k = 1:2
                averageOutput_dB_SPL = ...
                    compression.fullscale_dB_SPL + ...
                    speechmap2(HearingAidProcessor(compression).process(x, Fs), Fs) + ...
                    self.SennCorrection_dB;
                for n = 1:self.channels
                    vAverageOutput_dB_SPL = ...
                        mean(averageOutput_dB_SPL(selectedChannels(n)+1:selectedChannels(n+1)));
                    compression.kneepointGain_dB(n) = ...
                        compression.kneepointGain_dB(n) + ...
                        vTargetAverage_dB_SPL(n) - ...
                        vAverageOutput_dB_SPL;
                    compression.kneepointGain_dB(n) = ...
                        max(compression.kneepointGain_dB(n), minimumGain_dB(n));
                    compression.kneepointGain_dB(n) = ...
                        min(compression.kneepointGain_dB(n), maximumGain_dB);
                end
            end
        end
    end
end

