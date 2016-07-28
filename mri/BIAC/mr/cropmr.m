function cropmr(srsSpec,outpath,params,zoom)
%CROPMR Crop a run of volume images to a specified size
%
%   CROPMR(srsSpec,outpath,params,zoom)
%
%   srsSpec   = file specifier indicating the series of MR images to process
%   outpath   = path of the output images
%   params    = a cell array of the READMR parameters (except fName)
%   zoom      = specifies dimensions and location of image to keep
%               format: [x0 y0 z0 xSz ySz zSz]
%                       where (x0,y0,z0) is the lowest slice number upper left corner
%                       and [xSz ySz zSz] are the new dimensions of the cropped series
%
%   Note: Only volume and float image types are supported at this time
%
%   With no input arguments, you are prompted to specify inputs graphically
%
%   See also READMR

%   Examples:
%   >>cropmr('\\broca\data2\study\raw\run01\V*','\\broca\data2\study\raw\Srun01\',{128,128,12,'volume'},[33,33,1,64,64,12])

% CVS ID and authorship of this code
% CVSId = '$Id: cropmr.m,v 1.5 2005/02/03 16:58:38 michelich Exp $';
% CVSRevision = '$Revision: 1.5 $';
% CVSDate = '$Date: 2005/02/03 16:58:38 $';
% CVSRCSFile = '$RCSfile: cropmr.m,v $';

% Note: Used fullfile() when writing images so last filesep on outpath is optional

lasterr('');  % Clear last error message
emsg='';      % Error message string
p=[];         % Pointer to progress bar

try
  if nargin == 0                                                      % Handle GUI input of parameters
    [fullname,params]=readmrold('Params');                            % Request the user choose an input run
    if isempty(params)                                                % Check if user chose a file
      emsg='User abort while choosing file'; error(emsg);
    end
    if ~(strcmpi(params(4),'volume') | strcmpi(params(4),'float'))    % Check format immediately for user convenience
      emsg='Only volume and float formats are supported at this time.'; error(emsg);
    end
    
    readmr(fullname,params{:}); % Try reading one file to check if parameters are correct (readMR will display error)
    
    srsSpec=name2spec(fullname);                        % Generate series specifier
    
    if any([params{1,2}]< [128 128])                    % if images are smaller than 128x128
      defZoom = [1,1,1,params{1},params{2},params{3}];  % Use full size as default
    else
      defZoom = [33,33,1,64,64,params{3}];              % Otherwise use this (full size in z-direction as default)
    end
    
    zoom=getzoom(defZoom,[1,1,1,params{1},params{2},params{3}]);    % Get zoom
    if isempty(zoom)
      emsg='User abort while entering zoom parameters'; error(emsg);
    end
    
    outpath=input('Please enter output path (No quotes): ','s');    % Get output path
    
  elseif nargin ~= 4    % Check number of args if not GUI input
    emsg=nargchk(4,4,nargin); error(emsg);
  end
  
  % Check input and output arguments
  if ~ischar(srsSpec) | isempty(dir(srsSpec))
    emsg='Invalid input file specifier (srsSpec)'; error(emsg);
  end
  if ~iscell(params) | length(params) ~= 4 | any(~isint([params{1:3}]))
    emsg='Please specify file parameters as a cell array of readmr parameters'; error(emsg);
  end
  if ~(strcmpi(params(4),'volume') | strcmpi(params(4),'float'))
    emsg='Only volume and float formats are supported at this time.'; error(emsg);
  end
  if length(zoom) ~= 6
    emsg='Incorrect number of elements in zoom'; error(emsg);
  end
  % Zoom parameters must be positive integers less than or equal to the image size and x & y size must be powers of 2
  if any(zoom < 0) | any(~isint(zoom)) | any(zoom(1:3)+zoom(4:6)-1 > [params{1:3}]) | any(~isint(log2(zoom(4:5))))
    emsg='Specified zoom parameters are invalid.'; error(emsg);
  end
  if nargout ~= 0
    emsg='Too many output arguments specified'; error(emsg);
  end
  
  % Make sure output directory exists (create it if it doesn't)
  if ~mkdir('',outpath), emsg=sprintf('Unable to create output directory "%s"!',outPath); error(emsg); end
  
  % Create vectors of voxels to keep
  x=zoom(1):zoom(1)+zoom(4)-1;
  y=zoom(2):zoom(2)+zoom(5)-1;
  z=zoom(3):zoom(3)+zoom(6)-1;
  
  % Find filenames to process
  inpath=fileparts(srsSpec);                       % Find the input file path
  d=dir(srsSpec);                                  % Find all files and directories that match the srsSpec
  notdir_i=find([d.isdir] == 0);                   % Find all of the files (eliminate directories)
  
  if isempty(notdir_i)                             % Check if there are any files to process
    emsg='No files to process'; error(emsg);
  end
  
  fNames=sort(index({d.name},notdir_i)');          % Put filenames to process in cell array
  
  nVols = length(fNames);
  
  % Crop files
  p=progbar(sprintf('Cropping 0 of %d volumes in %s...',nVols,inpath));
  for n=1:length(fNames)
    if ~ishandle(p), emsg='User abort'; error(emsg); end
    progbar(p,n/nVols,sprintf('Cropping %d of %d volumes in %s...',n,nVols,inpath))
    
    srs=readmr(fullfile(inpath,fNames{n}),params{:});   % Read MR data in
    writemr(fullfile(outpath,fNames{n}),srs(x,y,z));    % Write croped MR data out
    
    if ~ishandle(p), emsg='User abort'; error(emsg); end
    progbar(p,n/nVols);
  end
  delete(p)
  
catch                   % Display captured errors and delete progress bar if it exists
  if isempty(emsg)
    if isempty(lasterr)
      emsg='An unidentified error occurred!';
    else
      emsg=lasterr;
    end
  end
  if ishandle(p), delete(p); end
  error(emsg);
end

% Modification History:
%
% $Log: cropmr.m,v $
% Revision 1.5  2005/02/03 16:58:38  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.4  2003/10/22 15:54:37  gadde
% Make some CVS info accessible through variables
%
% Revision 1.3  2003/07/01 18:03:16  michelich
% Changed readmr and writemr to lowercase.
%
% Revision 1.2  2003/06/30 16:35:39  michelich
% Use readmrold until function is updated for new readmr.
%
% Revision 1.1  2002/08/27 22:24:20  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2001/01/23. Change function name to lowercase.
%                                Changed readmr() and readtsv() to lowercase
% Francis Favorini,  1999/05/10. Use new form of readmr.
% Charles Michelich, 1999/05/04. Output directory created if it doesn't already exist.
% Charles Michelich, 1999/05/03. Added check to eliminate directories in srsSpec and other error checking.
%                                Added progress bar and try-catch (adapted from readtsv written by F. Favorini).
%                                Added GUI input option (except outpath).
% Charles Michelich, 1999/11/19. Original

