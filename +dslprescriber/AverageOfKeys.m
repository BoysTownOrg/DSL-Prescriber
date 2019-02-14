classdef AverageOfKeys < handle
    properties (Access = private)
        keys
    end
    
    methods
        function self = AverageOfKeys(keys)
            self.keys = keys;
        end
        
        function result = average(self, container)
            sum = 0;
            for i = 1:numel(self.keys)
                sum = sum + container(self.keys(i));
            end
            result = sum / numel(self.keys);
        end
    end
end