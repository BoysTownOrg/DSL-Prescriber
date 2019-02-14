classdef Audiogram < handle
    methods (Abstract)
        setController(self, controller)
        show(self)
        setMarkerPosition(self, i, x, y)
        setEntry(self, i, text_)
        clearEntry(self, i)
        text_ = entryText(self, i)
        createEntries(self, n)
        createMarkers(self, n)
        hideAllMarkers(self)
        hideMarker(self, i)
        setXLimits(self, limits)
        setYLimits(self, limits)
        setXTicks(self, ticks)
        setYTicks(self, ticks)
        setXLabel(self, label)
        setYLabel(self, label)
        setTableColumnNames(self, names)
        setTableRowName(self, name)
        setTableData(self, data)
        [fileName, pathName] = browseFilesForOpening(self, filters, title)
        [fileName, pathName] = browseFilesForSaving(self, filters, title)
        showErrorDialog(self, message)
        leftClicked(self)
    end
end

