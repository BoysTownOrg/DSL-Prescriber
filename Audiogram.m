classdef Audiogram < handle
    properties (Constant)
        TESTING_FREQUENCIES_HZ = [250,500,750,1000,1500,2000,3000,4000,6000,8000]
        X_TICKS = 1:numel(Audiogram.TESTING_FREQUENCIES_HZ)
        LOWER_LEVEL_BOUND_HL = -10
        UPPER_LEVEL_BOUND_HL = 120
        LEVEL_STEP_SIZE_HL = 10
    end
    
    properties (Access = private)
        mainFigure
        mainAxes
        selections
    end
    
    methods
        function self = Audiogram()
            mainFigure = figure( ...
                'menubar', 'none', ...
                'toolbar', 'none', ...
                'numbertitle', 'off', ...
                'units', 'normalized', ...
                'position', [0.1, 0.1, 0.8, 0.8], ...
                'name', 'Audiogram', ...
                'handlevisibility', 'off', ...
                'closerequestfcn', @(~, ~)self.onCloseRequest());
            frequencyNamesCell = cell(1, numel(self.TESTING_FREQUENCIES_HZ));
            for i = 1:numel(frequencyNamesCell)
                frequencyNamesCell{i} = sprintf('%i', self.TESTING_FREQUENCIES_HZ(i));
            end
            scale = 1.1;
            xLimits ...
                = [self.X_TICKS(end) * (1 - scale) + self.X_TICKS(1) * (1 + scale), ...
                self.X_TICKS(end) * (1 + scale) + self.X_TICKS(1) * (1 - scale)] * 0.5;
            yTicks = self.LOWER_LEVEL_BOUND_HL:self.LEVEL_STEP_SIZE_HL:self.UPPER_LEVEL_BOUND_HL;
            mainAxes = axes( ...
                'units', 'normalized', ...
                'position', [0.1, 0.1, 0.8, 0.8], ...
                'Parent', mainFigure, ...
                'xgrid', 'on', ...
                'ygrid', 'on', ...
                'xticklabel', frequencyNamesCell, ...
                'xtick', self.X_TICKS, ...
                'xlim', xLimits, ...
                'yTick', yTicks, ...
                'ylim', [yTicks(1), yTicks(end)], ...
                'buttondownfcn', @(~, ~)self.onAxesClick());
            xlabel(mainAxes, 'frequency (Hz)');
            ylabel(mainAxes, 'threshold (dB HL)');
            selections = gobjects(1, numel(self.TESTING_FREQUENCIES_HZ));
            for i = 1:numel(selections)
                selections(i) = line(mainAxes, self.X_TICKS(i), self.UPPER_LEVEL_BOUND_HL, ...
                    'marker', 'x', ...
                    'markersize', 15, ...
                    'color', 'red');
            end
            self.selections = selections;
            self.mainFigure = mainFigure;
            self.mainAxes = mainAxes;
        end
    end
    
    methods (Access = private)
        function onCloseRequest(self)
            delete(self.mainFigure);
        end
        
        function onAxesClick(self)
            points = get(self.mainAxes, 'currentpoint');
            clickX = points(1);
            clickY = points(3);
            index = self.getNearestIndex(self.X_TICKS, clickX);
            set(self.selections(index), 'ydata', clickY);
        end
        
        function index = getNearestIndex(~, array, value)
            [~, index] = min(abs(array - value));
        end
    end
end

