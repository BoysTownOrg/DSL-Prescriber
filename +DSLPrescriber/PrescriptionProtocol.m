classdef PrescriptionProtocol < handle
    properties (Access = private)
        theFigure
        attackMilliseconds
        attackMillisecondsEntry
        releaseMilliseconds
        releaseMillisecondsEntry
        selectionComplete
        userCancelled
    end
    
    methods
        function self = PrescriptionProtocol(defaultAttackMilliseconds, defaultReleaseMilliseconds)
            if nargin > 0
                self.attackMilliseconds = defaultAttackMilliseconds;
            end
            if nargin > 1
                self.releaseMilliseconds = defaultReleaseMilliseconds;
            end
            self.selectionComplete = false;
            self.userCancelled = false;
        end
        
        function cancels = userCancels(self)
            self.waitForSelectionsIfNeeded();
            cancels = self.userCancelled;
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
                'name', 'Select', ...
                'menubar', 'none', ...
                'toolbar', 'none', ...
                'numbertitle', 'off', ...
                'units', 'normalized', ...
                'position', [0.475, 0.475, 0.15, 0.15], ...
                'windowstyle', 'modal', ...
                'closerequestfcn', @(~, ~)self.onCancel());
            self.attackMillisecondsEntry = DSLPrescriber.LabeledEntry( ...
                'parent', self.theFigure, ...
                'units', 'normalized', ...
                'position', [0.1, 0.6, 0.8, 0.25]);
            self.attackMillisecondsEntry.setLabelProperties('string', 'attack (ms)');
            self.attackMillisecondsEntry.setEntryProperties('string', num2str(self.attackMilliseconds));
            self.attackMillisecondsEntry.setPropertiesForBoth('fontsize', 11);
            self.releaseMillisecondsEntry = DSLPrescriber.LabeledEntry( ...
                'parent', self.theFigure, ...
                'units', 'normalized', ...
                'position', [0.1, 0.3, 0.8, 0.25]);
            self.releaseMillisecondsEntry.setLabelProperties('string', 'release (ms)');
            self.releaseMillisecondsEntry.setEntryProperties('string', num2str(self.releaseMilliseconds));
            self.releaseMillisecondsEntry.setPropertiesForBoth('fontsize', 11);
            uicontrol( ...
                'parent', self.theFigure, ...
                'style', 'pushbutton', ...
                'units', 'normalized', ...
                'position', [0.7, 0.1, 0.2, 0.15], ...
                'string', 'confirm', ...
                'fontsize', 11, ...
                'callback', @(~, ~)self.onConfirm());
            waitfor(self.theFigure);
        end
        
        function onConfirm(self)
            self.releaseMilliseconds = str2double(self.releaseMillisecondsEntry.getEntry());
            self.attackMilliseconds = str2double(self.attackMillisecondsEntry.getEntry());
            delete(self.theFigure);
        end
        
        function onCancel(self)
            self.userCancelled = true;
            delete(self.theFigure)
        end
    end
end