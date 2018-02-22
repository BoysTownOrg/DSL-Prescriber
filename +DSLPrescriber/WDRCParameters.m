classdef WDRCParameters
    properties
        attackMilliseconds
        releaseMilliseconds
        rmsdB
        maxdB
        crossFrequencies
        TK
        TKGain
        CR
        BOLT
    end
    
    methods
        function self = WDRCParameters(channelCount)
            self.TK = zeros(1, channelCount);
            self.CR = zeros(1, channelCount);
            self.BOLT = zeros(1, channelCount);
            self.TKGain = zeros(1, channelCount);
            self.crossFrequencies = zeros(1, channelCount - 1);
        end
    end
end
