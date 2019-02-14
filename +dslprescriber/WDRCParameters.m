classdef WDRCParameters
    properties
        attack_ms
        release_ms
        fullscale_dB_SPL
        crossFrequenciesHz
        kneepoint_dB_SPL
        kneepointGain_dB
        ratio
        BOLT_dB_SPL
    end
    
    methods
        function self = WDRCParameters(channels)
            self.kneepoint_dB_SPL = zeros(1, channels);
            self.ratio = zeros(1, channels);
            self.BOLT_dB_SPL = zeros(1, channels);
            self.kneepointGain_dB = zeros(1, channels);
            self.crossFrequenciesHz = zeros(1, channels - 1);
        end
    end
end
