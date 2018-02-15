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
                'windowstyle', 'modal');
            attackMillisecondsEntry = LabeledEntry( ...
                'parent', theFigure, ...
                'units', 'normalized', ...
                'position', [0.1, 0.6, 0.8, 0.3]);
            attackMillisecondsEntry.setLabelProperties('string', 'attack (ms)');
            releaseMillisecondsEntry = LabeledEntry( ...
                'parent', theFigure, ...
                'units', 'normalized', ...
                'position', [0.1, 0.3, 0.8, 0.3]);
            releaseMillisecondsEntry.setLabelProperties('string', 'release (ms)');
            uicontrol( ...
                'parent', theFigure, ...
                'style', 'pushbutton', ...
                'units', 'normalized', ...
                'position', [0.7, 0.1, 0.2, 0.1], ...
                'string', 'confirm', ...
                'callback', @(~, ~)self.onConfirm());
        end
        
        function onConfirm(self)
            self.releaseMilliseconds = 
        end
    end
end