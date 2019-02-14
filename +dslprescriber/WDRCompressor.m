classdef WDRCompressor < handle
    properties (Access = private)
        fullscale_dB_SPL
        kneepoint_dB_SPL
        kneepointGain_dB
        ratio
        BOLT_dB_SPL
        pBOLT_dB_SPL
        smoother
    end
    
    methods
        function self = WDRCompressor(parameters)
            kneepoint_dB_SPL = min(...
                parameters.kneepoint_dB_SPL, ...
                parameters.BOLT_dB_SPL - parameters.kneepointGain_dB...
            );
            self.ratio = parameters.ratio;
            self.kneepointGain_dB = parameters.kneepointGain_dB;
            self.BOLT_dB_SPL = parameters.BOLT_dB_SPL;
            self.pBOLT_dB_SPL = parameters.ratio * (parameters.BOLT_dB_SPL - parameters.kneepointGain_dB - kneepoint_dB_SPL) + kneepoint_dB_SPL;
            self.fullscale_dB_SPL = parameters.fullscale_dB_SPL;
            self.smoother = dslprescriber.SmoothEnvelope(...
                parameters.attack_ms, ...
                parameters.release_ms...
            );
            self.kneepoint_dB_SPL = kneepoint_dB_SPL;
        end
        
        function x = compress(self, x, fs)
            x_dB_SPL = self.fullscale_dB_SPL + 20*log10(self.smoother.process(x, fs));
            gain_dB = (1 - 1/self.ratio) * (self.kneepoint_dB_SPL - x_dB_SPL) + self.kneepointGain_dB;
            if self.ratio >= 1
                gain_dB(x_dB_SPL < self.kneepoint_dB_SPL) = self.kneepointGain_dB;
            end
            I = x_dB_SPL > self.pBOLT_dB_SPL;
            gain_dB(I) = self.BOLT_dB_SPL - (self.pBOLT_dB_SPL + 9 * x_dB_SPL(I)) / 10;
            x = x .* 10 .^ (gain_dB/20);
        end
    end
end

