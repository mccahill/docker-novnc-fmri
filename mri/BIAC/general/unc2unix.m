function pathOut=unc2unix(pathIn)
%UNC2UNIX - Convert UNC filename or path to a UNIX filename or path
%
%  Converts UNC filenames or paths assuming that UNC shares
%    \\computer\share\ are mounted at $HOME/net/computer/share/
%    where computer and share are lowercase on the output.
%
%  pathOut=unc2unix(pathIn)
%
%   pathIn  - UNC filename/path string or cell array strings
%   pathOut - UNIX filename/path string or cell array of strings
%             corresponding to each element of pathIn.
%
%  Notes:
%    Any non-UNC filenames or paths (i.e. Do not start with \\) are
%      unchanged in output. 
%    $HOME environment variable must be defined.
%
% See Also: FILESEP

% CVS ID and authorship of this code
% CVSId = '$Id: unc2unix.m,v 1.6 2005/02/03 16:58:36 michelich Exp $';
% CVSRevision = '$Revision: 1.6 $';
% CVSDate = '$Date: 2005/02/03 16:58:36 $';
% CVSRCSFile = '$RCSfile: unc2unix.m,v $';

% Check input arguements.
error(nargchk(1,1,nargin))
if ~ischar(pathIn) & ~iscellstr(pathIn),
  error('pathIn must be a string or cell array of strings!');
end

% If input is not a cell array, put it in a cell array
isInputCell =1;
if ~iscellstr(pathIn),
  isInputCell = 0;
  pathIn = {pathIn};
end

% Initialize homeDir to empty (unless we need to get it)
homeDir = '';

% Loop through each filename/path
pathOut=cell(size(pathIn)); % Initialize output array (preserving shape)
for n=1:length(pathIn(:))
  currPath=pathIn{n};
  if strncmp(currPath,'\\',2)
    % This is a UNC path

    % Replace the \ with /
    currPath=strrep(currPath,'\','/');

    % Make the UNC computer and share lowercase.
    ii_filesep=findstr(currPath,'/');
    if length(ii_filesep) < 3, 
      error('Invalid UNC specifier: There is not a server and share in %s',pathIn{n});
    elseif length(ii_filesep) == 3
      % \\Computer\share
      endOfShare = length(currPath);
    else
      % \\Computer\share\abcd...
      endOfShare = ii_filesep(4)-1;
    end
    currPath(3:endOfShare)=lower(currPath(3:endOfShare));

    % Get home directory if we don't already have it
    if isempty(homeDir)
      homeDir = getenv('HOME');
      if isempty(homeDir)
         error('$HOME environment variable must be set!');
      end
    end

    % Replace the \\ with $HOME/net/
    currPath = fullfile(homeDir,'net',currPath(3:end));
  end
  pathOut{n}=currPath;
end

% If input was not in a cell array, take output out of cell array
if ~isInputCell, pathOut=pathOut{:}; end

% Modification History:
%
% $Log: unc2unix.m,v $
% Revision 1.6  2005/02/03 16:58:36  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.5  2003/10/22 15:54:37  gadde
% Make some CVS info accessible through variables
%
% Revision 1.4  2003/09/05 13:53:52  michelich
% Changed share mount point to $HOME\net\server\share
%
% Revision 1.3  2003/08/14 17:17:43  michelic
% Changed share mount point to $HOME\MOUNT\server\share from ~\server\share.
%
% Revision 1.2  2003/04/07 21:18:11  michelich
% Add missing semicolon.
% Remove extra end of line characters.
%
% Revision 1.1  2003/04/07 21:01:59  crm
% Initial version.
%
