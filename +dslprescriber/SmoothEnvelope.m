classdef SmoothEnvelope < handle
    properties (Access = private)
        attack_ms
        release_ms
    end
    
    methods
        function self = SmoothEnvelope(attack_ms, release_ms)
            self.attack_ms = attack_ms;
            self.release_ms = release_ms;
        end
        
        function band = process(self, x, fs)
            attackSamples = 0.001 * self.attack_ms * fs;
            alpha = attackSamples/(2.425 + attackSamples);
            releaseSamples = 0.001 * self.release_ms * fs;
            beta = releaseSamples/(1.782 + releaseSamples);
            band = abs(x);
            for k = 2:numel(band)
                if band(k) >= band(k-1)
                    band(k) = alpha*band(k-1) + (1-alpha)*band(k);
                else
                    band(k) = beta * band(k-1);
                end
            end
        end
    end
end

