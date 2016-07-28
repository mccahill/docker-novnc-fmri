function badCount=checkfiles(inFile,noDisplay)
%CHECKFILES Read list of files and make sure they exist.
%
%       badCount=checkfiles(inFile);
%
%       inFile is the name of a .TXT file with a list of files to check.
%
%       bad is the number of files that don't exist.

% CVS ID and authorship of this code
% CVSId = '$Id: checkfiles.m,v 1.4 2005/02/03 20:17:45 michelich Exp $';
% CVSRevision = '$Revision: 1.4 $';
% CVSDate = '$Date: 2005/02/03 20:17:45 $';
% CVSRCSFile = '$RCSfile: checkfiles.m,v $';

% Check args
if nargin<1 | nargin>2
  error('Incorrect number of input arguments.');
end
if ~ischar(inFile)
  error('Input argument must be a filename.');
end
if nargin<2
  noDisplay=0;
end

% Get data files from list file
listFid=fopen(inFile,'rt');
if listFid==-1
  error(['Couldn''t open list file "' inFile '"'])
end
[lines,count]=getstrs(listFid);
fclose(listFid);

if ~noDisplay, disp(sprintf('Checking %d files:',count)); end
bad=0;
for n=1:count
  % Process line from list file
  s=upper(lines{n});
  dataFile=sscanf(s,'%s',1);
  if dataFile(end)=='\', dataFile(end)=[]; end    % Trim trailing \
  ret=exist(dataFile);
  if ~any(ret==[2 3 4 6 7])
    bad=bad+1;
    if ~noDisplay, disp(sprintf('%s does not exist!',dataFile)); end
  end
end
if ~noDisplay
  if bad==0
    disp(sprintf('All files exist.\n'));
  elseif bad==1
    disp(sprintf('1 file does not exist!\n'));
  else
    disp(sprintf('%d files do not exist!\n',bad));
  end
end
if nargout==1
  badCount=bad;
end

% Modification History:
%
% $Log: checkfiles.m,v $
% Revision 1.4  2005/02/03 20:17:45  michelich
% M-Lint: Replace deprecated isstr with ischar.
%
% Revision 1.3  2005/02/03 16:58:32  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:34  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/08/27 22:24:14  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2001/01/23.  Changed getstrs() to lowercase.
% Francis Favorini,  1997/06/27.
