classdef PrescriptionProtocol < handle
    properties (Access = private)
        attackMilliseconds
        releaseMilliseconds
        selectionComplete
    end
    
    methods
        function self = PrescriptionProtocol()
            self.selectionComplete = false;
        end
        
        function attackMilliseconds = getAttackMilliseconds(self)
            if ~self.selectionComplete
                self.selectionComplete = true;
            end
            attackMilliseconds = self.attackMilliseconds;
        end
        
        function releaseMilliseconds = getReleaseMilliseconds(self)
            if ~self.selectionComplete
                self.selectionComplete = true;
            end
            releaseMilliseconds = self.releaseMilliseconds;
        end
        
        function waitForSelections(self)
            theFigure = figure( ...
                'menubar', 'none', ...
                'toolbar', 'none', ...
                'numbertitle', 'off', ...
                'units', 'normalized', ...
                'position', [0.4, 0.4, 0.2, 0.2], ...
                
        end
    end
end