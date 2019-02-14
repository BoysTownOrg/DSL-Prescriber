classdef Model < handle
    methods (Abstract)
        f = getFrequenciesHz(self)
        setThreshold(self, frequencyHz, levelHL)
        removeThreshold(self, frequencyHz)
        levels = getRealEarSpls(self)
        tunePrescription(self, filePath)
        savePrescription(self, filePath)
    end
end

