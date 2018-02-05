function [comp,gdB] = WDRC_Circuit(x,TKgain,pdB,TK,CR,BOLT)
if TK+TKgain > BOLT, TK = BOLT-TKgain; end
TKgain_origin = TKgain + (TK.*(1-1./CR));
gdB = ((1./CR)-1).*pdB + TKgain_origin;
if CR >= 1
    gdB(pdB < TK) = TKgain;
end
pBOLT = CR*(BOLT - TKgain_origin);
I = pdB > pBOLT;
gdB(I) = BOLT+((pdB(I)-pBOLT)*1/10)-pdB(I);
g=10.^(gdB/20);
comp=x.*g;