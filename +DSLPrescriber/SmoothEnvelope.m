classdef SmoothEnvelope < handle
    properties (Access = private)
        attackMilliseconds
        releaseMilliseconds
    end
    
    methods
        function self = SmoothEnvelope(attackMilliseconds, releaseMilliseconds)
            self.attackMilliseconds = attackMilliseconds;
            self.releaseMilliseconds = releaseMilliseconds;
        end
        
        function peak = process(self, x, fs)
            % Compute the filter time constants
            attackSamples = 0.001 * self.attackMilliseconds * fs;
            att = attackSamples / 2.425; %ANSI attack time => filter time constant
            alpha = att/(1.0 + att);
            releaseSamples = 0.001 * self.releaseMilliseconds * fs;
            rel = releaseSamples / 1.782; %ANSI release time => filter time constant
            beta = rel/(1.0 + rel);
            % Initialze the output array
            sampleCount = size(x, 1);
            peak = zeros(sampleCount, 1);
            % Loop to peak detect the signal in each band
            band = abs(x); %Extract the rectified signal in the band
            peak(1) = band(1); %First peak value is the signal sample
            for k = 2:sampleCount
                if band(k) >= peak(k-1)
                    peak(k) = alpha*peak(k-1) + (1-alpha)*band(k);
                else
                    peak(k) = beta * peak(k-1);
                end
            end
        end
    end
end

