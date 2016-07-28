function chanSortOrder=EEGSort(sortOrder,updateDisplay)
%EEGSORT Sort EEG channels and update display.
%
%       chanSortOrder=EEGSort(sortOrder);
%       chanSortOrder=EEGSort(sortOrder,updateDisplay);
%
%       sortOrder is 'numeric', 'alphabetic',
%         or a row vector with 1:nChannels in the desired order.
%       updateDisplay is 1 if the channels are to be redisplayed in the new order,
%         else 0.  Default is 0.

% CVS ID and authorship of this code
% CVSId = '$Id: EEGSort.m,v 1.4 2005/02/03 20:17:40 michelich Exp $';
% CVSRevision = '$Revision: 1.4 $';
% CVSDate = '$Date: 2005/02/03 20:17:40 $';
% CVSRCSFile = '$RCSfile: EEGSort.m,v $';

set(gcf,'Pointer','watch'); drawnow;

% Defaults
if nargin<2, updateDisplay=0; end

% Find EEG info
eeg=getfield(get(gcf,'UserData'),'eeg');
allChans=[1:eeg.nChannels];

% Get sort menu
sortMenu=findobj(gcf,'Tag','sortMenu');
menuItems=findobj(gcf,'Tag','sortMenuItem')';

% Check appropriate sortOrder item on channel sort menu
set(menuItems,'Checked','off');
if ischar(sortOrder)
  for item=menuItems
    if strcmp(lower(get(item,'Label')),lower(sortOrder))
      set(item,'Checked','on');
      break;
    end
  end
end

% Generate chanSortOrder
if ischar(sortOrder)
  if strcmp(sortOrder,'numeric')
    chanSortOrder=allChans;
  elseif strcmp(sortOrder,'alphabetic')
    [c ci]=alphasort(eeg.chanNames);
    chanSortOrder=ci';
  else
    error('Unknown sortOrder specified.');
  end
else
  chanSortOrder=sortOrder;
end

if updateDisplay
  % Build channels
  plots=getfield(get(gcf,'UserData'),'plots');
  channels=[];
  for c=plots
    channels=[channels get(c,'UserData')];
  end
  channels=chanSort(channels);
end

% Set sort order
set(sortMenu,'UserData',chanSortOrder);

% Update channel popup menu
chanNames=eeg.chanNames(chanMap(allChans));
set(findobj(gcf,'Tag','showChannel'),'String',chanNames);

if updateDisplay
  % Plot data starting with first channel on old display
  rChan=find(channels(1)==chanMap(allChans));   % Relative channel from actual
  EEGChan(rChan,1);
end

set(gcf,'Pointer','arrow');

% Modification History:
%
% $Log: EEGSort.m,v $
% Revision 1.4  2005/02/03 20:17:40  michelich
% M-Lint: Replace deprecated isstr with ischar.
%
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
% Francis Favorini, 10/23/96.
% Francis Favorini, 12/09/96.  Restored after corruption.  Eliminated no params variant.
%                              Now defaults to not updating the display.
% Francis Favorini, 01/29/97.  MATLAB 5 compliance.
% Francis Favorini, 07/01/97.  Changed to use eeg structure.
%                              Ignore case in strcmp of sortOrder.
