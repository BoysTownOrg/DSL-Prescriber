classdef Audiogram < handle
    properties (Constant)
        TESTING_FREQUENCIES_HZ = [250,500,750,1000,1500,2000,3000,4000,6000,8000]
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
                frequencyNamesCell{i} = sprintf('%i', tickFrequencies(i));
            end
            xticks = 0:1/(numel(self.TESTING_FREQUENCIES_HZ) + 1):1;
            yticks = self.LOWER_LEVEL_BOUND_HL:self.LEVEL_STEP_SIZE_HL:self.UPPER_LEVEL_BOUND_HL;
            mainAxes = axes( ...
                'units', 'normalized', ...
                'position', [0.1, 0.1, 0.8, 0.8], ...
                'Parent', mainFigure, ...
                'xgrid', 'on', ...
                'ygrid', 'on', ...
                'xticklabel', frequencyNamesCell, ...
                'xtick', xticks, ...
                'xlim', [xticks(1), xticks(end)], ...
                'yTick', yticks, ...
                'ylim', [yticks(1), yticks(end)], ...
                'buttondownfcn', @(~, ~)self.onAxesClick());
            selections = gobjects(1, numel(self.TESTING_FREQUENCIES_HZ));
            for i = 1:numel(selections)
                selections(i) = line(mainAxes, xticks(i + 1), 0, ...
                    'marker', 'x', ...
                    'markersize', 15, ...
                    'color', 'black');
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
            xticks = 0:1/(numel(self.TESTING_FREQUENCIES_HZ) + 1):1;
            candidates = xticks(2:end-1);
            index = self.getNearestIndex(candidates, clickX);
            set(self.selections(index), 'ydata', clickY);
        end
        
        function index = getNearestIndex(~, array, value)
            [~, index] = min(abs(array - value));
        end
    end
end

