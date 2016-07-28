function s=strlist(n,delim,fmt)
%STRLIST Return delimited list of strings.
%
%   s=strlist(n,delim,fmt);
%
%   n is an array of strings or a cell array of strings.
%   delim is a string used to delimit the numbers in n.
%     Default is ','.
%   fmt is a format string for sprintf.
%     Default is '%s'.

% CVS ID and authorship of this code
% CVSId = '$Id: strlist.m,v 1.3 2005/02/03 16:58:36 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:36 $';
% CVSRCSFile = '$RCSfile: strlist.m,v $';

error(nargchk(1,3,nargin));
if nargin<2, delim=','; end
if nargin<3, fmt='%s'; end
if ~(ischar(n) | iscellstr(n)), error('n must be an array of strings or a cell array of strings!'); end
if ~ischar(delim) | size(delim,1)>1, error('Delimiter must be a string!'); end
if ~ischar(fmt) | size(fmt,1)~=1, error('Format must be a non-empty string!'); end
if ischar(n)
  n=cellstr(n);
end
s=sprintf([fmt '&'],n{:});
s=strrep(s(1:end-1),'&',delim);

% Modification History:
%
% $Log: strlist.m,v $
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
% Francis Favorini,  1998/11/06.

