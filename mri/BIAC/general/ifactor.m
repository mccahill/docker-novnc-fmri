function f = ifactor(n)
%IFACTOR Return integer factors.
%   IFACTOR(N) returns a vector containing the integer factors of N.
%
%   See also FACTOR.

% CVS ID and authorship of this code
% CVSId = '$Id: ifactor.m,v 1.3 2005/02/03 16:58:34 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:34 $';
% CVSRCSFile = '$RCSfile: ifactor.m,v $';

if prod(size(n))~=1, error('N must be a scalar.'); end
if (n < 0) | (floor(n) ~= n), error('N must be a positive integer.'); end

ff=[1:floor(sqrt(n))];
f1=ff(isint(n./ff));
f2=fliplr(n./f1);
if f1(end)==f2(1)
  f2=f2(2:end);
end
f=[f1 f2];

% Modification History:
%
% $Log: ifactor.m,v $
% Revision 1.3  2005/02/03 16:58:34  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:35  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/08/27 22:24:15  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Francis Favorini, 2001/06/13.

