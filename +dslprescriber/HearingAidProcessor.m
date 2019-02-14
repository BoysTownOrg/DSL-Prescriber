classdef HearingAidProcessor < handle
    properties (Access = private)
        parameters
        limiter
    end
    
    methods
        function self = HearingAidProcessor(parameters)
            limiting.attack_ms = 1;
            limiting.release_ms = 50;
            limiting.kneepoint_dB_SPL = 105;
            limiting.ratio = 10;
            limiting.kneepointGain_dB = 0;
            limiting.BOLT_dB_SPL = 105;
            limiting.fullscale_dB_SPL = parameters.fullscale_dB_SPL;
            exceedsLimiterKneepoint = parameters.BOLT_dB_SPL > limiting.kneepoint_dB_SPL;
            parameters.BOLT_dB_SPL(exceedsLimiterKneepoint) = limiting.kneepoint_dB_SPL;
            negativeGain = parameters.kneepointGain_dB < 0;
            parameters.BOLT_dB_SPL(negativeGain) = ...
                parameters.BOLT_dB_SPL(negativeGain) + ...
                parameters.kneepointGain_dB(negativeGain);
            self.parameters = parameters;
            self.limiter = dslprescriber.WDRCompressor(limiting);
        end
        
        function x = process(self, x, fs)
            import dslprescriber.*
            x = self.limiter.compress(x, fs);
            channels = length(self.parameters.kneepointGain_dB);
            if channels > 1
                x = FirFilterBank(self.parameters.crossFrequenciesHz).process(x, fs);
            end
            for n = 1:channels
                p.attack_ms = self.parameters.attack_ms;
                p.release_ms = self.parameters.release_ms;
                p.kneepoint_dB_SPL = self.parameters.kneepoint_dB_SPL(n);
                p.ratio = self.parameters.ratio(n);
                p.kneepointGain_dB = self.parameters.kneepointGain_dB(n);
                p.BOLT_dB_SPL = self.parameters.BOLT_dB_SPL(n);
                p.fullscale_dB_SPL = self.parameters.fullscale_dB_SPL;
                x(:, n) = WDRCompressor(p).compress(x(:, n), fs);
            end
            x = self.limiter.compress(sum(x, 2), fs);
            x = x(89:end-88);
        end
    end
end

