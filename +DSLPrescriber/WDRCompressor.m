classdef WDRCompressor < handle
    properties (Access = private)
        parameters
    end
    
    methods
        function self = WDRCompressor(parameters)
            self.parameters = parameters;
        end
        
        function y = compress(self, x, fs)
            differencedB = self.parameters.rmsdB - self.parameters.maxdB;
            scale = 10^(differencedB/20) / rms(x);
            x = x * scale;
            attackMilliseconds = 1;
            releaseMilliseconds = 50;
            smoothEnvelope = dslprescriber.SmoothEnvelope(attackMilliseconds, releaseMilliseconds);
            inputPeaks = smoothEnvelope.process(x, fs);
            inputPeaksdB = self.parameters.maxdB + 20*log10(inputPeaks);
            compressionLimiterTK = 105;
            compressionLimiterCR = 10;
            TKGain = 0;
            compressedInput = self.WDRC_Circuit(x, TKGain, inputPeaksdB, compressionLimiterTK, compressionLimiterCR, compressionLimiterTK);
            Nchannel = length(self.parameters.TKGain);
            if Nchannel > 1
                y = self.firFilterBank(compressedInput, fs);
            else
                y = compressedInput;
            end
            sampleCount = size(y, 1);
            c = zeros(sampleCount, Nchannel);
            gdB = zeros(sampleCount, Nchannel);
            smoothEnvelope = dslprescriber.SmoothEnvelope(self.parameters.attackMilliseconds, self.parameters.releaseMilliseconds);
            for n = 1:Nchannel
                if self.parameters.BOLT(n) > compressionLimiterTK
                    self.parameters.BOLT(n) = compressionLimiterTK; 
                end
                if self.parameters.TKGain(n) < 0
                    self.parameters.BOLT(n) = self.parameters.BOLT(n) + self.parameters.TKGain(n); 
                end
                peaks = smoothEnvelope.process(y(:,n), fs);
                peaksdB = self.parameters.maxdB + 20*log10(peaks);
                [c(:,n), gdB(:,n)] = self.WDRC_Circuit(y(:,n), self.parameters.TKGain(n), peaksdB, self.parameters.TK(n), self.parameters.CR(n), self.parameters.BOLT(n));
            end
            comp = sum(c, 2);
            attackMilliseconds = 1;
            releaseMilliseconds = 50;
            smoothEnvelope = dslprescriber.SmoothEnvelope(attackMilliseconds, releaseMilliseconds);
            out_peak = smoothEnvelope.process(comp, fs);
            out_pdB = self.parameters.maxdB + 20*log10(out_peak);
            TKGain = 0;
            out_c = self.WDRC_Circuit(comp, TKGain, out_pdB, compressionLimiterTK, compressionLimiterCR, compressionLimiterTK);
            y = out_c(89:end-88);
        end
    end
    
    methods (Access = private)
        function y = firFilterBank(self, x, fs)  
            % 17 freq. bands
            % James M. Kates, 12 December 2008.
            % Last Modified by: J. Alexander 8/27/10
            if fs < 22050
                error('Signal sampling rate is too low');
            end
            impulseResponseMilliseconds = 8; % Length of the FIR filter impulse response in msec
            impulseResponseSeconds = impulseResponseMilliseconds / 1000;
            N = round(impulseResponseSeconds * fs);
            N = 2 * floor(N/2);
            sampleCount = length(x);
            channelCount = length(self.parameters.crossFrequencies) + 1;
            y = zeros(sampleCount+N, channelCount); %Include filter transients
            ft = 175; % Half the width of the filter transition region
            nyquistFrequency = fs/2;
            if self.parameters.crossFrequencies(1) < 2*ft
                mysteryFrequency = self.parameters.crossFrequencies(1) - ft/4;
            else
                mysteryFrequency = self.parameters.crossFrequencies(1) - ft;
            end
            f = [ ...
                0, ...
                mysteryFrequency, ...
                self.parameters.crossFrequencies(1) + ft, ...
                nyquistFrequency]; % frequency points
            lowPassGain = [1, 1, 0, 0];
            b = fir2(N, f/nyquistFrequency, lowPassGain);
            y(:, 1) = conv(x(:), b);
            f = [ ...
                0, ...
                self.parameters.crossFrequencies(end) - ft, ...
                self.parameters.crossFrequencies(end) + ft, ...
                nyquistFrequency];
            highPassGain = [0, 0, 1, 1];
            b = fir2(N, f/nyquistFrequency, highPassGain);
            y(:, channelCount) = conv(x(:), b);
            bandPassGain = [0, 0, 1, 1, 0, 0];
            for n = 2:channelCount-1
                if self.parameters.crossFrequencies(n-1) < 2*ft
                    mysteryFrequency = self.parameters.crossFrequencies(n-1) - ft/4;
                else
                    mysteryFrequency = self.parameters.crossFrequencies(n-1) - ft;
                end
                f = sort([ ...
                    0, ...
                    mysteryFrequency, ...
                    self.parameters.crossFrequencies(n-1) + ft, ...
                    self.parameters.crossFrequencies(n) - ft, ...
                    self.parameters.crossFrequencies(n) + ft, ...
                    nyquistFrequency]); % frequency points in increasing order
                b = fir2(N, f/nyquistFrequency, bandPassGain);
                y(:, n) = conv(x(:), b);
            end
        end

        function [comp, gdB] = WDRC_Circuit(self, x, TKGain, peaksdB, TK, CR, BOLT)
            if TK + TKGain > BOLT
                TK = BOLT - TKGain; 
            end
            TKGainOrigin = TKGain + TK * (1 - 1/CR);
            gdB = (1/CR - 1) * peaksdB + TKGainOrigin;
            if CR >= 1
                gdB(peaksdB < TK) = TKGain;
            end
            pBOLT = CR * (BOLT - TKGainOrigin);
            I = peaksdB > pBOLT;
            gdB(I) = BOLT + (peaksdB(I) - pBOLT)/10 - peaksdB(I);
            g = 10 .^ (gdB/20);
            comp = x .* g;
        end
    end
end

