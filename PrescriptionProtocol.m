classdef PrescriptionProtocol < handle
    properties (Access = private)
        theFigure
        attackMilliseconds
        attackMillisecondsEntry
        releaseMilliseconds
        releaseMillisecondsEntry
        selectionComplete
    end
    
    methods
        function self = PrescriptionProtocol()
            self.selectionComplete = false;
        end
        
        function attackMilliseconds = getAttackMilliseconds(self)
            self.waitForSelectionsIfNeeded();
            attackMilliseconds = self.attackMilliseconds;
        end
        
        function releaseMilliseconds = getReleaseMilliseconds(self)
            self.waitForSelectionsIfNeeded();
            releaseMilliseconds = self.releaseMilliseconds;
        end
    end
    
    methods (Access = private)
        function waitForSelectionsIfNeeded(self)
            if ~self.selectionComplete
                self.waitForSelections();
                self.selectionComplete = true;
            end
        end
        
        function waitForSelections(self)
            self.theFigure = figure( ...
                'menubar', 'none', ...
                'toolbar', 'none', ...
                'numbertitle', 'off', ...
                'units', 'normalized', ...
                'position', [0.4, 0.4, 0.2, 0.2], ...
                'windowstyle', 'modal');
            self.attackMillisecondsEntry = LabeledEntry( ...
                'parent', self.theFigure, ...
                'units', 'normalized', ...
                'position', [0.1, 0.6, 0.8, 0.3]);
            self.attackMillisecondsEntry.setLabelProperties('string', 'attack (ms)');
            self.releaseMillisecondsEntry = LabeledEntry( ...
                'parent', self.theFigure, ...
                'units', 'normalized', ...
                'position', [0.1, 0.3, 0.8, 0.3]);
            self.releaseMillisecondsEntry.setLabelProperties('string', 'release (ms)');
            uicontrol( ...
                'parent', self.theFigure, ...
                'style', 'pushbutton', ...
                'units', 'normalized', ...
                'position', [0.7, 0.1, 0.2, 0.1], ...
                'string', 'confirm', ...
                'callback', @(~, ~)self.onConfirm());
            waitfor(self.theFigure);
        end
        
        function onConfirm(self)
            self.releaseMilliseconds = self.releaseMillisecondsEntry.getEntry();
            self.attackMilliseconds = self.attackMillisecondsEntry.getEntry();
            close(self.theFigure);
        end
    end
end