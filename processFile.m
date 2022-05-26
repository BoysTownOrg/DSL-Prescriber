function processFile(prescriptionFilePath, audioFilePath)
fid = fopen(prescriptionFilePath);
raw = fread(fid, inf);
str = char(raw');
fclose(fid);
j = jsondecode(str);
p.fullscale_dB_SPL = 119;
p.BOLT_dB_SPL = j.BOLT_dB_SPL;
p.kneepointGain_dB = j.kneepoint_gains_dB;
p.crossFrequenciesHz = j.cross_frequencies_Hz;
p.attack_ms = j.attack;
p.release_ms = j.release;
p.kneepoint_dB_SPL = j.kneepoints_dB_SPL;
p.ratio = j.compression_ratios;
h = dslprescriber.HearingAidProcessor(p);
[y, fs] = audioread(audioFilePath);
audiowrite([audioFilePath(1:end-4), '-hearing-aid-simulated', audioFilePath(end-3:end)], h.process(y, fs), fs)
end