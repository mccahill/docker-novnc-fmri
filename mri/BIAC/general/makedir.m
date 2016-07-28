function varargout=makedir(dirName)
%MAKEDIR Create a directory and any parents that don't exist.
%
%   makedir(dirName);
%   status=makedir(dirName);
%   [status,emsg]=makedir(dirName);
%
%   dirName is the directory to create.
%   status is 0 on error, 1 if directory was created,
%     2 if directory already existed.
%   emsg contains any error message.
%
%   See also MKDIR.

% CVS ID and authorship of this code
% CVSId = '$Id: makedir.m,v 1.4 2005/02/03 16:58:34 michelich Exp $';
% CVSRevision = '$Revision: 1.4 $';
% CVSDate = '$Date: 2005/02/03 16:58:34 $';
% CVSRCSFile = '$RCSfile: makedir.m,v $';

% TODO: Use isrelpath/fileroot.

% Check args
error(nargchk(1,1,nargin));
dirName=trim(dirName);
if ~ischar(dirName) | isempty(dirName), error('Please supply a directory name.'); end
status=2;
emsg='';

if ~exist(dirName,'dir')
  % Add trailing filesep
  seps=findstr(dirName,filesep);
  if isempty(seps) | ~strcmp(dirName(seps(end):end),filesep)
    seps=[seps length(dirName)+1];
    dirName=strcat(dirName,filesep);
  end
  
  % Find "root" directory
  root='';
  if strncmp(computer,'PC',2)
    if length(dirName)>1 & strcmp(dirName(1:2),'\\')
      % UNC directory '\\machine\share\'
      if length(seps)>3
        root=dirName(1:seps(4));
        seps(1:3)=[];
      end
    elseif dirName(1)=='\'
      % No drive letter '\'
      root='\';
    elseif length(dirName)>2 & isletter(dirName(1)) & dirName(2)==':' & dirName(3)=='\'
      % Drive letter 'C:\'
      root=dirName(1:3);
    end
  elseif isunix
    if dirName(1)=='/'
      root='/';
    end
  end
  relative=isempty(root);
  if relative
    % Relative path
    seps=[0 seps];
  end
  
  % Create directories
  for s=1:length(seps)-1
    d=dirName(seps(s)+1:seps(s+1)-1);
    f=fullfile(root,d);
    if ~exist(f,'dir')
      if strncmp(computer,'PC',2)
        % BUG: MATLAB's mkdir doesn't properly detect errors when making the dir
        try
          [status,emsg]=dos(['mkdir "' f '"']);
        catch
          % Above dos call will fail if working dir is a UNC
          oldDir=pwd;
          cd(getenv('windir'));                  % Should always be safe?
          if relative
            % f is relative to oldDir
            [status,emsg]=dos(['mkdir "' fullfile(oldDir,f) '"']);
          else
            [status,emsg]=dos(['mkdir "' f '"']);
          end
          cd(oldDir);
        end
        if isempty(emsg)
          status=1;
        else
          emsg=['Cannot make directory "' f '". ' emsg];
          status=0;
        end
      else
        [status,emsg]=mkdir(root,d);
      end
    end
    root=f;
  end % for s
end % if ~exist

if nargout==0
  error(emsg);
else
  varargout{1}=status;
  varargout{2}=emsg;
end

% Modification History:
%
% $Log: makedir.m,v $
% Revision 1.4  2005/02/03 16:58:34  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.3  2004/08/05 20:30:39  gadde
% Set status to zero on DOS error.
%
% Revision 1.2  2003/10/22 15:54:36  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/08/27 22:24:16  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2001/06/29. Added semicolon for non-PC case to supress display of status and emsg
% Charles Michelich, 2001/01/23. Changed function name to lowercase
%                                Changed fileroot() and isrelpath() to lowercase.
% Francis Favorini,  2000/03/06. Fix bug with creating relative path when working directory is a UNC.
% Francis Favorini,  2000/02/22. Handle case on PC where working directory is a UNC.
% Francis Favorini,  1999/05/03.
