classdef LabeledEntry < handle
    properties (Access = private)
        panel
        label
        entry
    end
    
    methods
        function self = LabeledEntry(varargin)
            panel = uipanel(varargin{:});
            set(panel, 'bordertype', 'none');
            label = uicontrol(panel, ...
                'Style', 'text', ...
                'Units', 'normalized', ...
                'Position', [0, 0.6, 1, 0.4], ...
                'HorizontalAlignment', 'Left');
            entry = uicontrol(panel, ...
                'Style', 'Edit', ...
                'Units', 'Normalized', ...
                'Position', [0, 0, 0.99, 0.6], ...
                'HorizontalAlignment', 'left');
            self.label = label;
            self.entry = entry;
            self.panel = panel;
        end
        
        function setLabelProperties(self, varargin)
            set(self.label, varargin{:});
        end
        
        function setEntryProperties(self, varargin)
            set(self.entry, varargin{:});
        end
        
        function setPropertiesForBoth(self, varargin)
            set([self.entry, self.label], varargin{:});
        end
        
        function entry = getEntry(self)
            entry = get(self.entry, 'string');
        end
        
        function hide(self)
            set(self.panel, 'visible', 'off');
        end
        
        function show(self)
            set(self.panel, 'visible', 'on');
        end
    end
end

