function EEGPage(action)
%EEGPage Page up or down through channels on current EEG plot.

% CVS ID and authorship of this code
% CVSId = '$Id: EEGPage.m,v 1.3 2005/02/03 16:58:18 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:18 $';
% CVSRCSFile = '$RCSfile: EEGPage.m,v $';

% Find EEG info
eeg=getfield(get(gcf,'UserData'),'eeg');
grid=getfield(get(gcf,'UserData'),'grid');

pageSz=grid(1)*grid(2);
currChan=get(findobj(gcf,'Tag','showChannel'),'Value');

if strcmp(action,'up')
  chan=currChan-pageSz;
  chan=max(1,chan);
elseif strcmp(action,'down')
  chan=currChan+pageSz;
  chan=min(eeg.nChannels,chan);
end
EEGChan(chan);
figure(gcf);

% Modification History:
%
% $Log: EEGPage.m,v $
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
% Francis Favorini, 07/02/97.  Changed to use eeg structure.
