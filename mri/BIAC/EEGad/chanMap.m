function sortedChans=chanMap(chans)
%CHANMAP Sort and remap list of channels in chans based on names in strs.
%
%       sortedChans=CHANMAP(chans);
%
%       chans is a row vector of relative channel numbers.
%       sortedChans is a row vector of sorted channel numbers remapped
%         according to user-specified chanSortOrder.

% CVS ID and authorship of this code
% CVSId = '$Id: chanMap.m,v 1.3 2005/02/03 16:58:19 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:19 $';
% CVSRCSFile = '$RCSfile: chanMap.m,v $';

% Sort the channels we got
chans=sort(chans')';

% Use as index into sorted version of all channels
chanSortOrder=get(findobj(gcf,'Tag','sortMenu'),'UserData');
sortedChans=chanSortOrder(chans);

% Modification History:
%
% $Log: chanMap.m,v $
% Revision 1.3  2005/02/03 16:58:19  michelich
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
%       Francis Favorini, 10/23/96.
