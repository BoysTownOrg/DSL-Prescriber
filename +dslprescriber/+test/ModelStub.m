classdef ModelStub < dslprescriber.Model
    properties
        frequenciesHz
        realEarSpls
        thresholdFrequencySet
        thresholdLevelSet
        thresholdFrequencyRemoved
        tunePrescriptionFilePath
        savePrescriptionFilePath
        whenTuningPrescription
        whenThresholdSet
        whenThresholdRemoved
    end
    
    methods
        function callWhenThresholdRemoved(self, f)
            self.whenThresholdRemoved = f;
        end
        
        function callWhenThresholdSet(self, f)
            self.whenThresholdSet = f;
        end
        
        function removeThreshold(self, frequencyHz)
            self.thresholdFrequencyRemoved = frequencyHz;
            self.whenThresholdRemoved();
        end
        
        function f = getFrequenciesHz(self)
            f = self.frequenciesHz;
        end
        
        function levels = getRealEarSpls(self)
            levels = self.realEarSpls;
        end
        
        function setThreshold(self, frequencyHz, levelHL)
            self.thresholdFrequencySet = frequencyHz;
            self.thresholdLevelSet = levelHL;
            self.whenThresholdSet();
        end 
        
        function tunePrescription(self, filePath)
            self.tunePrescriptionFilePath = filePath;
            self.whenTuningPrescription();
        end
        
        function savePrescription(self, filePath)
            self.savePrescriptionFilePath = filePath;
        end
    end
end

