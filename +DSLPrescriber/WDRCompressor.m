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
            smoothEnvelope = dslprescriber.SmoothEnvelope(1, 50);
            in_peak = smoothEnvelope.process(x, fs);
            in_pdB = self.parameters.maxdB + 20*log10(in_peak);
            CL_TK = 105; % Compression limiter threshold kneepoint
            CL_CR = 10;  % Compression limiter compression ratio
            in_c = self.WDRC_Circuit(x,0,in_pdB,CL_TK,CL_CR,CL_TK);
            Nchannel = length(self.parameters.TKGain);
            if Nchannel > 1
                y = self.HA_fbank2(in_c, fs);    % Nchannel FIR filter bank
            else
                y = in_c;
            end
            nsamp = size(y,1);
            pdB = zeros(nsamp, Nchannel);
            c = zeros(nsamp, Nchannel);
            gdB = zeros(nsamp, Nchannel);
            for n = 1:Nchannel
                if self.parameters.BOLT(n) > CL_TK
                    self.parameters.BOLT(n) = CL_TK; 
                end
                if self.parameters.TKGain(n) < 0
                    self.parameters.BOLT(n) = self.parameters.BOLT(n) + self.parameters.TKGain(n); 
                end
                smoothEnvelope = dslprescriber.SmoothEnvelope(self.parameters.attackMilliseconds, self.parameters.releaseMilliseconds);
                peak = smoothEnvelope.process(y(:,n), fs);
                pdB(:,n) = self.parameters.maxdB+20.*log10(peak);
                [c(:,n),gdB(:,n)] = self.WDRC_Circuit(y(:,n),self.parameters.TKGain(n),pdB(:,n),self.parameters.TK(n),self.parameters.CR(n),self.parameters.BOLT(n));
            end
            comp=sum(c,2);
            smoothEnvelope = dslprescriber.SmoothEnvelope(1, 50);
            out_peak = smoothEnvelope.process(comp, fs);
            out_pdB = self.parameters.maxdB + 20.*log10(out_peak);
            out_c = self.WDRC_Circuit(comp,0,out_pdB,CL_TK,CL_CR,CL_TK);
            y = out_c(89:end-88);
        end
    end
    
    methods (Access = private)
        function y = HA_fbank2(self, x, Fs)  
            % 17 freq. bands
            % James M. Kates, 12 December 2008.
            % Last Modified by: J. Alexander 8/27/10
            if Fs < 22050
                error('Signal sampling rate is too low');
            end
            impulseResponseMilliseconds = 8; % Length of the FIR filter impulse response in msec
            impulseResponseSeconds = impulseResponseMilliseconds / 1000;
            N = round(impulseResponseSeconds * Fs);
            N = 2 * floor(N/2);
            sampleCount = length(x);
            channelCount = length(self.parameters.crossFrequencies) + 1;
            y = zeros(sampleCount+N, channelCount); %Include filter transients
            ft = 175; % Half the width of the filter transition region
            nyquistFrequency = Fs/2;
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

        function [comp, gdB] = WDRC_Circuit(self, x, TKGain, pdB, TK, CR, BOLT)
            if TK + TKGain > BOLT
                TK = BOLT - TKGain; 
            end
            TKGainOrigin = TKGain + TK .* (1 - 1./CR);
            gdB = (1./CR - 1) .* pdB + TKGainOrigin;
            if CR >= 1
                gdB(pdB < TK) = TKGain;
            end
            pBOLT = CR * (BOLT - TKGainOrigin);
            I = pdB > pBOLT;
            gdB(I) = BOLT + (pdB(I) - pBOLT)/10 - pdB(I);
            g = 10 .^ (gdB/20);
            comp = x .* g;
        end
    end
end

