function y = HA_fbank2(crossFrequencies, x, Fs)  % 17 freq. bands
% James M. Kates, 12 December 2008.
% Last Modified by: J. Alexander 8/27/10
if Fs < 22050
    fprintf('Error in HA_fbank: Signal sampling rate is too low.\n');
    return
end
impulseResponseMilliseconds = 8; % Length of the FIR filter impulse response in msec
impulseResponseSeconds = impulseResponseMilliseconds / 1000;
N = round(impulseResponseSeconds * Fs); % Length of the FIR filters in samples
N = 2 * floor(N/2); % Force filter length to be even
nsamp = length(x);
channelCount = length(crossFrequencies)+1;
y = zeros(nsamp+N, channelCount); %Include filter transients
ft = 175; % Half the width of the filter transition region
% First band is a low-pass filter
gain = [1 1 0 0];
nyqfreq = Fs/2;
if (crossFrequencies(1)-ft) < ft
    f = [0, crossFrequencies(1) - ft/4, crossFrequencies(1)+ft, nyqfreq]; % frequency points
else
    f = [0, crossFrequencies(1)-ft, crossFrequencies(1)+ft, nyqfreq]; % frequency points
end
b = zeros(channelCount, ft+2);
b(1, :) = fir2(N, f/nyqfreq, gain); % FIR filter design
x = x(:);
y(:, 1) = conv(x, b(1, :));
% Last band is a high-pass filter
gain = [0 0 1 1];
f = [0, crossFrequencies(channelCount-1)-ft, crossFrequencies(channelCount-1)+ft, nyqfreq];
b(channelCount, :) = fir2(N, f/nyqfreq, gain); %FIR filter design
y(:, channelCount) = conv(x, b(channelCount, :));
% Remaining bands are bandpass filters
gain=[0 0 1 1 0 0];
for n = 2:channelCount-1
    if (crossFrequencies(n-1)-ft) < ft
        f = sort([0, crossFrequencies(n-1)-(ft/4), crossFrequencies(n-1)+ft, crossFrequencies(n)-ft, crossFrequencies(n)+ft, nyqfreq]); % frequency points in increasing order
    else
        f = sort([0, crossFrequencies(n-1)-ft, crossFrequencies(n-1)+ft, crossFrequencies(n)-ft, crossFrequencies(n)+ft, nyqfreq]); % frequency points in increasing order
    end
    b(n, :) = fir2(N, f/nyqfreq, gain); %FIR filter design
    y(:, n) = conv(x, b(n, :));
end