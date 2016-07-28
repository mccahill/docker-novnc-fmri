function EEGRaw
%EEGRAW Revert to raw EEG data.

% CVS ID and authorship of this code
% CVSId = '$Id: EEGRaw.m,v 1.3 2005/02/03 16:58:18 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:18 $';
% CVSRCSFile = '$RCSfile: EEGRaw.m,v $';

% Find EEG info
eeg=getfield(get(gcf,'UserData'),'eeg');

if ~isempty(eeg.rawData)
  % Restore raw data
  eeg.data=eeg.rawData;
  eeg.rawData=[];
  set(gcf,'UserData',setfield(get(gcf,'UserData'),'eeg',eeg));
  
  % Plot data
  EEGPlot;
end

% Modification History:
%
% $Log: EEGRaw.m,v $
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
% Francis Favorini, 10/23/96.
% Francis Favorini, 07/02/97.  Changed to use eeg structure.
