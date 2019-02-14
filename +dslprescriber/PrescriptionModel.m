classdef PrescriptionModel < dslprescriber.Model
    properties (Access = private)
        frequenciesHz
        thresholds
        tdhCorrections
        prescription
    end
    
    methods
        function self = PrescriptionModel(tdhCorrections)
            frequenciesHz = cell2mat(tdhCorrections.keys());
            self.thresholds = containers.Map(...
                frequenciesHz, ...
                nan(1, numel(frequenciesHz)));
            self.frequenciesHz = frequenciesHz;
            self.tdhCorrections = tdhCorrections;
        end
        
        function f = getFrequenciesHz(self)
            f = self.frequenciesHz;
        end
        
        function levels = getRealEarSpls(self)
            levels = nan(1, numel(self.frequenciesHz));
            for i = 1:numel(self.frequenciesHz)
                levels(i) = ...
                    self.thresholds(self.frequenciesHz(i)) + ...
                    self.tdhCorrections(self.frequenciesHz(i));
            end
        end
        
        function setThreshold(self, frequencyHz, levelHL)
            self.thresholds(frequencyHz) = levelHL;
        end
        
        function removeThreshold(self, frequencyHz)
            self.thresholds(frequencyHz) = nan;
        end
        
        function tunePrescription(self, filePath)
            channelCount = 8;
            attack_ms = 5;
            release_ms = 50;
            tuner = dslprescriber.WDRCTuner(channelCount, self.thresholds, filePath);
            self.prescription = tuner.generateDSL(attack_ms, release_ms);
        end
        
        function savePrescription(self, filePath)
            file = dslprescriber.File(filePath, 'w');
            file.fprintf('%s', jsonencode(self.prescription));
        end
    end
end

