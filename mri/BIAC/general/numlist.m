function s=numlist(n,delim,fmt)
%NUMLIST Return delimited list of numbers.
%
%   s=numlist(n,delim,fmt);
%
%   n is a numeric matrix.
%   delim is a string used to delimit the numbers in n.
%     Default is ','.
%   fmt is a format string for sprintf.
%     Default is '%d'.

% CVS ID and authorship of this code
% CVSId = '$Id: numlist.m,v 1.3 2005/02/03 16:58:34 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:34 $';
% CVSRCSFile = '$RCSfile: numlist.m,v $';

error(nargchk(1,3,nargin));
if nargin<2, delim=','; end
if nargin<3, fmt='%d'; end
if ~isnumeric(n), error('n must be a numeric array!'); end
if ~ischar(delim) | size(delim,1)>1, error('Delimiter must be a string!'); end
if ~ischar(fmt) | size(fmt,1)~=1, error('Format must be a non-empty string!'); end
s=sprintf([fmt '&'],n);
s=strrep(s(1:end-1),'&',delim);

% Modification History:
%
% $Log: numlist.m,v $
% Revision 1.3  2005/02/03 16:58:34  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:36  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/08/27 22:24:17  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Francis Favorini, 1998/11/06.
% Francis Favorini, 2001/09/14. Changed filename to lowercase.

