classdef Audiogram < handle
    properties (Constant)
        LOWER_LEVEL_BOUND_HL = -10
        UPPER_LEVEL_BOUND_HL = 120
        LEVEL_STEP_SIZE_HL = 10
    end
    
    properties (Access = private)
        mainFigure
        mainAxes
        selections
        entries
        frequencies
        xTicks
        mouseHoverText
        model
    end
    
    methods
        function self = Audiogram(frequencies)
            model = Model(frequencies, @(level, frequency)self.onUpdateModel(level, frequency));
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
            xTicks = 1:numel(frequencies);
            frequencyNamesCell = cell(1, numel(xTicks));
            for i = 1:numel(xTicks)
                frequency = frequencies(i);
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
            selections = gobjects(1, numel(frequencies));
            for i = 1:numel(frequencies)
                frequency = frequencies(i);
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
            entries = gobjects(1, numel(frequencies));
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
                    'callback', @(~, ~)self.onUpdateEntry(frequencies(i)));
            end
            self.entries = entries;
            self.mouseHoverText = mouseHoverText;
            self.selections = selections;
            self.mainFigure = mainFigure;
            self.mainAxes = mainAxes;
            self.model = model;
            self.xTicks = xTicks;
            self.frequencies = frequencies;
        end
    end
    
    methods (Access = private)
        function onCloseRequest(self)
            delete(self.mainFigure);
        end
        
        function onUpdateModel(self, frequency, level)
            selection = self.selections(self.frequencies == frequency);
            set(selection, 'ydata', level);
            entry = self.entries(self.frequencies == frequency);
            set(entry, 'string', num2str(level));
        end
        
        function onAxesClick(self)
            points = get(self.mainAxes, 'currentpoint');
            clickX = points(1);
            clickY = points(3);
            index = self.getNearestIndex(self.xTicks, clickX);
            frequency = self.frequencies(index);
            evaluatedLevel = round(clickY);
            self.model.setLevel(frequency, evaluatedLevel);
        end
        
        function index = getNearestIndex(~, array, value)
            [~, index] = min(abs(array - value));
        end
        
        function onUpdateEntry(self, frequency)
            entry = self.entries(self.frequencies == frequency);
            enteredLevel = str2double(get(entry, 'string'));
            self.model.setLevel(frequency, enteredLevel);
        end
        
        function onMoveMouse(self)
            currentPoint = get(self.mainAxes, 'currentpoint');
            mouseX = currentPoint(1);
            mouseY = currentPoint(3);
            if mouseX < self.xTicks(2)
                direction = -1;
            else
                direction = 1;
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
                'position', [0.3, 0.4, 0.4, 0.2], ...
                'name', 'Thresholds (SPL)', ...
                'handlevisibility', 'off');
            uitable(newFigure, ...
                'units', 'normalized', ...
                'position', [0.1, 0.1, 0.8, 0.8], ...
                'columnName', {'Frequency (Hz)', 'Real Ear SPL'});
        end
    end
end

