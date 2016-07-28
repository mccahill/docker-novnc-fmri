function EEGShow(eeg,bins,channels,grid,yRange,xRange,sortOrder)
%EEGShow Plot EEG data on multiple axes.
%
%       Plots channels from specified bins in nRows by nCols subplots.
%       Sets y-axis scale to [ymin ymax]=yRange.
%       Sets x-axis scale to [xmin xmax]=xRange.
%
%       There are several variants of the calling sequence:
%
%         EEGShow(eeg,bins,channels);
%         EEGShow(eeg,bins,channels,grid);
%         EEGShow(eeg,bins,channels,grid,yRange);
%         EEGShow(eeg,bins,channels,grid,yRange,xRange);
%         EEGShow(eeg,bins,channels,grid,yRange,xRange,sortOrder);
%
%       eeg is a structure with the following fields:
%         expName is the experiment name
%         expDate is the experiment date string
%         nBins is the number of bins.
%         nChannels is the number of data channels (electrodes).
%         nPoints is the number of data points collected per channel.
%         sampling is the sampling rate of the data points in ms/point.
%         uvunits is the microvolt conversion factor in raw data units/microvolt.
%         onset is the stimulus onset from the first data point in ms.
%         binNames is a cell array of bin names.
%         chanNames is a cell array of channel names.
%         coords is a matrix of electrode coordinates
%           with size [nChannels 2] or [nChannels 3].
%         data is the EEG data in a [nBins nChannels nPoints] matrix.
%         rawData is the raw EEG data in a [nBins nChannels nPoints] matrix when data has been filtered.
%       bins is a vector of bins to plot.
%       channels is a vector of relative channels to plot.
%       grid can be [nRows] or [nRows nCols] or [nRows nCols across].
%         nRows and nCols default to 1.  If there are more than nRows*nCols channels
%         to plot, rows are added as needed.
%         If across is present and non-zero, plot across rows, else plot down columns.
%       yRange can be [ymax] or [ymin ymax].  ymin defaults to -ymax.
%         If yRange is [] or omitted, auto-scaling is used.
%       xRange must be [xmin xmax].
%         If xRange is [] or omitted, all points are used.
%       sortOrder is 'numeric', 'alphabetic',
%         or a row vector with 1:nChannels in the desired order.
%         Default is 'numeric'

% CVS ID and authorship of this code
% CVSId = '$Id: EEGShow.m,v 1.3 2005/02/03 16:58:19 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:19 $';
% CVSRCSFile = '$RCSfile: EEGShow.m,v $';

% Defaults
if nargin<4, grid=[]; end
if nargin<5, yRange=[]; end
if nargin<6, xRange=[]; end
if nargin<7, sortOrder='numeric'; end
if isempty(grid), grid=[1 1 0]; end
if length(grid)==1, grid=[grid 1 0]; end
if length(grid)==2, grid=[grid 0]; end
if isempty(xRange), xRange='full'; end
if isempty(yRange)
  yRange='auto';
elseif length(yRange)==1
  yRange=[-yRange yRange];
end

% binColors fields: Color LineStyle LineWidth Marker MarkerSize
binColors(1)=struct('Color',[1   0    0],'LineStyle','-','LineWidth',0.5,'Marker','none','MarkerSize',3);   % red solid
binColors(2)=struct('Color',[0   1    0],'LineStyle','-','LineWidth',0.5,'Marker','none','MarkerSize',3);   % green solid
binColors(3)=struct('Color',[1   0    1],'LineStyle','-','LineWidth',0.5,'Marker','none','MarkerSize',3);   % magenta solid
binColors(4)=struct('Color',[0   1    1],'LineStyle','-','LineWidth',0.5,'Marker','none','MarkerSize',3);   % cyan solid
binColors(5)=struct('Color',[1   0.5  0],'LineStyle','-','LineWidth',0.5,'Marker','none','MarkerSize',3);   % orange solid
binColors(6)=struct('Color',[0   0.25 1],'LineStyle','-','LineWidth',0.5,'Marker','none','MarkerSize',3);   % blue solid
binColors(7)=struct('Color',[0.5 0    0],'LineStyle','-','LineWidth',0.5,'Marker','none','MarkerSize',3);   % dark red solid
binColors(8)=struct('Color',[0.5 0    1],'LineStyle','-','LineWidth',0.5,'Marker','none','MarkerSize',3);   % purple solid
binColors(9)=struct('Color',[0.5 0.5  0],'LineStyle','-','LineWidth',0.5,'Marker','none','MarkerSize',3);   % olive green solid
binColors(10)=struct('Color',[1   1    1],'LineStyle','-','LineWidth',0.5,'Marker','none','MarkerSize',3);  % white solid
binColors(11)=struct('Color',[1   0    0],'LineStyle',':','LineWidth',0.5,'Marker','none','MarkerSize',3);  % red dotted
binColors(12)=struct('Color',[0   1    0],'LineStyle',':','LineWidth',0.5,'Marker','none','MarkerSize',3);  % green dotted
binColors(13)=struct('Color',[1   0    1],'LineStyle',':','LineWidth',0.5,'Marker','none','MarkerSize',3);  % magenta dotted
binColors(14)=struct('Color',[0   1    1],'LineStyle',':','LineWidth',0.5,'Marker','none','MarkerSize',3);  % cyan dotted
binColors(15)=struct('Color',[1   0.5  0],'LineStyle',':','LineWidth',0.5,'Marker','none','MarkerSize',3);  % orange dotted
binColors(16)=struct('Color',[0   0.25 1],'LineStyle',':','LineWidth',0.5,'Marker','none','MarkerSize',3);  % blue dotted
binColors(17)=struct('Color',[0.5 0    0],'LineStyle',':','LineWidth',0.5,'Marker','none','MarkerSize',3);  % dark red dotted
binColors(18)=struct('Color',[0.5 0    1],'LineStyle',':','LineWidth',0.5,'Marker','none','MarkerSize',3);  % purple dotted
binColors(19)=struct('Color',[0.5 0.5  0],'LineStyle',':','LineWidth',0.5,'Marker','none','MarkerSize',3);  % olive green dotted
binColors(20)=struct('Color',[1   1    1],'LineStyle',':','LineWidth',0.5,'Marker','none','MarkerSize',3);  % white dotted

% Make sure we have room for all channels by adding extra rows if needed.
nRows=grid(1); nCols=grid(2); across=grid(3);
if nRows*nCols<length(channels)
  nRows=ceil(length(channels)/nCols);
  grid(1)=nRows;
end

% Store EEG info
set(gcf,'Tag','EEGFig','UserData',struct('eeg',eeg,'raw',[],'plots',[],'grid',grid,'binColors',binColors));

% Add Format menu
formatMenu=uimenu('Label','For&mat','Tag','formatMenu');
uimenu(formatMenu,'Label','Axis','Tag','axisFormat','Checked','On',...
       'Callback','EEGFmt(''a'');');
uimenu(formatMenu,'Label','Box','Tag','boxFormat',...
       'Callback','EEGFmt(''o'');');
uimenu(formatMenu,'Label','Channel Names','Tag','nameFormat','Checked','On',...
       'Callback','EEGFmt(''n'');');
uimenu(formatMenu,'Label','Channel Numbers','Tag','numberFormat',...
       'Callback','EEGFmt(''u'');');
uimenu(formatMenu,'Label','Horizontal Gridlines','Tag','hGridFormat','Separator','on',...
       'Callback','EEGFmt(''h'');');
uimenu(formatMenu,'Label','Vertical Gridlines','Tag','vGridFormat',...
       'Callback','EEGFmt(''v'');');
uimenu(formatMenu,'Label','Both Gridlines','Tag','bGridFormat',...
       'Callback','EEGFmt(''b'');');
uimenu(formatMenu,'Label','Baseline','Tag','baseFormat','Separator','on',...
       'Callback','EEGFmt(''y0'');');
uimenu(formatMenu,'Label','Task Line','Tag','taskFormat',...
       'Callback','EEGFmt(''x0'');');
uimenu(formatMenu,'Label','Zoom','Accelerator','Z','Separator','on',...
       'Tag','Zoom Menu','CallBack','EEGZoom;');
uimenu(formatMenu,'Label','Redraw','Accelerator','R',...
       'Callback','refresh;');

% Add Grid menu
gridMenu=uimenu('Label','&Grid','Tag','gridMenu');
itemStr=[num2str(grid(1)) ' x ' num2str(grid(2))];
callStr=['EEGGrid(' mat2str(grid) ');'];
prevGrid=uimenu(gridMenu,'Label',itemStr,'Accelerator','G','Callback',callStr);
for g=1:8
  itemStr=[num2str(g) ' x ' num2str(g)];
  callStr=['EEGGrid(' mat2str([g g grid(3)]) ');'];
  gridMenuItems(2*g-1)=uimenu(gridMenu,'Label',itemStr,'Callback',callStr);
  itemStr=[num2str(g+1) ' x ' num2str(g)];
  callStr=['EEGGrid(' mat2str([g+1 g grid(3)]) ');'];
  gridMenuItems(2*g)=uimenu(gridMenu,'Label',itemStr,'Callback',callStr);
end
gridMenuItems(end+1)=prevGrid;
gridMenuItems(end+1)=uimenu(gridMenu,'Label','Current','Enable','off');
set(gridMenuItems(1),'Separator','on');
set(gridMenu,'UserData',gridMenuItems);
uimenu(gridMenu,'Label','Custom...','Separator','on','Callback','EEGGrid(''custom'');');

% Add Bins menu
binMenu=uimenu('Label','&Bins','Tag','binMenu');
uimenu(binMenu,'Label','All Bins','Accelerator','A',...
               'Callback',['EEGBin(1:' num2str(eeg.nBins) ',''on'');']);
uimenu(binMenu,'Label','No Bins','Accelerator','N',...
               'Callback',['EEGBin(1:' num2str(eeg.nBins) ',''off'');']);
uimenu(binMenu,'Label','Invert Bins','Accelerator','I',...
               'Callback',['EEGBin(1:' num2str(eeg.nBins) ',''invert'');']);
for b=1:eeg.nBins
  binMenuItems(b)=uimenu(binMenu,'Label',eeg.binNames{b},'Tag','binMenuItem','UserData',b,...
                         'Callback',['EEGBin(' num2str(b) ');']);
  if b<=10
    set(binMenuItems(b),'Accelerator',char('0'+mod(b,10)));
  end
end
set(binMenuItems(1),'Separator','on');
set(binMenuItems(bins),'Checked','on');
set(binMenu,'UserData',binMenuItems);

% Add Channels menu
%chanMenu=uimenu('Label','&Channels','Tag','chanMenu');

% Add Sort menu
sortMenu=uimenu('Label','&Sort','Tag','sortMenu');
uimenu(sortMenu,'Label','Alphabetic','Tag','sortMenuItem',...
       'Callback','EEGSort(''alphabetic'',1);');
uimenu(sortMenu,'Label','Numeric','Tag','sortMenuItem',...
       'Callback','EEGSort(''numeric'',1);');
EEGSort(sortOrder);

% Fill Channels menu
%mappedChans=chanMap(1:eeg.nChannels);
%for c=1:eeg.nChannels
%  chanMenuItems(c)=uimenu(chanMenu,'Label',eeg.chanNames{c},'Tag','chanMenuItem',...
%                          'UserData',mappedChans(c),'CallBack',['EEGChan(' num2str(c) ');']);
%end
%set(chanMenu,'UserData',chanMenuItems);

% Get figure size
figPos=get(gcf,'Position');
figWidth=figPos(3);
figHeight=figPos(4);

% Other control's info
bottom=6;
top=10;
height=17;
right=10;

% Add Filter controls
uicontrol('Style','Push','Tag','Raw Button','String','Raw',...
          'Units','Pixels','Position',[10 figHeight-height-top 30 height+1],...
          'FontName','Arial Narrow','FontSize',8,...
          'CallBack','EEGRaw; figure(gcf);');

uicontrol('Style','Push','Tag','MovAvg Button','String','MovAvg',...
          'Units','Pixels','Position',[50 figHeight-height-top 40 height+1],...
          'FontName','Arial Narrow','FontSize',8,...
          'CallBack',...
          ['EEGFilt(''movavg'',str2num(get(findobj(gcf,''Tag'',''MovAvg Size''),''String'')),3);',...
           'figure(gcf);']);
uicontrol('Style','Edit','Tag','MovAvg Size','String','3',...
          'Units','Pixels','Position',[95 figHeight-height-top+1 25 height],...
          'FontName','Arial Narrow','FontSize',8,...
          'CallBack','figure(gcf);');
        
uicontrol('Style','Push','Tag','Smooth Button','String','Smooth',...
          'Units','Pixels','Position',[130 figHeight-height-top 40 height+1],...
          'FontName','Arial Narrow','FontSize',8,...
          'CallBack',...
          ['EEGFilt(''EEGSmooth'');',...
           'figure(gcf);']);
        
% Add "Topo" button
uicontrol('Style','Push','Tag','Topo Button','String','Topo',...
          'Units','Pixels','Position',[figWidth-35-right figHeight-height-top 35 height+1],...
          'FontName','Arial Narrow','FontSize',8,...
          'CallBack','EEGTopo; figure(gcf);');

% Add "Crosshairs" checkbox
uicontrol('Style','Checkbox','Tag','Crosshairs Checkbox','String','Crosshairs',...
          'Units','Pixels','Position',[20 bottom 65 height],...
          'FontName','Arial Narrow','FontSize',8,...
          'CallBack','xHairs;');

% Add channel PopUp menu
uicontrol('Style','Text','String','Channel:',...
          'Units','Pixels','Position',[100 bottom 40 height-1],...
          'FontName','Arial Narrow','FontSize',8);
uicontrol('Style','PopUpMenu','Tag','showChannel',...
          'String',eeg.chanNames,'Value',channels(1),...
          'Units','Pixels','Position',[145 bottom+5 60 height-3],...
          'FontName','Arial Narrow','FontSize',8,...
          'CallBack','EEGChan;');

% Add grid text boxes
uicontrol('Style','Text','String','Grid',...
          'Units','Pixels','Position',[215 bottom 21 height-1],...
          'FontName','Arial Narrow','FontSize',8);
uicontrol('Style','Edit','Tag','gridRows','String','',...
          'Units','Pixels','Position',[241 bottom 17 height],...
          'FontName','Arial Narrow','FontSize',8,...
          'CallBack','EEGGrid;');
uicontrol('Style','Edit','Tag','gridCols','String','',...
          'Units','Pixels','Position',[263 bottom 17 height],...
          'FontName','Arial Narrow','FontSize',8,...
          'CallBack','EEGGrid;');

% Add "FullX" button
uicontrol('Style','Push','Tag','FullX Button','String','FullX',...
          'Units','Pixels','Position',[290 bottom-1 30 height+1],...
          'FontName','Arial Narrow','FontSize',8,...
          'CallBack','EEGScale(''full'');');

% Add x-axis-scaling text boxes
uicontrol('Style','Text','String','X Range:',...
          'Units','Pixels','Position',[325 bottom 45 height-1],...
          'FontName','Arial Narrow','FontSize',8);
uicontrol('Style','Edit','Tag','XMin','String','',...
          'Units','Pixels','Position',[375 bottom 35 height],...
          'FontName','Arial Narrow','FontSize',8,...
          'CallBack','EEGScale;');
uicontrol('Style','Edit','Tag','XMax','String','',...
          'Units','Pixels','Position',[415 bottom 35 height],...
          'FontName','Arial Narrow','FontSize',8,...
          'CallBack','EEGScale;');

% Add "AutoY" button
uicontrol('Style','Push','Tag','AutoY Button','String','AutoY',...
          'Units','Pixels','Position',[460 bottom-1 30 height+1],...
          'FontName','Arial Narrow','FontSize',8,...
          'CallBack','EEGScale(''auto'');');

% Add y-axis-scaling text boxes
uicontrol('Style','Text','String','Y Range:',...
          'Units','Pixels','Position',[495 bottom 45 height-1],...
          'FontName','Arial Narrow','FontSize',8);
uicontrol('Style','Edit','Tag','YMin','String','',...
          'Units','Pixels','Position',[545 bottom 35 height],...
          'FontName','Arial Narrow','FontSize',8,...
          'CallBack','EEGScale;');
uicontrol('Style','Edit','Tag','YMax','String','',...
          'Units','Pixels','Position',[585 bottom 35 height],...
          'FontName','Arial Narrow','FontSize',8,...
          'CallBack','EEGScale;');

% Add "Zoom" button
uicontrol('Style','Push','Tag','Zoom Button','String','Zoom',...
          'Units','Pixels','Position',[630 bottom-1 30 height+1],...
          'FontName','Arial Narrow','FontSize',8,...
          'CallBack','EEGZoom;');

% Add "PgUp" button
uicontrol('Style','Push','Tag','PgUp Button','String','PgUp',...
          'Units','Pixels','Position',[670 bottom-1 30 height+1],...
          'FontName','Arial Narrow','FontSize',8,...
          'CallBack','EEGPage(''up'');');

% Add "PgDn" button
uicontrol('Style','Push','Tag','PgDn Button','String','PgDn',...
          'Units','Pixels','Position',[705 bottom-1 30 height+1],...
          'FontName','Arial Narrow','FontSize',8,...
          'CallBack','EEGPage(''down'');');

% Add "Redraw" button
uicontrol('Style','Push','Tag','Redraw Button','String','Redraw',...
          'Units','Pixels','Position',[745 bottom-1 40 height+1],...
          'FontName','Arial Narrow','FontSize',8,...
          'CallBack','refresh; figure(gcf);');

% Plot data
set(gcf,'name',eeg.expName);
set(gcf,'Pointer','watch'); drawnow;
channels=chanMap(channels);
EEGPlot(bins,channels,xRange,yRange,grid);
EEGTweak;
set(gcf,'Pointer','arrow');

% Modification History:
%
% $Log: EEGShow.m,v $
% Revision 1.3  2005/02/03 16:58:19  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:33  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/10/08 23:46:45  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Francis Favorini, 10/01/96.
% Francis Favorini, 10/22/96.  Modified to use EEGPlot.
% Francis Favorini, 10/23/96.  Modified to use chanMap.  Added Sort menu.
% Francis Favorini, 10/31/96.  Added custom grid layout.
% Francis Favorini, 11/14/96.  Added Baseline and Task Line to Format menu.
% Francis Favorini, 12/09/96.  Added sortOrder parameter.  Used by EEGZoom.
%                              EEGSort now defaults to not updating the display.
% Francis Favorini, 01/29/97.  MATLAB 5 compliance.
% Francis Favorini, 02/05/97.  Changed binColors to a structure.
% Francis Favorini, 02/12/97.  Added 'EEGFig' tag to figure.
% Francis Favorini, 02/20/97.  Handles electrode coords in header file.
% Francis Favorini, 03/14/97.  Changed Redraw button to use MATLAB 5.0's refresh.
% Francis Favorini, 03/17/97.  Changed some of the uicontrol positions.
% Francis Favorini, 07/02/97.  Changed to use eeg structure.
% Francis Favorini, 07/04/97.  Added Channel Names/Numbers to Format menu.
% Francis Favorini, 07/08/97.  Added previous/current grid to Grid menu.
%                              Added accelerators to menus.
%                              Added Redraw to Format menu.
% Francis Favorini, 07/22/97.  Changed call to EEGFilt.
% Francis Favorini, 07/24/97.  Changed button layout.
% Francis Favorini, 08/26/97.  Added Zoom to Format menu.
