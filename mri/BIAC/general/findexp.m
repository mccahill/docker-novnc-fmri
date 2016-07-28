function [expPath,expName,emsg]=findexp(expName)
% FINDEXP - Find the experiment path for given experiment name
%
%  [expPath,expName,emsg]=findexp(expName)
%
%  Find the path of the given experiment name in the experiment database
%
%   Inputs:
%   expName - Name of experiment to find (e.g. 'visual.01') - Not case sensitive
%
%   Outputs:
%   expPath - experiment path for given experiment name  
%   expName - Name of experiment chosen (matches case in experiment database)
%   emsg    - If the user selects cancel or closed the GUI window, 
%             expPath = '', expName = '', and emsg = 'No experiment chosen'
%           - If an error occurs, expPath = '', expName = '', 
%             and emsg contains the error message.
%
%   If no experiment name is given, a GUI will prompt the user to select
%   an experiment from the database.
%
%   Note: If an experiment is listed in the database more than once, the
%         last entry is used.
%
%   Note: The GUI only lists experiment that the user has permssion to
%         access.  If permissions are changed after MATLAB is running,
%         type 'clear findexp' to reset the list of accessable experiments.
%
%   Note: If running on UNIX machines, assumes that CIFS/SMB shares are
%         mounted per the convention in UNC2UNIX.
%  
%   Example:
%   >> [expPath,expName,emsg]=findexp('visual.01');
%   >> [expPath,expName,emsg]=findexp;
%
% See Also: UNC2UNIX

% CVS ID and authorship of this code
% CVSId = '$Id: findexp.m,v 1.15 2008/03/17 19:44:18 gadde Exp $';
% CVSRevision = '$Revision: 1.15 $';
% CVSDate = '$Date: 2008/03/17 19:44:18 $';
% CVSRCSFile = '$RCSfile: findexp.m,v $';

% TODO: Add this to the comments once the ESC bug in listgui() has been resolved.
%    Note: Double clicking or pressing return in the GUI is equivalent to pressing OK
%          Pressing Esc in the GUI is equivalent to pressing Cancel
% TODO: Preserve cached experiment info more agressively on errors.

% Location of experiment databases (UNC Paths)
%expDB={'\\munin\data\daemon\inactive.txt','\\munin\data\daemon\experiments.txt'};
expDB={'\\munin\data\daemon\exp.txt','/mnt/munin/node.space/common/biac_dbs/exp.txt'};
if isunix, expDB=unc2unix(expDB); end % Convert to UNIX paths

% Struct to hold cached experiment information Fields:
%   expNames, expPath - cached experiment names & paths cell arrays
%   expNamesAccessible, expPathsAccessible - cached experiment names &
%                paths cell arrays for experiments user has access to.
%   date - cell array of cached expDB file time stamps
persistent cachedExpInfo

% Set up error catching variables
lasterr('');
emsg='';
try
  % Check inputs
  error(nargchk(0,1,nargin));

  % Check if cached experiment info is current
  if ~isempty(cachedExpInfo)
    % Check if the timestamp has changed on any of the files
    validExpInfo=1; filename=1;
    while (filename <= length(expDB)) & (validExpInfo == 1) & exist(expDB{filename},'file')
      d=dir(expDB{filename});
      if isempty(d),
        emsg=sprintf('Unable to access list of experiments (%s). %s',expDB{filename},emsg); error(emsg);
      end
      validExpInfo = strcmp(cachedExpInfo.date{filename},d.date);
      filename=filename+1;
    end
    % Clear the cached info if it is not valid
    if ~validExpInfo, cachedExpInfo = []; end
    % Clear unnesssary variables
    clear('validExpInfo','filename','d');
  end
  
  % Get experiment names and paths for each experiment's data
  if ~isempty(cachedExpInfo)
    % Cached info is valid, use it
    expNames = cachedExpInfo.expNames;
    expPaths = cachedExpInfo.expPaths;
  else
    % Read info from files
    expPaths={}; expNames={};
    for filename=1:length(expDB)
        if exist(expDB{filename},'file')
            [currExpNames,currExpPaths]=local_parseExperimentFile(expDB{filename});
            expNames = cat(1,expNames,currExpNames);
            expPaths = cat(1,expPaths,currExpPaths);
          % Cache file timestamps
            d=dir(expDB{filename});
            cachedExpInfo.date{filename} = d.date;
        end
    end
    % If an experiment is listed multiple times, use last entry!
    [uniqueNames,ii] = unique(lower(expNames));
    if length(uniqueNames) ~= length(expNames)
      % Only need to search for those names that were not unique
      toRemove = [];
      for n = setdiff(1:length(expNames),ii)
        if ~any(n == toRemove)
          expName_ii = find(strcmpi(expNames{n},expNames));
          toRemove = [toRemove; expName_ii(1:end-1)];
        end
      end

      % Remove duplicates from Names and Paths
      expNames(toRemove) = [];
      expPaths(toRemove) = [];
      clear toRemove n expName_ii
    end
    clear uniqueNames ii
    
    % Cache information
    cachedExpInfo.expNames=expNames;
    cachedExpInfo.expPaths=expPaths;
  end
  
  if nargin==0
    % Show GUI to chose experiment if no arguments    
      
    % Remove experiment paths the current user does not have access to.
    if isfield(cachedExpInfo,'expNamesAccessible')
      % Cached info is valid, use it
      expNames = cachedExpInfo.expNamesAccessible;
      expPaths = cachedExpInfo.expPathsAccessible;
    else
      % Cached copy has not been checked for access yet.
      cannotAccess=repmat(logical(0),size(expPaths));
      for n=1:length(expPaths)
        % dir returns empty if path cannot be accessed
        cannotAccess(n)=isempty(dir(expPaths{n})); % Comment out this line to disable exist check.
      end
      expNames(cannotAccess)=[]; expPaths(cannotAccess)=[];
      % Cache information
      cachedExpInfo.expNamesAccessible=expNames;
      cachedExpInfo.expPathsAccessible=expPaths;
    end
    
    % Sort by experiment name (case-insensitive)
    [junk,ii]=sort(lower(expNames));
    expNames=expNames(ii); expPaths=expPaths(ii);
    
    % Bring up GUI for user to select experiment name
    [expName,expName_ii]=listgui(expNames,'Choose an experiment ...');
    
    % Handle user cancel
    if isempty(expName)
      emsg='No experiment chosen'; error(emsg);
    end

    % Get corresponding experiment path
    expPath=expPaths{expName_ii};
  else
    % No GUI, just find the experiment

    % Check that experiment name passed is a string
    if ~ischar(expName)
      emsg='Experiment name must be a string'; error(emsg);
    end
    
    % Find matching experiment (case-insensitve)
    expName_ii = find(strcmpi(expName,expNames));
    
    % Handle no match & multiple matches.
    if isempty(expName_ii)
      emsg=sprintf('There is no experiment called "%s".',expName); error(emsg);
    elseif length(expName_ii) > 1
      emsg=sprintf('There is more than one experiment called "%s".  Duplicate removal not working!',expName); error(emsg);
    end  
    expName = expNames{expName_ii}; % Get correct case for experiment from database
    expPath = expPaths{expName_ii}; % Get corresponding experiment path
  end
catch
  expPath='';
  expName='';
  if isempty(emsg)
    if isempty(lasterr)
      emsg='An unidentified error occurred!';
    else
      emsg=lasterr;
    end
  end
  % Clear cached info unless user cancelled.
  if ~strcmp(emsg,'No experiment chosen'), cachedExpInfo=[]; end
end

% ------------------------------------------------------------
function [expNames,expPaths]=local_parseExperimentFile(filename)
% Parse experiments file
%
%   [expNames,expPaths]=local_parseExperimentFile(filename)
%
%           filename - file to parse
%           expNames - cell array of experiment names
%           expPaths - cell array of paths for each experiment
%
%   filename must have one line per experiment.  Each line must consist of
%   the base experiment path followed by a tab followed by the experiment
%   name.  The experiment path is constructed by concatenating the base
%   experiment path with the experiment name.
%
%   Lines starting with # are skipped

lasterr(''); emsg='';
try
  % Open experiment database
  [fid,emsg]=fopen(filename,'rt');
  if fid==-1
    emsg=sprintf('Unable to open list of experiments (%s). %s',filename,emsg); error(emsg);
  end
  
  expNames={};
  expPaths={};
  while 1
    line=fgetl(fid);
    if ~ischar(line), break; end
    if line(1) ~= '#'  % Skip lines starting with #
      % Find the base experiment path and the experiment name (tab delimited)
      parts = regexp(line,'\t','split');
      if parts{6} == '-1'
          servparts = regexp(parts{2},'\.','split');
          server = servparts{1};
          expbasepath = sprintf('\\\\%s\\%s\\%s',lower(server),lower(parts{3}),parts{4}(2:end));
      
          if expbasepath(end) == '\'
              expbasepath = expbasepath(1:end-1);
          end
      
        expName = char(parts(1));
        dirName = char(parts(5));
      
        expNames=cat(1,expNames,cellstr(expName));
        expPaths=cat(1,expPaths,cellstr([expbasepath,'\',dirName]));
      end
    end
  end
  fclose(fid);
  % Convert UNC paths to unix paths on unix machines.
  if isunix
    expPaths=unc2unix(expPaths);
  end
catch
  % Set return variables to empty
  expNames = {}; expPaths = {};
  if isempty(emsg)
    if isempty(lasterr)
      emsg='An unidentified error occurred!';
    else
      emsg=lasterr;
    end
  end
  if exist('fid','var'), if fid>2, fclose(fid); end, end
  error(emsg);
end

% GUI sizes from removed local function expName=local_chooseexp(expNames)
% These are just here for future reference if listgui() changes algorithms
% for sizing the GUI.  CRM 2001-09-27
%
% GUI element sizes
%listwidth=35;                           % Width of list in characters
%listheight=20;                          % Height of list in characters
%buttonwidth=10;                         % Width of button in characters
%buttonheight=2;                         % Height of button in characters
%figurewidth=listwidth;                  % Width of figure in characters
%figureheight=listheight+buttonheight+2; % Height of figure in characters

% Modification History:
%
% $Log: findexp.m,v $
% Revision 1.15  2008/03/17 19:44:18  gadde
% Move experiment databases to Fatt.
%
% Revision 1.14  2005/02/16 21:49:05  michelich
% Corrected comments in code on duplicate entry handling.
% Fixed bug in error handling of local_parseExperimentFile.
% M-Lint: Use isempty instead of length == 0.
%
% Revision 1.13  2005/02/03 20:05:24  michelich
% Remove diagnostic message accidentally commited in rev 1.11.
%
% Revision 1.12  2005/02/03 16:58:33  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.11  2004/11/12 16:19:48  michelich
% Correct error message.  Remove deprecated isstr call.
%
% Revision 1.10  2004/07/22 20:42:35  michelich
% Code cleanup.  Simplified logical and corrected comments.
%
% Revision 1.9  2003/10/22 15:54:35  gadde
% Make some CVS info accessible through variables
%
% Revision 1.8  2003/09/05 14:09:54  michelich
% Updated help.
%
% Revision 1.7  2003/08/14 15:27:22  michelich
% Moved experiment databases to huxley.
% Use last entry if an experiment is listed multiple times.
%
% Revision 1.6  2003/04/07 21:05:54  crm
% Use unc2unix for experiment databases
%
% Revision 1.5  2003/04/07 20:58:05  crm
% Added support for UNC paths on UNIX.
%
% Revision 1.4  2002/11/14 02:14:08  michelich
% Added note on caching
%
% Revision 1.3  2002/11/14 02:06:54  michelich
% Use dir instead of exist to check for access to contents of directory (not just listing privledges).
% Don't remove entries with experiment paths starting with \\Bristol\BIAC\Scans (no longer necessary).
% Added caching of experiment names and paths for increased performance.
%
% Revision 1.2  2002/11/13 14:48:10  michelich
% Added support for mulitple experiment databases.
% Remove entries with experiment paths starting with \\Bristol\BIAC\Scans
% Changed handling of dupication entries:
%   Warning if duplicate entries exist.
%   Error on duplicate entries if expName passed as a variable.
%   Both entries listed in GUI.
% Moved file parsing to local function.
% Skip lines starting with #
% Do exist check on Scripts subdirectory to exclude unaccessable experiments on SAN.
% Always set expName = '' on an error.
% Use experiment databases on Bristol.
%
% Revision 1.1  2002/08/27 22:24:15  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Revision History:
% Charles Michelich, 2001/09/27. Removed local function local_chooseexp().  Use listgui instead.
%                                Removed BUG and TODO comments related to local_chooseexp()
%                                Updated comments regarding multiple entries in the database. 
%                                Changed to only open experiments file once (use fseek to rewind)
%                                Added fclose and proper error passing to catch block
%                                Moved expName initialization output try-catch (for error before GUI sets expName)
% Charles Michelich, 2001/07/17. Fixed function description and added TODO section
%                                Exclude experiments from GUI which do not "exist"
%                                Added keyboard shortcuts for OK and Cancel
%                                Added support for double clicking
%                                Changed experiment name sort to be case-insensitive
% Charles Michelich, 2001/06/22. Take capitalization for expName from database rather
%                                than from the command line.
% Charles Michelich, 2001/06/21. original. extracted searching code from qastats2.
