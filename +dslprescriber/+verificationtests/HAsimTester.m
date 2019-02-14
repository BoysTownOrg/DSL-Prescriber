classdef HAsimTester < matlab.unittest.TestCase
    methods (Test)
        function WDRC_TuneTestA(self)
            attack = 5;
            release = 50;
            Nchannel = 8;
            DSLFile = 'fdsa left.csv';
            thresholds = containers.Map( ...
                [250, 500, 750, 1000, 1500, 2000, 3000, 4000, 6000, 8000], ...
                [50 50 50 50 50 50 50 50 50 50]);
            tuner = dslprescriber.WDRCTuner(Nchannel, thresholds, DSLFile);
            DSL = tuner.generateDSL(attack, release);
            self.verifyEqual(DSL.kneepoint_gains_dB, [ ...
                29.8259, ...
                24.6773, ...
                31.4625, ...
                36.8484, ...
                36.0132, ...
                42.1330, ...
                45.1831, ...
                45.2986], 'abstol', 1e-4);
            self.verifyEqual(DSL.compression_ratios, [1.8, 1.8, 1.9, 1.8, 1.8, 1.8, 1.8, 1.9]);
            self.verifyEqual(DSL.BOLT_dB_SPL, [91.7, 99.4, 102.6, 103.5333, 105.05, 106.8, 101.25, 99.1], 'abstol', 1e-4);
        end
        
        function WDRC_TuneTestB(self)
            attack = 5;
            release = 50;
            Nchannel = 8;
            DSLFile = 'wilfred left.csv';
            thresholds = containers.Map( ...
                [250, 500, 750, 1000, 1500, 2000, 3000, 4000, 6000, 8000], ...
                [35 50 75 75 -99 70 75 70 55 40]);
            tuner = dslprescriber.WDRCTuner(Nchannel, thresholds, DSLFile);
            DSL = tuner.generateDSL(attack, release);
            self.verifyEqual(DSL.kneepoint_gains_dB, [-3.7431 3.4256 27.2833 44.2919 40.4308 48.4414 46.8509 32.0707], 'abstol', 1e-4);
            self.verifyEqual(DSL.compression_ratios, [1.1000 1.3000 1.9000 2.1000 2 2 1.7000 1.5000]);
            self.verifyEqual(DSL.kneepoints_dB_SPL, [32.2000 39.6000 53.6000 52.1000 47.9000 45.5000 37.3000 29.9000]);
            self.verifyEqual(DSL.BOLT_dB_SPL, [85.4667 98.7500 108.2000 113.0333 113 115.7000 107.1000 100.9000], 'abstol', 1e-4);
        end
        
        function WDRC_TuneTestC(self)
            attack = 5;
            release = 50;
            Nchannel = 8;
            DSLFile = 'bobby right.csv';
            thresholds = containers.Map( ...
                [250, 500, 1000, 2000, 4000, 8000], ...
                [65 75 90 80 60 40]);
            tuner = dslprescriber.WDRCTuner(Nchannel, thresholds, DSLFile);
            DSL = tuner.generateDSL(attack, release);
            self.verifyEqual(DSL.kneepoint_gains_dB, [37.6775 41.2924 54.1683 55 55 55 54.0291 47.7291], 'abstol', 1e-4);
            self.verifyEqual(DSL.compression_ratios, [2.3000 2.5000 2.9000 3.4000 3.3000 2.4000 2.1000 2.2000]);
            self.verifyEqual(DSL.kneepoints_dB_SPL, [42.4000 53.6000 57.4000 54.9000 51 42.6000 34.2000 32.4000]);
            self.verifyEqual(DSL.BOLT_dB_SPL, [97.7000 107.7000 113.5000 118.2667 117.2000 113.4500 104.8500 102.6000], 'abstol', 1e-4);
        end
        
        function WDRC_TuneTestD(self)
            attack = 5;
            release = 50;
            Nchannel = 8;
            DSLFile = 'simon right.csv';
            thresholds = containers.Map( ...
                [250, 500, 750, 1000, 2000, 3000, 4000, 6000, 8000], ...
                [20 20 25 30 30 40 65 40 25]);
            tuner = dslprescriber.WDRCTuner(Nchannel, thresholds, DSLFile);
            DSL = tuner.generateDSL(attack, release);
            self.verifyEqual(DSL.kneepoint_gains_dB, [-13.594233203252770 -14.645534149950805   3.113334197798839  10.440670259269082   1.549968917363938  29.883744524802282  35.028626237362559   4.807001852507902], 'reltol', 1e-12);
            self.verifyEqual(DSL.compression_ratios, [0.8000 0.9000 1.1000 1.1000 1.1000 1.5000 1.5000 1.1000], 'reltol', 1e-15);
            self.verifyEqual(DSL.kneepoints_dB_SPL, [32.200000000000003  27.300000000000001  29.699999999999999  28.899999999999995  27.000000000000000  37.299999999999997  31.600000000000001  25.699999999999999]);
            self.verifyEqual(DSL.BOLT_dB_SPL, [79.5000 89.0500 92.1000 94 96 105.4500 100.4500 89.8000]);
            self.verifyEqual(DSL.MPO, 1.0e+02 * [0.799933751847711   0.779018167319937   0.847447955448461   0.896992847934617   0.936701894810215   0.966410647089014   0.977378635924432   0.951698658804891   0.988048322908721   0.955831207850830   1.083566245189908   1.074943944761741   1.121997697728792 1.044616211649116   1.017536374607938   0.885164681491762   0.963908181618811], 'reltol', 1e-14);
            self.verifyEqual(DSL.target_low, [23.100000000000001  32.100000000000001  34.500000000000000  41.000000000000000  44.299999999999997  48.399999999999999  50.100000000000001  49.600000000000001  50.399999999999999  52.200000000000003  53.799999999999997  66.700000000000003  71.599999999999994 69.900000000000006  56.899999999999999  43.799999999999997  40.799999999999997]);
            self.verifyEqual(DSL.target_average, [32.700000000000003  41.700000000000003  44.100000000000001  49.600000000000001  52.899999999999999  55.899999999999999  57.200000000000003  56.700000000000003  57.500000000000000  59.200000000000003  60.799999999999997  72.500000000000000  79.599999999999994 77.900000000000006  62.299999999999997  51.200000000000003  43.125000000000007]);
            self.verifyEqual(DSL.target_high, [36.500000000000000  48.000000000000000  56.000000000000000  58.200000000000003  64.099999999999994  69.500000000000000  72.500000000000000  71.900000000000006  74.599999999999994  77.400000000000006  78.099999999999994  84.099999999999994  93.099999999999994 91.200000000000003  73.000000000000000  62.799999999999997  58.600000000000001]);
            self.verifyEqual(DSL.threshold_dB_SPL, [28.399999999999999  28.399999999999999  28.634000000000000  28.939999999999998  29.300000000000001  34.603999999999999  40.340000000000003  43.700000000000003  45.075000000000003  47.000000000000000  49.200000000000003  55.150000000000006  64.145000000000010 81.400000000000006  69.150000000000006  55.474999999999994  47.399999999999999]);
        end
    end
end

