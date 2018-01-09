classdef Model < handle
    properties (Access = private)
        map
    end
    
    methods
        function self = Model(frequencies)
            values = nan(1, numel(frequencies));
            map = containers.Map(frequencies, values);
            self.map = map;
        end
        
        function setLevel(self, frequency, level)
            self.map(frequency) = level;
        end
        
        function level = getLevel(self, frequency)
            level = self.map(frequency);
        end
    end
end

