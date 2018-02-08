classdef Audiogram < handle
    properties (Constant, Access = private)
        LOWER_LEVEL_BOUND_HL = -10
        UPPER_LEVEL_BOUND_HL = 120
        LEVEL_STEP_SIZE_HL = 10
    end
    
    properties (Access = private)
        mainFigure
        mainAxes
        selections
        entries
        frequenciesHz
        xTicks
        mouseHoverText
        model
    end
    
    methods
        function self = Audiogram(frequenciesHz)
            mainFigure = self.initFigure();
            self.initMenu(mainFigure);
            frequencyNames = self.getFrequencyNames(frequenciesHz);
            xTicks = 1:numel(frequencyNames);
            mainAxes = self.initAxes(mainFigure, xTicks);
            set(mainAxes, 'xticklabel', frequencyNames);
            selections = gobjects(1, numel(frequenciesHz));
            model = Model( ...
                frequenciesHz, ...
                @(level, frequency)self.onUpdateModel(level, frequency));
            for i = 1:numel(frequenciesHz)
                frequency = frequenciesHz(i);
                level = model.getLevel(frequency);
                selections(i) = line(mainAxes, xTicks(i), level, ...
                    'marker', 'x', ...
                    'markersize', 15, ...
                    'color', 'red');
            end
            mouseHoverText = text(0, 0, '', ...
                'parent', mainAxes, ...
                'clipping', 'on', ...
                'pickableparts', 'none');
            entries = gobjects(1, numel(frequenciesHz));
            axesPosition = get(mainAxes, 'position');
            axesXLimits = get(mainAxes, 'xlim');
            textWidth = 0.04;
            for i = 1:numel(entries)
                xMid = axesPosition(1) + (xTicks(i) - axesXLimits(1)) / (axesXLimits(end) - axesXLimits(1)) * axesPosition(3);
                selectionY = get(selections(i), 'ydata');
                entries(i) = uicontrol(mainFigure, ...
                    'style', 'edit', ...
                    'units', 'normalized', ...
                    'position', [xMid - textWidth / 2, 0.08, textWidth, 0.04], ...
                    'string', num2str(selectionY), ...
                    'callback', @(~, ~)self.onUpdateEntry(frequenciesHz(i)));
            end
            self.entries = entries;
            self.mouseHoverText = mouseHoverText;
            self.selections = selections;
            self.mainFigure = mainFigure;
            self.mainAxes = mainAxes;
            self.model = model;
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
        end
        
        function onCloseRequest(self)
            delete(self.mainFigure);
        end
        
        function onUpdateModel(self, frequency, level)
            selection = self.selections(self.frequenciesHz == frequency);
            set(selection, 'ydata', level);
            entry = self.entries(self.frequenciesHz == frequency);
            set(entry, 'string', num2str(level));
        end
        
        function onAxesClick(self)
            points = get(self.mainAxes, 'currentpoint');
            clickX = points(1);
            clickY = points(3);
            index = self.getNearestIndex(self.xTicks, clickX);
            frequency = self.frequenciesHz(index);
            evaluatedLevel = round(clickY);
            self.model.setLevel(frequency, evaluatedLevel);
        end
        
        function index = getNearestIndex(self, array, value)
            [~, index] = min(abs(array - value));
        end
        
        function onUpdateEntry(self, frequency)
            entry = self.entries(self.frequenciesHz == frequency);
            enteredLevel = str2double(get(entry, 'string'));
            self.model.setLevel(frequency, enteredLevel);
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
            set(self.mouseHoverText, ...
                'position', [mouseX + offsetScale * (xLimit(end) - xLimit(1)), mouseY, 0], ...
                'string', sprintf('%d dB HL', round(mouseY)));
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
                level = self.model.getLevel(frequency);
                tableData(i, LEVEL) = level + TDHCorrections.levels(frequency);
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
                errordlg(ME.message, 'error');
            end
        end
        
        function generatePrescription(self)
            [fileName, pathName] = uigetfile('*.csv', 'Open DSL output file');
            if pathName
                dslFile = [pathName, fileName];
                DSL = self.generateDSL(dslFile);
                self.saveDSL(DSL);
            end
        end
        
        function DSL = generateDSL(self, dslFile)
            attackMilliseconds = 5;
            releaseMilliseconds = 50;
            channelCount = 8;
            thresholds = self.model.getThresholds();
            tuner = WDRCTuner( ...
                attackMilliseconds, ...
                releaseMilliseconds, ...
                channelCount, ...
                dslFile, ...
                thresholds);
            DSL = tuner.generateDSL();
        end
        
        function saveDSL(self, DSL)
            [fileName, pathName] = uiputfile('*.json', 'Save prescription');
            file = [pathName, fileName];
            fid = fopen(file, 'w');
            assert(fid ~= -1, 'Unable to open ', file, ' for writing.');
            result = jsonencode(DSL);
            fprintf(fid, '%s', result);
            fclose(fid);
        end
    end
end

