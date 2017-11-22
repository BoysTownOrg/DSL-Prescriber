function HAsim052017
[protocolFileName, pathname] = uigetfile('*.mat*', 'Select Protocol');
if ~pathname
    return
end
load([pathname, protocolFileName]);
answer = inputdlg('Enter Subject ID');
listenerID = answer{1};
LOGIN = 1;
while LOGIN == 1
    main = menu4( ...
        'WHAT DO YOU WANT TO DO?', ...
        'Enter Audiometric Thresholds', ...
        'Run DSLv5.0', ...
        'Generate Prescription', ...
        'Process Stimuli', ...
        'Load Speechmap', ...
        'WDRC Diagnostics', ...
        'Run another subject/protocol', ...
        'Downsample to 22.05 kHz', ...
        'Exit to MATLAB');
    switch main
        case 1
            [HL, freq] = Audiogram(listenerID, audiodir); %#ok
            save([audiodir, filesep(), listenerID, ' Audiogram'], 'HL', 'freq');
        case 2
            ear = menu4('Select Ear', 'RIGHT', 'LEFT') - 1;
            [freq, thr] = GetThresh(1, ear, audiodir, [listenerID, ' Audiogram']);
            if ear == 0
                fprintf('\n \t Thresholds in dB SPL for the RIGHT ear for subject %s:\n\n', listenerID);
            else
                fprintf('\n \t Thresholds in dB SPL for the LEFT ear for subject %s: \n\n', listenerID);
            end
            for i = 1:length(thr)
                fprintf('\t \t \t \t %g Hz, %g dB SPL \n\n', freq(i), thr(i));
            end
            fprintf('***** USE THE ARROW to select %d for the Number of Channels ***** \n\n', Nchannel);
            fprintf('***** Save DSL output in the folder: ''%s'' ***** \n\n', DSLdir);
            if ear == 0
                fprintf('***** Save DSL output with the name: ''%s right'' ***** \n\n', listenerID);
            else
                fprintf('***** Save DSL output with the name: ''%s left'' ***** \n\n', listenerID);
            end
            open('C:\HA Simulator\DSL\DSL.exe');
        case 3
            fnameR = [listenerID, ' right.csv'];
            fnameL = [listenerID, ' left.csv'];
            d = dir([DSLdir, filesep(), '*.csv']);
            fileNames = {d.name};
            for n = 1:length(fileNames)
                sameR = strcmpi(fnameR, fileNames(n));
                sameL = strcmpi(fnameL, fileNames(n));
                if sameR
                    DSL = WDRC_Tune(att, rel, Nchannel, listenerID, 0, DSLdir, audiodir);
                    save([DSLdir, filesep(), listenerID, ' right DSL'], 'DSL');
                    saveas(gcf, [DSLdir, filesep(), listenerID, ' right Speechmap'], 'fig');
                end
                if sameL
                    DSL = WDRC_Tune(att,rel,Nchannel,listenerID,1,DSLdir,audiodir);
                    save([DSLdir, filesep(), listenerID, ' left DSL'], 'DSL');
                    saveas(gcf, [DSLdir, filesep(), listenerID, ' left Speechmap'], 'fig');
                end
            end
        case 4
            fnameR = [listenerID, ' right.csv'];
            fnameL = [listenerID, ' left.csv'];
            d = dir([DSLdir, filesep(), '*.csv']);
            fileNames = {d.name};
            sameEARright = any(strcmpi(fnameR, fileNames));
            sameEARleft = any(strcmpi(fnameL, fileNames));
            tic();
            for i = 1:length(activeRows)
                row = activeRows(i);
                SourceDir = cell2mat(RAW(row,1));
                DestDir = cell2mat(RAW(row,2));
                nameMod = cell2mat(RAW(row,3));
                Nchannel = cell2mat(RAW(row,4));
                att = cell2mat(RAW(row,5));
                rel = cell2mat(RAW(row,6));
                refdB = cell2mat(RAW(row,7));
                Proc = cell2mat(RAW(row,8));
                NFCstartLEFT = cell2mat(RAW(row,9));
                NFCratioLEFT = cell2mat(RAW(row,10));
                NFCstartRIGHT = cell2mat(RAW(row,11));
                NFCratioRIGHT = cell2mat(RAW(row,12));
                if sameEARright
                    rightRx = load([DSLdir, filesep(), fnameR]);
                    ProcDir([listenerID, nameMod], 0, SourceDir, DestDir, refdB, Proc, rightRx.DSL, att, rel, NFCstartRIGHT, NFCratioRIGHT);
                end
                if sameEARleft
                    leftRx = load([DSLdir, filesep(), fnameL]);
                    ProcDir([listenerID, nameMod], 1, SourceDir, DestDir, refdB, Proc, leftRx.DSL, att, rel, NFCstartLEFT, NFCratioLEFT);
                end
            end
            elapsedTime = toc;
            warndlg(sprintf('PROCESSING COMPLETED in %g minutes, %g seconds',floor(elapsedTime/60),round(rem(elapsedTime, 60))), 'HAsim Update');
        case 5
            ear = menu4('Select Ear', 'RIGHT', 'LEFT') - 1;
            if ear == 0
                open([DSLdir, filesep(), listenerID, ' right Speechmap.fig']);
            else
                open([DSLdir, filesep(), listenerID, ' left Speechmap.fig']);
            end
            button = 1;
            while button == 1
                [x, y, button] = ginput(1);
                title(sprintf('%g Hz, %g dB SPL', round(x), round2(y, 1)), ...
                    'fontsize', 18, ...
                    'fontweight', 'bold');
            end
        case 6
            DiagOpt = menu4( ...
                'Select Option', ...
                'RIGHT Ear, Carrot Passage', ...
                'LEFT Ear, Carrot Passage', ...
                'RIGHT Ear, Stimulus File', ...
                'LEFT Ear, Stimulus File');
            TestEar = rem(DiagOpt+1, 2);
            if TestEar == 0
                load([DSLdir, filesep(), listenerID, ' right DSL.mat']);
                NFCstart = NFCstartRIGHT;
                NFCratio = NFCratioRIGHT;
            else
                load([DSLdir, filesep(), listenerID, ' left DSL.mat']);
                NFCstart = NFCstartLEFT;
                NFCratio = NFCratioLEFT;
            end
            if DiagOpt < 3
                [x, Fs] = audioread('C:\HA Simulator\MATLAB\carrots');
            else
                [filename, pathname] = uigetfile([SourceDir, filesep(), '*.wav'], 'Select Wav File');
                if ~pathname
                    return
                end
                [x, Fs] = audioread([pathname, filename]);
            end
            WDRCvisual(x, Fs, refdB, Proc, NFCstart, NFCratio, DSL, att, rel)
        case 7
            startup
        case 8
            DownSampleBatch;
        case 9
            LOGIN = 0;
    end
end

function [HL, audiogramFrequencies] = Audiogram(listenerID, pathname, altdir, altdir2, HL)
if nargin < 2
    pathname = cd;
end
answer = inputdlg(sprintf('Enter Test Date, dd-Mmm-yyyy (e.g., 01-Jan-2011) \n OR leave blank for today''s date'));
if isempty(answer)
    testdate = date();
else
    testdate = answer{1};
end
ear = 1;
audiogramFrequencies = [250,500,750,1000,1500,2000,3000,4000,6000,8000]; %Audiogram frequencies
scnsize = get(0, 'ScreenSize');
scnsize(1:2) = [0 0];
figure1 = figure( ...
    'Position', scnsize, ...
    'units', 'pixels');
hold on
grid on
axis square
set(gca, ...
    'FontName', 'Arial', ...
    'FontWeight', 'bold', ...
    'FontSize', 12, ...
    'YDir', 'rev', ...
    'xTick', 1:6, ...
    'LineWidth', 1.25, ...
    'xlim', [0 6.2], ...
    'YMinorTick', 'off', ...
    'yTick', -10:10:120, ...
    'LineWidth', 1.25, ...
    'ylim', [-10 120], ...
    'XTickLabel', ['250 '; '500 '; '1000'; '2000'; '4000'; '8000']);
xlabel('Frequency, Hertz');
ylabel('Hearing Level, dB HL');
annotation(figure1,'textbox','String',{'Right TDH (o)'},...
    'HorizontalAlignment','center',...
    'FontWeight','bold',...
    'FontSize',14,...
    'FontName','Arial',...
    'LineWidth',1,...
    'BackgroundColor',[1 1 1],...
    'Position',[0.83 0.79 0.17 0.07],...
    'Color',[1 0 0 ]);
annotation(figure1,'textbox','String',{'Left TDH (x)'},...
    'HorizontalAlignment','center',...
    'FontWeight','bold',...
    'FontSize',14,...
    'FontName','Arial',...
    'LineWidth',1,...
    'BackgroundColor',[1 1 1],...
    'Position',[0.83 0.728 0.17 0.07],...
    'Color',[0 0 1]);
annotation(figure1,'textbox','String',{'Right Insert (\bullet)'},...
    'HorizontalAlignment','center',...
    'FontWeight','bold',...
    'FontSize',14,...
    'FontName','Arial',...
    'LineWidth',1,...
    'BackgroundColor',[1 1 1],...
    'Position',[0.83 0.666 0.17 0.07],...
    'Color',[1 0 0 ]);
annotation(figure1,'textbox','String',{'Left Insert (*)'},...
    'HorizontalAlignment','center',...
    'FontWeight','bold',...
    'FontSize',14,...
    'FontName','Arial',...
    'LineWidth',1,...
    'BackgroundColor',[1 1 1],...
    'Position',[0.83 0.604 0.17 0.07],...
    'Color',[0 0 1]);
annotation(figure1,'textbox','String',{'Right Bone ([)'},...
    'HorizontalAlignment','center',...
    'FontWeight','bold',...
    'FontSize',14,...
    'FontName','Arial',...
    'LineWidth',1,...
    'BackgroundColor',[1 1 1],...
    'Position',[0.83 0.542 0.17 0.07],...
    'Color',[1 0 0 ]);
annotation(figure1,'textbox','String',{'Left Bone (])'},...
    'HorizontalAlignment','center',...
    'FontWeight','bold',...
    'FontSize',14,...
    'FontName','Arial',...
    'LineWidth',1,...
    'BackgroundColor',[1 1 1],...
    'Position',[0.83 0.48 0.17 0.07],...
    'Color',[0 0 1]);
annotation(figure1,'textbox','String',{'Bone Unmasked (\^)'},...
    'HorizontalAlignment','center',...
    'FontWeight','bold',...
    'FontSize',12,...
    'FontName','Arial',...
    'LineWidth',1,...
    'BackgroundColor',[1 1 1],...
    'Position',[0.83 0.418 0.17 0.07]);
annotation(figure1,'textbox','String',{'Done'},...
    'HorizontalAlignment','center',...
    'FontWeight','bold',...
    'FontSize',16,...
    'FontName','Arial',...
    'LineWidth',1,...
    'BackgroundColor',[(255/255) (240/255) (165/255)],...
    'Position',[0.83 0.358 0.17 0.07]);
if nargin < 5
    HL.Rtdh(1:10) = -99;
    HL.Ltdh(1:10) = -99;
    HL.Rins(1:10) = -99;
    HL.Lins(1:10) = -99;
    HL.Rbc(1:10) = -99;
    HL.Lbc(1:10) = -99;
    HL.Ubc(1:10) = -99;
else
    redraw_audiogram(HL, 0);
end
done = 0;
while done == 0
    x = 0; 
    y = 0;
    while x<=0 || x>8 || y<=-15 || y>=120
        [x, y, button] = ginput(1);
        q = round(x.*2);
        x = q./2;
        if x == 1.5, x = 1; end
        w = round(y./5);
        y = w.*5;
        if x >= 6.5 && y<0
            y = -25;
        end
        if (x >= 6.5) && (y>80)
            y = 125;
        end
        if (x >= 6.5) && (y>=0) && (y<10)
            ear = 1;
            x = -1;
        end
        if (x >= 6.5) && (y>=10) && (y<20)
            ear = 2;
            x = -1;
        end
        if (x >= 6.5) && (y>=20) && (y<30)
            ear = 3;
            x = -1;
        end
        if (x >= 6.5) && (y>=30) && (y<40)
            ear = 4;
            x = -1;
        end
        if (x >= 6.5) && (y>=40) && (y<50)
            ear = 5;
            x = -1;
        end
        if (x >= 6.5) && (y>=50) && (y<60)
            ear = 6;
            x = -1;
        end
        if (x >= 6.5) && (y>=60) && (y<70)
            ear = 7;
            x = -1;
        end
        if (x >= 6.5) && (y>=70) && (y<=80)
            sure = menu3('Are you sure you are done?', 'YES', 'NO');
            if sure == 1
                done = 1;
            else
                x = -1;
            end
        end
    end
    if x > 1
        F = (x.*2)-2;
    else
        F = 1;
    end
    if done < 1
        switch ear
            case 1
                if HL.Rtdh(F) < -10
                    if y >= -10
                        h1 = plot(x-0.08,y,'ro');
                        set(h1,'MarkerSize',12,'MarkerFaceColor','white','LineWidth',2);
                        HL.Rtdh(F) = y;
                    end
                else
                    if button == 3, HL.Rtdh(F) = -99;
                        redraw_audiogram(HL,done)
                    elseif y == HL.Rtdh(F)
                    else
                        HL.Rtdh(F) = y;
                        redraw_audiogram(HL,done)
                    end
                end
            case 2
                if HL.Ltdh(F) < -10
                    if y >= -10
                        h1 = plot(x+0.08,y,'bx');
                        set(h1,'MarkerSize',17,'MarkerFaceColor','white','LineWidth',2);
                        HL.Ltdh(F) = y;
                    end
                else
                    if button == 3, HL.Ltdh(F) = -99;
                        redraw_audiogram(HL,done)
                    elseif y == HL.Ltdh(F)
                    else
                        HL.Ltdh(F) = y;
                        redraw_audiogram(HL,done)
                    end
                end
            case 3
                if HL.Rins(F) < -10
                    if y >= -10
                        h1 = plot(x-0.12,y+0.35,'ro');
                        set(h1,'MarkerSize',8,'MarkerFaceColor','red','LineWidth',2);
                        HL.Rins(F) = y;
                    end
                else
                    if button == 3, HL.Rins(F) = -99;
                        redraw_audiogram(HL,done)
                    elseif y == HL.Rins(F)
                    else
                        HL.Rins(F) = y;
                        redraw_audiogram(HL,done)
                    end
                end
            case 4
                if HL.Lins(F) < -10
                    if y >= -10
                        h1 = plot(x+0.12,y+0.35,'b*');
                        set(h1,'MarkerSize',8,'MarkerFaceColor','blue','LineWidth',2);
                        HL.Lins(F) = y;
                    end
                else
                    if button == 3, HL.Lins(F) = -99;
                        redraw_audiogram(HL,done)
                    elseif y == HL.Lins(F)
                    else
                        HL.Lins(F) = y;
                        redraw_audiogram(HL,done)
                    end
                end
            case 5
                if HL.Rbc(F) < -10
                    if y >= -10
                        text(x-0.12,y,'[','Fontsize',18,'Fontweight','Bold');
                        HL.Rbc(F) = y;
                    end
                else
                    if button == 3, HL.Rbc(F) = -99;
                        redraw_audiogram(HL,done)
                    elseif y == HL.Rbc(F)
                    else
                        HL.Rbc(F) = y;
                        redraw_audiogram(HL,done)
                    end
                end
            case 6
                if HL.Lbc(F) < -10
                    if y >= -10
                        text(x+0.03,y,']','Fontsize',18,'Fontweight','Bold');
                        HL.Lbc(F) = y;
                    end
                else
                    if button == 3, HL.Lbc(F) = -99;
                        redraw_audiogram(HL,done)
                    elseif y == HL.Lbc(F)
                    else
                        HL.Lbc(F) = y;
                        redraw_audiogram(HL,done)
                    end
                end
            case 7
                if HL.Ubc(F) < -10
                    if y >= -10
                        text(x-0.09,y-1,'\^','Fontsize',28);
                        HL.Ubc(F) = y;
                    end
                else
                    if button == 3, HL.Ubc(F) = -99;
                        redraw_audiogram(HL,done)
                    elseif y == HL.Ubc(F)
                    else
                        HL.Ubc(F) = y;
                        redraw_audiogram(HL,done)
                    end
                end
        end
    end
end
proceed = menu3('Save Audiogram?','YES','NO');
if proceed == 1
    redraw_audiogram(HL,done)
    if nargin == 0, [file, pathname] = uiputfile('*.pdf', 'Save As'); listenerID = file(1:end-4); end
    title(sprintf('Audiogram for %s (%s)',char(listenerID),char(testdate)));
    orient landscape
    rect = [1, 1, 1, 1];
    saveas(gcf, [pathname, listenerID, ' Audiogram ', testdate], 'pdf');
    if nargin > 2
        saveas(gcf, [altdir, listenerID, ' Audiogram ', testdate], 'pdf');
    end
    if nargin > 3
        saveas(gcf, [altdir2, listenerID, ' Audiogram ', testdate], 'pdf');
    end
end

function comp_freq = compf(sel_freq,factor,Fc,Fs)
bound = 2*pi*Fc/Fs;
comp_freq = (sel_freq.^factor)*(bound^(1-factor));

function DownSampleBatch()
[~, pathname1] = uigetfile('*.wav', 'Select Folder to Retrieve Files FROM');
if ~pathname1
    return
end
[~, pathname2] = uiputfile('Select Folder to Save Files TO');
if ~pathname2
    return
end
Fs2 = 22050;
files = dir([pathname1, '*.wav']);
fileNames = {files.name};
fileCount = length(fileNames);
h = timebar('Resample batch Counter','Progress');
for n = 1:fileCount
    [x, Fs, Nbits] = audioread([pathname1, fileNames{n}]);
    y = resample(x(:,1), Fs2, Fs);
    audiowrite([pathname2, fileNames{n}], y, Fs2, ...
        'bitspersample', Nbits);
    timebar(h,n/fileCount);
end
close(h)

function banana = DSLspeechmap(maxdB, x, Fs, lid, ear, Thresh, TargetAvg, BOLT, MPO, DSLdir, att, rel, Nchannel)
lower = 30;
upper = 99;
SENNcorrection = [1.2, 1.2, 2.29, 3.72, 5.4, 5.04, 4.86, 5.5, 6.75, 8.94, 12.7, 12.95, 12.6, 9.2, 5.95, 4.26, 13.1]+3;
N = 3;
f = [200 250 315, 400 500 630, 800 1000 1250, 1600 2000 2500, 3150 4000 5000, 6300 8000];
nF = 17;
ff = (1000).*((2^(1/3)).^(-7:nF-8));
B(1:nF,1:7) = 0;
A(1:nF,1:7) = 0;
for i = nF:-1:10
    [B(i,1:7),A(i,1:7)] = oct3dsgn(ff(i),Fs,N);
end
for j = 0:2
    B((j.*3)+1,:) = B(10,:);
    B((j.*3)+2,:) = B(11,:);
    B((j.*3)+3,:) = B(12,:);
    A((j.*3)+1,:) = A(10,:);
    A((j.*3)+2,:) = A(11,:);
    A((j.*3)+3,:) = A(12,:);
end
winsize = round(Fs.*0.128);
stepsize = winsize./2;
Nsamples = floor(length(x)./stepsize)-1;
w = hann(winsize);
levels(1:Nsamples,1:nF) = 0;
h = timebar('Speechmap','Progress');
for n = 1:Nsamples
    startpt = ((n-1).*stepsize)+1;
    y = w.*x(startpt:(startpt+winsize-1));
    for i = nF:-1:10
        z = filter(B(i,:),A(i,:),y);
        P(n,i) = sum(z.^2)/length(z);
    end
    for j = 2:-1:0
        y = decimate(y,2);
        i = (j.*3)+3;
        z = filter(B(i,:),A(i,:),y);
        P(n,i) = sum(z.^2)/length(z);
        i = (j.*3)+2;
        z = filter(B(i,:),A(i,:),y);
        P(n,i) = sum(z.^2)/length(z);
        i = (j.*3)+1;
        z = filter(B(i,:),A(i,:),y);
        P(n,i) = sum(z.^2)/length(z);
    end
    timebar(h,n/Nsamples);
end
close(h)
idx = P>0;
minP = min(min(P(idx)));
for n = 1:nF
    idx = (P(:,n)>0);
    P(~idx,n) = minP*ones(sum(~idx),1);
end
levels = maxdB+10*log10(P);
for n = 1:nF
    banana(1,n) = prctile(levels(:,n),upper)+SENNcorrection(n);
end
for n = 1:nF
    banana(2,n) = maxdB+10*log10((mean(P(:,n))))+SENNcorrection(n);
end
for n = 1:nF
    banana(3,n) = prctile(levels(:,n),lower)+SENNcorrection(n);
end
axes('Xscale','log')
hold on
for i = 1:nF-1
    H = patch([f(i),f(i),f(i+1),f(i+1)],[banana(3,i),banana(1,i),banana(1,i+1),banana(3,i+1)],[0.85 0.85 0.85]);
    set(H,'LineStyle','none');
end
h(1) = semilogx(f,banana(2,:));
set(h(1),'Linestyle','-','color','k','linewidth',4);
if ear == 0
    h(2) = semilogx(f,Thresh,'ro');
    set(h(2),'MarkerSize',12,'linewidth',3);
else
    h(2) = semilogx(f,Thresh,'bx');
    set(h(2),'MarkerSize',15,'linewidth',3);
end
h(3) = semilogx(f,TargetAvg,'g+');
set(h(3),'MarkerSize',15,'linewidth',3);
h(4) = semilogx(f,MPO,'m.');
set(h(4),'MarkerSize',25,'linewidth',1.5);
h(5) = semilogx(f,BOLT+10','k*');
set(h(5),'MarkerSize',10,'linewidth',1.5);
set(0,'Units','pixels');
scnsize = get(0,'ScreenSize');
scnsize(1:2) = [0 0];
set(gcf,'Position',scnsize)
axis([185,8500,0,120])
set(gca,'fontsize',16,'xTick',[250,500,1000,2000,4000,8000])
set(gca,'fontsize',16,'yTick',0:10:120)
xlabel('Frequency, Hertz','fontsize',20)
ylabel('Output Level, dB SPL','fontsize',20)
legend(h,'LTASS','Threshold','DSL Targets','MPO','UCL','Location','Southeast');
title(sprintf('Speechmap for %s',lid),'fontsize',18,'fontweight','bold');
text(4000,30,sprintf('%sms/%sms, %s channels',num2str(att),num2str(rel),num2str(Nchannel)));
if ear == 0
    earlabel = 'right';
else
    earlabel = 'left';
end
orient landscape
rect = [1, 1, 1, 1];
saveas(gcf,sprintf('%s/%s Speechmap (%s ear)',DSLdir,lid,earlabel),'pdf');

function y = FIRbandpass(x,Fs,nfir,F1,F2)
Fnyq = Fs/2; % Nyquist frequency
x = x(:);
gain = [0 0 1 1 0 0];
f = [0 F1 F1 F2 F2 Fnyq];
h = fir2(nfir,f./Fnyq,gain,hamming(nfir+1));
y = conv(x,h,'same');

function y = FIRlowpass(x,Fs,nfir,Fc)
Fnyq = Fs/2;
x = x(:);
gain = [1 1 0 0];
f = [0 Fc Fc Fnyq];
h = fir2(nfir,f./Fnyq,gain,hamming(nfir+1));
y = conv(x,h,'same');

function output = FreqComp(x,Fs,Fc,CR,Nbins)
if nargin < 5
    Nbins = 26;
end
if size(x,1)>size(x,2)
    x=x';
end
x = [zeros(1,round(Fs*0.25),1),x];
win_size = 256;
steps = 32;
nfft = 128;
tot_t = length(x)/Fs;
time = tot_t*linspace(0,1,length(x));
pi2 = 2*pi;
if rem(nfft,2) == 1
    ret_n = (nfft+1)/2;
else
    ret_n = nfft/2;
end
cent_freq_Hz = (0:ret_n)*Fs/nfft;
cent_freq_rad = ((0:nfft-1)*pi2/nfft)';
start_bin = find(cent_freq_Hz > Fc, 1);
if (abs(cent_freq_Hz(start_bin) - Fc) > abs(cent_freq_Hz(start_bin - 1) - Fc))
    start_bin = start_bin - 1;
end
end_bin = start_bin + Nbins;
start_freq = cent_freq_Hz(start_bin);
end_freq = cent_freq_Hz(end_bin);
[low_out] = FIRlowpass(x,Fs,win_size,start_freq);
w1 = window(@hamming,win_size);
w2 = lanczos(win_size);
win = w1.*w2;
win_size = length(win);
[block_X] = spectrogram(x,win,win_size-steps,nfft,Fs);
fft_mag = abs(block_X(1:ret_n+1,:));
phases = unwrap(angle(block_X(1:ret_n+1,:)));
[num_bin,num_seg] = size(phases);
syn_mag = zeros(num_bin,num_seg+1);
for n = 1:num_seg
    syn_mag(:,n) = fft_mag(:,n);
end
synthSignal = zeros(1,(num_seg*steps) + length(win));
curStart = 1;
pXk_base = phases(1:num_bin,1);
for i = 1:num_seg-1
    pXk = phases(1:num_bin,i+1);
    diff_phase = pXk - pXk_base - (i.*steps*cent_freq_rad(1:num_bin));
    diff_phase = mod(diff_phase+pi2,pi2) - pi2;
    inst_freq = (1/(steps*i))*diff_phase+cent_freq_rad(1:num_bin);
    inst_phase = (1/(steps*i))*pXk+cent_freq_rad(1:num_bin);
    sel_freq = abs(inst_freq(start_bin:end_bin));
    sel_mag = syn_mag(start_bin:end_bin,i+1);
    comp_freq = compf(sel_freq,1/CR,start_freq,Fs);
    comp_mag = sel_mag*max(comp_freq)/max(sel_freq);
    samp_t = time(steps*(i-1)+1:steps*(i-1)+win_size);
    osc_out = sinoscillator(comp_freq,comp_mag,samp_t,Fs,inst_phase);
    synthSignal(curStart:curStart + win_size -1) = synthSignal(curStart:curStart + win_size -1) + osc_out.*win';
    curStart = curStart + steps;
end
band_out = FIRbandpass(x,Fs,win_size,start_freq,end_freq);
synthSignal = -synthSignal/rms2(synthSignal)*rms2(band_out)./CR;
output = low_out(round(Fs*0.25)+1:length(x)) + synthSignal(round(Fs*0.25)-1:length(x)-2)';

function [frequency,thrCorr] = GetThresh(thrType,ear,audiodir,filename)
if nargin < 2
    ear = menu2('Select Test Ear','RIGHT','LEFT')-1;
end
if nargin == 3
    cd(audiodir);
end
if nargin < 4
    [filename,audiodir] = uigetfile('*.mat', 'Select Data File');
    if isequal(filename,0) || isequal(audiodir,0)
        close
        return
    end
end

load(strcat(audiodir,'\',filename));
if ear == 0 
    thr1 = HL.Rtdh; 
    thr2 = HL.Rins; 
end
if ear == 1 
    thr1 = HL.Ltdh; 
    thr2 = HL.Lins; 
end
thr1(thr1 == -99) = 999;
thr2(thr2 == -99) = 999;
for i = 1:length(thr1)
    thr(i) = min([thr1(i),thr2(i)]);
    if thr(i) == 999, thr(i) = -99; end
end

TDHcorrection = [8.4, 9.3, 14.5, 13.7, 14.4, 19.2, 21.1, 16.4, 16.9, 22.4];

if thr(end) == -99, thr(end) = thr(end-1); end
I = find(thr ~= -99);

switch thrType
    case 0
        I = [1,2,4,6,8];
        thr = thr+TDHcorrection;
        for i = 1:length(I)
            thrCorr(i) = round2(thr(I(i)),1);
            frequency(i) = freq(I(i));
        end
    case 1
        thr = thr+TDHcorrection;
        for i = 1:length(I)
            thrCorr(i) = round2(thr(I(i)),1);
            frequency(i) = freq(I(i));
        end
    case 2
        thrCorr = thr;
        frequency = freq;
    case 3
        for i = 1:length(I)
            thrNEW(i) = thr(I(i))+TDHcorrection(I(i));
            freq2(i) = freq(I(i));
        end
        frequency = [200 250 315 400 500 630 800 1000 1250 1600 2000 2500 3150 4000 5000 6300 8000]; % center frequencies in Hz
        thrCorr = interp1(freq2,thrNEW,frequency);
        if isnan(thrCorr(1)), thrCorr(1) = thrCorr(2); end
        if isnan(thrCorr(end)), thrCorr(end) = thrCorr(end-1); end
        if isnan(thrCorr(end))
            h= warndlg('A threshold must be entered for 6000 or 8000 Hz.  If no response, please enter 120 dB HL.','WARNING','modal');
            uiwait(h);
        end
    case 4
        for i = 1:length(I)
            thrNEW(i) = thr(I(i));
            freq2(i) = freq(I(i));
        end
        frequency = [200 250 315 400 500 630 800 1000 1250 1600 2000 2500 3150 4000 5000 6300 8000]; % center frequencies in Hz
        thrCorr = interp1(freq2,thrNEW,frequency);
        if isnan(thrCorr(1)), thrCorr(1) = thrCorr(2); end
        if isnan(thrCorr(end)), thrCorr(end) = thrCorr(end-1); end
        if isnan(thrCorr(end))
            h= warndlg('A threshold must be entered for 6000 or 8000 Hz.  If no response, please enter 120 dB HL.','WARNING','modal');
            uiwait(h);
        end
end

function [Cross_freq,Select_channel] = HA_channelselect(cent_freq, Nchannel)
Select_channel = zeros(1,Nchannel);
Cross_freq = zeros(1,Nchannel-1);
bandwidth = (log10(cent_freq(end))-log10(cent_freq(1)))/Nchannel;
for i = 1:Nchannel-1
    Cross_freq(i) = 10^(bandwidth*i + log10(cent_freq(1)));
    a = find((cent_freq/Cross_freq(i))<=1, 1, 'last' );
    Select_channel(i) = a;
end
Select_channel(end) = length(cent_freq);
if Nchannel == 16, Select_channel = 2:17; end

function [y] = HA_fbank2(Cross_freq, x, Fs)  % 17 freq. bands
% James M. Kates, 12 December 2008.
% Last Modified by: J. Alexander 8/27/10
if Fs < 22050
    fprintf('Error in HA_fbank: Signal sampling rate is too low.\n');
    return
end
nyqfreq = Fs./2;
num_channel = length(Cross_freq)+1;
tfir = 8; % Length of the FIR filter impulse response in msec
nfir = round(0.001.*tfir.*Fs); % Length of the FIR filters in samples
nfir = 2.*floor(nfir./2); % Force filter length to be even
ft = 175; % Half the width of the filter transition region
x = x(:);
nsamp = length(x);
y = zeros(nsamp+nfir,num_channel); %Include filter transients
b = zeros(num_channel,ft+2);
% First band is a low-pass filter
gain = [1 1 0 0];
if (Cross_freq(1)-ft) < ft
    f = [0,(Cross_freq(1)-(ft/4)),(Cross_freq(1)+ft),nyqfreq]; % frequency points
else
    f = [0,(Cross_freq(1)-ft),(Cross_freq(1)+ft),nyqfreq]; % frequency points
end
b(1,:) = fir2(nfir,f./nyqfreq,gain); % FIR filter design
y(:,1) = conv(x,b(1,:));
% Last band is a high-pass filter
gain = [0 0 1 1];
f = [0,(Cross_freq(num_channel-1)-ft),(Cross_freq(num_channel-1)+ft),nyqfreq];
b(num_channel,:) = fir2(nfir,f./nyqfreq,gain); %FIR filter design
y(:,num_channel) = conv(x,b(num_channel,:));
% Remaining bands are bandpass filters
gain=[0 0 1 1 0 0];
for n = 2:num_channel-1
    if (Cross_freq(n-1)-ft) < ft
        f = sort([0,(Cross_freq(n-1)-(ft/4)),(Cross_freq(n-1)+ft),(Cross_freq(n)-ft),(Cross_freq(n)+ft),nyqfreq]); % frequency points in increasing order
    else
        f = sort([0,(Cross_freq(n-1)-ft),(Cross_freq(n-1)+ft),(Cross_freq(n)-ft),(Cross_freq(n)+ft),nyqfreq]); % frequency points in increasing order
    end
    b(n,:) = fir2(nfir,f./nyqfreq,gain); %FIR filter design
    y(:,n) = conv(x,b(n,:));
end

function window = lanczos(L)
k = 1:L;
window = sinc(2*k/(L-1)-1);
window = window';

function k = menu2(xHeader,varargin)
%   J.N. Little 4-21-87, revised 4-13-92 by LS, 2-18-97 by KGK.
%   Copyright 1984-2005 The MathWorks, Inc.
%   $Revision: 5.21.4.2 $  $Date: 2005/06/21 19:41:25 $
if nargin < 2
    disp('MENU: No menu items to choose from.')
    k=0;
    return
elseif nargin==2 && iscell(varargin{1})
    ArgsIn = varargin{1}; % a cell array was passed in
else
    ArgsIn = varargin;    % use the varargin cell array
end

useGUI   = 1; % Assume we can use a GUI
if isunix    % Unix?
    useGUI = ~isempty(getenv('DISPLAY'));
end

if useGUI
    % Create a GUI menu to aquire answer "k"
    k = local_GUImenu2( xHeader, ArgsIn );
else
    % Create an ascii menu to aquire answer "k"
    k = local_ASCIImenu2( xHeader, ArgsIn );
end

function k = local_ASCIImenu2( xHeader, xcItems )
% local function to display an ascii-generated menu and return the user's
% selection from that menu as an index into the xcItems cell array
numItems = length(xcItems);
while 1
    disp(' ')
    disp(['----- ',xHeader,' -----'])
    disp(' ')
    for n = 1 : numItems
        disp( [ '      ' int2str(n) ') ' xcItems{n} ] )
    end
    disp(' ')
    k = input('Select a menu number: ');
    if isempty(k), k = -1; end
    if  (k < 1) || (k > numItems) ...
            || ~isa(k, 'double') ...
            || ~isreal(k) || isnan(k) || isinf(k)
        % Failed a key test. Ask question again
        disp(' ')
        disp('Selection out of range. Try again.')
    else
        % Passed all tests, exit loop and return k
        return
    end
end

function k = local_GUImenu2( xHeader, xcItems )
% local function to display a Handle Graphics menu and return the user's
% selection from that menu as an index into the xcItems cell array

MenuUnits   = 'points'; % units used for all HG objects
textPadding = [18 8];   % extra [Width Height] on uicontrols to pad text
uiGap       = 5;        % space between uicontrols
uiBorder    = 5;        % space between edge of figure and any uicontol
winTopGap   = 50;       % gap between top of screen and top of figure **
winLeftGap  = 15;       % gap between side of screen and side of figure **

% ** "figure" ==> viewable figure. You must allow space for the OS to add
% a title bar (aprx 42 points on Mac and Windows) and a window border
% (usu 2-6 points). Otherwise user cannot move the window.
numItems = length( xcItems );
menuFig = figure(...
    'Units'       ,MenuUnits, ...
    'Visible'     ,'off', ...
    'NumberTitle' ,'off', ...
    'Name'        ,'MENU', ...
    'Resize'      ,'off', ...
    'Colormap'    ,[], ...
    'Menubar'     ,'none',...
    'Toolbar' 	,'none',...
    'CloseRequestFcn','set(gcbf,''userdata'',0)');
hText = uicontrol( ...
    'style'       ,'text', ...
    'string'      ,xHeader, ...
    'units'       ,MenuUnits, ...
    'Position'    ,[ 100 100 100 20 ], ...
    'Horizontal'  ,'center',...
    'BackGround'  ,get(menuFig,'Color') );
maxsize = get( hText, 'Extent' );
textWide  = 4.*maxsize(3);
textHigh  = 4.*maxsize(4);
% Loop to add buttons in reverse order (to automatically initialize numitems).
% Note that buttons may overlap, but are placed in correct position relative
% to each other. They will be resized and spaced evenly later on.

for idx = numItems : -1 : 1 % start from top of screen and go down
    n = numItems - idx + 1;  % start from 1st button and go to last
    % make a button
    hBtn(n) = uicontrol( ...
        'units'          ,MenuUnits, ...
        'position'       ,[uiBorder uiGap*idx textHigh textWide], ...
        'callback'       ,['set(gcf,''userdata'',',int2str(n),')'], ...
        'string'         ,xcItems{n} );
end
cAllExtents = get( hBtn, {'Extent'} );  % put all data in a cell array
AllExtents  = cat( 1, cAllExtents{:} ); % convert to an n x 3 matrix
maxsize     = max( AllExtents(:,3:4) ); % calculate the largest width & height
maxsize     = maxsize + textPadding;    % add some blank space around text
btnHigh     = 4.*maxsize(2);
btnWide     = 4.*maxsize(1);
oldUnits = get(0,'Units');         % remember old units
set( 0, 'Units', MenuUnits );      % convert to desired units
screensize = get(0,'ScreenSize');  % record screensize
set( 0, 'Units',  oldUnits );      % convert back to old units
% How many rows and columns of buttons will fit in the screen?
% Note: vertical space for buttons is the critical dimension
% --window can't be moved up, but can be moved side-to-side
openSpace = screensize(4) - winTopGap - 2*uiBorder - textHigh;
numRows = min( floor( openSpace/(btnHigh + uiGap) ), numItems );
if numRows == 0; numRows = 1; end % Trivial case--but very safe to do
numCols = ceil( numItems/numRows );
% Calculate the window size needed to display all buttons
winHigh = numRows*(btnHigh + uiGap) + textHigh + 2*uiBorder;
winWide = numCols*(btnWide) + (numCols - 1)*uiGap + 2*uiBorder;

% Make sure the text header fits
if winWide < (2*uiBorder + textWide)
    winWide = 2*uiBorder + textWide;
end
bottom = screensize(4) - (winHigh + winTopGap);
set( menuFig, 'Position', [winLeftGap bottom winWide winHigh],'color','y' );
xPos = ( uiBorder + [0:numCols-1]'*( btnWide + uiGap )*ones(1,numRows) )';
xPos = xPos(1:numItems); % [ all 1st col; all 2nd col; ...; all nth col ]
yPos = ( uiBorder + [numRows-1:-1:0]'*( btnHigh + uiGap )*ones(1,numCols) );
yPos = yPos(1:numItems); % [ rows 1:m; rows 1:m; ...; rows 1:m ]
allBtn   = ones(numItems,1);
uiPosMtx = [ xPos(:), yPos(:), btnWide*allBtn, btnHigh*allBtn ];
cUIPos   = num2cell( uiPosMtx( 1:numItems, : ), 2 );
set( hBtn, {'Position'}, cUIPos,'fontsize',30,'fontweight','bold' )
textWide = winWide - 2*uiBorder;
set( hText, ...
    'Position', [ uiBorder winHigh-uiBorder-textHigh textWide textHigh ],'fontsize',30,'fontweight','bold','BackgroundColor','w' );
set( menuFig, 'Visible', 'on' );
waitfor(gcf,'userdata')
k = get(gcf,'userdata');
delete(menuFig)

function k = menu3(xHeader,varargin)
%   J.N. Little 4-21-87, revised 4-13-92 by LS, 2-18-97 by KGK.
%   Copyright 1984-2005 The MathWorks, Inc.
%   $Revision: 5.21.4.2 $  $Date: 2005/06/21 19:41:25 $
if nargin < 2
    disp('MENU: No menu items to choose from.')
    k=0;
    return
elseif nargin==2 && iscell(varargin{1})
    ArgsIn = varargin{1}; % a cell array was passed in
else
    ArgsIn = varargin;    % use the varargin cell array
end
useGUI   = 1; % Assume we can use a GUI
if isunix     % Unix?
    useGUI = ~isempty(getenv('DISPLAY'));
end

if useGUI
    k = local_GUImenu3( xHeader, ArgsIn );
else
    k = local_ASCIImenu3( xHeader, ArgsIn );
end
function k = local_ASCIImenu3( xHeader, xcItems )
% local function to display an ascii-generated menu and return the user's
% selection from that menu as an index into the xcItems cell array
numItems = length(xcItems);
while 1
    disp(' ')
    disp(['----- ',xHeader,' -----'])
    disp(' ')
    for n = 1 : numItems
        disp( [ '      ' int2str(n) ') ' xcItems{n} ] )
    end
    disp(' ')
    k = input('Select a menu number: ');
    if isempty(k), k = -1; end
    if  (k < 1) || (k > numItems) ...
            || ~isa(k,'double') ...
            || ~isreal(k) || (isnan(k)) || isinf(k)
        % Failed a key test. Ask question again
        disp(' ')
        disp('Selection out of range. Try again.')
    else
        % Passed all tests, exit loop and return k
        return
    end
end
function k = local_GUImenu3( xHeader, xcItems )
% local function to display a Handle Graphics menu and return the user's
% selection from that menu as an index into the xcItems cell array
MenuUnits   = 'points'; % units used for all HG objects
textPadding = [18 8];   % extra [Width Height] on uicontrols to pad text
uiGap       = 5;        % space between uicontrols
uiBorder    = 5;        % space between edge of figure and any uicontol
winTopGap   = 50;       % gap between top of screen and top of figure **
winLeftGap  = 15;       % gap between side of screen and side of figure **
numItems = length( xcItems );
menuFig = figure( 'Units'       ,MenuUnits, ...
    'Visible'     ,'off', ...
    'NumberTitle' ,'off', ...
    'Name'        ,'MENU', ...
    'Resize'      ,'off', ...
    'Colormap'    ,[], ...
    'Menubar'     ,'none',...
    'Toolbar' 	,'none',...
    'CloseRequestFcn','set(gcbf,''userdata'',0)');
hText = uicontrol( ...
    'style'       ,'text', ...
    'string'      ,xHeader, ...
    'units'       ,MenuUnits, ...
    'Position'    ,[ 100 100 100 20 ], ...
    'Horizontal'  ,'center',...
    'BackGround'  ,get(menuFig,'Color') );
% Record extent of text string
maxsize = get( hText, 'Extent' );
textWide  = 4.*maxsize(3);
textHigh  = 4.*maxsize(4);
% Loop to add buttons in reverse order (to automatically initialize numitems).
% Note that buttons may overlap, but are placed in correct position relative
% to each other. They will be resized and spaced evenly later on.

for idx = numItems:-1:1 % start from top of screen and go down
    n = numItems - idx + 1;  % start from 1st button and go to last
    hBtn(n) = uicontrol( ...
        'units'          ,MenuUnits, ...
        'position'       ,[uiBorder uiGap*idx textHigh textWide], ...
        'callback'       ,['set(gcf,''userdata'',',int2str(n),')'], ...
        'string'         ,xcItems{n} );
end

cAllExtents = get( hBtn, {'Extent'} );  % put all data in a cell array
AllExtents  = cat( 1, cAllExtents{:} ); % convert to an n x 3 matrix
maxsize     = max( AllExtents(:,3:4) ); % calculate the largest width & height
maxsize     = maxsize + textPadding;    % add some blank space around text
btnHigh     = 4.*maxsize(2);
btnWide     = 4.*maxsize(1);
oldUnits = get(0,'Units');         % remember old units
set( 0, 'Units', MenuUnits );      % convert to desired units
screensize = get(0,'ScreenSize');  % record screensize
set( 0, 'Units',  oldUnits );      % convert back to old units
openSpace = screensize(4) - winTopGap - 2*uiBorder - textHigh;
numRows = min( floor( openSpace/(btnHigh + uiGap) ), numItems );
if numRows == 0; numRows = 1; end % Trivial case--but very safe to do
numCols = ceil( numItems/numRows );
winHigh = numRows*(btnHigh + uiGap) + textHigh + 2*uiBorder;
winWide = numCols*(btnWide) + (numCols - 1)*uiGap + 2*uiBorder;
% Make sure the text header fits
if winWide < (2*uiBorder + textWide)
    winWide = 2*uiBorder + textWide;
end
bottom = screensize(4) - (winHigh + winTopGap);
set( menuFig, 'Position', [winLeftGap bottom winWide winHigh]);
xPos = ( uiBorder + (0:numCols-1)'*( btnWide + uiGap )*ones(1,numRows) )';
xPos = xPos(1:numItems); % [ all 1st col; all 2nd col; ...; all nth col ]
yPos = ( uiBorder + (numRows-1:-1:0)'*( btnHigh + uiGap )*ones(1,numCols) );
yPos = yPos(1:numItems); % [ rows 1:m; rows 1:m; ...; rows 1:m ]
allBtn   = ones(numItems,1);
uiPosMtx = [ xPos(:), yPos(:), btnWide*allBtn, btnHigh*allBtn ];
cUIPos   = num2cell( uiPosMtx( 1:numItems, : ), 2 );
set( hBtn, {'Position'}, cUIPos,'fontsize',30,'fontweight','bold' );
textWide = winWide - 2*uiBorder;
set( hText, ...
    'Position', [ uiBorder winHigh-uiBorder-textHigh textWide textHigh ],'fontsize',30,'fontweight','bold','BackgroundColor','w' );
set( menuFig, 'Visible', 'on' );
waitfor(gcf,'userdata')
k = get(gcf,'userdata');
delete(menuFig)

function k = menu4(xHeader,varargin)
%   J.N. Little 4-21-87, revised 4-13-92 by LS, 2-18-97 by KGK.
%   Copyright 1984-2005 The MathWorks, Inc.
%   $Revision: 5.21.4.2 $  $Date: 2005/06/21 19:41:25 $
if nargin < 2
    disp('MENU: No menu items to choose from.')
    k=0;
    return
elseif nargin==2 && iscell(varargin{1})
    ArgsIn = varargin{1}; % a cell array was passed in
else
    ArgsIn = varargin;    % use the varargin cell array
end
useGUI   = 1; % Assume we can use a GUI
if isunix     % Unix?
    useGUI = ~isempty(getenv('DISPLAY'));
end
if useGUI
    k = local_GUImenu4( xHeader, ArgsIn );
else
    k = local_ASCIImenu4( xHeader, ArgsIn );
end

function k = local_ASCIImenu4( xHeader, xcItems )
% local function to display an ascii-generated menu and return the user's
% selection from that menu as an index into the xcItems cell array
numItems = length(xcItems);
while 1
    disp(' ')
    disp(['----- ',xHeader,' -----'])
    disp(' ')
    % Display items in a numbered list
    for n = 1 : numItems
        disp( [ '      ' int2str(n) ') ' xcItems{n} ] )
    end
    disp(' ')
    % Prompt for user input
    k = input('Select a menu number: ');
    % Check input:
    % 1) make sure k has a value
    if isempty(k), k = -1; end
    % 2) make sure the value of k is valid
    if  (k < 1) || (k > numItems) ...
            || ~isa(k,'double') ...
            || ~isreal(k) || (isnan(k)) || isinf(k)
        % Failed a key test. Ask question again
        disp(' ')
        disp('Selection out of range. Try again.')
    else
        % Passed all tests, exit loop and return k
        return
    end
end

function k = local_GUImenu4( xHeader, xcItems )
% local function to display a Handle Graphics menu and return the user's
% selection from that menu as an index into the xcItems cell array
MenuUnits   = 'points'; % units used for all HG objects
textPadding = [18 8];   % extra [Width Height] on uicontrols to pad text
uiGap       = 5;        % space between uicontrols
uiBorder    = 5;        % space between edge of figure and any uicontol
winTopGap   = 50;       % gap between top of screen and top of figure **
winLeftGap  = 15;       % gap between side of screen and side of figure **
numItems = length( xcItems );
menuFig = figure( 'Units'       ,MenuUnits, ...
    'Visible'     ,'off', ...
    'NumberTitle' ,'off', ...
    'Name'        ,'MENU', ...
    'Resize'      ,'off', ...
    'Colormap'    ,[], ...
    'Menubar'     ,'none',...
    'Toolbar' 	,'none',...
    'CloseRequestFcn','set(gcbf,''userdata'',0)');
hText = uicontrol( ...
    'style'       ,'text', ...
    'string'      ,xHeader, ...
    'units'       ,MenuUnits, ...
    'Position'    ,[ 100 100 100 20 ], ...
    'Horizontal'  ,'center',...
    'BackGround'  ,get(menuFig,'Color') );
maxsize = get( hText, 'Extent' );
textWide  = 4.*maxsize(3);
textHigh  = 4.*maxsize(4);

for idx = numItems:-1:1 % start from top of screen and go down
    n = numItems - idx + 1;  % start from 1st button and go to last
    hBtn(n) = uicontrol( ...
        'units'          ,MenuUnits, ...
        'position'       ,[uiBorder uiGap*idx textHigh textWide], ...
        'callback'       ,['set(gcf,''userdata'',',int2str(n),')'], ...
        'string'         ,xcItems{n} );
end
cAllExtents = get( hBtn, {'Extent'} );  % put all data in a cell array
AllExtents  = cat( 1, cAllExtents{:} ); % convert to an n x 3 matrix
maxsize     = max( AllExtents(:,3:4) ); % calculate the largest width & height
maxsize     = maxsize + textPadding;    % add some blank space around text
btnHigh     = 3.*maxsize(2);
btnWide     = 3.*maxsize(1);
oldUnits = get(0,'Units');         % remember old units
set( 0, 'Units', MenuUnits );      % convert to desired units
screensize = get(0,'ScreenSize');  % record screensize
set( 0, 'Units',  oldUnits );      % convert back to old units
openSpace = screensize(4) - winTopGap - 2*uiBorder - textHigh;
numRows = min( floor( openSpace/(btnHigh + uiGap) ), numItems );
if numRows == 0; numRows = 1; end % Trivial case--but very safe to do
numCols = ceil( numItems/numRows );
winHigh = numRows*(btnHigh + uiGap) + textHigh + 2*uiBorder;
winWide = numCols*(btnWide) + (numCols - 1)*uiGap + 2*uiBorder;
if winWide < (2*uiBorder + textWide)
    winWide = 2*uiBorder + textWide;
end
bottom = screensize(4) - (winHigh + winTopGap);
set( menuFig, 'Position', [winLeftGap bottom winWide winHigh],'color','y' );
xPos = ( uiBorder + (0:numCols-1)'*( btnWide + uiGap )*ones(1,numRows) )';
xPos = xPos(1:numItems); % [ all 1st col; all 2nd col; ...; all nth col ]
yPos = ( uiBorder + (numRows-1:-1:0)'*( btnHigh + uiGap )*ones(1,numCols) );
yPos = yPos(1:numItems); % [ rows 1:m; rows 1:m; ...; rows 1:m ]
allBtn   = ones(numItems,1);
uiPosMtx = [ xPos(:), yPos(:), btnWide*allBtn, btnHigh*allBtn ];
cUIPos   = num2cell( uiPosMtx( 1:numItems, : ), 2 );
set( hBtn, {'Position'}, cUIPos,'fontsize',20,'fontweight','bold' );
textWide = winWide - 2*uiBorder;
set( hText, ...
    'Position', [ uiBorder winHigh-uiBorder-textHigh textWide textHigh ],'fontsize',30,'fontweight','bold','BackgroundColor','w' );
set( menuFig, 'Visible', 'on' );
waitfor(gcf,'userdata')
k = get(gcf,'userdata');
delete(menuFig)

function newfigure(c)
if c ~= 99
    figure('Name',sprintf('Channel %s, I/O Plot',c),'NumberTitle','off');
else
    figure('Name','Broadband OCL I/O Plot','NumberTitle','off');
end

function newfigure2(c)
if c ~= 99
    figure('Name',sprintf('Channel %s, Internal Dynamics',c),'NumberTitle','off');
else
    figure('Name','Broadband OCL Internal Dynamics','NumberTitle','off');
end

function [B,A] = oct3dsgn(Fc,Fs,N)
% OCT3DSGN  Design of a one-third-octave filter.
%    [B,A] = OCT3DSGN(Fc,Fs,N) designs a digital 1/3-octave filter with
%    center frequency Fc for sampling frequency Fs.
%    The filter is designed according to the Order-N specification
%    of the ANSI S1.1-1986 standard. Default value for N is 3.
%    Warning: for meaningful design results, center frequency used
%    should preferably be in range Fs/200 < Fc < Fs/5.
%    Usage of the filter: Y = FILTER(B,A,X).
%
%    Requires the Signal Processing Toolbox.
%
%    See also OCT3SPEC, OCTDSGN, OCTSPEC.

% Author: Christophe Couvreur, Faculte Polytechnique de Mons (Belgium)
%         couvreur@thor.fpms.ac.be
% Last modification: Aug. 25, 1997, 2:00pm.

% References:
%    [1] ANSI S1.1-1986 (ASA 65-1986): Specifications for
%        Octave-Band and Fractional-Octave-Band Analog and
%        Digital Filters, 1993.
if (nargin > 3) || (nargin < 2)
    error('Invalid number of arguments.');
end
if (nargin == 2)
    N = 3;
end
if (Fc > 0.88*(Fs/2))
    error('Design not possible. Check frequencies.');
end
% Design Butterworth 2Nth-order one-third-octave filter
% Note: BUTTER is based on a bilinear transformation, as suggested in [1].
pi = 3.14159265358979;
f1 = Fc/(2^(1/6));
f2 = Fc*(2^(1/6));
Qr = Fc/(f2-f1);
Qd = (pi/2/N)/(sin(pi/2/N))*Qr;
alpha = (1 + sqrt(1+4*Qd^2))/2/Qd;
W1 = Fc/(Fs/2)/alpha;
W2 = Fc/(Fs/2)*alpha;
[B,A] = butter(N,[W1,W2]);

function ProcDir(lid,TestEar,SourceDir,DestDir,refdB,Proc,DSL,att,rel,NFCstart,NFCratio)
if TestEar == 0
    EARlabel = 'RIGHT';
else
    EARlabel = 'LEFT';
end
if strncmpi(SourceDir,'C:\HA Simulator\BoyDogFrog',26)
    story = 1;
    delFolderContents(tempdir,'boy*');
elseif strncmpi(SourceDir,'C:\HA Simulator\Frog',20)
    story = 2;
    delFolderContents(tempdir,'Frog*');
else
    story = 0;
end
mkdir(strcat(DestDir,'\',lid));
cd(SourceDir)
file = dir('*.wav');
filename = {file.name};
index = length(filename);
parfor n = 1:index
    procfile(char(filename(n)),refdB,lid,EARlabel,Proc,story,NFCstart,NFCratio,DestDir,DSL,att,rel)
end
if story > 0
    concat = [];
    for n = 1:index
        [q,Fs,~] = audioread(strcat(tempdir,char(filename(n))));
        concatsize = length(concat);
        qsize = length(q);
        concat(concatsize+1:concatsize+qsize) = q;
    end
    if story == 1
        audiowrite(strcat(DestDir,'\',lid,'\',sprintf('Boy-%s-%s',Proc,EARlabel(1))), concat, Fs);
        delFolderContents(tempdir,'boy*');
    else
        audiowrite(strcat(DestDir,'\',lid,'\',sprintf('Frog-%s-%s',Proc,EARlabel(1))), concat, Fs);
        delFolderContents(tempdir,'Frog*');
    end
    cd(SourceDir)
end

function procfile(stim,refdB,lid,EARlabel,Proc,story,NFCstart,NFCratio,DestDir,DSL,att,rel)
maxdB = 119;
[x,Fs,Nbits] = audioread(stim);
if Fs ~= 22050
    warndlg('The sampling rate needs to be 22.05 kHz.','SAMPLING RATE ERROR');
    startup
end
switch Proc
    case 'EBW'
        y = WDRC(DSL.Cross_freq,x,Fs,refdB,maxdB,DSL.TKgain,DSL.CR,DSL.TK,DSL.BOLT,att,rel);
        z = FIRlowpass(y,22050,1024,10000);
    case 'RBW'
        y = WDRC(DSL.Cross_freq,x,Fs,refdB,maxdB,[DSL.TKgain(1:7),0],DSL.CR,DSL.TK,DSL.BOLT,att,rel);
        z = FIRlowpass(y,22050,1024,5000);
    case 'NFC'
        startbin = round((NFCstart/(22050/128)));
        startfreq = startbin*(22050/128);
        maxIN = (26+startbin)*(22050/128);
        maxOut= (startfreq^(1-(1/NFCratio)))*(maxIN^(1/NFCratio));
        [I] = find(DSL.Cross_freq > maxOut);
        DSL.TKgain(I+1) = 0;
        w = FreqComp(x,Fs,NFCstart,NFCratio,26);
        y = WDRC(DSL.Cross_freq,w,Fs,refdB,maxdB,DSL.TKgain,DSL.CR,DSL.TK,DSL.BOLT,att,rel);
        z = FIRlowpass(y,22050,1024,maxOut);
end
if story == 0
    audiowrite(strcat(DestDir,'\',lid,'\',sprintf('%s-%s-%s',stim(1:end-4),Proc,EARlabel(1))),z,Fs, ...
        'bitsPerSample', Nbits);
else
    audiowrite(strcat(tempdir,stim),z,Fs, ...
        'bitsPerSample', Nbits);
end

function [Thresh, ThreshSPL, TK, TKgain, BOLT, CR, TargetAvg, TargetLo, TargetHi] = readDSLfile(filename)
a = csvread(filename,1,1);
a=a(:,1:18);
length = size(a,2);
Thresh = a(1,1:length-1);
ThreshSPL = a(8,1:length-1);
CTout = a(13,1:length-1);
TK = a(15,1:length-1);
BOLT = a(10,1:length-1);
CR = a(17,1:length-1);
TKgain = CTout - TK;
TargetLo = a(22,1:length-1);
TargetAvg = a(23,1:length-1);
TargetHi = a(24,1:length-1);

function redraw_audiogram(HL,done)
set(0,'Units','pixels');
scnsize = get(0,'ScreenSize');
scnsize(4) = scnsize(4).*0.9;
scnsize(1:2) = [0 0];
figure1 = figure('Position',scnsize);
hold on
grid on
axis square
set(gca,'FontName','Arial','FontWeight','bold','FontSize',12)
set(gca,'YDir','rev'); % flip y-axis
set(gca,'xTick',1:6,'LineWidth',1.25,'xlim',[0 6.2],'YMinorTick','off');
set(gca,'yTick',-10:10:120,'LineWidth',1.25,'ylim',[-10 120]);
set(gca,'XTickLabel',['250 ';'500 ';'1000';'2000';'4000';'8000']);
xlabel('Frequency, Hertz');
ylabel('Hearing Level, dB HL');
annotation(figure1,'textbox','String',{'Right TDH (o)'},...
    'HorizontalAlignment','center',...
    'FontWeight','bold',...
    'FontSize',14,...
    'FontName','Arial',...
    'LineWidth',1,...
    'BackgroundColor',[1 1 1],...
    'Position',[0.83 0.79 0.17 0.07],...
    'Color',[1 0 0 ]);
annotation(figure1,'textbox','String',{'Left TDH (x)'},...
    'HorizontalAlignment','center',...
    'FontWeight','bold',...
    'FontSize',14,...
    'FontName','Arial',...
    'LineWidth',1,...
    'BackgroundColor',[1 1 1],...
    'Position',[0.83 0.728 0.17 0.07],...
    'Color',[0 0 1]);
annotation(figure1,'textbox','String',{'Right Insert (\bullet)'},...
    'HorizontalAlignment','center',...
    'FontWeight','bold',...
    'FontSize',14,...
    'FontName','Arial',...
    'LineWidth',1,...
    'BackgroundColor',[1 1 1],...
    'Position',[0.83 0.666 0.17 0.07],...
    'Color',[1 0 0 ]);
annotation(figure1,'textbox','String',{'Left Insert (*)'},...
    'HorizontalAlignment','center',...
    'FontWeight','bold',...
    'FontSize',14,...
    'FontName','Arial',...
    'LineWidth',1,...
    'BackgroundColor',[1 1 1],...
    'Position',[0.83 0.604 0.17 0.07],...
    'Color',[0 0 1]);
annotation(figure1,'textbox','String',{'Right Bone ([)'},...
    'HorizontalAlignment','center',...
    'FontWeight','bold',...
    'FontSize',14,...
    'FontName','Arial',...
    'LineWidth',1,...
    'BackgroundColor',[1 1 1],...
    'Position',[0.83 0.542 0.17 0.07],...
    'Color',[1 0 0 ]);
annotation(figure1,'textbox','String',{'Left Bone (])'},...
    'HorizontalAlignment','center',...
    'FontWeight','bold',...
    'FontSize',14,...
    'FontName','Arial',...
    'LineWidth',1,...
    'BackgroundColor',[1 1 1],...
    'Position',[0.83 0.48 0.17 0.07],...
    'Color',[0 0 1]);
annotation(figure1,'textbox','String',{'Bone Unmasked (\^)'},...
    'HorizontalAlignment','center',...
    'FontWeight','bold',...
    'FontSize',12,...
    'FontName','Arial',...
    'LineWidth',1,...
    'BackgroundColor',[1 1 1],...
    'Position',[0.83 0.418 0.17 0.07]);

if done < 1
    annotation(figure1,'textbox','String',{'Done'},...
        'HorizontalAlignment','center',...
        'FontWeight','bold',...
        'FontSize',16,...
        'FontName','Arial',...
        'LineWidth',1,...
        'BackgroundColor',[(255/255) (240/255) (165/255)],...
        'Position',[0.83 0.358 0.17 0.07]);
end
xvec(1) = 1;
for F = 2:10, xvec(F) = (F+2)./2; end
for F = 1:10
    if HL.Rtdh(F) >= -10
        h1 = plot(xvec(F)-0.08,HL.Rtdh(F),'ro');
        set(h1,'MarkerSize',12,'MarkerFaceColor','white','LineWidth',2);
    end
    if HL.Rins(F) >= -10
        h1 = plot(xvec(F)-0.12,HL.Rins(F)+0.35,'ro');
        set(h1,'MarkerSize',8,'MarkerFaceColor','red','LineWidth',2);
    end
    if HL.Lins(F) >= -10
        h1 = plot(xvec(F)+0.12,HL.Lins(F)+0.35,'b*');
        set(h1,'MarkerSize',8,'MarkerFaceColor','blue','LineWidth',2);
    end
    if HL.Rbc(F) >= -10
        text(xvec(F)-0.12,HL.Rbc(F),'[','Fontsize',18,'Fontweight','Bold');
    end
    if HL.Lbc(F) >= -10
        text(xvec(F)+0.03,HL.Lbc(F),']','Fontsize',18,'Fontweight','Bold');
    end
    if HL.Ltdh(F) >= -10
        h1 = plot(xvec(F)+0.08,HL.Ltdh(F),'bx');
        set(h1,'MarkerSize',17,'MarkerFaceColor','white','LineWidth',2);
    end
    
    if HL.Ubc(F) >= -10
        text(xvec(F)-0.09,HL.Ubc(F)-1,'\^','Fontsize',28);
    end
end

function RMS = rms2(x)
RMS = norm(x)/sqrt(length(x));

function y = round2(x,dec)
y = (round(x.*(10.^dec)))./(10.^dec);

function osc_out = sinoscillator(freq,mag,t,Fs,pXk)
temp = zeros(length(freq),length(t));
for k = 1:length(freq)
    temp(k,:) = mag(k)*sin(Fs*freq(k)*t+pXk(k));
end
osc_out = sum(temp,1);

function peak = Smooth_ENV(x,attack,release,Fs)
% Compute the filter time constants
att=0.001*attack*Fs/2.425; %ANSI attack time => filter time constant
alpha=att/(1.0 + att);
rel=0.001*release*Fs/1.782; %ANSI release time => filter time constant
beta=rel/(1.0 + rel);
% Initialze the output array
nsamp=size(x,1);
peak=zeros(nsamp,1);
% Loop to peak detect the signal in each band
band=abs(x); %Extract the rectified signal in the band
peak(1)=band(1); %First peak value is the signal sample
for k=2:nsamp
    if band(k) >= peak(k-1)
        peak(k)=alpha*peak(k-1) + (1-alpha)*band(k);
    else
        peak(k)=beta*peak(k-1);
    end
end

function banana = speechmap2(maxdB,x,Fs)
N = 3; 					% Order of analysis filters.
f = [200 250 315, 400 500 630, 800 1000 1250, 1600 2000 2500, 3150 4000 5000, 6300 8000]; % Preferred labeling freq.
nF = 17;
ff = (1000).*((2^(1/3)).^(-7:nF-8)); 	% Exact center freq.
% Design filters and compute RMS powers in 1/3-oct. bands
% 10000 Hz band to 1600 Hz band, direct implementation of filters.
B(1:nF,1:7) = 0;
A(1:nF,1:7) = 0;
for i = nF:-1:10
    [B(i,1:7),A(i,1:7)] = oct3dsgn(ff(i),Fs,N);
end
for j = 0:2
    B((j.*3)+1,:) = B(10,:);
    B((j.*3)+2,:) = B(11,:);
    B((j.*3)+3,:) = B(12,:);
    
    A((j.*3)+1,:) = A(10,:);
    A((j.*3)+2,:) = A(11,:);
    A((j.*3)+3,:) = A(12,:);
end
winsize = round(Fs.*0.128);
stepsize = winsize./2;
Nsamples = floor(length(x)./stepsize)-1;
w = hann(winsize);
levels(1:Nsamples,1:nF) = 0;
for n = 1:Nsamples
    startpt = ((n-1).*stepsize)+1;
    y = w.*x(startpt:(startpt+winsize-1));
    for i = nF:-1:10
        z = filter(B(i,:),A(i,:),y);
        P(n,i) = sum(z.^2)/length(z);
    end
    for j = 2:-1:0
        y = decimate(y,2);
        
        i = (j.*3)+3;
        z = filter(B(i,:),A(i,:),y);
        P(n,i) = sum(z.^2)/length(z);
        
        i = (j.*3)+2;
        z = filter(B(i,:),A(i,:),y);
        P(n,i) = sum(z.^2)/length(z);
        
        i = (j.*3)+1;
        z = filter(B(i,:),A(i,:),y);
        P(n,i) = sum(z.^2)/length(z);
    end
end
for n = 1:nF
    banana(n) = maxdB+10*log10((mean(P(:,n))));
end

function h = timebar(message,name,update_rate)
%    Version: 2.0
%    Version History:
%    1.0   2002-01-18   Initial release
%    2.0   2002-01-21   Added update rate option
%
%    Copyright 2002, Chad English
%    cenglish@myrealbox.com
if nargin < 3                                               % If update rate is not input
    update_rate = 0.1;                                      %    set it to 0.1 seconds
end
if ~ishandle(message)                                       % If first input is not a timebar handle,
    winwidth = 300;                                         % Width of timebar window
    winheight = 75;                                         % Height of timebar window
    screensize = get(0,'screensize');                       % User's screen size [1 1 width height]
    screenwidth = screensize(3);                            % User's screen width
    screenheight = screensize(4);                           % User's screen height
    winpos = [0.5*(screenwidth-winwidth), ...
        0.5*(screenheight-winheight), winwidth, winheight];  % Position of timebar window origin
    if nargin < 2
        name = '';                                          % If timebar name not input, set blank
    end
    wincolor = 0.75*[1 1 1];                                % Define window color
    est_text = 'Estimated time remaining: ';                % Set static estimated time text
    h = figure('menubar','none',...                         % Turn figure menu display off
        'numbertitle','off',...                             % Turn figure numbering off
        'name',name,...                                     % Set the figure name to input name
        'position',winpos,...                               % Set the position of the figure as above
        'color',wincolor,...                                % Set the figure color
        'resize','off',...                                  % Turn of figure resizing
        'tag','timebar');                                   % Tag the figure for later checking
    userdata.text(1) = uicontrol(h,'style','text',...       % Prepare message text (set the style to text)
        'pos',[10 winheight-30 winwidth-20 20],...          % Set the textbox position and size
        'hor','center',...                                  % Center the text in the textbox
        'backgroundcolor',wincolor,...                      % Set the textbox background color
        'foregroundcolor',0*[1 1 1],...                     % Set the text color
        'string',message);                                  % Set the text to the input message
    userdata.text(2) = uicontrol(h,'style','text',...       % Prepare static estimated time text
        'pos',[10 5 winwidth-20 20],...                     % Set the textbox position and size
        'hor','left',...                                    % Left align the text in the textbox
        'backgroundcolor',wincolor,...                      % Set the textbox background color
        'foregroundcolor',0*[1 1 1],...                     % Set the text color
        'string',est_text);             % Set the static text for estimated time
    userdata.text(3) = uicontrol(h,'style','text',...       % Prepare estimated time
        'pos',[135 5 winwidth-145 20],...                   % Set the textbox position and size
        'hor','left',...                                    % Left align the text in the textbox
        'backgroundcolor',wincolor,...                      % Set the textbox background color
        'foregroundcolor',0*[1 1 1],...                     % Set the text color
        'string','');                                       % Initialize the estimated time as blank
    userdata.text(4) = uicontrol(h,'style','text',...       % Prepare the percentage progress
        'pos',[winwidth-35 winheight-50 25 20],...          % Set the textbox position and size
        'hor','right',...                                   % Left align the text in the textbox
        'backgroundcolor',wincolor,...                      % Set the textbox background color
        'foregroundcolor',0*[1 1 1],...                     % Set the textbox foreground color
        'string','');                                       % Initialize the progress text as blank
    userdata.axes = axes('parent',h,...                     % Set the progress bar parent to the figure
        'units','pixels',...                                % Provide axes units in pixels
        'pos',[10 winheight-45 winwidth-50 15],...          % Set the progress bar position and size
        'xlim',[0 1],...                                    % Set the range from 0 to 1
        'box','on',...                                      % Turn on axes box (to see where 100% is)
        'color',[1 1 1],...                                 % Set plot background color to white
        'xtick',[],'ytick',[]);                             % Turn off axes tick marks and labels
    userdata.bar = patch([0 0 0 0 0],[0 1 1 0 0],'r');      % Initialize progress bar to zero area
    userdata.time = clock;                                  % Record the current time
    userdata.inc = clock;                                   % Set incremental clock to current time
    set(h, 'userdata', userdata)                            % Allow access to the text and axes settings
else                                                        % If first input is a timebar handle, update
    pause(10e-100)                                          % Message, bar, and static text won't display
    %    without arbitrary pause (don't know why)
    h = message;                                            % Set handle to first input
    progress = name;                                        % Set progress to second input
    
    if ~strcmp(get(h,'tag'), 'timebar')                     % Check object tag to see if it is a timebar
        error('Handle is not to a timebar window')          % If not a timebar, report error and stop
    end
    userdata = get(h,'userdata');                           % Get the userdata included with the timebar
    inc = clock-userdata.inc;                               % Calculate time increment since last update
    inc_secs = inc(3)*3600*24 + inc(4)*3600 + ...
        inc(5)*60 + inc(6);                                 % Convert the increment to seconds
    if inc_secs > update_rate || progress == 1           % Only update at update rate or 100% complete
        userdata.inc = clock;                               % If updating, reset the increment clock
        set(h,'userdata',userdata)                          % Update userdata with the new clock setting
        tpast = clock-userdata.time;                        % Calculate time since timebar initialized
        seconds_past = tpast(3)*3600*24 + tpast(4)*3600 + ...
            tpast(5)*60 + tpast(6);                         % Transform passed time into seconds
        estimated_seconds = seconds_past*(1/progress-1);    % Estimate the time remaining in seconds
        hours = floor(estimated_seconds/3600);              % Calculate integer hours of estimated time
        minutes = floor((estimated_seconds-3600*hours)/60); % Calculate integer minutes of estimated time
        seconds = floor(estimated_seconds-3600*hours- ...
            60*minutes);                                    % Calculate integer seconds of estimated time
        tenths = floor(10*(estimated_seconds - ...
            floor(estimated_seconds)));                     % Calculate tenths of seconds (as integer)
        if progress > 1                                     % Check if input progress is > 1
            time_message = ' Error!  Progress > 1!';        % If >1, print error to estimated time
            time_color = 'r';                               %    in red
        else
            if hours < 10 
                h0 = '0'; 
            else
                h0 = '';
            end       % Put leading zero on hours if < 10
            if minutes < 10 
                m0 = '0'; 
            else
                m0 = '';
            end     % Put leading zero on minutes if < 10
            if seconds < 10 
                s0 = '0'; 
            else
                s0 = '';
            end     % Put leading zero on seconds if < 10
            time_message = strcat(h0,num2str(hours),':',m0,...
                num2str(minutes),':',s0,num2str(seconds),...
                '.',num2str(tenths),' (hh:mm:ss.t)');       % Format estimated time as hh:mm:ss.t
            time_color = 'k';                               % Format estimated time text as black
        end
        
        set(userdata.bar,'xdata',[0 0 progress progress 0]) % Update progress bar
        set(userdata.text(3),'string',time_message,...
            'foregroundcolor',time_color);                  % Update estimated time
        set(userdata.text(4),'string',...
            strcat(num2str(floor(100*progress)),'%'));      % Update progress percentage
    end
end

function y = WDRC(Cross_freq,x,Fs,rmsdB,maxdB,TKgain,CR,TK,BOLT,att,rel)
Nchannel = length(TKgain);
CL_TK = 105; % Compression limiter threshold kneepoint
CL_CR = 10;  % Compression limiter compression ratio
old_dB = maxdB + 20.*log10(sqrt(mean(x.^2)));
scale = 10.^((rmsdB - old_dB)/20);
x = x.*scale;
in_peak = Smooth_ENV(x,1,50,Fs);
in_pdB = maxdB + 20.*log10(in_peak);
[in_c,in_gdB] = WDRC_Circuit(x,0,in_pdB,CL_TK,CL_CR,CL_TK);
if Nchannel > 1
    [y] = HA_fbank2(Cross_freq,in_c,Fs);    % Nchannel FIR filter bank
else
    y = in_c;
end
nsamp = size(y,1);
pdB = zeros(nsamp, Nchannel);
parfor n = 1:Nchannel
    if BOLT(n) > CL_TK, BOLT(n) = CL_TK; end
    if TKgain(n) < 0, BOLT(n) = BOLT(n) + TKgain(n); end
    peak = Smooth_ENV(y(:,n),att,rel,Fs);
    pdB(:,n) = maxdB+20.*log10(peak);
    [c(:,n),gdB(:,n)]=WDRC_Circuit(y(:,n),TKgain(n),pdB(:,n),TK(n),CR(n),BOLT(n));
end
comp=sum(c,2);
out_peak = Smooth_ENV(comp,1,50,Fs);
out_pdB = maxdB + 20.*log10(out_peak);
[out_c,out_gdB] = WDRC_Circuit(comp,0,out_pdB,CL_TK,CL_CR,CL_TK);
y = out_c(89:end-88);

function [comp,gdB] = WDRC_Circuit(x,TKgain,pdB,TK,CR,BOLT)
nsamp=length(x);
if TK+TKgain > BOLT, TK = BOLT-TKgain; end
TKgain_origin = TKgain + (TK.*(1-1./CR));
gdB = zeros(nsamp,1);
pBOLT = CR*(BOLT - TKgain_origin);
parfor n=1:nsamp
    if ((pdB(n) < TK) && (CR >= 1))
        gdB(n)= TKgain;
    elseif (pdB(n) > pBOLT)
        gdB(n) = BOLT+((pdB(n)-pBOLT)*1/10)-pdB(n);
    else
        gdB(n) = ((1./CR)-1).*pdB(n) + TKgain_origin;
    end
end
g=10.^(gdB/20);
comp=x.*g;

function [comp,gdB,pBOLT,OCLcnt] = WDRC_Circuit2(x,TKgain,pdB,TK,CR,BOLT)
nsamp=length(x);
if TK+TKgain > BOLT, TK = BOLT-TKgain; end
TKgain_origin = TKgain + (TK.*(1-1./CR));
gdB = zeros(nsamp,1);
pBOLT = CR*(BOLT - TKgain_origin);
OCLcnt = 0;
parfor n=1:nsamp
    if ((pdB(n) < TK) && (CR >= 1))
        gdB(n)= TKgain;
    elseif (pdB(n) > pBOLT)
        gdB(n) = BOLT+((pdB(n)-pBOLT)*1/10)-pdB(n);
        OCLcnt = OCLcnt+1;
    else
        gdB(n) = ((1./CR)-1).*pdB(n) + TKgain_origin;
    end
end
g=10.^(gdB/20);
comp=x.*g;

function [Y,y,scale,x_dB,pdB,gdB,gdBnominal,BOLT,pBOLT,OCLcnt] = WDRC_diagnostics(Cross_freq,x,Fs,rmsdB,maxdB,TKgain,CR,TK,BOLT,att,rel)
Nchannel = length(TKgain);
CL_TK = 105;
CL_CR = 10;
old_dB = maxdB + 20.*log10(sqrt(mean(x.^2)));
scale = 10.^((rmsdB - old_dB)/20);
x = x.*scale;
in_peak = Smooth_ENV(x,1,50,Fs);
in_pdB = maxdB + 20.*log10(in_peak);
[in_c,in_gdB] = WDRC_Circuit2(x,0,in_pdB,CL_TK,CL_CR,CL_TK);
if Nchannel > 1
    [y] = HA_fbank2(Cross_freq,in_c,Fs);    % Nchannel FIR filter bank
else
    y = in_c;
end
nsamp = size(y,1);
pdB = zeros(nsamp, Nchannel);
OCLcnt(1:Nchannel) = 0;
parfor n = 1:Nchannel
    if BOLT(n) > CL_TK, BOLT(n) = CL_TK; end
    if TKgain(n) < 0, BOLT(n) = BOLT(n) + TKgain(n); end
    x_dB(:,n) = maxdB + 20.*log10(abs(y(:,n)));
    peak = Smooth_ENV(y(:,n),att,rel,Fs);
    pdB(:,n) = maxdB+20.*log10(peak);
    [c(:,n),gdB(:,n),pBOLT(n),OCLcnt(n)]=WDRC_Circuit2(y(:,n),TKgain(n),pdB(:,n),TK(n),CR(n),BOLT(n));
    [~,gdBnominal(:,n),~,~]=WDRC_Circuit2(ones(121,1),TKgain(n),0:120,TK(n),CR(n),BOLT(n));
end
comp=sum(c,2);
out_peak = Smooth_ENV(comp,1,50,Fs);
out_pdB = maxdB + 20.*log10(out_peak);
[out_c,out_gdB,out_pBOLT,out_OCLcnt] = WDRC_Circuit2(comp,0,out_pdB,CL_TK,CL_CR,CL_TK);
[~,out_gdBnominal,~,~] = WDRC_Circuit2(ones(121,1),0,0:120,CL_TK,CL_CR,CL_TK);
Y = out_c(89:end-88);
y(:,Nchannel+1) = [zeros(1,88) x' zeros(1,88)]';
x_dB(:,Nchannel+1) = maxdB + 20.*log10(abs(comp));
pdB(:,Nchannel+1) = out_pdB;
gdB(:,Nchannel+1) = out_gdB;
gdBnominal(:,Nchannel+1) = out_gdBnominal;
BOLT(Nchannel+1) = CL_TK;
pBOLT(Nchannel+1) = out_pBOLT;
OCLcnt(Nchannel+1) = out_OCLcnt;
OCLcnt = OCLcnt./nsamp;

function DSL = WDRC_Tune(att,rel,Nchannel,lid,ear,DSLdir,audiodir,rolloff)
[cent_freq,thirdOCTthr] = GetThresh(3,ear,audiodir,sprintf('%s Audiogram',lid));
SENNcorrection = [1.2, 1.2, 2.29, 3.72, 5.4, 5.04, 4.86, 5.5, 6.75, 8.94, 12.7, 12.95, 12.6, 9.2, 5.95, 4.26, 13.1]+3;
if ear == 0
    [~,ThreshSPL,vTK,vTKgain,TargetBOLT,vCR,TargetAvg,TargetLo,TargetHi] = readDSLfile(strcat(DSLdir,'\',sprintf('%s right.csv',lid)));
else
    [~,ThreshSPL,vTK,vTKgain,TargetBOLT,vCR,TargetAvg,TargetLo,TargetHi] = readDSLfile(strcat(DSLdir,'\',sprintf('%s left.csv',lid)));
end
[oct_freq,OCTthr] = GetThresh(0,ear,audiodir,sprintf('%s Audiogram',lid));
DSLoctThr = [ThreshSPL(2),ThreshSPL(5),ThreshSPL(8),ThreshSPL(11),ThreshSPL(14)];
err = 0;
for j = 1:5
    if OCTthr(j) ~= DSLoctThr(j)
        warndlg(sprintf('You entered %s in the DSL program instead of %s at %s Hz',num2str(DSLoctThr(j)),num2str(OCTthr(j)),num2str(oct_freq(j))),'ERROR');
        err = 1;
    end
end
if err == 1
    DSL = -99;
    return
end
minchannel = 1;
for j = 1:16
    if vTK(j)~=vTK(j+1), minchannel = minchannel+1;end
end

if Nchannel < minchannel
    warndlg(sprintf('The minimum # of channels for the selected file must be at least %s',num2str(minchannel)),'ERROR');
    return
end
TargetAvg(17) = TargetAvg(16)-thirdOCTthr(16)+thirdOCTthr(17);
if TargetAvg(17)-TargetAvg(16) > 10
    TargetAvg(17) = TargetAvg(16) + 10;
end
[Cross_freq, Select_channel] = HA_channelselect(cent_freq, Nchannel);
Select_channel = [0,Select_channel];
for n = 1:Nchannel
    TK(n) = mean(vTK(Select_channel(n)+1:Select_channel(n+1)));
    CR(n) = mean(vCR(Select_channel(n)+1:Select_channel(n+1)));
    BOLT(n) = mean(TargetBOLT(Select_channel(n)+1:Select_channel(n+1)));
    TKgain(n) = mean(vTKgain(Select_channel(n)+1:Select_channel(n+1)));
    adjBOLT(n) = BOLT(n)-(mean(SENNcorrection(Select_channel(n)+1:Select_channel(n+1))));
    vTargetAvg(n) = mean(TargetAvg(Select_channel(n)+1:Select_channel(n+1)));
    vSENNcorr(n) = mean(SENNcorrection(Select_channel(n)+1:Select_channel(n+1)));
end
rmsdB = 60;
maxdB = 119;
[x,Fs] = audioread('Carrots.wav');
minGain = zeros(size(vSENNcorr));%-vSENNcorr; changed April 16, 2016 by Marc Brennan
%minGain(1:round(Nchannel/4)) = minGain(1:round(Nchannel/4))-10*log10(Nchannel); % Correct for channel overlap
maxGain = 55;
if nargin > 7
    [I] = find(Cross_freq > rolloff);
    TKgain(I+1) = minGain(I+1);
    LastChannel = I(1);
    [J] = find(cent_freq > rolloff);
    vSENNcorr(LastChannel) = mean(SENNcorrection(Select_channel(n)+1:J(1)-1));
else
    LastChannel = Nchannel;
end

for k = 1:2
    y = WDRC(Cross_freq,x,Fs,rmsdB,maxdB,TKgain,CR,TK,adjBOLT,att,rel);
    avg_out =speechmap2(maxdB,y,Fs)+SENNcorrection;
    for n = 1:LastChannel
        vavg_out= mean(avg_out(Select_channel(n)+1:Select_channel(n+1)));
        diff = vTargetAvg(n) - vavg_out;
        TKgain(n) = TKgain(n)+diff;
        if TKgain(n) < minGain(n), TKgain(n) = minGain(n); end
        if TKgain(n) > maxGain, TKgain(n) = maxGain; end
    end
end
y = WDRC(Cross_freq,x,Fs,rmsdB,maxdB,TKgain,CR,TK,adjBOLT,att,rel);
T = round(0.128.*Fs);
t = 0:T;
tj = t./Fs;
parfor n = 1:length(cent_freq)
    MPOsignal = zeros(1,T);
    MPOsignal = sin(2*pi*cent_freq(n)*tj);
    w = WDRC(Cross_freq,MPOsignal',Fs,90,maxdB,TKgain,CR,TK,adjBOLT,att,rel);
    MPO(n) = SENNcorrection(n) + maxdB + 20*log10(rms2(w));
end
if nargin > 7
    banana = DSLspeechmap(maxdB,y,Fs,sprintf('%s (%s Hz Roll-off)',lid,num2str(rolloff)),ear,thirdOCTthr,TargetAvg,TargetBOLT,MPO,DSLdir,att,rel,Nchannel);
else
    banana = DSLspeechmap(maxdB,y,Fs,lid,ear,thirdOCTthr,TargetAvg,TargetBOLT,MPO,DSLdir,att,rel,Nchannel);
end
DSL.attack = att;
DSL.release = rel;
DSL.Nchannel = Nchannel;
DSL.Cross_freq = Cross_freq;
DSL.TKgain = TKgain;
DSL.CR = CR;
DSL.TK = TK;
DSL.BOLT = BOLT;
DSL.MPO = MPO;
DSL.TargetLo = TargetLo;
DSL.TargetAvg = TargetAvg;
DSL.TargetHi = TargetHi;
DSL.TargetBOLT = TargetBOLT;
DSL.Thresh = thirdOCTthr;
DSL.banana = banana;

function WDRCvisual(x,Fs,refdB,Proc,NFCstart,NFCratio,DSL,att,rel)
maxdB = 119;
if Fs ~= 22050
    figure = warndlg('The sampling rate needs to be 22.05 kHz.','SAMPLING RATE ERROR');
    uiwait(figure)
    HAsim3
end
switch Proc
    case 'EBW'
        z = FIRlowpass(x,22050,1024,10000);
    case 'RBW'
        z = FIRlowpass(x,22050,1024,5000);
    case 'NFC'
        startbin = round((NFCstart/(22050/128)));
        startfreq = startbin*(22050/128);
        maxIN = (26+startbin)*(22050/128);
        maxOut= (startfreq^(1-(1/NFCratio)))*(maxIN^(1/NFCratio));
        w = FreqComp(x,Fs,NFCstart,NFCratio,26);
        z = FIRlowpass(w,22050,1024,maxOut);
        I = find(DSL.Cross_freq > maxOut);
        DSL.TKgain(I+1) = 0;
end
[~,y,~,x_dB,pdB,gdB,gdBnominal,BOLT,pBOLT,OCLcnt] = WDRC_diagnostics(DSL.Cross_freq,z,Fs,refdB,maxdB,DSL.TKgain,DSL.CR,DSL.TK,DSL.BOLT,att,rel);
in = 0:120;
DSL.TK(end+1) = BOLT(end);
DSL.TKgain(end+1) = 0;
for c = 1:length(DSL.TKgain)
    if c < length(DSL.TKgain)
        if DSL.TK(c)+DSL.TKgain(c) > BOLT(c)
            TK(c) = BOLT(c)-DSL.TKgain(c)-0.5;
        else
            TK(c) = DSL.TK(c);
        end
        newfigure(num2str(c));
    else
        TK(c) = DSL.TK(c);
        newfigure(99);
    end
    axes('Parent',gcf,'PlotBoxAspectRatio',[1 1 1],'FontSize',20);
    hold on
    plot(x_dB(89:end-88,c),x_dB(89:end-88,c)+gdB(89:end-88,c),'r.')
    plot(0:120,gdBnominal(:,c)+in','k','LineWidth',2)
    axis([0 120 0 120])
    plot(floor(TK(c))+0.5,((DSL.TKgain(c)))+in(ceil(TK(c)))+0.5,'ko','MarkerSize',12);
    text(TK(c)-2,gdBnominal(round(TK(c)),c)+in(round(TK(c))+4),'TK','FontSize',16)
    plot(pBOLT(c),BOLT(c),'k*','MarkerSize',12)
    text(pBOLT(c)-3.5,BOLT(c)+3,'BOLT','FontSize',16)
    text(pBOLT(c),BOLT(c)-5,strcat(num2str(round2(OCLcnt(c)*100,1)),'% in OCL'),'FontSize',16)
    axis square
    xlabel('Input, dB SPL','FontWeight','bold','FontSize',24);
    ylabel('Output, dB SPL','FontWeight','bold','FontSize',24);
    if c < length(DSL.TKgain)
        title(sprintf('Channel %s',num2str(c)),'FontSize',28,'FontWeight','bold');
    else
        title(sprintf('Broadband OCL'),'FontSize',28,'FontWeight','bold');
    end
    if c < length(DSL.TKgain)
        newfigure2(num2str(c));
    else
        newfigure2(99);
    end
    subplot(5,1,1),plot(1/Fs:1/Fs:(length(x_dB)-176)/Fs,y(89:end-88,c));
    title('Input','FontSize',12,'FontWeight','bold')
    axis([0 (length(x_dB)-176)/Fs -(exp(ceil(log(max(abs(y(89:end-88,c))))))) (exp(ceil(log(max(abs(y(89:end-88,c)))))))])
    
    subplot(5,1,2),plot(1/Fs:1/Fs:(length(x_dB)-176)/Fs,pdB(89:end-88,c));
    title('Smoothed Envelope, dB SPL','FontSize',12,'FontWeight','bold')
    axis([0 (length(x_dB)-176)/Fs max([0,(5*(floor(min(pdB(200:end-88,c)/5))))]) (5*(ceil(max(pdB(200:end-88,c)/5))))])
    
    subplot(5,1,3),plot(1/Fs:1/Fs:(length(x_dB)-176)/Fs,gdB(89:end-88,c));
    title('Gain, dB','FontSize',12,'FontWeight','bold')
    if min(gdB) > max(gdB)
        axis([0 (length(x_dB)-176)/Fs max([0,(5*(floor(min(gdB(200:end-88,c)/5))))]) (5*(ceil(max(gdB(200:end-88,c)/5))))])
    else
        axis tight
    end
    subplot(5,1,4),plot(1/Fs:1/Fs:(length(x_dB)-176)/Fs,gdB(89:end-88,c)+pdB(89:end-88,c));
    title('Smoothed Envelope + Gain, dB SPL','FontSize',12,'FontWeight','bold')
    axis([0 (length(x_dB)-176)/Fs max([0,(5*(floor(min(gdB(200:end-88,c)+pdB(200:end-88,c))/5)))]) (5*(ceil(max(gdB(200:end-88,c)+pdB(200:end-88,c))/5)))])
    subplot(5,1,5),plot(1/Fs:1/Fs:(length(x_dB)-176)/Fs,y(89:end-88,c).*(10.^(gdB(89:end-88,c)./20)));
    title('Output, dB SPL','FontSize',12,'FontWeight','bold')
    xlabel('Time, s','FontSize',18,'FontWeight','bold','Color','red')
    axis([0 (length(x_dB)-176)/Fs -(exp(ceil(log(max(abs((y(89:end-88,c).*(10.^(gdB(89:end-88,c)./20))))))))) (exp(ceil(log(max(abs((y(89:end-88,c).*(10.^(gdB(89:end-88,c)./20)))))))))])
    if c < length(DSL.TKgain)
        annotation('textbox',[0.45 0.96 0.12 0.03],'String',{sprintf('Channel %s',num2str(c))},'FontWeight','bold','FontSize',22,'FitBoxToText','off','LineStyle','none','Color',[1 0 0]);
    else
        annotation('textbox',[0.45 0.96 0.12 0.03],'String',{'Broadband OCL'},'FontWeight','bold','FontSize',18,'FitBoxToText','off','LineStyle','none','Color',[1 0 0]);
    end
end