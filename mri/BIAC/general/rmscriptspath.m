function rmscriptspath(cmd)
% RMSCRIPTSPATH - Remove current experiment paths (Scripts only)
%
%  Remove one or all directories in path that 
%  start with the path to the current experiment (Scripts directory only)
%
%  Usage:
%     rmscriptspath          - Prompts with GUI to path to remove
%     rmscriptspath all      - Removes all paths without prompting
%     rmscriptspath allquiet - Removes allpaths without prompting
%                              or messages
%
% See also: ADDSCRIPTSPATH, CHEXP, PWE, RMEXPPATH

% CVS ID and authorship of this code
% CVSId = '$Id: rmscriptspath.m,v 1.3 2005/02/03 16:58:36 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:36 $';
% CVSRCSFile = '$RCSfile: rmscriptspath.m,v $';

% Check input arguments
error(nargchk(0,1,nargin));
if nargin == 0, cmd=''; end
if nargin == 1,
  if ~(strcmpi(cmd,'all') | strcmpi(cmd,'allquiet'))
    error('Invalid option for rmscriptspath!');
  end
end

% Get settings for current experiment
currExp = chexp('settings'); 

if isempty(currExp) % No experiment selected
  disp('No record of current experiment.  Use chexp to select experiment.');
else                % Experiment selected, continue
  % Find paths in current path that start with the path to the current experiment 
  expPaths={}; % List of current paths that start with the path of the current experiment
  remainPath=path; % Remaining path to search
   while ~isempty(remainPath)
    [currItem,remainPath]=strtok(remainPath,pathsep); % Get item from path
    
    % Base directory to compare paths against
    basepath = fullfile(currExp.Path,'Scripts');
    
    % Check if it starts with the path to the current experiment
    if strncmp(basepath,currItem,length(basepath))
      expPaths = cat(1,expPaths,{currItem});
    end
  end
  
  % Handle removing directories
  if ~isempty(expPaths) % There are directories to remove
    if strcmpi(cmd,'all') | strcmpi(cmd,'allquiet')  % Remove all
      rmpath(expPaths{:});
    else % Prompt user for path to remove
      % Ask the user which path to remove
      dir2rm=listgui(expPaths,'Path to remove...');
      
      % Remove the directory (empty if user hit cancel or closed GUI)
      if ~isempty(dir2rm)
        rmpath(dir2rm)
      end
    end
  else % No directories to remove
    if ~strcmpi(cmd,'allquiet') % Supress output on 'allquiet' case
      disp(sprintf('No directories in experiment %s to remove from path',currExp.Name));
    end
  end
end

% Modification History:
%
% $Log: rmscriptspath.m,v $
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
% Charles Michelich, 2001/10/25. Updated See Also section.
% Charles Michelich, 2001/08/13. original.  Adapted from rmexppath
% Charles Michelich, 2001/08/13. Finished implementation.
%                                Added recursive directory search
%                                Added 'all' and 'allquiet' option
% Charles Michelich, 2001/08/10. original
