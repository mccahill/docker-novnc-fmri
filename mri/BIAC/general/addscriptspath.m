function addscriptspath
% addscriptspath
%
% Add specified scripts directory from current experiment to path
%
%  Usage:
%     addscriptspath - Prompts with GUI to path to add
%
% See also: RMSCRIPTSPATH, CHEXP, PWE, RMEXPPATH

% CVS ID and authorship of this code
% CVSId = '$Id: addscriptspath.m,v 1.3 2005/02/03 16:58:31 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:31 $';
% CVSRCSFile = '$RCSfile: addscriptspath.m,v $';

% Check input arguments
error(nargchk(0,0,nargin));

% Get sertings for current experiment
currExp = chexp('settings');
if isempty(currExp)
  disp('No record of current experiment.  Use chexp to select experiment.');
else
  % Find all directories and subdirectories in the scripts directory (except . & ..)
  % Use a maximum depth of 100 just in case of circular links
  [scriptdirs depth]= finddirs(fullfile(currExp.Path,'Scripts'),100);
  
  if depth == -1
      warning('Scripts directory has more than 100 sublevels.  Only first 100 searched!')
  end
  
  % Ask the user to select a directory
  dir2add=listgui(scriptdirs,'Choose Directory...');
  
  % Add the scripts directory to the path
  if ~isempty(dir2add)
    addpath(dir2add);
  end
end

% Modification History:
%
% $Log: addscriptspath.m,v $
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
% Charles Michelich, 2001-10-25. Updated See Also section.
% Charles Michelich, 2001-09-27. Added warning if maxdepth reached on search.
% Charles Michelich, 2001-08-13. Finished implementation
% Charles Michelich, 2001-08-10. original
