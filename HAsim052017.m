function HAsim052017
[protocolFileName, pathname] = uigetfile('*.mat*', 'Select Protocol');
if ~pathname
    return
end
load([pathname, protocolFileName]);
answer = inputdlg('Enter Subject ID');
listenerID = answer{1};
main = menu4( ...
    'WHAT DO YOU WANT TO DO?', ...
    'Enter Audiometric Thresholds', ...
    'Run DSLv5.0', ...
    'Generate Prescription');
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
                DSL = WDRC_Tune(att, rel, Nchannel, listenerID, 0, DSLdir, audiodir); %#ok
                save([DSLdir, filesep(), listenerID, ' right DSL'], 'DSL');
                saveas(gcf, [DSLdir, filesep(), listenerID, ' right Speechmap'], 'fig');
            end
            if sameL
                DSL = WDRC_Tune(att,rel,Nchannel,listenerID,1,DSLdir,audiodir); %#ok
                save([DSLdir, filesep(), listenerID, ' left DSL'], 'DSL');
                saveas(gcf, [DSLdir, filesep(), listenerID, ' left Speechmap'], 'fig');
            end
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
mainFigure = figure( ...
    'units', 'normalized', ...
    'Position', [0, 0, 1, 1]);
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
annotation(mainFigure,'textbox','String',{'Right TDH (o)'},...
    'HorizontalAlignment','center',...
    'FontWeight','bold',...
    'FontSize',14,...
    'FontName','Arial',...
    'LineWidth',1,...
    'BackgroundColor',[1 1 1],...
    'Position',[0.83 0.79 0.17 0.07],...
    'Color',[1 0 0 ]);
annotation(mainFigure,'textbox','String',{'Left TDH (x)'},...
    'HorizontalAlignment','center',...
    'FontWeight','bold',...
    'FontSize',14,...
    'FontName','Arial',...
    'LineWidth',1,...
    'BackgroundColor',[1 1 1],...
    'Position',[0.83 0.728 0.17 0.07],...
    'Color',[0 0 1]);
annotation(mainFigure,'textbox','String',{'Right Insert (\bullet)'},...
    'HorizontalAlignment','center',...
    'FontWeight','bold',...
    'FontSize',14,...
    'FontName','Arial',...
    'LineWidth',1,...
    'BackgroundColor',[1 1 1],...
    'Position',[0.83 0.666 0.17 0.07],...
    'Color',[1 0 0 ]);
annotation(mainFigure,'textbox','String',{'Left Insert (*)'},...
    'HorizontalAlignment','center',...
    'FontWeight','bold',...
    'FontSize',14,...
    'FontName','Arial',...
    'LineWidth',1,...
    'BackgroundColor',[1 1 1],...
    'Position',[0.83 0.604 0.17 0.07],...
    'Color',[0 0 1]);
annotation(mainFigure,'textbox','String',{'Right Bone ([)'},...
    'HorizontalAlignment','center',...
    'FontWeight','bold',...
    'FontSize',14,...
    'FontName','Arial',...
    'LineWidth',1,...
    'BackgroundColor',[1 1 1],...
    'Position',[0.83 0.542 0.17 0.07],...
    'Color',[1 0 0 ]);
annotation(mainFigure,'textbox','String',{'Left Bone (])'},...
    'HorizontalAlignment','center',...
    'FontWeight','bold',...
    'FontSize',14,...
    'FontName','Arial',...
    'LineWidth',1,...
    'BackgroundColor',[1 1 1],...
    'Position',[0.83 0.48 0.17 0.07],...
    'Color',[0 0 1]);
annotation(mainFigure,'textbox','String',{'Bone Unmasked (\^)'},...
    'HorizontalAlignment','center',...
    'FontWeight','bold',...
    'FontSize',12,...
    'FontName','Arial',...
    'LineWidth',1,...
    'BackgroundColor',[1 1 1],...
    'Position',[0.83 0.418 0.17 0.07]);
annotation(mainFigure,'textbox','String',{'Done'},...
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
    %redraw_audiogram(HL, 0);
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
                        h1 = line(x-0.08,y, 'marker', 'o', 'color', 'r');
                        set(h1,'MarkerSize',12,'MarkerFaceColor','white','LineWidth',2);
                        HL.Rtdh(F) = y;
                    end
                else
                    if button == 3, HL.Rtdh(F) = -99;
                        %redraw_audiogram(HL,done)
                    elseif y == HL.Rtdh(F)
                    else
                        HL.Rtdh(F) = y;
                        %redraw_audiogram(HL,done)
                    end
                end
            case 2
                if HL.Ltdh(F) < -10
                    if y >= -10
                        h1 = line(x+0.08,y, 'marker', 'x', 'color', 'b');
                        set(h1,'MarkerSize',17,'MarkerFaceColor','white','LineWidth',2);
                        HL.Ltdh(F) = y;
                    end
                else
                    if button == 3, HL.Ltdh(F) = -99;
                        %redraw_audiogram(HL,done)
                    elseif y == HL.Ltdh(F)
                    else
                        HL.Ltdh(F) = y;
                        %redraw_audiogram(HL,done)
                    end
                end
            case 3
                if HL.Rins(F) < -10
                    if y >= -10
                        h1 = line(x-0.12,y+0.35, 'marker', 'o', 'color', 'r');
                        set(h1,'MarkerSize',8,'MarkerFaceColor','red','LineWidth',2);
                        HL.Rins(F) = y;
                    end
                else
                    if button == 3, HL.Rins(F) = -99;
                        %redraw_audiogram(HL,done)
                    elseif y == HL.Rins(F)
                    else
                        HL.Rins(F) = y;
                        %redraw_audiogram(HL,done)
                    end
                end
            case 4
                if HL.Lins(F) < -10
                    if y >= -10
                        h1 = line(x+0.12,y+0.35, 'marker', '*', 'color', 'b');
                        set(h1,'MarkerSize',8,'MarkerFaceColor','blue','LineWidth',2);
                        HL.Lins(F) = y;
                    end
                else
                    if button == 3, HL.Lins(F) = -99;
                        %redraw_audiogram(HL,done)
                    elseif y == HL.Lins(F)
                    else
                        HL.Lins(F) = y;
                        %redraw_audiogram(HL,done)
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
                        %redraw_audiogram(HL,done)
                    elseif y == HL.Rbc(F)
                    else
                        HL.Rbc(F) = y;
                        %redraw_audiogram(HL,done)
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
                        %redraw_audiogram(HL,done)
                    elseif y == HL.Lbc(F)
                    else
                        HL.Lbc(F) = y;
                        %redraw_audiogram(HL,done)
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
                        %redraw_audiogram(HL,done)
                    elseif y == HL.Ubc(F)
                    else
                        HL.Ubc(F) = y;
                        %redraw_audiogram(HL,done)
                    end
                end
        end
    end
end
proceed = menu3('Save Audiogram?','YES','NO');
if proceed == 1
    %redraw_audiogram(HL,done)
    if nargin == 0, [file, pathname] = uiputfile('*.pdf', 'Save As'); listenerID = file(1:end-4); end
    title(sprintf('Audiogram for %s (%s)',char(listenerID),char(testdate)));
    orient landscape
    saveas(gcf, [pathname, listenerID, ' Audiogram ', testdate], 'pdf');
    if nargin > 2
        saveas(gcf, [altdir, listenerID, ' Audiogram ', testdate], 'pdf');
    end
    if nargin > 3
        saveas(gcf, [altdir2, listenerID, ' Audiogram ', testdate], 'pdf');
    end
end

function [frequency,thrCorr] = GetThresh(thrType,ear,audiodir,filename)
if nargin < 2
    ear = menu2('Select Test Ear','RIGHT','LEFT')-1;
end
if nargin == 3
    cd(audiodir);
end
if nargin < 4
    [filename, audiodir] = uigetfile('*.mat', 'Select Data File');
    if ~audiodir
        return
    end
end

load([audiodir, filesep(), filename]);
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
thr = zeros(1, length(thr1));
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

function y = HA_fbank2(Cross_freq, x, Fs)  % 17 freq. bands
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
xPos = ( uiBorder + (0:numCols-1)'*( btnWide + uiGap )*ones(1,numRows) )';
xPos = xPos(1:numItems); % [ all 1st col; all 2nd col; ...; all nth col ]
yPos = ( uiBorder + (numRows-1:-1:0)'*( btnHigh + uiGap )*ones(1,numCols) );
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

function y = round2(x,dec)
y = (round(x.*(10.^dec)))./(10.^dec);

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
banana = zeros(1, nF);
for n = 1:nF
    banana(n) = maxdB+10*log10((mean(P(:,n))));
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
[in_c,~] = WDRC_Circuit(x,0,in_pdB,CL_TK,CL_CR,CL_TK);
if Nchannel > 1
    [y] = HA_fbank2(Cross_freq,in_c,Fs);    % Nchannel FIR filter bank
else
    y = in_c;
end
nsamp = size(y,1);
pdB = zeros(nsamp, Nchannel);
for n = 1:Nchannel
    if BOLT(n) > CL_TK, BOLT(n) = CL_TK; end
    if TKgain(n) < 0, BOLT(n) = BOLT(n) + TKgain(n); end
    peak = Smooth_ENV(y(:,n),att,rel,Fs);
    pdB(:,n) = maxdB+20.*log10(peak);
    [c(:,n), ~]=WDRC_Circuit(y(:,n),TKgain(n),pdB(:,n),TK(n),CR(n),BOLT(n));
end
comp=sum(c,2);
out_peak = Smooth_ENV(comp,1,50,Fs);
out_pdB = maxdB + 20.*log10(out_peak);
[out_c,~] = WDRC_Circuit(comp,0,out_pdB,CL_TK,CL_CR,CL_TK);
y = out_c(89:end-88);

function [comp,gdB] = WDRC_Circuit(x,TKgain,pdB,TK,CR,BOLT)
nsamp=length(x);
if TK+TKgain > BOLT, TK = BOLT-TKgain; end
TKgain_origin = TKgain + (TK.*(1-1./CR));
gdB = zeros(nsamp,1);
pBOLT = CR*(BOLT - TKgain_origin);
for n=1:nsamp
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

function DSL = WDRC_Tune(att,rel,Nchannel,lid,ear,DSLdir,audiodir,rolloff)
if ear == 0
    [~,ThreshSPL,vTK,vTKgain,TargetBOLT,vCR,TargetAvg,~,~] = readDSLfile(strcat(DSLdir,'\',sprintf('%s right.csv',lid)));
else
    [~,ThreshSPL,vTK,vTKgain,TargetBOLT,vCR,TargetAvg,~,~] = readDSLfile(strcat(DSLdir,'\',sprintf('%s left.csv',lid)));
end
[oct_freq,OCTthr] = GetThresh(0,ear,audiodir,sprintf('%s Audiogram',lid));
DSLoctThr = ThreshSPL(ThreshSPL ~= 0);
for j = 1:numel(DSLoctThr)
    if OCTthr(j) ~= DSLoctThr(j)
        warndlg(sprintf('You entered %s in the DSL program instead of %s at %s Hz',num2str(DSLoctThr(j)),num2str(OCTthr(j)),num2str(oct_freq(j))),'ERROR');
        DSL = -99;
        return
    end
end
minchannel = 1;
for j = 1:numel(vTK)-1
    if vTK(j)~=vTK(j+1), minchannel = minchannel+1;end
end
if Nchannel < minchannel
    warndlg(sprintf('The minimum # of channels for the selected file must be at least %s',num2str(minchannel)),'ERROR');
    return
end
[cent_freq,thirdOCTthr] = GetThresh(3,ear,audiodir,sprintf('%s Audiogram',lid));
TargetAvg(end) = TargetAvg(end-1)-thirdOCTthr(end-1)+thirdOCTthr(end);
if TargetAvg(end)-TargetAvg(end-1) > 10
    TargetAvg(end) = TargetAvg(end-1) + 10;
end
[Cross_freq, Select_channel] = HA_channelselect(cent_freq, Nchannel);
Select_channel = [0,Select_channel];
TK = zeros(1, Nchannel);
CR = zeros(1, Nchannel);
BOLT = zeros(1, Nchannel);
TKgain = zeros(1, Nchannel);
adjBOLT = zeros(1, Nchannel);
vTargetAvg = zeros(1, Nchannel);
vSENNcorr = zeros(1, Nchannel);
SENNcorrection = [1.2, 1.2, 2.29, 3.72, 5.4, 5.04, 4.86, 5.5, 6.75, 8.94, 12.7, 12.95, 12.6, 9.2, 5.95, 4.26, 13.1]+3;
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
    I = find(Cross_freq > rolloff);
    TKgain(I+1) = minGain(I+1);
    LastChannel = I(1);
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
DSL.attack = att;
DSL.release = rel;
DSL.Nchannel = Nchannel;
DSL.Cross_freq = Cross_freq;
DSL.TKgain = TKgain;
DSL.CR = CR;
DSL.TK = TK;
DSL.BOLT = BOLT;