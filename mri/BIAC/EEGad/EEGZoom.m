function EEGZoom(action)
%EEGZoom Select and hilight EEG plots with the mouse.  Then zoom grid to just those plots.

% CVS ID and authorship of this code
% CVSId = '$Id: EEGZoom.m,v 1.4 2005/02/03 20:17:40 michelich Exp $';
% CVSRevision = '$Revision: 1.4 $';
% CVSDate = '$Date: 2005/02/03 20:17:40 $';
% CVSRCSFile = '$RCSfile: EEGZoom.m,v $';

global EEGZoomHiPlots EEGZoomAnchor;
if nargin==0
  % Enter zoom mode, set button and menu callbacks
  EEGZoomHiPlots=[];
  EEGZoomAnchor=[];
  set(gcf,'WindowButtonDownFcn','EEGZoom(''down'');');
  set(findobj(gcf,'Tag','Zoom Button'),'CallBack','EEGZoom(''zoom'');');
  set(findobj(gcf,'Tag','Zoom Menu'),'CallBack','EEGZoom(''zoom'');');
  figure(gcf);
elseif strcmp(action,'zoom')
  % Ready to zoom, reset button and menu callbacks
  set(gcf,'WindowButtonDownFcn','EEGTweak(''down'')');
  set(gcf,'WindowButtonMotionFcn','');
  set(gcf,'WindowButtonUpFcn','');
  set(findobj(gcf,'Tag','Zoom Button'),'CallBack','EEGZoom');
  set(findobj(gcf,'Tag','Zoom Menu'),'CallBack','EEGZoom');
  set(EEGZoomHiPlots,'Color','none');

  % Find EEG info
  eeg=getfield(get(gcf,'UserData'),'eeg');

  % Zoom grid to highlighted plots
  nHiChannels=length(EEGZoomHiPlots);
  if nHiChannels>0
    % Build channels and hiChannels
    channels=chanSort(1:eeg.nChannels);
    hiChannels=zeros(1,nHiChannels);
    for p=1:nHiChannels
      hiChannels(p)=get(EEGZoomHiPlots(p),'UserData');
    end

    % Change sort order by making highlighted channels contiguous.
    for p=2:nHiChannels
      channels(find(hiChannels(p)==channels))=[];     % Remove all but first hiChannels
    end
    p=find(hiChannels(1)==channels);
    sortOrder=[channels(1:p-1) hiChannels channels(p+1:length(channels))];

    % Calculate grid size and display
    nRows=ceil(sqrt(nHiChannels));
    nCols=ceil(nHiChannels/nRows);
    grid=[nRows nCols];

    if strcmp(get(gcf,'SelectionType'),'normal') | ...
       strcmp(get(gcf,'SelectionType'),'open')            % Zoom into current window
      EEGSort(sortOrder);
      EEGGrid(grid,hiChannels(1));
    else                                                  % Zoom into new window
      % Find EEG info
      eeg=getfield(get(gcf,'UserData'),'eeg');
      plots=getfield(get(gcf,'UserData'),'plots');
      xRange=[str2num(get(findobj(gcf,'Tag','XMin'),'String')),...
              str2num(get(findobj(gcf,'Tag','XMax'),'String'))];
      yRange=[str2num(get(findobj(gcf,'Tag','YMin'),'String')),...
              str2num(get(findobj(gcf,'Tag','YMax'),'String'))];

      % Build channels and bins
      ci=find(hiChannels(1)==sortOrder);
      channels=ci:min(eeg.nChannels,ci-1+grid(1)*grid(2));  % Relative channels
      bins=[];
      for b=findobj(plots(1),'Tag','bin')'
        bins=[bins; get(b,'UserData')];
      end
      bins=sort(bins)';

      % Create new figure window and show data
      EEGFig;
      EEGShow(eeg,bins,channels,grid,yRange,xRange,sortOrder);
    end
  end

  clear global EEGZoomHiPlots EEGZoomAnchor;
  figure(gcf);
elseif strcmp(action,'down') | strcmp(action,'move') | strcmp(action,'up')
  if strcmp(get(gcf,'SelectionType'),'open')      % Double-click
    EEGZoom('zoom');
    return;
  end
  if strcmp(action,'down')
    set(gcf,'WindowButtonMotionFcn','EEGZoom(''move'');');
    set(gcf,'WindowButtonUpFcn','EEGZoom(''up'');');
    EEGZoomAnchor=[];
  elseif strcmp(action,'up')
    set(gcf,'WindowButtonMotionFcn','');
    set(gcf,'WindowButtonUpFcn','');
  end

  % Find EEG info
  eeg=getfield(get(gcf,'UserData'),'eeg');
  plots=getfield(get(gcf,'UserData'),'plots');
  if length(plots)>eeg.nChannels, plots=plots(1:eeg.nChannels); end

  % Find the plot that was clicked on/moved over
  clickPoint=get(gcf,'CurrentPoint');
  for aPlot=plots
    units=get(aPlot,'Units');
    set(aPlot,'Units',get(gcf,'Units'));
    rect=get(aPlot,'Position');
    set(aPlot,'Units',units);
    rect(3)=rect(1)+rect(3); rect(4)=rect(2)+rect(4);
    inRect=clickPoint(1)>rect(1) & clickPoint(1)<rect(3) &...
           clickPoint(2)>rect(2) & clickPoint(2)<rect(4);
    if inRect, break, end
  end
  if ~inRect, return, end

  % Set anchor point, if haven't already
  if isempty(EEGZoomAnchor)
    if ischar(get(aPlot,'Color'))
      set(aPlot,'Color','white');
      EEGZoomHiPlots=[EEGZoomHiPlots aPlot];
    else
      set(aPlot,'Color','none');
      if ~isempty(EEGZoomHiPlots)
        EEGZoomHiPlots(find(EEGZoomHiPlots==aPlot))=[];
      end
    end
    EEGZoomAnchor=aPlot;
  end

  % (De)Hilight all plots between anchor plot and plot where mouse is
  anchorColor=get(EEGZoomAnchor,'Color');
  anchorIndex=find(plots==EEGZoomAnchor);
  mouseIndex=find(plots==aPlot);
  for aPlot=plots(min(anchorIndex,mouseIndex):max(anchorIndex,mouseIndex))
    plotColor=get(aPlot,'Color');
    if ~ischar(anchorColor)
      if ischar(plotColor)
        EEGZoomHiPlots=[EEGZoomHiPlots aPlot];
        set(aPlot,'Color',anchorColor);
      end
    elseif ~ischar(plotColor)
      EEGZoomHiPlots(find(EEGZoomHiPlots==aPlot))=[];
      set(aPlot,'Color',anchorColor);
    end
  end
end

% Modification History:
%
% $Log: EEGZoom.m,v $
% Revision 1.4  2005/02/03 20:17:40  michelich
% M-Lint: Replace deprecated isstr with ischar.
%
% Revision 1.3  2005/02/03 16:58:19  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:34  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/10/08 23:46:45  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Francis Favorini, 10/16/96.
% Francis Favorini, 10/25/96.  Modified to allow range and discontinuous selections.
%                              Now zooms on press of any key.
% Francis Favorini, 10/31/96.  Changed to zoom on second press of zoom button.
% Francis Favorini, 11/06/96.  Right click for selection zooms to new window.
% Francis Favorini, 11/08/96.  Modified to allow double-click to zoom also.
%                              In new sort order, zoomed range is anchored to first channel
%                              in range instead of beginning of sort order.
% Francis Favorini, 11/11/96.  Fixed problem with first channel always coming up when
%                              zooming to new window.
% Francis Favorini, 12/09/96.  Fixed bug with channel order when zooming to new window.
% Francis Favorini, 01/29/97.  MATLAB 5 compliance.
% Francis Favorini, 06/13/97.  Added isempty check.
% Francis Favorini, 07/02/97.  Changed to use eeg structure.
% Francis Favorini, 07/08/97.  Changed to use EEGFig.
% Francis Favorini, 08/26/97.  Added Zoom to Format menu.
%                              Double-click zooms to current window.
