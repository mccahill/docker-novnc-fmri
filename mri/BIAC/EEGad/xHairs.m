function xHairs(action)
%XHAIRS Display crosshairs for reading (x,y) values from a set of EEG plots.
%
%  A set of mouse driven crosshairs is placed on all EEG display axes,
%  and the corresponding (latency,amplitude) values are also displayed.
%  For plots with multiple bins, you can select the bin you want to see.
%  Can be toggled on and off.

% CVS ID and authorship of this code
% CVSId = '$Id: xHairs.m,v 1.3 2005/02/03 16:58:20 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:20 $';
% CVSRCSFile = '$RCSfile: xHairs.m,v $';

if nargin==0, action=[]; end
if get(findobj(gcf,'Tag','Crosshairs Checkbox'),'Value')~=1
  action='close';
end

if isempty(action)
  set(gcf,'WindowButtonDownFcn','xHairs(''down'');');

  % Turn off controls
  set(findobj(gcf,'Tag','gridMenu'),'Enable','Off');
  set(findobj(gcf,'Tag','sortMenu'),'Enable','Off');
  set(findobj(gcf,'Tag','gridRows'),'Enable','Off');
  set(findobj(gcf,'Tag','gridCols'),'Enable','Off');
  set(findobj(gcf,'Tag','Zoom Button'),'Enable','Off');

  grid=getfield(get(gcf,'UserData'),'grid');
  nRows=grid(1);
  nCols=grid(2);
  plots=findobj(gcf,'Tag','EEG')';
  for aPlot=plots
    axes(aPlot);

    % Set up crosshairs for each channel (hide 'em at origin to start)
    xRange=get(aPlot,'XLim');
    yRange=get(aPlot,'YLim');
    xLine=line([xRange(1) xRange(1)],[yRange(1) yRange(1)]);
    yLine=line([xRange(1) xRange(1)],[yRange(1) yRange(1)]);
    set(xLine,'Color','r','EraseMode','xor','Tag','xLine');
    set(yLine,'Color','r','EraseMode','xor','Tag','yLine');

    % Set up coords (latency,amplitude) for each channel
    if 0
      units=get(aPlot,'Units');
      set(aPlot,'Units','Pixels');
      pos=get(aPlot,'Position');
      set(aPlot,'Units',units);
      % Assumes 8 point Arial Narrow font
      if nCols>5
        pos=[pos(1)+2 pos(2)+pos(4)+8 61 13];           % Put above channel label
        align='Left';
      else
        pos=[pos(1)+pos(3)-61 pos(2)+pos(4) 61 13];     % Put next to channel label
        align='Right';
      end
      coords=uicontrol('Style','Text','String','','Tag','xCoords',...
                       'Units','Pixels','Position',pos,'HorizontalAlignment',align,...
                       'FontName','Arial Narrow','FontSize',8,...
                       'ForegroundColor','green','BackgroundColor','black');
      set(coords,'UserData',aPlot,'Units','Normalized');
    else
      % Adjust font size based on grid
      pos=[0.98 1.0];
      hAlign='Right';
      vAlign='Bottom';
      fontsize=9;
      if nCols>4, fontsize=8; end
      if nRows>6 | nCols>6, fontsize=7; end
      if nRows>7 | nCols>7, fontsize=6; end
      if nCols>6, fontsize=fontsize+1; end
      if nCols>5
        pos=[0.02 1.2];
        hAlign='Left';
        vAlign='Bottom';
      end
      coords=text('String',' ','Tag','xCoords','EraseMode','xor',...
                  'Units','Normalized','Position',pos,...
                  'FontName','Arial Narrow','FontSize',fontsize,'Color','Red',...
                  'HorizontalAlignment',hAlign,'VerticalAlignment',vAlign);
    end
  end

  % Set up popup menu for bin selection
  handles=findobj(findobj(gcf,'Tag','Legend'),'Tag','binName')';
  bins=[];
  binNames=[];
  for h=handles
    bins(end+1)=get(h,'UserData');
    binNames{end+1}=get(h,'String');
  end
  [bins bi]=sort(bins);
  binNames=binNames(bi);
  nBins=length(bins);
  binSelector=uicontrol('Style','PopupMenu','Tag','binSelector','String',binNames,...
                        'Value',1,'Visible','off',...
                        'Units','Pixels','Position',[10 38 85 12],...
                        'FontName','Arial Narrow','FontSize',8,...
                        'CallBack',['xHairs(''up'')',]);  
  if nBins>1,
    set(binSelector,'Visible','On');
  end

elseif strcmp(action,'down') | strcmp(action,'move') | strcmp(action,'up')
  if strcmp(action,'down')
    set(gcf,'WindowButtonMotionFcn','xHairs(''move'');');
    set(gcf,'WindowButtonUpFcn','xHairs(''up'');');
  elseif strcmp(action,'up')
    set(gcf,'WindowButtonMotionFcn','');
    set(gcf,'WindowButtonUpFcn','');
  end

  % Find the plot that was clicked on
  plots=findobj(gcf,'Tag','EEG')';
if 0
  if strcmp(get(gco,'Tag'),'EEG')
    aPlot=gco;
  elseif strcmp(get(get(gco,'Parent'),'Tag'),'EEG')
    aPlot=get(gco,'Parent');
  else
    return;
  end
else
  clickPoint=get(gcf,'CurrentPoint');
  for aPlot=plots
    units=get(aPlot,'Units');
    set(aPlot,'Units',get(gcf,'Units'));
    rect=get(aPlot,'Position');
    set(aPlot,'Units',units);
    rect(1)=rect(1)-1;
    rect(3)=rect(1)+rect(3);
    rect(4)=rect(2)+rect(4)-1;
    rect=fix(rect);
    inRect=clickPoint(1)>=rect(1) & clickPoint(1)<=rect(3) &...
           clickPoint(2)>=rect(2) & clickPoint(2)<=rect(4);
    if inRect, break, end
  end
  if ~inRect
    return;
  end
end

  % Which bin should crosshairs track?
  binSelector=findobj(gcf,'Tag','binSelector');
  handles=findobj(findobj(gcf,'Tag','Legend'),'Tag','binName')';
  bins=[];
  for h=handles
    bins=[bins; get(h,'UserData')];
  end
  bins=sort(bins);
  if isempty(bins)
    bin=0;
  else
    bin=bins(get(binSelector,'Value'));
  end

  % Display crosshairs and coordinates on each plot
  clickPoint=get(aPlot,'CurrentPoint');   % Clicked point in data units
  for aPlot=plots
    if bin
      % Adjust clicked point coords to actual data values
      aLine=findobj(aPlot,'Type','line','Tag','bin','UserData',bin);
      xData=get(aLine,'XData');
      xi=find(xData>=clickPoint(1,1));
      if isempty(xi)                        % Axes rect can be slightly larger than data
        return;
      end
      xi=xi(1);
      xDataPt=xData(xi);
      yData=get(aLine,'YData');
      yDataPt=yData(xi);
    end

    % Display coords
    if 0
      coords=findobj(gcf,'Tag','xCoords','UserData',aPlot);
    else
      coords=findobj(aPlot,'Tag','xCoords');
    end
    if bin
      set(coords,'String',sprintf('(%d,%.2f)',xDataPt,yDataPt));
    else
      set(coords,'String','');
    end

    % Display crosshairs
    xLine=findobj(aPlot,'Tag','xLine');
    yLine=findobj(aPlot,'Tag','yLine');
    xRange=get(aPlot,'XLim');
    yRange=get(aPlot,'YLim');
    if bin
      set(xLine,'XData',[xDataPt xDataPt],'YData',yRange);
      set(yLine,'XData',xRange,'YData',[yDataPt yDataPt]);
    else
      set(xLine,'XData',[xRange(1) xRange(1)],'YData',[yRange(1) yRange(1)]);
      set(yLine,'XData',[xRange(1) xRange(1)],'YData',[yRange(1) yRange(1)]);
    end
  end
  
elseif strcmp(action,'close')
  % Turn on controls
  set(findobj(gcf,'Tag','gridMenu'),'Enable','On');
  set(findobj(gcf,'Tag','sortMenu'),'Enable','On');
  set(findobj(gcf,'Tag','gridRows'),'Enable','On');
  set(findobj(gcf,'Tag','gridCols'),'Enable','On');
  set(findobj(gcf,'Tag','Zoom Button'),'Enable','On');

  delete(findobj(gcf,'Tag','binSelector'));
  delete(findobj(gcf,'Tag','xLine'));
  delete(findobj(gcf,'Tag','yLine'));
  delete(findobj(gcf,'Tag','xCoords'));
  set(gcf,'WindowButtonDownFcn','EEGTweak(''down'')');
  set(gcf,'WindowButtonUpFcn','');
  set(gcf,'WindowButtonMotionFcn','');  
end

% Modification History:
%
% $Log: xHairs.m,v $
% Revision 1.3  2005/02/03 16:58:20  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:34  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/10/08 23:46:46  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Francis Favorini, 10/08/96.
% Francis Favorini, 01/29/97.  MATLAB 5 compliance.
% Francis Favorini, 07/02/97.  Use grid field of UserData.
% Francis Favorini, 07/03/97.  Changed binNames to cell array.
%                              Changed 'coords' tag to 'xCoords'
% Francis Favorini, 07/07/97.  Tweaked position of bin selector.

