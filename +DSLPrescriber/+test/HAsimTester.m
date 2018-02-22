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
            tuner = DSLPrescriber.WDRCTuner(Nchannel, thresholds, DSLFile);
            DSL = tuner.generateDSL(attack, release);
            self.verifyEqual(DSL.TKgain, [ ...
                29.8259, ...
                24.6773, ...
                31.4625, ...
                36.8484, ...
                36.0132, ...
                42.1330, ...
                45.1831, ...
                45.2986], 'abstol', 1e-4);
            self.verifyEqual(DSL.CR, [1.8, 1.8, 1.9, 1.8, 1.8, 1.8, 1.8, 1.9]);
            self.verifyEqual(DSL.BOLT, [91.7, 99.4, 102.6, 103.5333, 105.05, 106.8, 101.25, 99.1], 'abstol', 1e-4);
        end
        
        function WDRC_TuneTestB(self)
            attack = 5;
            release = 50;
            Nchannel = 8;
            DSLFile = 'wilfred left.csv';
            thresholds = containers.Map( ...
                [250, 500, 750, 1000, 1500, 2000, 3000, 4000, 6000, 8000], ...
                [35 50 75 75 -99 70 75 70 55 40]);
            tuner = DSLPrescriber.WDRCTuner(Nchannel, thresholds, DSLFile);
            DSL = tuner.generateDSL(attack, release);
            self.verifyEqual(DSL.TKgain, [-3.7431 3.4256 27.2833 44.2919 40.4308 48.4414 46.8509 32.0707], 'abstol', 1e-4);
            self.verifyEqual(DSL.CR, [1.1000 1.3000 1.9000 2.1000 2 2 1.7000 1.5000]);
            self.verifyEqual(DSL.TK, [32.2000 39.6000 53.6000 52.1000 47.9000 45.5000 37.3000 29.9000]);
            self.verifyEqual(DSL.BOLT, [85.4667 98.7500 108.2000 113.0333 113 115.7000 107.1000 100.9000], 'abstol', 1e-4);
        end
        
        function WDRC_TuneTestC(self)
            attack = 5;
            release = 50;
            Nchannel = 8;
            DSLFile = 'bobby right.csv';
            thresholds = containers.Map( ...
                [250, 500, 1000, 2000, 4000, 8000], ...
                [65 75 90 80 60 40]);
            tuner = DSLPrescriber.WDRCTuner(Nchannel, thresholds, DSLFile);
            DSL = tuner.generateDSL(attack, release);
            self.verifyEqual(DSL.TKgain, [37.6775 41.2924 54.1683 55 55 55 54.0291 47.7291], 'abstol', 1e-4);
            self.verifyEqual(DSL.CR, [2.3000 2.5000 2.9000 3.4000 3.3000 2.4000 2.1000 2.2000]);
            self.verifyEqual(DSL.TK, [42.4000 53.6000 57.4000 54.9000 51 42.6000 34.2000 32.4000]);
            self.verifyEqual(DSL.BOLT, [97.7000 107.7000 113.5000 118.2667 117.2000 113.4500 104.8500 102.6000], 'abstol', 1e-4);
        end
    end
end

