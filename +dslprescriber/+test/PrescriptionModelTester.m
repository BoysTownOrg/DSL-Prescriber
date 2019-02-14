classdef PrescriptionModelTester < matlab.unittest.TestCase
    methods (Test)
        function realEarSplsAreSumOfThresholdsAndTdhCorrections(self)
            model = dslprescriber.PrescriptionModel(...
                containers.Map([1, 2, 3], [4, 5, 6]));
            model.setThreshold(1, 7);
            model.setThreshold(2, 8);
            model.setThreshold(3, 9);
            self.assertEqual(model.getRealEarSpls(), [4 + 7, 5 + 8, 6 + 9]);
        end
        
        function removeThresholdSetsToNaN(self)
            model = dslprescriber.PrescriptionModel(...
                containers.Map([1, 2, 3], [4, 5, 6]));
            model.setThreshold(1, 7);
            model.setThreshold(2, 8);
            model.setThreshold(3, 9);
            model.removeThreshold(2);
            self.assertEqual(model.getRealEarSpls(), [4 + 7, nan, 6 + 9]);
        end
    end
end

