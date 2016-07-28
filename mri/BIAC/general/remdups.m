function stripped=remdups(v)
%REMDUPS   sort and remove duplicates from vector.
%   remdups(v) sorts and removes duplicates (and non-finites) from vector v and returns result.

% CVS ID and authorship of this code
% CVSId = '$Id: remdups.m,v 1.3 2005/02/03 16:58:36 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:36 $';
% CVSRCSFile = '$RCSfile: remdups.m,v $';

sorted=sort(v(isfinite(v)));
stripped=sorted(find(diff([sorted Inf])));

% Modification History:
%
% $Log: remdups.m,v $
% Revision 1.3  2005/02/03 16:58:36  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:36  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/08/27 22:24:18  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2001/01/23. Changed function name to lowercase.
% Francis Favorini,  1997/12/09.  

