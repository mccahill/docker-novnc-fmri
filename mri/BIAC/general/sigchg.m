function y=sigchg(x)
%SIGCHG Calculate signal change of values in x.
%
%       y=sigchg(x);
%
%       The formula is y=(x-mean(x))./mean(x)

% CVS ID and authorship of this code
% CVSId = '$Id: sigchg.m,v 1.3 2005/02/03 16:58:36 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:36 $';
% CVSRCSFile = '$RCSfile: sigchg.m,v $';

m=mean(x);
y=(x-m)./m;

% Modification History:
%
% $Log: sigchg.m,v $
% Revision 1.3  2005/02/03 16:58:36  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:36  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/08/27 22:24:19  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2001/01/23. Changed function name to lowercase.
% Francis Favorini,  1998/08/24.
