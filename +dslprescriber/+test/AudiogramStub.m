classdef AudiogramStub < dslprescriber.Audiogram
    properties
        controller
        showCalled = false
        lastMarkerX
        lastMarkerY
        lastMarkerIndex
        markersCount
        markerLog
        xLimits
        yLimits
        xTicks
        yTicks
        xLabel
        yLabel
        tableColumnNames
        tableRowName
        tableData
        fileForOpening
        pathForOpening
        fileForSaving
        pathForSaving
        errorMessage
        lastHiddenMarkerIndex
        leftClicked_ = true
        entriesCount
        lastEntryIndex
        lastClearedEntryIndex
        lastEntryText
        entryText_
        entryTextIndex
    end
    
    methods
        function text_ = entryText(self, i)
            text_ = self.entryText_;
            self.entryTextIndex = i;
        end
        
        function simulateEntryEdit(self, i)
            self.controller.onEntryEdit(i);
        end
        
        function clearEntry(self, i)
            self.lastClearedEntryIndex = i;
        end
        
        function setEntry(self, i, text_)
            self.lastEntryIndex = i;
            self.lastEntryText = text_;
        end
        
        function createEntries(self, n)
            self.entriesCount = n;
        end
        
        function answer = leftClicked(self)
            answer = self.leftClicked_;
        end
        
        function hideMarker(self, index)
            self.lastHiddenMarkerIndex = index;
        end
        
        function setController(self, controller)
            self.controller = controller;
        end
        
        function show(self)
            self.showCalled = true;
        end
        
        function simulateAxesClick(self, x, y)
            self.controller.onClickAxes(x, y);
        end
        
        function setMarkerPosition(self, i, x, y)
            self.lastMarkerIndex = i;
            self.lastMarkerX = x;
            self.lastMarkerY = y;
        end
        
        function createMarkers(self, n)
            self.markersCount = n;
            self.markerLog = [self.markerLog, 'create '];
        end
        
        function hideAllMarkers(self)
            self.markerLog = [self.markerLog, 'hide '];
        end
        
        function setXLimits(self, limits)
            self.xLimits = limits;
        end
        
        function setYLimits(self, limits)
            self.yLimits = limits;
        end
        
        function setXTicks(self, ticks)
            self.xTicks = ticks;
        end
        
        function setYTicks(self, ticks)
            self.yTicks = ticks;
        end
        
        function setXLabel(self, label)
            self.xLabel = label;
        end
        
        function setYLabel(self, label)
            self.yLabel = label;
        end
        
        function setTableColumnNames(self, names)
            self.tableColumnNames = names;
        end
        
        function setTableRowName(self, name)
            self.tableRowName = name;
        end
        
        function setTableData(self, data)
            self.tableData = data;
        end
        
        function savePrescription(self)
            self.controller.savePrescription();
        end
        
        function [fileName, filePath] = browseFilesForOpening(self, filters, title)
            fileName = self.fileForOpening;
            filePath = self.pathForOpening;
        end
        
        function [fileName, filePath] = browseFilesForSaving(self, filters, title)
            fileName = self.fileForSaving;
            filePath = self.pathForSaving;
        end
        
        function showErrorDialog(self, m)
            self.errorMessage = m;
        end
    end
end

