classdef Audiogram < handle
    properties (Constant, Access = private)
        LOWER_LEVEL_BOUND_HL = -10
        UPPER_LEVEL_BOUND_HL = 120
        LEVEL_STEP_SIZE_HL = 10
        CANCEL_EXCEPTION_ID = 'Audiogram:userCancel'
    end
    
    properties (Access = private)
        mainFigure
        mainAxes
        selections
        entries
        frequenciesHz
        xTicks
        mouseHoverText
        thresholds
    end
    
    methods
        function self = Audiogram(frequenciesHz)
            mainFigure = self.initFigure();
            self.initMenu(mainFigure);
            frequencyNames = self.getFrequencyNames(frequenciesHz);
            xTicks = 1:numel(frequencyNames);
            mainAxes = self.initAxes(mainFigure, xTicks);
            set(mainAxes, 'xticklabel', frequencyNames);
            selections = self.initSelections(mainAxes, xTicks);
            mouseHoverText = self.initMouseHoverText(mainAxes);
            xMidPoints = self.getXMidPoints(mainAxes, xTicks);
            entries = self.initEntries(mainFigure, xMidPoints);
            self.setEntryCallbacks(entries, frequenciesHz)
            levels = nan(1, numel(frequenciesHz));
            thresholds = containers.Map(frequenciesHz, levels);
            self.entries = entries;
            self.mouseHoverText = mouseHoverText;
            self.selections = selections;
            self.mainFigure = mainFigure;
            self.mainAxes = mainAxes;
            self.thresholds = thresholds;
            self.xTicks = xTicks;
            self.frequenciesHz = frequenciesHz;
        end
    end
    
    methods (Access = private)
        function mainFigure = initFigure(self)
            mainFigure = figure( ...
                'menubar', 'none', ...
                'toolbar', 'none', ...
                'numbertitle', 'off', ...
                'units', 'normalized', ...
                'position', [0.1, 0.1, 0.8, 0.8], ...
                'name', 'Audiogram', ...
                'handlevisibility', 'off', ...
                'windowbuttonmotionfcn', @(~, ~)self.onMoveMouse(), ...
                'closerequestfcn', @(~, ~)self.onCloseRequest());
        end
        
        function initMenu(self, parent)
            theMenu = uimenu(parent, ...
                'label', 'Analyze');
            uimenu(theMenu, ...
                'label', 'Compute thresholds (SPL)', ...
                'callback', @(~, ~)self.computeThresholds());
            uimenu(theMenu, ...
                'label', 'Generate prescription', ...
                'callback', @(~, ~)self.tryGeneratingPrescription());
        end
        
        function names = getFrequencyNames(self, frequencies)
            frequencyCount = numel(frequencies);
            names = cell(1, frequencyCount);
            for i = 1:frequencyCount
                frequency = frequencies(i);
                names{i} = sprintf('%g', frequency);
            end
        end
        
        function mainAxes = initAxes(self, parent, xTicks)
            scale = 1.1;
            xLimits = [ ...
                xTicks(end) * (1 - scale) + xTicks(1) * (1 + scale), ...
                xTicks(end) * (1 + scale) + xTicks(1) * (1 - scale)] * 0.5;
            yTicks = self.LOWER_LEVEL_BOUND_HL:self.LEVEL_STEP_SIZE_HL:self.UPPER_LEVEL_BOUND_HL;
            mainAxes = axes( ...
                'units', 'normalized', ...
                'position', [0.1, 0.2, 0.8, 0.7], ...
                'Parent', parent, ...
                'xgrid', 'on', ...
                'ygrid', 'on', ...
                'xtick', xTicks, ...
                'xlim', xLimits, ...
                'yTick', yTicks, ...
                'ylim', [yTicks(1), yTicks(end)], ...
                'buttondownfcn', @(~, ~)self.onAxesClick());
            xlabel(mainAxes, 'frequency (Hz)');
            ylabel(mainAxes, 'level (dB HL)');
        end
        
        function selections = initSelections(self, parent, xTicks)
            selectionsCount = numel(xTicks);
            selections = gobjects(1, selectionsCount);
            for i = 1:selectionsCount
                selections(i) = line(xTicks(i), nan, ...
                    'parent', parent, ...
                    'marker', 'pentagram', ...
                    'markersize', 15, ...
                    'color', 'magenta');
            end
        end
        
        function mouseHoverText = initMouseHoverText(self, parent)
            mouseHoverText = text(0, 0, '', ...
                'parent', parent, ...
                'clipping', 'on', ...
                'pickableparts', 'none');
        end
        
        function midPoints = getXMidPoints(self, mainAxes, xTicks)
            axesPosition = get(mainAxes, 'position');
            axesXLimits = get(mainAxes, 'xlim');
            xLimitSpan = axesXLimits(end) - axesXLimits(1);
            midPoints = axesPosition(1) + (xTicks - axesXLimits(1)) / xLimitSpan * axesPosition(3);
        end
        
        function entries = initEntries(self, parent, xMidPoints)
            entryCount = numel(xMidPoints);
            entries = gobjects(1, entryCount);
            textWidth = 0.04;
            for i = 1:entryCount
                entries(i) = uicontrol(parent, ...
                    'style', 'edit', ...
                    'units', 'normalized', ...
                    'position', [xMidPoints(i) - textWidth / 2, 0.08, textWidth, 0.04]);
            end
        end
        
        function setEntryCallbacks(self, entries, frequencies)
            for i = 1:numel(entries)
                set(entries(i), ...
                    'callback', @(~, ~)self.onUpdateEntry(frequencies(i)));
            end
        end
        
        function onCloseRequest(self)
            delete(self.mainFigure);
        end
        
        function onAxesClick(self)
            points = get(self.mainAxes, 'currentpoint');
            clickX = points(1);
            index = self.getNearestIndex(self.xTicks, clickX);
            frequency = self.frequenciesHz(index);
            clickY = points(3);
            evaluatedLevel = self.getLevelFromMouseY(clickY);
            self.thresholds(frequency) = evaluatedLevel;
            set(self.selections(index), 'ydata', evaluatedLevel);
            set(self.entries(index), 'string', sprintf('%d', evaluatedLevel));
        end
        
        function index = getNearestIndex(self, array, value)
            [~, index] = min(abs(array - value));
        end
        
        function onUpdateEntry(self, frequency)
            entry = self.entries(self.frequenciesHz == frequency);
            enteredLevel = str2double(get(entry, 'string'));
            self.thresholds(frequency) = enteredLevel;
            set(self.selections(self.frequenciesHz == frequency), ...
                'ydata', enteredLevel);
        end
        
        function onMoveMouse(self)
            currentPoint = get(self.mainAxes, 'currentpoint');
            mouseX = currentPoint(1);
            mouseY = currentPoint(3);
            if mouseX < self.xTicks(2)
                direction = 1;
            else
                direction = -1;
            end
            scale = 0.07;
            offsetScale = direction * scale;
            xLimit = get(self.mainAxes, 'xlim');
            textPosition = [mouseX + offsetScale * (xLimit(end) - xLimit(1)), mouseY, 0];
            theText = sprintf('%d dB HL', self.getLevelFromMouseY(mouseY));
            set(self.mouseHoverText, ...
                'position', textPosition, ...
                'string', theText);
        end
        
        function level = getLevelFromMouseY(self, mouseY)
            level = round(mouseY);
        end
        
        function computeThresholds(self)
            newFigure = figure( ...
                'menubar', 'none', ...
                'toolbar', 'none', ...
                'numbertitle', 'off', ...
                'units', 'normalized', ...
                'position', [0.4, 0.3, 0.2, 0.4], ...
                'name', 'Thresholds (SPL)', ...
                'handlevisibility', 'off');
            COLUMNS = 2;
            tableData = nan(numel(self.frequenciesHz), COLUMNS);
            FREQUENCY = 1;
            LEVEL = 2;
            for i = 1:numel(self.frequenciesHz)
                frequency = self.frequenciesHz(i);
                tableData(i, FREQUENCY) = frequency;
                level = self.thresholds(frequency);
                tableData(i, LEVEL) = level + dslprescriber.TDHCorrections.levels(frequency);
            end
            columnHeadings = cell(1, COLUMNS);
            columnHeadings{FREQUENCY} = 'Frequency (Hz)';
            columnHeadings{LEVEL} = 'Real Ear SPL';
            uitable(newFigure, ...
                'units', 'normalized', ...
                'position', [0.1, 0.1, 0.8, 0.8], ...
                'columnName', columnHeadings, ...
                'data', tableData);
        end
        
        function tryGeneratingPrescription(self)
            try
                self.generatePrescription();
            catch ME
                if strcmpi(ME.identifier, self.CANCEL_EXCEPTION_ID)
                    return
                else
                    errordlg(ME.message, 'Error');
                end
            end
        end
        
        function generatePrescription(self)
            [fileName, pathName] = uigetfile('*.csv', 'Open DSL output file');
            if ~pathName
                throw(MException(self.CANCEL_EXCEPTION_ID, ''));
            end
            dslFile = [pathName, fileName];
            DSL = self.generateDSL(dslFile);
            self.saveDSL(DSL);
            msgbox('Successfully saved prescription', 'Success', 'modal');
        end
        
        function DSL = generateDSL(self, dslFile)
            defaultAttackMilliseconds = 5;
            defaultReleaseMilliseconds = 50;
            protocol = dslprescriber.PrescriptionProtocol(defaultAttackMilliseconds, defaultReleaseMilliseconds);
            if protocol.userCancels()
                throw(MException(self.CANCEL_EXCEPTION_ID, ''));
            end
            attackMilliseconds = protocol.getAttackMilliseconds();
            releaseMilliseconds = protocol.getReleaseMilliseconds();
            channelCount = 8;
            tuner = dslprescriber.WDRCTuner(channelCount, self.thresholds, dslFile);
            DSL = tuner.generateDSL(attackMilliseconds, releaseMilliseconds);
        end
        
        function saveDSL(self, DSL)
            [fileName, pathName] = uiputfile('*.json', 'Save prescription');
            file = [pathName, fileName];
            fid = fopen(file, 'w');
            assert(fid ~= -1, ['Unable to open ', file, ' for writing.']);
            result = jsonencode(DSL);
            fprintf(fid, '%s', result);
            fclose(fid);
        end
    end
end
