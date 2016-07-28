function s1 = spacejam(s)
%SPACEJAM Collapse consecutive spaces to one in string.
%   SPACEJAM(S) Collapses consecutive spaces to one in strings S.
%
%   See also TRIM.

% CVS ID and authorship of this code
% CVSId = '$Id: spacejam.m,v 1.4 2005/02/03 20:17:46 michelich Exp $';
% CVSRevision = '$Revision: 1.4 $';
% CVSDate = '$Date: 2005/02/03 20:17:46 $';
% CVSRCSFile = '$RCSfile: spacejam.m,v $';

if ~isempty(s) & ~ischar(s) & ~iscellstr(s)
  warning('Input must be a string or cell array of strings.')
end

% Collapse n spaces to 1 in channel name
if iscellstr(s)
  s1=cell(size(s));
  for n=1:length(s)
    sn=s{n};
    while ~isempty(findstr(sn,'  '))
      sn=strrep(sn,'  ',' ');
    end
    s1{n}=sn;
  end
else
  s1=s;
  while ~isempty(findstr(s1,'  '))
    s1=strrep(s1,'  ',' ');
  end
end

% Modification History:
%
% $Log: spacejam.m,v $
% Revision 1.4  2005/02/03 20:17:46  michelich
% M-Lint: Replace deprecated isstr with ischar.
%
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
% Francis Favorini, 1997/10/20.
