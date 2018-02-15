function [Cross_freq, Select_channel] = HA_channelselect(cent_freq, Nchannel)
Select_channel = zeros(1,Nchannel);
Cross_freq = zeros(1,Nchannel-1);
bandwidth = (log10(cent_freq(end))-log10(cent_freq(1)))/Nchannel;
for i = 1:Nchannel-1
    Cross_freq(i) = 10^(bandwidth*i + log10(cent_freq(1)));
    Select_channel(i) = find((cent_freq/Cross_freq(i)) <= 1, 1, 'last');
end
Select_channel(end) = length(cent_freq);
if Nchannel == 16, Select_channel = 2:17; end