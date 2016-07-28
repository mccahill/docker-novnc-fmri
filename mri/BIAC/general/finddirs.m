function [dirs,depth] = finddirs(startdir,maxdepth)
% FINDDIRS Recursively search for directories
%
%     [dirs depth]= finddirs(startdir,maxdepth)
%
%     startdir - Path to search (included in dirs) (type: single string)
%     maxdepth - Maximum search depth (default = inf);
%     dirs     - Cell array of directories sorted descending alphabetically
%     depth    - Actual search depth (-1 if max depth reached with directories remaining)
%

% CVS ID and authorship of this code
% CVSId = '$Id: finddirs.m,v 1.4 2005/02/03 16:58:33 michelich Exp $';
% CVSRevision = '$Revision: 1.4 $';
% CVSDate = '$Date: 2005/02/03 16:58:33 $';
% CVSRCSFile = '$RCSfile: finddirs.m,v $';

% Check inputs and set defaults
error(nargchk(1,2,nargin))
if ~ischar(startdir) | size(startdir,1) ~= 1
  error('startDir must be a single line character array');
end
if ~exist(startdir,'dir')
  error(sprintf('Directory %s does not exist!',startdir));
end
if nargin == 1      % Default maximum search depth = inf
  maxdepth = inf;
end

% Replace / with \ on PC to be more robust
if strncmp(computer,'PC',2)
   startdir = strrep(startdir,'/','\');
end

% Directories at current search depth
currDirs = {startdir};

% Initialize variables
dirs = {startdir};    % Directories under startdir (including startdir)
depth = 0;            % Current depth in search

% Search until maximum number depth has been reached or all directories have been found
while depth < maxdepth & length(currDirs) > 0
  
  % Initialize the listing of next directories to search
  allSubDirs = {};
    
  % Loop through all of the directories at the current depth to look for subdirectories
  for n = 1:length(currDirs)
    
    % Extract current direcotory to look through
    currDir = currDirs{n};
    
    % Get listing of direcories
    subDirs = dir(currDir);  
    
    % Keep only directories other than . and ..
    isdir_i=find([subDirs.isdir] == 1 & ~strcmp({subDirs.name},'.') & ~strcmp({subDirs.name},'..'));
    subDirs = subDirs(isdir_i);
    
    % Only continue processing this branch if subdirectories exist
    if length(subDirs) > 0
      
      % Add a file separator to the end of the current directory (if not already there)
      if currDir(end) ~= filesep
        currDir = [currDir filesep];
      end
      
      % Add the fullpath path to directory
      subDirs = cellstr(cat(2,repmat(currDir,length(subDirs),1),char(subDirs.name)));
      
      % Add this to the list of all subdirectories at current search depth
      allSubDirs = cat(1,allSubDirs,subDirs);
    end
    
  end
  
  % Add this listing of all subdirectories to the full list of directories
  dirs = cat(1,dirs,allSubDirs);
  
  % Make the current subdirectories the next directories to search
  currDirs = allSubDirs;
  
  % Increment search depth counter
  depth = depth+1;
  
end

if length(currDirs) > 0
    % Maximum search depth was reached without returning all directories
    depth = -1;
end

% Sort output directories alphbetically
dirs = sort(dirs);

% Return number of depths deep searched
%disp(sprintf('Searched %d levels deep',depth))

% Modification History:
%
% $Log: finddirs.m,v $
% Revision 1.4  2005/02/03 16:58:33  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.3  2004/11/12 16:19:19  michelich
% Correct error message.
%
% Revision 1.2  2003/10/22 15:54:35  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/08/27 22:24:14  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2001/09/27. Set search depth to -1 if directories remain when maxdepth reached.
%                                Replace / with \ in startdir with using a PC to be more robust if user
%                                types wrong path separator (from fullfile.m)
% Charles Michelich, 2000/07/19. Added return variable for search depth
% Charles Michelich, 2000/07/12. original
