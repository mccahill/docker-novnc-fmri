function fsizes = getfilesizes(files)
%GETFILESIZES Determine size of the specified file(s)
%  
%  fsizes = GETFILESIZES(files)
%
%    files is a cell array of filename(s) to get sizes of.
%    fsizes is a vector of the filesizes corresponding to each element of
%      files.  fsizes(n) = -1 if the size could not be determined for
%      files(n).
%
%  NOTE: MEX implementation uses 32-bit version of stat.
%
%  Example:
%  files = {'test1.txt','test2.txt'};
%  fsizes = getfilesizes(files);
%  if any(fsizes==-1),
%    missingFnames=strcat({sprintf('\n')},files(find(fsizes==-1)));
%    error(sprintf('Unable to read size of file(s):%s',[missingFnames{:}]))
%  end
%
%  See also DIR

% CVS ID and authorship of this code
% CVSId = '$Id: getfilesizes.m,v 1.5 2011/02/15 15:47:08 petty Exp $';
% CVSRevision = '$Revision: 1.5 $';
% CVSDate = '$Date: 2011/02/15 15:47:08 $';
% CVSRCSFile = '$RCSfile: getfilesizes.m,v $';

% Implemented as a MEX file also (faster)

% Warn user to build MEX the first time it is used.
persistent haveWarned
if isempty(haveWarned)
  warning('Using m-file version of getfilesizes().  Compile getfilesizes.c for better performance!');
  haveWarned = 1;
end

% Check input arguments.
if nargin ~= 1, error('GETFILESIZES requires 1 input argument.'); end
if nargout > 1, error('GETFILESIZES requires 0 or 1 output arguments.'); end
if ~iscellstr(files) | isempty(files),
  error('GETFILESIZES: files must be a non-empty cell array of strings!');
end

% Check if all files are in the same directory
fnames = cell(size(files));
allinsamedir = 1;
[commonpathstr,name,ext] = fileparts(files{1});
fnames{1} = [name ext];
for n=2:length(files(:))
  [pathstr,name,ext] = fileparts(files{n});
  fnames{n} = [name ext];
  if ~strcmp(commonpathstr, pathstr)
    allinsamedir = 0;
    clear('fnames');  % fnames is not complete, so make sure we don't use it accidentally.
    break
  end
end

% Initialize fsizes (-1 if it was not found)
fsizes = -ones(size(files));

if allinsamedir & length(files(:)) > 1
  % fast case 
  % Don't use this method for a single file because it is slow.
  dents = dir(commonpathstr);
  try
    % MATLAB 6.5 ismember returns ind.
    [tf,ind] = ismember(fnames,{dents.name});
  catch
    % Previous versions do not.
    tf = ismember(fnames,{dents.name});
    % Find location of each entry
    % TODO: Find faster solution?
    ind = zeros(size(tf)); % ind = 0 if it was not a member
    for n = find(tf)
      ind(n) = find(strcmp(fnames{n},{dents.name}));
    end
  end
  fsizes(tf) = [dents(ind(tf)).bytes];
else
  % slow case
  for n = 1:length(files(:))
    dent = dir(files{n});
    if ~isempty(dent)
      fsizes(n) = dent.bytes;
    end
  end
end

% Modification History:
%
% $Log: getfilesizes.m,v $
% Revision 1.5  2011/02/15 15:47:08  petty
% *** empty log message ***
%
% Revision 1.4  2005/02/03 16:58:33  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.3  2003/10/22 15:54:35  gadde
% Make some CVS info accessible through variables
%
% Revision 1.2  2003/06/16 18:27:15  michelich
% Added warning if not using MEX file.
%
% Revision 1.1  2003/04/18 22:03:07  michelich
% Initial version.
%
