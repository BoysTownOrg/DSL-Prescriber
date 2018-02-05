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
            model = Model( ...
                frequenciesHz, ...
                @(level, frequency)self.onUpdateModel(level, frequency));
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
            theMenu = uimenu(mainFigure, ...
                'label', 'Analyze');
            uimenu(theMenu, ...
                'label', 'Compute thresholds (SPL)', ...
                'callback', @(~, ~)self.computeThresholds());
            xTicks = 1:numel(frequenciesHz);
            frequencyNamesCell = cell(1, numel(xTicks));
            for i = 1:numel(xTicks)
                frequency = frequenciesHz(i);
                frequencyNamesCell{i} = sprintf('%i', frequency);
            end
            scale = 1.1;
            xLimits = [ ...
                xTicks(end) * (1 - scale) + xTicks(1) * (1 + scale), ...
                xTicks(end) * (1 + scale) + xTicks(1) * (1 - scale)] * 0.5;
            yTicks = self.LOWER_LEVEL_BOUND_HL:self.LEVEL_STEP_SIZE_HL:self.UPPER_LEVEL_BOUND_HL;
            mainAxes = axes( ...
                'units', 'normalized', ...
                'position', [0.1, 0.2, 0.8, 0.7], ...
                'Parent', mainFigure, ...
                'xgrid', 'on', ...
                'ygrid', 'on', ...
                'xticklabel', frequencyNamesCell, ...
                'xtick', xTicks, ...
                'xlim', xLimits, ...
                'yTick', yTicks, ...
                'ylim', [yTicks(1), yTicks(end)], ...
                'buttondownfcn', @(~, ~)self.onAxesClick());
            xlabel(mainAxes, 'frequency (Hz)');
            ylabel(mainAxes, 'threshold (dB HL)');
            selections = gobjects(1, numel(frequenciesHz));
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
        
        function index = getNearestIndex(~, array, value)
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
    end
end

