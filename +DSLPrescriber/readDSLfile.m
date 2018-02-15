function fileOutput = readDSLfile(filename)
a = csvread(filename, 1, 1);
frequencies = [200, 250, 315, 400, 500, 630, 800, 1000, 1250, 1600, 2000, 2500, 3150, 4000, 5000, 6300, 8000];
columnRange = 1:numel(frequencies);
fileOutput = DSLPrescriber.DSLFileOutput();
fileOutput.ThreshSPL = containers.Map(frequencies, a(8, columnRange));
fileOutput.TK = containers.Map(frequencies, a(15, columnRange));
fileOutput.TargetBOLT = containers.Map(frequencies, a(10, columnRange));
fileOutput.CR = containers.Map(frequencies, a(17, columnRange));
fileOutput.TKgain = containers.Map(frequencies, a(13, columnRange) - a(15, columnRange));
fileOutput.TargetAvg = containers.Map(frequencies, a(23, columnRange));
end
