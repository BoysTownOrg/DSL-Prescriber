function peak = Smooth_ENV(x,attack,release,Fs)
% Compute the filter time constants
att=0.001*attack*Fs/2.425; %ANSI attack time => filter time constant
alpha=att/(1.0 + att);
rel=0.001*release*Fs/1.782; %ANSI release time => filter time constant
beta=rel/(1.0 + rel);

% Initialze the output array
nsamp=size(x,1);
peak=zeros(nsamp,1);

% Loop to peak detect the signal in each band
band=abs(x); %Extract the rectified signal in the band
peak(1)=band(1); %First peak value is the signal sample
for k=2:nsamp
    if band(k) >= peak(k-1)
        peak(k)=alpha*peak(k-1) + (1-alpha)*band(k);
    else
        peak(k)=beta*peak(k-1);
    end
end