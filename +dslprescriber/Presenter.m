classdef Presenter < handle
    properties (Access = private)
        audiogram
        model
    end
    
    methods
        function self = Presenter(...
                audiogram, ...
                model, ...
                levelsHL...
            )
            if nargin < 3
                levelsHL = -10:10:120;
            end
            audiogram.setController(self);
            frequenciesHz = model.getFrequenciesHz();
            audiogram.createEntries(numel(frequenciesHz));
            audiogram.createMarkers(numel(frequenciesHz));
            audiogram.hideAllMarkers();
            audiogram.setTableColumnNames(strsplit(num2str(frequenciesHz)));
            audiogram.setTableRowName('Real Ear SPL');
            audiogram.setTableData(nan(1, numel(frequenciesHz)));
            if numel(frequenciesHz) > 0
                audiogram.setXLimits([0.9*frequenciesHz(1), 1.1*frequenciesHz(end)]);
            end
            audiogram.setYLimits([levelsHL(1), levelsHL(end)]);
            audiogram.setXTicks(frequenciesHz);
            audiogram.setYTicks(levelsHL);
            audiogram.setXLabel('frequency (Hz)');
            audiogram.setYLabel('level (dB HL)');
            self.audiogram = audiogram;
            self.model = model;
        end
        
        function run(self)
            self.audiogram.show();
        end
        
        function onEntryEdit(self, index)
            frequenciesHz = self.model.getFrequenciesHz();
            frequency = frequenciesHz(index);
            threshold = str2double(self.audiogram.entryText(index));
            self.model.setThreshold(frequency, threshold);
            self.audiogram.setMarkerPosition(...
                index, ...
                frequency, ...
                threshold ...
            );
            self.audiogram.setTableData(self.model.getRealEarSpls());
        end
        
        function onClickAxes(self, x, y)
            frequenciesHz = self.model.getFrequenciesHz();
            [~, index] = min(abs(frequenciesHz - x));
            frequency = frequenciesHz(index);
            if self.audiogram.leftClicked()
                newThreshold = round(y);
                self.model.setThreshold(frequency, newThreshold);
                self.audiogram.setMarkerPosition(...
                    index, ...
                    frequency, ...
                    newThreshold ...
                );
                self.audiogram.setEntry(index, sprintf('%i', newThreshold));
            else
                self.model.removeThreshold(frequency);
                self.audiogram.hideMarker(index);
                self.audiogram.clearEntry(index);
            end
            self.audiogram.setTableData(self.model.getRealEarSpls());
        end
        
        function savePrescription(self)
            try
                [fileName, filePath] = self.audiogram.browseFilesForOpening('*.csv', 'Open DSL file');
                if fileName == 0
                    return
                end
                self.model.tunePrescription([filePath, fileName]);
                [fileName, filePath] = self.audiogram.browseFilesForSaving('*.json', 'Save prescription');
                if fileName == 0
                    return
                end
                self.model.savePrescription([filePath, fileName]);
            catch exception
                self.audiogram.showErrorDialog(exception.message());
            end
        end
    end
end

