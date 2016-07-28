function [y,yi]=alphasort(x)
%ALPHASORT Sort string array or cell array alphabetically using sortrows.
%
%       [y,yi]=alphasort(x);
%
%       x is the input array.
%       y is the sorted array.
%       yi is the index array.

% CVS ID and authorship of this code
% CVSId = '$Id: alphasort.m,v 1.3 2005/02/03 16:58:31 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:31 $';
% CVSRCSFile = '$RCSfile: alphasort.m,v $';

if ischar(x)
  [y,yi]=sortrows(x);
elseif iscellstr(x)
  [tmp,yi] = sortrows(strvcat(x{:}));
  y = x(yi);
else
  error('Input to alphasort must be a character array or cell array of strings.');
end

% Modification History:
%
% $Log: alphasort.m,v $
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
% Francis Favorini, 1997/07/01.