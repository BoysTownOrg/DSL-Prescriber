classdef PresenterTester < matlab.unittest.TestCase
    properties (Access = private)
        audiogram
        model
    end
    
    methods(TestMethodSetup)
        function setup(self)
            import dslprescriber.*
            self.audiogram = test.AudiogramStub();
            self.model = test.ModelStub();
        end
    end
    
    methods (Test)
        function constructorSetsItself(self)
            import dslprescriber.*
            controller = test.PresenterFacade(self.audiogram);
            self.assertEqual(self.audiogram.controller, controller.get());
        end
        
        function runShowsAudiogram(self)
            import dslprescriber.*
            test.PresenterFacade(self.audiogram).run();
            self.assertTrue(self.audiogram.showCalled);
        end
        
        function constructorAssignsFrequencyColumnNamesToRealEarSplTable(self)
            import dslprescriber.*
            self.model.frequenciesHz = [1, 2, 3];
            Presenter(...
                self.audiogram, ...
                self.model...
            );
            self.assertEqual(...
                self.audiogram.tableColumnNames, ...
                {'1', '2', '3'}...
            );
        end
        
        function constructorAssignsNanForEachFrequencyInRealEarSplTable(self)
            import dslprescriber.*
            self.model.frequenciesHz = zeros(1, 3);
            Presenter(...
                self.audiogram, ...
                self.model...
            );
            self.assertEqual(self.audiogram.tableData, [nan, nan, nan]);
        end
        
        function constructorSetsRealEarSplTableRowName(self)
            import dslprescriber.*
            test.PresenterFacade(self.audiogram);
            self.assertEqual(self.audiogram.tableRowName, 'Real Ear SPL');
        end
        
        function constructorCreatesMarkerForEachFrequency(self)
            import dslprescriber.*
            self.model.frequenciesHz = zeros(1, 3);
            Presenter(...
                self.audiogram, ...
                self.model...
            );
            self.assertEqual(self.audiogram.markersCount, 3);
        end
        
        function constructorCreatesEntryForEachFrequency(self)
            import dslprescriber.*
            self.model.frequenciesHz = zeros(1, 3);
            Presenter(...
                self.audiogram, ...
                self.model...
            );
            self.assertEqual(self.audiogram.entriesCount, 3);
        end
        
        function constructorCreatesMarkersBeforeHidingThem(self)
            import dslprescriber.*
            test.PresenterFacade(self.audiogram);
            self.assertEqual(self.audiogram.markerLog, 'create hide ');
        end
        
        function constructorSetsXTicksFromFrequencies(self)
            import dslprescriber.*
            self.model.frequenciesHz = [1, 2, 3];
            Presenter(...
                self.audiogram, ...
                self.model...
            );
            self.assertEqual(self.audiogram.xTicks, [1, 2, 3]);
        end
        
        function constructorSetsYTicksFromLevels(self)
            import dslprescriber.*
            Presenter(...
                self.audiogram, ...
                self.model, ...
                [4, 5]...
            );
            self.assertEqual(self.audiogram.yTicks, [4, 5]);
        end
        
        function constructorSetsAxesLimits(self)
            import dslprescriber.*
            self.model.frequenciesHz = [1, 2, 3];
            Presenter(...
                self.audiogram, ...
                self.model, ...
                [4, 5]...
            );
            self.assertEqual(self.audiogram.xLimits, [1*0.9, 3*1.1]);
            self.assertEqual(self.audiogram.yLimits, [4, 5]);
        end
        
        function constructorSetsLabels(self)
            import dslprescriber.*
            test.PresenterFacade(self.audiogram);
            self.assertEqual(self.audiogram.xLabel, 'frequency (Hz)');
            self.assertEqual(self.audiogram.yLabel, 'level (dB HL)');
        end
        
        function entryEditUpdatesMarkerCorrespondingToFrequency(self)
            import dslprescriber.*
            self.model.frequenciesHz = [500, 750, 1000];
            Presenter(...
                self.audiogram, ...
                self.model...
            );
            self.audiogram.simulateEntryEdit(1);
            self.assertEqual(self.audiogram.lastMarkerX, 500);
            self.assertEqual(self.audiogram.lastMarkerIndex, 1);
            self.audiogram.simulateEntryEdit(2);
            self.assertEqual(self.audiogram.lastMarkerX, 750);
            self.assertEqual(self.audiogram.lastMarkerIndex, 2);
            self.audiogram.simulateEntryEdit(3);
            self.assertEqual(self.audiogram.lastMarkerX, 1000);
            self.assertEqual(self.audiogram.lastMarkerIndex, 3);
        end
        
        function axesClickUpdatesMarkerCorrespondingToNearestFrequency(self)
            import dslprescriber.*
            self.model.frequenciesHz = [500, 750, 1000];
            Presenter(...
                self.audiogram, ...
                self.model...
            );
            self.audiogram.simulateAxesClick(500, 0);
            self.assertEqual(self.audiogram.lastMarkerX, 500);
            self.assertEqual(self.audiogram.lastMarkerIndex, 1);
            self.audiogram.simulateAxesClick(750, 0);
            self.assertEqual(self.audiogram.lastMarkerX, 750);
            self.assertEqual(self.audiogram.lastMarkerIndex, 2);
            self.audiogram.simulateAxesClick(1000, 0);
            self.assertEqual(self.audiogram.lastMarkerX, 1000);
            self.assertEqual(self.audiogram.lastMarkerIndex, 3);
            self.audiogram.simulateAxesClick(499, 0);
            self.assertEqual(self.audiogram.lastMarkerX, 500);
            self.assertEqual(self.audiogram.lastMarkerIndex, 1);
            self.audiogram.simulateAxesClick(749, 0);
            self.assertEqual(self.audiogram.lastMarkerX, 750);
            self.assertEqual(self.audiogram.lastMarkerIndex, 2);
            self.audiogram.simulateAxesClick(999, 0);
            self.assertEqual(self.audiogram.lastMarkerX, 1000);
            self.assertEqual(self.audiogram.lastMarkerIndex, 3);
        end
        
        function axesClickUpdatesEntryCorrespondingToNearestFrequency(self)
            import dslprescriber.*
            self.model.frequenciesHz = [500, 750, 1000];
            Presenter(...
                self.audiogram, ...
                self.model...
            );
            self.audiogram.simulateAxesClick(500, 0);
            self.assertEqual(self.audiogram.lastEntryIndex, 1);
            self.audiogram.simulateAxesClick(750, 0);
            self.assertEqual(self.audiogram.lastEntryIndex, 2);
            self.audiogram.simulateAxesClick(1000, 0);
            self.assertEqual(self.audiogram.lastEntryIndex, 3);
            self.audiogram.simulateAxesClick(499, 0);
            self.assertEqual(self.audiogram.lastEntryIndex, 1);
            self.audiogram.simulateAxesClick(749, 0);
            self.assertEqual(self.audiogram.lastEntryIndex, 2);
            self.audiogram.simulateAxesClick(999, 0);
            self.assertEqual(self.audiogram.lastEntryIndex, 3);
        end
        
        function axesRightClickHidesMarkerCorrespondingToNearestFrequency(self)
            import dslprescriber.*
            self.model.frequenciesHz = [500, 750, 1000];
            Presenter(...
                self.audiogram, ...
                self.model...
            );
            self.audiogram.leftClicked_ = false;
            self.audiogram.simulateAxesClick(500, 0);
            self.assertEqual(self.audiogram.lastHiddenMarkerIndex, 1);
            self.audiogram.simulateAxesClick(750, 0);
            self.assertEqual(self.audiogram.lastHiddenMarkerIndex, 2);
            self.audiogram.simulateAxesClick(1000, 0);
            self.assertEqual(self.audiogram.lastHiddenMarkerIndex, 3);
            self.audiogram.simulateAxesClick(499, 0);
            self.assertEqual(self.audiogram.lastHiddenMarkerIndex, 1);
            self.audiogram.simulateAxesClick(749, 0);
            self.assertEqual(self.audiogram.lastHiddenMarkerIndex, 2);
            self.audiogram.simulateAxesClick(999, 0);
            self.assertEqual(self.audiogram.lastHiddenMarkerIndex, 3);
        end
        
        function axesRightClickClearsEntryCorrespondingToNearestFrequency(self)
            import dslprescriber.*
            self.model.frequenciesHz = [500, 750, 1000];
            Presenter(...
                self.audiogram, ...
                self.model...
            );
            self.audiogram.leftClicked_ = false;
            self.audiogram.simulateAxesClick(500, 0);
            self.assertEqual(self.audiogram.lastClearedEntryIndex, 1);
            self.audiogram.simulateAxesClick(750, 0);
            self.assertEqual(self.audiogram.lastClearedEntryIndex, 2);
            self.audiogram.simulateAxesClick(1000, 0);
            self.assertEqual(self.audiogram.lastClearedEntryIndex, 3);
            self.audiogram.simulateAxesClick(499, 0);
            self.assertEqual(self.audiogram.lastClearedEntryIndex, 1);
            self.audiogram.simulateAxesClick(749, 0);
            self.assertEqual(self.audiogram.lastClearedEntryIndex, 2);
            self.audiogram.simulateAxesClick(999, 0);
            self.assertEqual(self.audiogram.lastClearedEntryIndex, 3);
        end
        
        function entryEditUpdatesFrequencyThreshold(self)
            import dslprescriber.*
            self.model.frequenciesHz = [500, 750, 1000];
            Presenter(...
                self.audiogram, ...
                self.model...
            );
            self.audiogram.simulateEntryEdit(1);
            self.assertEqual(self.model.thresholdFrequencySet, 500);
            self.audiogram.simulateEntryEdit(2);
            self.assertEqual(self.model.thresholdFrequencySet, 750);
            self.audiogram.simulateEntryEdit(3);
            self.assertEqual(self.model.thresholdFrequencySet, 1000);
        end
        
        function axesClickUpdatesNearestFrequencyThreshold(self)
            import dslprescriber.*
            self.model.frequenciesHz = [500, 750, 1000];
            Presenter(...
                self.audiogram, ...
                self.model...
            );
            self.audiogram.simulateAxesClick(500, 0);
            self.assertEqual(self.model.thresholdFrequencySet, 500);
            self.audiogram.simulateAxesClick(750, 0);
            self.assertEqual(self.model.thresholdFrequencySet, 750);
            self.audiogram.simulateAxesClick(1000, 0);
            self.assertEqual(self.model.thresholdFrequencySet, 1000);
            self.audiogram.simulateAxesClick(499, 0);
            self.assertEqual(self.model.thresholdFrequencySet, 500);
            self.audiogram.simulateAxesClick(749, 0);
            self.assertEqual(self.model.thresholdFrequencySet, 750);
            self.audiogram.simulateAxesClick(999, 0);
            self.assertEqual(self.model.thresholdFrequencySet, 1000);
        end
        
        function axesRightClickRemovesNearestFrequencyThreshold(self)
            import dslprescriber.*
            self.model.frequenciesHz = [500, 750, 1000];
            Presenter(...
                self.audiogram, ...
                self.model...
            );
            self.audiogram.leftClicked_ = false;
            self.audiogram.simulateAxesClick(500, 0);
            self.assertEqual(self.model.thresholdFrequencyRemoved, 500);
            self.audiogram.simulateAxesClick(750, 0);
            self.assertEqual(self.model.thresholdFrequencyRemoved, 750);
            self.audiogram.simulateAxesClick(1000, 0);
            self.assertEqual(self.model.thresholdFrequencyRemoved, 1000);
            self.audiogram.simulateAxesClick(499, 0);
            self.assertEqual(self.model.thresholdFrequencyRemoved, 500);
            self.audiogram.simulateAxesClick(749, 0);
            self.assertEqual(self.model.thresholdFrequencyRemoved, 750);
            self.audiogram.simulateAxesClick(999, 0);
            self.assertEqual(self.model.thresholdFrequencyRemoved, 1000);
        end
        
        function entryEditUpdatesThresholds(self)
            import dslprescriber.*
            self.model.frequenciesHz = 0;
            Presenter(...
                self.audiogram, ...
                self.model...
            );
            self.audiogram.entryText_ = '10';
            self.audiogram.simulateEntryEdit(1);
            self.assertEqual(self.model.thresholdLevelSet, 10);
            self.assertEqual(self.audiogram.lastMarkerY, 10);
        end
        
        function entryEditQueriesTextOfSameEntry(self)
            import dslprescriber.*
            self.model.frequenciesHz = 0;
            Presenter(...
                self.audiogram, ...
                self.model...
            );
            self.audiogram.simulateEntryEdit(1);
            self.assertEqual(self.audiogram.entryTextIndex, 1);
        end
        
        function axesClickRoundedToNearestInteger(self)
            import dslprescriber.*
            Presenter(...
                self.audiogram, ...
                self.model...
            );
            self.audiogram.simulateAxesClick(0, 1.4);
            self.assertEqual(self.model.thresholdLevelSet, 1);
            self.assertEqual(self.audiogram.lastMarkerY, 1);
            self.assertEqual(self.audiogram.lastEntryText, '1');
            self.audiogram.simulateAxesClick(0, 1.8);
            self.assertEqual(self.model.thresholdLevelSet, 2);
            self.assertEqual(self.audiogram.lastMarkerY, 2);
            self.assertEqual(self.audiogram.lastEntryText, '2');
            self.audiogram.simulateAxesClick(0, 3.2);
            self.assertEqual(self.model.thresholdLevelSet, 3);
            self.assertEqual(self.audiogram.lastMarkerY, 3);
            self.assertEqual(self.audiogram.lastEntryText, '3');
        end
        
        function axesClickSetsRealEarSplTableAfterUpdatingModel(self)
            import dslprescriber.*
            Presenter(...
                self.audiogram, ...
                self.model...
            );
            self.model.callWhenThresholdSet(@()update);
            function update()
                self.model.realEarSpls = [1, 2, 3];
            end
            self.audiogram.simulateEntryEdit([]);
            self.assertEqual(self.audiogram.tableData, [1, 2, 3]);
        end
        
        function axesRightClickSetsRealEarSplTableAfterUpdatingModel(self)
            import dslprescriber.*
            Presenter(...
                self.audiogram, ...
                self.model...
            );
            self.model.callWhenThresholdRemoved(@()update);
            function update()
                self.model.realEarSpls = [1, 2, 3];
            end
            self.audiogram.leftClicked_ = false;
            self.audiogram.simulateAxesClick(0, 0);
            self.assertEqual(self.audiogram.tableData, [1, 2, 3]);
        end
        
        function entryEditSetsRealEarSplTableAfterUpdatingModel(self)
            import dslprescriber.*
            Presenter(...
                self.audiogram, ...
                self.model...
            );
            self.model.callWhenThresholdSet(@()update);
            function update()
                self.model.realEarSpls = [1, 2, 3];
            end
            self.audiogram.simulateAxesClick(0, 0);
            self.assertEqual(self.audiogram.tableData, [1, 2, 3]);
        end
        
        function savePrescriptionPassesFileToModelForTuning(self)
            import dslprescriber.*
            self.audiogram.fileForOpening = 'a';
            self.audiogram.pathForOpening = 'b/';
            Presenter(...
                self.audiogram, ...
                self.model...
            );
            self.audiogram.savePrescription();
            self.assertEqual(self.model.tunePrescriptionFilePath, 'b/a');
        end
        
        function savePrescriptionDoesNotTuneWhenUserCancelsOpeningFile(self)
            import dslprescriber.*
            self.audiogram.fileForOpening = 0;
            Presenter(...
                self.audiogram, ...
                self.model...
            );
            self.audiogram.savePrescription();
            self.assertEmpty(self.model.tunePrescriptionFilePath);
        end
        
        function savePrescriptionPassesFileToModelForSaving(self)
            import dslprescriber.*
            self.audiogram.fileForSaving = 'a';
            self.audiogram.pathForSaving = 'b/';
            Presenter(...
                self.audiogram, ...
                self.model...
            );
            self.audiogram.savePrescription();
            self.assertEqual(self.model.savePrescriptionFilePath, 'b/a');
        end
        
        function savePrescriptionDoesNotSaveWhenUserCancelsSavingFile(self)
            import dslprescriber.*
            self.audiogram.fileForSaving = 0;
            Presenter(...
                self.audiogram, ...
                self.model...
            );
            self.audiogram.savePrescription();
            self.assertEmpty(self.model.savePrescriptionFilePath);
        end
        
        function savePrescriptionShowsErrorDialogWhenTuningErrors(self)
            import dslprescriber.*
            Presenter(...
                self.audiogram, ...
                self.model...
            );
            self.model.whenTuningPrescription = @()error('error.');
            self.audiogram.savePrescription();
            self.assertEqual(self.audiogram.errorMessage, 'error.');
        end
    end
end

