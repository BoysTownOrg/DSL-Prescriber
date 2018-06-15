classdef TDHCorrections < handle
    properties (Constant)
        levels = containers.Map( ...
            [250, 500, 750, 1000, 1500, 2000, 3000, 4000, 6000, 8000], ...
            [8.4, 9.3, 14.5, 13.7, 14.4, 19.2, 21.1, 16.4, 16.9, 22.4]);
    end
end

