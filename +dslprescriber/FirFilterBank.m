classdef FirFilterBank < handle
    properties (Constant)
        halfTransitionWidthHz = 175;
        impulseResponse_ms = 8;
    end
    
    properties (Access = private)
        crossFrequenciesHz
    end
    
    methods
        function self = FirFilterBank(crossFrequenciesHz)
            self.crossFrequenciesHz = crossFrequenciesHz;
        end
        
        function y = process(self, x, fs)
            if fs < 22050
                error('Signal sampling rate is too low');
            end
            N = 2 * floor(round(fs * self.impulseResponse_ms / 1000)/2);
            channels = length(self.crossFrequenciesHz) + 1;
            y = zeros(length(x)+N, channels);
            for n = 1:channels
                if n == 1
                    b = self.lowPassDesign(N, fs);
                elseif n == channels
                    b = self.highPassDesign(N, fs);
                else
                    b = self.bandPassDesign(n, N, fs);
                end
                y(:, n) = conv(x(:), b);
            end
        end
    end
    
    methods (Access = private)
        function b = lowPassDesign(self, N, fs)
            nyquistHz = fs/2;
            lowPassBreakPointsHz = ...
                [ ...
                    0, ...
                    self.firstBreakPointHz(self.crossFrequenciesHz(1)), ...
                    self.crossFrequenciesHz(1) + self.halfTransitionWidthHz, ...
                    nyquistHz...
                ];
            b = fir2(N, lowPassBreakPointsHz/nyquistHz, [1, 1, 0, 0]);
        end
        
        function breakPointHz = firstBreakPointHz(self, crossFrequencyHz)
            if crossFrequencyHz < 2*self.halfTransitionWidthHz
                breakPointHz = crossFrequencyHz - self.halfTransitionWidthHz/4;
            else
                breakPointHz = crossFrequencyHz - self.halfTransitionWidthHz;
            end
        end
        
        function b = highPassDesign(self, N, fs)
            nyquistHz = fs/2;
            highPassBreakPointsHz = ...
                [ ...
                    0, ...
                    self.crossFrequenciesHz(end) - self.halfTransitionWidthHz, ...
                    self.crossFrequenciesHz(end) + self.halfTransitionWidthHz, ...
                    nyquistHz...
                ];
            b = fir2(N, highPassBreakPointsHz/nyquistHz, [0, 0, 1, 1]);
        end
        
        function b = bandPassDesign(self, n, N, fs)
            nyquistHz = fs/2;
            breakPointsHz = sort([ ...
                0, ...
                self.firstBreakPointHz(self.crossFrequenciesHz(n-1)), ...
                self.crossFrequenciesHz(n-1) + self.halfTransitionWidthHz, ...
                self.crossFrequenciesHz(n) - self.halfTransitionWidthHz, ...
                self.crossFrequenciesHz(n) + self.halfTransitionWidthHz, ...
                nyquistHz...
            ]);
            b = fir2(N, breakPointsHz/nyquistHz, [0, 0, 1, 1, 0, 0]);
        end
    end
end

