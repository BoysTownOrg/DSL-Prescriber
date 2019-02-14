classdef MatlabAudiogram < dslprescriber.Audiogram
    properties (Access = private)
        theFigure
        theAxes
        theTable
        markers
        entries
        controller
    end
    
    methods
        function self = MatlabAudiogram()
            theFigure = figure( ...
                'menubar', 'none', ...
                'toolbar', 'none', ...
                'numbertitle', 'off', ...
                'units', 'normalized', ...
                'position', [0.1, 0.1, 0.8, 0.8], ...
                'name', 'Audiogram', ...
                'visible', 'off');
            theAxes = axes(theFigure, ...
                'units', 'normalized', ...
                'position', [0.1, 0.28, 0.8, 0.7], ...
                'xgrid', 'on', ...
                'ygrid', 'on', ...
                'xscale', 'log', ...
                'buttondownfcn', @(~, ~)self.onClickAxes());
            theTable = uitable(theFigure, ...
                'units', 'normalized', ...
                'position', [0.1, 0.05, 0, 0], ...
                'rowname', '');
            uicontrol(theFigure, ...
                'style', 'pushbutton', ...
                'units', 'normalized', ...
                'position', [0.7, 0.05, 0.08, 0.05], ...
                'string', 'save prescription', ...
                'callback', @(~, ~)self.controller.savePrescription());
            self.theFigure = theFigure;
            self.theAxes = theAxes;
            self.theTable = theTable;
        end
        
        function setEntry(self, i, text_)
            set(self.entries(i), 'string', text_);
        end
        
        function clearEntry(self, i)
            set(self.entries(i), 'string', '');
        end
        
        function text_ = entryText(self, i)
            text_ = get(self.entries(i), 'string');
        end
        
        function createEntries(self, n)
            self.entries = gobjects(1, n);
            textWidth = 0.04;
            axesPosition = get(self.theAxes, 'position');
            axesLeftEdge = axesPosition(1);
            for i = 1:n
                self.entries(i) = uicontrol(self.theFigure, ...
                    'style', 'edit', ...
                    'units', 'normalized', ...
                    'position', [axesLeftEdge + (i - 1) * textWidth, 0.16, textWidth, 0.04], ...
                    'callback', @(~, ~)self.controller.onEntryEdit(i));
            end
        end
        
        function answer = leftClicked(self)
            answer = strcmp('normal', get(self.theFigure, 'SelectionType'));
        end
        
        function setController(self, controller)
            self.controller = controller;
        end
        
        function setXLimits(self, limits)
            set(self.theAxes, 'xlim', limits);
        end
        
        function setYLimits(self, limits)
            set(self.theAxes, 'ylim', limits);
        end
        
        function setXTicks(self, ticks)
            set(self.theAxes, 'xtick', ticks);
        end
        
        function setYTicks(self, ticks)
            set(self.theAxes, 'ytick', ticks);
        end
        
        function setXLabel(self, label)
            xlabel(self.theAxes, label);
        end
        
        function setYLabel(self, label)
            ylabel(self.theAxes, label);
        end
        
        function show(self)
            set(self.theFigure, 'visible', 'on');
        end
        
        function setMarkerPosition(self, i, x, y)
            set(self.markers(i), 'xdata', x, 'ydata', y);
        end
        
        function createMarkers(self, n)
            self.markers = gobjects(1, n);
            for i = 1:n
                self.markers(i) = line(0, 0, ...
                    'parent', self.theAxes, ...
                    'marker', 'pentagram', ...
                    'markersize', 15, ...
                    'color', 'magenta', ...
                    'hittest', 'off');
            end
        end
        
        function hideAllMarkers(self)
            for i = 1:numel(self.markers)
                set(self.markers(i), 'ydata', nan);
            end
        end
        
        function hideMarker(self, index)
            set(self.markers(index), 'ydata', nan);
        end
        
        function setTableColumnNames(self, names)
            set(self.theTable, 'columnname', names);
            self.fitTablePosition();
        end
        
        function setTableRowName(self, name)
            set(self.theTable, 'rowname', name);
            self.fitTablePosition();
        end
        
        function setTableData(self, data)
            set(self.theTable, 'data', data);
            self.fitTablePosition();
        end
    end
    
    methods (Access = private)
        function fitTablePosition(self)
            extent = get(self.theTable, 'extent');
            position = get(self.theTable, 'position');
            position(3:4) = extent(3:4);
            set(self.theTable, 'position', position);
        end
        
        function onClickAxes(self)
            points = get(self.theAxes, 'currentpoint');
            clickX = points(1);
            clickY = points(3);
            self.controller.onClickAxes(clickX, clickY);
        end
    end
    
    methods
        function [fileName, pathName] = browseFilesForOpening(~, filters, title)
            [fileName, pathName] = uigetfile(filters, title);
        end
        
        function [fileName, pathName] = browseFilesForSaving(~, filters, title)
            [fileName, pathName] = uiputfile(filters, title);
        end
        
        function showErrorDialog(~, message)
            errordlg(message);
        end
    end
end

