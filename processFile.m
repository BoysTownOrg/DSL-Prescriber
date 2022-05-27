function processFile(prescriptionFilePath, audioFilePath, inputLevel_dB_SPL)
json = readJsonFile(prescriptionFilePath);
p.fullscale_dB_SPL = 119;
p.BOLT_dB_SPL = json.BOLT_dB_SPL;
p.kneepointGain_dB = json.kneepoint_gains_dB;
p.crossFrequenciesHz = json.cross_frequencies_Hz;
p.attack_ms = json.attack;
p.release_ms = json.release;
p.kneepoint_dB_SPL = json.kneepoints_dB_SPL;
p.ratio = json.compression_ratios;
hearingAid = dslprescriber.HearingAidProcessor(p);
[y, fs] = audioread(audioFilePath);
outputFilePath = [audioFilePath(1:end-4), '-hearing-aid-simulated', audioFilePath(end-3:end)];
audiowrite(outputFilePath, hearingAid.process(y * 10^((inputLevel_dB_SPL - p.fullscale_dB_SPL)/20) / rms(y), fs), fs)
end

function json = readJsonFile(path)
fid = fopen(path);
contents = char(fread(fid, inf)');
fclose(fid);
json = jsondecode(contents);
end