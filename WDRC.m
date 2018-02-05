function y = WDRC(Cross_freq,x,Fs,rmsdB,maxdB,TKgain,CR,TK,BOLT,att,rel)
old_dB = maxdB + 20.*log10(rms(x));
scale = 10.^((rmsdB - old_dB)/20);
x = x.*scale;
in_peak = Smooth_ENV(x,1,50,Fs);
in_pdB = maxdB + 20.*log10(in_peak);
CL_TK = 105; % Compression limiter threshold kneepoint
CL_CR = 10;  % Compression limiter compression ratio
in_c = WDRC_Circuit(x,0,in_pdB,CL_TK,CL_CR,CL_TK);
Nchannel = length(TKgain);
if Nchannel > 1
    y = HA_fbank2(Cross_freq,in_c,Fs);    % Nchannel FIR filter bank
else
    y = in_c;
end
nsamp = size(y,1);
pdB = zeros(nsamp, Nchannel);
c = zeros(nsamp, Nchannel);
gdB = zeros(nsamp, Nchannel);
for n = 1:Nchannel
    if BOLT(n) > CL_TK, BOLT(n) = CL_TK; end
    if TKgain(n) < 0, BOLT(n) = BOLT(n) + TKgain(n); end
    peak = Smooth_ENV(y(:,n),att,rel,Fs);
    pdB(:,n) = maxdB+20.*log10(peak);
    [c(:,n),gdB(:,n)]=WDRC_Circuit(y(:,n),TKgain(n),pdB(:,n),TK(n),CR(n),BOLT(n));
end
comp=sum(c,2);
out_peak = Smooth_ENV(comp,1,50,Fs);
out_pdB = maxdB + 20.*log10(out_peak);
out_c = WDRC_Circuit(comp,0,out_pdB,CL_TK,CL_CR,CL_TK);
y = out_c(89:end-88);