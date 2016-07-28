function EEGPlot(bins,channels,xRange,yRange,grid,updateXHairs)
%EEGPlot Plots the specified EEG channels and bins on current figure.
%
%       EEGPlot();
%       EEGPlot(bins,channels);
%       EEGPlot(bins,channels,xRange);
%       EEGPlot(bins,channels,xRange,yRange);
%       EEGPlot(bins,channels,xRange,yRange,grid);
%       EEGPlot(bins,channels,xRange,yRange,grid,updateXHairs);
%
%       bins is the bins to plot.  If empty, scaling will still take place.
%       channels is the channels to plot.
%       xRange is the optional scaling range for the x-axis.  'full' means use full scale.
%       yRange is the optional scaling range for the y-axis.  'auto' means auto scale.
%       grid is the optional new grid to use.
%       updateXHairs says whether to update crosshairs or not.  Default is yes.
%
%       With no arguments, EEGPlot just redisplays the current data.

% CVS ID and authorship of this code
% CVSId = '$Id: EEGPlot.m,v 1.4 2005/02/03 20:17:40 michelich Exp $';
% CVSRevision = '$Revision: 1.4 $';
% CVSDate = '$Date: 2005/02/03 20:17:40 $';
% CVSRCSFile = '$RCSfile: EEGPlot.m,v $';

% Defaults
ymin=Inf;
ymax=-Inf;
updateLegend=0;
updateGrid=0;
gridFileName='';
if nargin<3, xRange=[]; end
if nargin<4, yRange=[]; end
if nargin<5, grid=[]; end
if nargin<6, updateXHairs=1; end
if isempty(grid)
  % Use existing grid
  grid=getfield(get(gcf,'UserData'),'grid');
else
  % Create new grid
  if ~iscell(grid)
    EEGSub(grid(1),grid(2));
  else
    gridFileName=grid{1};                     % File name is added to Grid menu
    grid=grid{2};                             % Custom positions
    EEGSub(grid);
    grid=[length(grid) 1 0];
  end
  updateGrid=1;
end

% Find EEG info
eeg=getfield(get(gcf,'UserData'),'eeg');
plots=getfield(get(gcf,'UserData'),'plots');
binColors=getfield(get(gcf,'UserData'),'binColors');
nRows=grid(1);
nCols=grid(2);
across=grid(3);
if length(plots)>eeg.nChannels, plots=plots(1:eeg.nChannels); end

if nargin<1
  % Build channels and bins
  channels=[];
  bins=[];
  for c=plots
    channels=[channels get(c,'UserData')];
  end
  channels=chanSort(channels);
  for b=findobj(plots(1),'Tag','bin')'
    bins=[bins; get(b,'UserData')];
  end
  bins=sort(bins)';
end

% Convert time to ms
time=([0:eeg.nPoints-1]*eeg.sampling)-eeg.onset;
if ischar(xRange)
  xRange=[min(time) max(time)];           % Scale x-axis to full time range
end

% Get axis formatting
axisVisible=get(findobj(gcf,'Tag','axisFormat'),'Checked');
box=get(findobj(gcf,'Tag','boxFormat'),'Checked');
nameVisible=strcmp(get(findobj(gcf,'Tag','nameFormat'),'Checked'),'on');
numberVisible=strcmp(get(findobj(gcf,'Tag','numberFormat'),'Checked'),'on');
hGrid=get(findobj(gcf,'Tag','hGridFormat'),'Checked');
vGrid=get(findobj(gcf,'Tag','vGridFormat'),'Checked');
if strcmp(get(findobj(gcf,'Tag','bGridFormat'),'Checked'),'on')
  hGrid='on';
  vGrid='on';
end
taskLine=strcmp(get(findobj(gcf,'Tag','taskFormat'),'Checked'),'on');
baseLine=strcmp(get(findobj(gcf,'Tag','baseFormat'),'Checked'),'on');

p=0;
for c=channels
  % Select subplot, going across rows or down columns.
  p=p+1;
  if ~across, pp=p; else pp=ceil(p/nRows)+rem(p-1,nRows)*nCols; end
  axes(plots(pp));
  set(gca,'UserData',c,'Tag','EEG','Visible',axisVisible,'Box',box,...
      'xGrid',vGrid,'YGrid',hGrid);

  % Any bins already there?
  binHandles=findobj(gca,'Tag','bin');
  oldBins=[];
  for h=binHandles'
    oldBins=[oldBins; get(h,'UserData')];
  end

  % Plot each bin in a different color
  hold on
  for b=bins
    amplitude=squeeze(eeg.data(b,c,:)/eeg.uvunits);
    if isempty(oldBins)
      bi=[];
    else
      bi=find(b==oldBins);
    end
    if isempty(bi)                                  % Create new bin
      updateLegend=1;
      ci=rem(b-1,length(binColors))+1;
      h=plot(time,amplitude);
      set(h,'Tag','bin','UserData',b,'Color',binColors(ci).Color,...
            'LineStyle',binColors(ci).LineStyle,'LineWidth',binColors(ci).LineWidth,...
            'Marker',binColors(ci).Marker,'MarkerSize',binColors(ci).MarkerSize);
    else                                            % Update old bin
      h=binHandles(bi);
      set(h,'XData',time,'YData',amplitude);
    end
  end
  hold off

  % Scale axes
  if ~isempty(xRange)
    set(gca,'XLim',xRange,'XLimMode','Manual');   % Scale x-axis to specified range
  end
  if ischar(yRange)                                % Scale y-axis automatically
    for b=findobj(gca,'Tag','bin')'
      YData=get(b,'YData');
      ymin=min(ymin,min(YData));
      ymax=max(ymax,max(YData));
    end
  elseif ~isempty(yRange)
    set(gca,'YLim',yRange,'YLimMode','Manual');   % Scale y-axis to specified range
  end

  % Add base line
  if baseLine
    hold on
    plot(get(gca,'XLim'),[0 0],'Tag','y0','Color',get(gca,'YColor'),...
         'LineStyle',get(gca,'GridLineStyle'));
    hold off
  end

  % Adjust font
  vAlign='Bottom';
  fontsize=9;
  if nCols>4, fontsize=8; end
  if nRows>6 | nCols>6, fontsize=7; end
  if nRows>7 | nCols>7, fontsize=6; end
  set(gca,'FontName','Arial Narrow','FontSize',fontsize);
  if nCols>6, fontsize=fontsize+1; end
  if nCols>5, vAlign='Baseline'; end

  % Channel label
  h=findobj(gca,'Tag','chanLabel');
  label=chanLabel(c,eeg.chanNames{c},numberVisible,nameVisible);
  if isempty(h)                                 % Create new channel label
    text('String',label,'Tag','chanLabel',...
         'Units','Normalized','Position',[0.02 1.0],...
         'FontName','Arial Narrow','FontSize',fontsize,'Color','Red',...
         'HorizontalAlignment','Left','VerticalAlignment',vAlign);
  else                                          % Update old channel label
    set(h,'String',label);
  end
end

% Auto-scale y-axis
if ischar(yRange)
  if isinf(ymin) | isinf(ymax)          % No bins were found
    yRange=[];
  else
    range=ymax-ymin;
    if range>150, level=50;
    elseif range>30, level=10;
    elseif range>10, level=5;
    else level=1; end
    yRange=[floor(ymin/level)*level ceil(ymax/level)*level];
    set(findobj(gcf,'Tag','EEG'),'YLim',yRange,'YLimMode','manual');
  end
end

if taskLine
  for p=plots
    axes(p);
    hold on
    plot([0 0],get(gca,'YLim'),'Tag','x0','Color',get(gca,'XColor'),...
      'LineStyle',get(gca,'GridLineStyle'));
    hold off
  end
end

% Update legend
if updateLegend
  bins=[];
  for b=findobj(gca,'Tag','bin')'
    bins=[bins; get(b,'UserData')];
  end
  bins=sort(bins)';
  EEGLegnd(bins);
end

% Update crosshairs if on
if updateXHairs & get(findobj(gcf,'Tag','Crosshairs Checkbox'),'Value')
  xHairs('up');
end

% Update channel popup menu
rChan=find(channels(1)==chanMap(1:eeg.nChannels));            % Relative channel from actual
set(findobj(gcf,'Tag','showChannel'),'Value',rChan);
% Update Channels menu
%set(findobj(gcf,'Tag','chanMenuItem','Checked','on'),'Checked','Off');
%set(findobj(gcf,'Tag','chanMenuItem','UserData',channels(1)),'Checked','On');

% Update scaling edit controls
if ~isempty(xRange)
  set(findobj(gcf,'Tag','XMin'),'String',num2str(xRange(1)));
  set(findobj(gcf,'Tag','XMax'),'String',num2str(xRange(2)));
end
if ~isempty(yRange)
  set(findobj(gcf,'Tag','YMin'),'String',num2str(yRange(1)));
  set(findobj(gcf,'Tag','YMax'),'String',num2str(yRange(2)));
end

if updateGrid
  % Update EEG info
  set(gcf,'UserData',setfield(get(gcf,'UserData'),'grid',grid));

  % Update grid edit controls
  set(findobj(gcf,'Tag','gridRows'),'String',num2str(nRows));
  set(findobj(gcf,'Tag','gridCols'),'String',num2str(nCols));

  % Update previous grid layout choice on Grid menu
  gridMenuItems=get(findobj(gcf,'Tag','gridMenu'),'UserData');
  currGrid=findobj(gridMenuItems,'Checked','on');
  if ~isempty(currGrid)
    prevGrid=gridMenuItems(end-1);
    set(prevGrid,'Label',get(currGrid,'Label'),'Callback',get(currGrid,'Callback'));
  end

  % Check new grid layout on Grid menu
  set(gridMenuItems,'Checked','Off');
  if nCols<=8 & (nRows==nCols | nRows-1==nCols) & isempty(gridFileName)
    % Standard grid layout chosen
    if nRows==nCols
      set(gridMenuItems(2*nCols-1),'Checked','on');
    else
      set(gridMenuItems(2*nCols),'Checked','on');
    end
    set(gridMenuItems(end),'Enable','off');
  else
    % Custom grid layout chosen
    if isempty(gridFileName)
      itemStr=[num2str(grid(1)) ' x ' num2str(grid(2))];
      callStr=['EEGGrid(' mat2str(grid) ');'];
    else
      itemStr=gridFileName;
      callStr=['EEGGrid(''' gridFileName ''');'];
    end
    set(gridMenuItems(end),'Label',itemStr,'Callback',callStr,...
      'Checked','on','Enable','on');
  end
end

% Modification History:
%
% $Log: EEGPlot.m,v $
% Revision 1.4  2005/02/03 20:17:40  michelich
% M-Lint: Replace deprecated isstr with ischar.
%
% Revision 1.3  2005/02/03 16:58:18  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:33  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/10/08 23:46:44  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Francis Favorini, 10/22/96.
% Francis Favorini, 10/31/96.  Can handle no bins properly.
% Francis Favorini, 11/13/96.  Made auto-scaling smarter.
% Francis Favorini, 01/10/97.  Added updateXHairs parameter to fix problem with inverting
%                              bins with crosshairs on.
% Francis Favorini, 01/29/97.  MATLAB 5 compliance.
% Francis Favorini, 02/05/97.  Changed binColors to a structure.
% Francis Favorini, 07/01/97.  Changed to use eeg structure.
% Francis Favorini, 07/04/97.  Draw task/base lines according to Format menu.
%                              Show/hide channel labels according to Format menu.
% Francis Favorini, 07/08/97.  Add current grid layout to Grid menu, if not already there.
