function arefresh(h)
%AREFRESH Refresh axes.
%
%       arefresh;
%       arefresh(h);
%
%       Refresh axes pointed to by h.  Default is current axes.

% CVS ID and authorship of this code
% CVSId = '$Id: arefresh.m,v 1.3 2005/02/03 16:58:31 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:31 $';
% CVSRCSFile = '$RCSfile: arefresh.m,v $';

if nargin<1, h=gca; end
set(h,'Color',get(h,'Color'));

% Modification History:
%
% $Log: arefresh.m,v $
% Revision 1.3  2005/02/03 16:58:31  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:34  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/08/27 22:24:13  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2001/01/23. Changed function name to all lowercase.
% Francis Favorini,  1996/11/11.
