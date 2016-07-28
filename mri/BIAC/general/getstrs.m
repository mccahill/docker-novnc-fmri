function [strs,count]=getstrs(fid,n)
%GETSTRS Read lines from text file and put into cell array.
%
%       [strs,count]=GETSTRS(fid);
%       [strs,count]=GETSTRS(fid,n);
%
%       fid is the file identifier for an open file.
%       n optionally specifies the max number of lines to read.
%
%       strs is a cell array of strings.
%       count is the number of lines actually read.
%

% CVS ID and authorship of this code
% CVSId = '$Id: getstrs.m,v 1.4 2005/02/03 20:17:45 michelich Exp $';
% CVSRevision = '$Revision: 1.4 $';
% CVSDate = '$Date: 2005/02/03 20:17:45 $';
% CVSRCSFile = '$RCSfile: getstrs.m,v $';

if nargin<2, n=0; end
l=0;
strs={};
while 1
  s=fgetl(fid);
  if ~ischar(s), break; end                            % No more strings
  l=l+1;
  strs{l}=s;
	if l==n, break; end
end
strs=strs';
count=l;

% Modification History:
%
% $Log: getstrs.m,v $
% Revision 1.4  2005/02/03 20:17:45  michelich
% M-Lint: Replace deprecated isstr with ischar.
%
% Revision 1.3  2005/02/03 16:58:33  michelich
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
% Charles Michelich, 2001/01/23. Changed case of function name to all lowercase
% Francis Favorini,  1997/06/12. Returns a cell array of strings.
% Francis Favorini,  1997/01/14. n is optional.
% Francis Favorini,  1996/10/02.

