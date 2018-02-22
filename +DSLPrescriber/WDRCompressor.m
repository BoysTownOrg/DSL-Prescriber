classdef WDRCompressor < handle
    properties (Access = private)
        parameters
    end
    
    methods
        function self = WDRCompressor(parameters)
            self.parameters = parameters;
        end
        
        function y = compress(self, x, fs)
            old_dB = self.parameters.maxdB + 20.*log10(rms(x));
            scale = 10.^((self.parameters.rmsdB - old_dB)/20);
            x = x.*scale;
            in_peak = DSLPrescriber.Smooth_ENV(x,1,50,fs);
            in_pdB = self.parameters.maxdB + 20.*log10(in_peak);
            CL_TK = 105; % Compression limiter threshold kneepoint
            CL_CR = 10;  % Compression limiter compression ratio
            in_c = DSLPrescriber.WDRC_Circuit(x,0,in_pdB,CL_TK,CL_CR,CL_TK);
            Nchannel = length(self.parameters.TKGain);
            if Nchannel > 1
                y = DSLPrescriber.HA_fbank2(self.parameters.crossFrequencies,in_c,fs);    % Nchannel FIR filter bank
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
                peak = DSLPrescriber.Smooth_ENV(y(:,n),self.parameters.attackMilliseconds,self.parameters.releaseMilliseconds,fs);
                pdB(:,n) = self.parameters.maxdB+20.*log10(peak);
                [c(:,n),gdB(:,n)] = DSLPrescriber.WDRC_Circuit(y(:,n),self.parameters.TKGain(n),pdB(:,n),self.parameters.TK(n),self.parameters.CR(n),self.parameters.BOLT(n));
            end
            comp=sum(c,2);
            out_peak = DSLPrescriber.Smooth_ENV(comp,1,50,fs);
            out_pdB = self.parameters.maxdB + 20.*log10(out_peak);
            out_c = DSLPrescriber.WDRC_Circuit(comp,0,out_pdB,CL_TK,CL_CR,CL_TK);
            y = out_c(89:end-88);
        end
    end
end

