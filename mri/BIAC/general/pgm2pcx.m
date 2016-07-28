function pgm2pcx(fileSpec)
%PGM2PCX  Convert PGM files to PCX files.
%
%   PGM2PCX(fileSpec);
%
%   fileSpec is a file specifier for the input files.
%     If fileSpec is a directory, *.PGM is assumed.
%
%   Files are written with a .PCX extension in the same directory
%     as the input files.
%
%   Example:
%   >>pgm2pcx('\\Broca\Data3\BIAC\exp.01\stimuli\pictures\*.pgm')

% CVS ID and authorship of this code
% CVSId = '$Id: pgm2pcx.m,v 1.3 2005/02/03 16:58:35 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:35 $';
% CVSRCSFile = '$RCSfile: pgm2pcx.m,v $';

% Check args
error(nargchk(1,1,nargin));

lasterr('');
emsg='';
try
  
p=[];

% Get file names
if exist(fileSpec,'dir')
  fPath=fileSpec;
  fileSpec=fullfile(fPath,'*.pgm');
else
  fPath=fileparts(fileSpec);
end
d=dir(fileSpec);
if isempty(d)
  emsg=sprintf('No files found matching "%s"!',fileSpec); error(emsg);
end
nFiles=length(d);

% Convert files
p=progbar(sprintf('Converting 0 of %d files...',nFiles));
for f=1:nFiles
  if ~ishandle(p), emsg='User abort'; error(emsg); end
  progbar(p,sprintf('Converting %d of %d files...',f,nFiles));
  if ~d(f).isdir
    [dummy,fName,fExt]=fileparts(d(f).name);
    [x,map]=pgmread(fullfile(fPath,[fName fExt]));
    imwrite(x,map,fullfile(fPath,[fName '.pcx']),'pcx');
  end
  if ~ishandle(p), emsg='User abort'; error(emsg); end
  progbar(p,f/nFiles);
end
delete(p);

catch
  if ishandle(p), delete(p); end
  if isempty(emsg)
    if isempty(lasterr)
      emsg='An unidentified error occurred!';
    else
      emsg=lasterr;
    end
  end
  error(emsg);
end

% Modification History:
%
% $Log: pgm2pcx.m,v $
% Revision 1.3  2005/02/03 16:58:35  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:36  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/08/27 22:24:17  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Francis Favorini, 1999/05/24.

