function EEGGrid(grid,chan)
%EEGGrid Sets grid dimensions of current EEG plot.
%
%       EEGGrid;
%       EEGGrid(grid);
%       EEGGrid(grid,chan);
%
%       grid is the new grid dimensions [m n]
%         or the name of a custom grid file
%         or 'custom' to prompt for a custom grid.
%         If not specified, get dimensions from text boxes.
%       chan is the starting channel. If not specified, use current first channel.

% CVS ID and authorship of this code
% CVSId = '$Id: EEGGrid.m,v 1.4 2005/02/03 20:17:40 michelich Exp $';
% CVSRevision = '$Revision: 1.4 $';
% CVSDate = '$Date: 2005/02/03 20:17:40 $';
% CVSRCSFile = '$RCSfile: EEGGrid.m,v $';

set(gcf,'Pointer','watch'); drawnow;

% Defaults
oldGrid=getfield(get(gcf,'UserData'),'grid');
if nargin<1
  grid=[str2num(get(findobj(gcf,'Tag','gridRows'),'String')),...
        str2num(get(findobj(gcf,'Tag','gridCols'),'String'))];
end
if length(grid)==2, grid(3)=oldGrid(3); end
if nargin<2, chan=[]; end
 
% Find EEG info
eeg=getfield(get(gcf,'UserData'),'eeg');
plots=getfield(get(gcf,'UserData'),'plots');
if length(plots)>eeg.nChannels, plots=plots(1:eeg.nChannels); end
xRange=[str2num(get(findobj(gcf,'Tag','XMin'),'String')),...
        str2num(get(findobj(gcf,'Tag','XMax'),'String'))];
yRange=[str2num(get(findobj(gcf,'Tag','YMin'),'String')),...
        str2num(get(findobj(gcf,'Tag','YMax'),'String'))];

if ischar(grid)
  % If using a custom grid, get layout from file, sort and calculate size
  [grid sortOrder fname]=EEGCustm(grid);
  if isempty(grid)                    % User cancelled
    set(gcf,'Pointer','arrow');
    figure(gcf);
    return;
  end
  sortOrder=EEGSort(sortOrder);
  chan=sortOrder(1);
  gLen=size(grid,1);
  grid={fname grid};                  % Pass file name along with positions
else
  gLen=grid(1)*grid(2);
end

% Build channels and bins
channels=chanSort(1:eeg.nChannels);
bins=[];
for b=findobj(plots(1),'Tag','bin')'
  bins=[bins; get(b,'UserData')];
end
bins=sort(bins)';

% Get starting channel
if isempty(chan)
  chan=get(plots(1),'UserData');
end
ci=find(chan==channels);
cLen=eeg.nChannels-ci+1;

% Adjust starting channel to maximize number of channels displayed
if cLen<gLen                        % If not enough to fill grid,
  ci=max(1,ci-(gLen-cLen));         %  start with earlier channel
  cLen=eeg.nChannels-ci+1;
elseif cLen>gLen                    % If more than enough to fill grid,
  cLen=gLen;                        %  use just enough channels
end
channels=channels(ci:ci+cLen-1);

% Update grid
EEGPlot(bins,channels,xRange,yRange,grid);

set(gcf,'Pointer','arrow');
figure(gcf);

% Modification History:
%
% $Log: EEGGrid.m,v $
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
% Francis Favorini, 10/15/96.
% Francis Favorini, 10/23/96.  Modified to use EEGPlot and chanSort.
% Francis Favorini, 10/31/96.  Added custom grid layout.
% Francis Favorini, 12/09/96.  EEGSort now defaults to not updating the display.
% Francis Favorini, 01/29/97.  MATLAB 5 compliance.
% Francis Favorini, 02/06/97.  Fixed cancel custom grid bug.
% Francis Favorini, 07/02/97.  Changed to use eeg structure.
% Francis Favorini, 07/08/97.  Added ability to pass grid file name.
