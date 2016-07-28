function currExp = chexp(expName,expPath)
% CHEXP - Setup for experiment
%
%   Setup MATLAB for the experiment selected.  
%   The setup consists of:
%   (1) Add the Scripts directory for the current
%       experiment to the path
%   (2) Change directory to the experiment
%
%   chexp
%     Change to a current experiment using a GUI dialog
%     to select an experiment from the database
%
%   chexp(expName) or chexp expName
%     Change to experiment expName using database to
%     find path to experiment 
%
%   chexp(expName,expPath)
%     Change to experiment expName specifying path to 
%     experiment
%
%   chexp('clear') or chexp clear
%     Clear experiment related changes.  This consists of:
%     (1) Clear persistent record of current experiment 
%     (2) Remove all path entries referencing current experiment path
%
%   currExp = chexp('settings') or chexp settings
%     Return the stored information about the current experiment
%
% See Also: PWE, ADDSCRIPTSPATH, RMSCRIPTSPATH, RMEXPPATH

%   Note:
%    The path to the database is stored in the function findexp()

% Modes for use with other functions:
%
%   currExp = chexp('update',newExp)
%     Update the stored information about the current experiment
%     This can be used to add additional fields if desired.
%     NOTE: Do NOT use this to change the experiment (Name or Path). Use chexp.

% CVS ID and authorship of this code
% CVSId = '$Id: chexp.m,v 1.5 2005/02/03 16:58:32 michelich Exp $';
% CVSRevision = '$Revision: 1.5 $';
% CVSDate = '$Date: 2005/02/03 16:58:32 $';
% CVSRCSFile = '$RCSfile: chexp.m,v $';

persistent currentExperiment

% Initialize catch variables
emsg = '';
errorType = 0; % See catch comments for description
lasterr = '';

try
  % Handle input arguments
  error(nargchk(0,2,nargin));
  
  if nargin == 0, expName = ''; end % Set expName to empty if GUI mode desired
  
  % Handle each of the modes
  switch expName
  case 'clear'  % Clear the settings
    local_removelastexperiment(currentExperiment);
    if isempty(currentExperiment)  % Display feedback
      disp(sprintf('No record of current experiment.\n'));
    else
      disp(sprintf('Experiment "%s" settings removed from path.\n',currentExperiment.Name));
    end
    currentExperiment='';  % Set current experiment to empty
    
  case 'settings'   % Just display the settings
    % Don't display anything unless no output varables requested since this
    % may be used by other functions to get current experiment varables
    if nargout == 0
      if isempty(currentExperiment)
        disp(sprintf('No record of current experiment.\n'));
      else
        disp(sprintf('Current experiment "%s" is located at "%s"\n', ...
          currentExperiment.Name,currentExperiment.Path));
      end
    end
    
  case 'update'     % Update the currentExperiment structure
    newExp = expPath; % Copy second input variable (new structure)
    
    % Check if the passed experiment has the required fields:
    %  .Name  - Experiment Name
    %  .Path  - Experiment Path
    if ~isstruct(newExp) | ~isfield(newExp,'Name') | ~isfield(newExp,'Path')
      emsg = 'Not a valid experiment information structure!'; 
      errorType = 1; error(emsg); % Nothing has been changed, errorType 1
    end
    
    % Check that the experiment has not changed.  If it has, issue an 
    % error and instruct user to change using chexp.
    if strcmp(currentExperiment.Name,newExp.Name) & ...
        strcmp(currentExperiment.Name,newExp.Path)
      emsg = 'Experiment Name and Path have changed.\nUse chexp to change!'; 
      errorType = 1; error(emsg); % Nothing has been changed, errorType 1
    end 
    
    % Update currentExperiment structure
    currentExperiment=newExp;
    
  otherwise     % Experiment name passed or GUI 
    if nargin == 0 % If experiment not specified, chose with GUI
      [expPath,expName,emsg]=findexp;
      if isempty(expPath) % No path returned, something went wrong  
        if strcmp(emsg,'No experiment chosen')
          errorType = 2; error(emsg); % User abort and nothing has been changed, errorType 2
        else
          errorType = 1; error(emsg); % Nothing has been changed, errorType 1
        end
      end
    elseif nargin == 1 
      % If experiment specified, but path not specified, find in database 
      [expPath,expName,emsg]=findexp(expName);
      if isempty(expPath), 
        errorType = 1; error(emsg); % Nothing has been changed, errorType 1
      end
    end
    
    % Check that the expPath exists
    if isempty(dir(expPath))
      emsg=sprintf('Unable to access "%s"! Existence? Permissions?',expPath); 
      errorType = 1; error(emsg);
    end
    
    % Handle old experiment
    lastExperiment=currentExperiment; % Save data from last experiment
    local_removelastexperiment(currentExperiment); % Remove any changes from the last experiment
    
    % Set values for new experiment
    currentExperiment.Path = expPath;
    currentExperiment.Name = expName;
    
    % Add paths for current experiment
    pathtoadd = fullfile(currentExperiment.Path,'Scripts');
    if ~exist(pathtoadd,'dir')
      disp(sprintf('Unable to access "%s"!\n  This directory will not be added to the path.\n',pathtoadd));
    else
      addpath(pathtoadd);
    end
    
    % Change to base directory of experiment
    cd(currentExperiment.Path);
    
    % Print feedback
    if isempty(lastExperiment)
      disp(sprintf('Changed to experiment "%s", located at "%s"\n', ...
        currentExperiment.Name,currentExperiment.Path));
    else
      disp(sprintf('Changed from experiment "%s", located at "%s" \n        to experiment "%s" located at "%s" \n',...
        lastExperiment.Name,lastExperiment.Path,currentExperiment.Name,currentExperiment.Path));
    end
  end % End mode (expPath) switch
  
  % Set output argument if requested (Set returned current experiment)
  if nargout == 1, currExp = currentExperiment; end

catch
  if errorType == 2 % User cancelled with no settings changed   
    if isempty(currentExperiment)  % Display error and feedback
      disp(sprintf('User cancelled. No settings changed\n'));
    else
      disp(sprintf('User cancelled. Settings for current experiment "%s" unchanged.\n',currentExperiment.Name));
    end
    % Set output argument if requested (Set returned current experiment)
    if nargout == 1, currExp = currentExperiment; end
    
  elseif errorType == 1 % An error occurred, but nothing was changed, show appropriate message 
    if isempty(currentExperiment)  % Display error and feedback
      emsg=sprintf('%s\nNo settings changed',emsg);
    else
      emsg=sprintf('%s\nSettings for current experiment "%s" unchanged.',emsg,currentExperiment.Name);
    end

    % Set output argument if requested (Set returned current experiment)
    if nargout == 1, currExp = currentExperiment; end
    error(emsg)
    
  else              % All other errors
    currentExperiment = ''; % Reset the current experiment
    if isempty(emsg)
      if isempty(lasterr)
        emsg='An unidentified error occurred!';
      else
        emsg=lasterr;
      end
    end
    
    % Set output argument if requested (Set returned current experiment)
    if nargout == 1, currExp = currentExperiment; end
    error(emsg)
    
  end % End errorType
end % End catch

function local_removelastexperiment(experiment)
% Local function to remove any relvant changes from the last experiment
%

% Charles Michelich 2001/06/21 original
% Charles Michelich 2001/08/13 changed to remove all paths using rmexppath

% Remove the paths from the previous experiment
if ~isempty(experiment)
  %rmpath(fullfile(experiment.Path,'Scripts'));
  rmexppath('allquiet');
end

% Modification History:
%
% $Log: chexp.m,v $
% Revision 1.5  2005/02/03 16:58:32  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.4  2003/10/22 15:54:34  gadde
% Make some CVS info accessible through variables
%
% Revision 1.3  2002/11/14 00:53:53  michelich
% Use dir instead of exist to check for access to contents of directory (not
%   just listing privledges).
% Not all experiments have scripts directories, display a message instead
%   of issuing an error.
%
% Revision 1.2  2002/11/07 20:01:00  michelich
% Removed unnecessary check for empty expName returned by listgui
%
% Revision 1.1  2002/08/27 22:24:14  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2001/11/12. Corrected spelling in help section
% Charles Michelich, 2001/10/25. Added See Also section.
% Charles Michelich, 2001/08/22. Updated help comments.
% Charles Michelich, 2001/08/13. Changed to use rmexppath to remove all experiment paths
%                                Changed User Abort catch to return output if requested
%                                Added method to update currentExperiment structure
% Charles Michelich, 2001/06/21. original.
