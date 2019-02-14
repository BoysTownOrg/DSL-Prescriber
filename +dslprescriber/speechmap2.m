function banana = speechmap2(x, fs)
frequencyCount = 17;
centerFrequencies = 1000 * (2^(1/3)).^(-7:frequencyCount-8);
N = 3; 					% Order of analysis filters.
% Design filters and compute RMS powers in 1/3-oct. bands
% 10000 Hz band to 1600 Hz band, direct implementation of filters.
B = zeros(frequencyCount, 7);
A = zeros(frequencyCount, 7);
for i = frequencyCount:-1:10
    [B(i, :), A(i, :)] = dslprescriber.oct3dsgn(centerFrequencies(i), fs, N);
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
windowSize = round(fs * 0.128);
stepSize = windowSize / 2;
Nsamples = floor(length(x) / stepSize) - 1;
w = hann(windowSize);
P = zeros(Nsamples, frequencyCount);
for n = 1:Nsamples
    head = (n-1)*stepSize + 1;
    y = w .* x(head:head+windowSize-1);
    for i = frequencyCount:-1:1
        if i < 10 && mod(i, 3) == 0
            y = decimate(y, 2);
        end
        z = filter(B(i, :), A(i, :), y);
        P(n, i) = sum(z.^2) / length(z);
    end
end
banana = 10*log10(mean(P));
end