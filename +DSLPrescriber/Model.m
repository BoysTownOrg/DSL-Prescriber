classdef Model < handle
    properties (Access = private)
        thresholds
        onUpdate
    end
    
    methods
        function self = Model(frequencies, onUpdate)
            values = nan(1, numel(frequencies));
            thresholds = containers.Map(frequencies, values);
            self.thresholds = thresholds;
            self.onUpdate = onUpdate;
        end
        
        function setLevel(self, frequency, level)
            self.thresholds(frequency) = level;
            self.onUpdate(frequency, level);
        end
        
        function level = getLevel(self, frequency)
            level = self.thresholds(frequency);
        end
        
        function thresholds = getThresholds(self)
            thresholds = self.thresholds;
        end
    end
end

