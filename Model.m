classdef Model < handle
    properties (Access = private)
        map
        onUpdate
    end
    
    methods
        function self = Model(frequencies, onUpdate)
            values = nan(1, numel(frequencies));
            map = containers.Map(frequencies, values);
            self.map = map;
            self.onUpdate = onUpdate;
        end
        
        function setLevel(self, frequency, level)
            self.map(frequency) = level;
            self.onUpdate(frequency, level);
        end
        
        function level = getLevel(self, frequency)
            level = self.map(frequency);
        end
    end
end

