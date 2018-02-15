function banana = speechmap2(maxdB, x, Fs)
N = 3; 					% Order of analysis filters.
nF = 17;
ff = 1000*((2^(1/3)).^(-7:nF-8)); 	% Exact center freq.
% Design filters and compute RMS powers in 1/3-oct. bands
% 10000 Hz band to 1600 Hz band, direct implementation of filters.
B = zeros(nF, 7);
A = zeros(nF, 7);
for i = nF:-1:10
    [B(i, :), A(i, :)] = DSLPrescriber.oct3dsgn(ff(i), Fs, N);
end
for j = 0:2
    rowOffset = j * 3;
    B(rowOffset+1, :) = B(10, :);
    B(rowOffset+2, :) = B(11, :);
    B(rowOffset+3, :) = B(12, :);
    A(rowOffset+1, :) = A(10, :);
    A(rowOffset+2, :) = A(11, :);
    A(rowOffset+3, :) = A(12, :);
end
winsize = round(Fs * 0.128);
stepsize = winsize / 2;
Nsamples = floor(length(x) / stepsize) - 1;
w = hann(winsize);
for n = 1:Nsamples
    startpt = ((n-1).*stepsize)+1;
    y = w.*x(startpt:(startpt+winsize-1));
    for i = nF:-1:10
        z = filter(B(i, :), A(i, :), y);
        P(n, i) = sum(z.^2) / length(z);
    end
    for j = 2:-1:0
        y = decimate(y, 2);
        for k = 3:-1:1
            i = j * 3 + k;
            z = filter(B(i, :), A(i, :), y);
            P(n, i) = sum(z.^2) / length(z);
        end
    end
end
banana = zeros(1, nF);
for n = 1:nF
    banana(n) = maxdB + 10*log10((mean(P(:,n))));
end