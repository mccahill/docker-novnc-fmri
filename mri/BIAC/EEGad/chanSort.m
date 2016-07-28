function sortedChans=chanSort(chans)
%CHANSORT Sort list of channels in chans based on names in strs.
%
%       sortedChans=CHANSORT(chans);
%
%       chans is a row vector of actual channel numbers.
%       sortedChans is a row vector of channel numbers sorted
%         according to user-specified chanSortOrder.

% CVS ID and authorship of this code
% CVSId = '$Id: chanSort.m,v 1.3 2005/02/03 16:58:20 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:20 $';
% CVSRCSFile = '$RCSfile: chanSort.m,v $';

chanSortOrder=get(findobj(gcf,'Tag','sortMenu'),'UserData');
ci=[];
for c=chans
  ci=[ci; find(c==chanSortOrder)];
end
ci=sort(ci)';
sortedChans=chanSortOrder(ci);

% Modification History:
%
% $Log: chanSort.m,v $
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
%       Francis Favorini, 10/23/96.
