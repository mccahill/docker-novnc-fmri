function cropmrexam(srsSpec,params,zoom)
%CROPMREXAM Crop an exam of images to a specified size
%
%   CROPMREXAM(srsSpec,outpath,params,zoom)
%
%   srsSpec   = file specifier indicating the MR exam to process
%   params    = a cell array of the readmr parameters (except fName)
%   zoom      = specifies dimensions and location of image to keep
%               format: [x0 y0 z0 xSz ySz zSz]
%                       where (x0,y0,z0) is the lowest slice number upper left corner
%                       and [xSz ySz zSz] are the new dimensions of the cropped series
%
%   With no input arguments, you are prompted to specify inputs graphically.
%
%   Note: Only volume and float image types are supported at this time.
%
%   Notes on output destination:
%       If srsSpec is:
%              '\\broca\data2\username\experiment\imageType\exam\run01\V*.img'
%       then all files in
%              '\\broca\data2\username\experiment\imageType\exam\run*\V*.img'
%       will be cropped and saved in
%              '\\broca\data2\username\experiment\imageType_small\exam\'
%
%       Example:
%       if srsSpec:
%              '\\broca\data2\michelich\workmem\raw\093098_01753\run01\V*.img'
%       then all files in
%              '\\broca\data2\michelich\workmem\raw\093098_01753\run*\V*.img'
%       will be cropped and saved in
%              '\\broca\data2\michelich\workmem\raw_small\093098_01753\'
%
%   See also READMR
%
%   Example:
%   >>cropmrexam('\\broca\data2\username\experiment\raw\exam\run01\V*.img',{128,128,12,'volume'},[33,33,1,64,64,12])
%

% CVS ID and authorship of this code
% CVSId = '$Id: cropmrexam.m,v 1.4 2005/02/03 16:58:38 michelich Exp $';
% CVSRevision = '$Revision: 1.4 $';
% CVSDate = '$Date: 2005/02/03 16:58:38 $';
% CVSRCSFile = '$RCSfile: cropmrexam.m,v $';

lasterr('');                    % Clear last error message
emsg='';                        % Error message string
p=[];                           % Pointer to progress bar

try
  if nargin == 0               % Handle GUI input of parameters
    [fullname,params]=readmrold('Params');                          % Request the user choose an input run
    if isempty(params)                                              % Check if user chose a file
      emsg='User abort while choosing file'; error(emsg);
    end
    if ~(strcmpi(params(4),'volume') | strcmpi(params(4),'float'))  % Check format immediately for user convenience
      emsg='Only volume and float formats are supported at this time.'; error(emsg);
    end
    
    readmr(fullname,params{:});  % Try reading one file to check if parameters are correct (readmr will display error)
    
    srsSpec=name2spec(fullname); % Generate series specifier
    
    if any([params{1,2}]< [128 128])                    % if images are smaller than 128x128
      defZoom = [1,1,1,params{1},params{2},params{3}];  % Use full size as default
    else
      defZoom = [33,33,1,64,64,params{3}];              % Otherwise use this
    end
    
    zoom=getzoom(defZoom,[1,1,1,params{1},params{2},params{3}]);      % Get zoom
    if isempty(zoom)
      emsg='User abort while entering zoom parameters'; error(emsg);
    end
    
  elseif nargin ~= 3 % Check number of args if not GUI input
    emsg=nargchk(3,3,nargin); error(emsg);
  end
  
  % Now process the files
  % Assumptions:  srsSpec  format => experiment\imageType\exam\runXX\V*.img
  %                        ex: srsSpec = \\broca\data2\michelich\nnet\raw\093098_01753\run01\V*.img
  %               outfile  format => experiement\imageType_small\
  %                        ex: outfile = \\broca\data2\michelich\nnet\raw_small\
  %                        NOTE: Automatically appends _small to ImageType
  
  [runname image_file image_ext]=fileparts(srsSpec);
  examname=fileparts(runname);
  imagetypename=fileparts(examname);
  
  examnameonly=examname(length(imagetypename)+2:length(examname));     % Find just the ExamNumber directory
  
  % Make output directories up to ExamNumber
  outpath=fullfile([imagetypename,'_small'],examnameonly);
  [status,emsg]=mkdir('',outpath);
  if status == 0, error(emsg); end
  
  % Find all of the run directories
  d=dir(fullfile(examname,'run*'));         % Find all files and directories that match run*
  isdir_i=find([d.isdir] == 1);             % Find indicies to directories
  rundir=sort(index({d.name},isdir_i)');    % Find directories
  
  nRuns=length(rundir);
  
  % Process the Runs
  p=progbar(sprintf('Cropping 0 of %d runs in %s...',nRuns,examname),[-1 0.6 -1 -1]);
  for n=1:length(rundir)
    if ~ishandle(p), emsg='User abort'; error(emsg); end
    progbar(p,(n-1)/nRuns,sprintf('Cropping %d of %d runs in %s...',n,nRuns,examname))
    
    curr_srsSpec = fullfile(examname,rundir{n},[image_file image_ext]);
    curr_outpath = fullfile(outpath,rundir{n},'');
    
    % Crop run
    cropmr(curr_srsSpec,curr_outpath,params,zoom);
    
    if ~ishandle(p), emsg='User abort'; error(emsg); end
    progbar(p,(n-1)/nRuns);
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
% $Log: cropmrexam.m,v $
% Revision 1.4  2005/02/03 16:58:38  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.3  2003/10/22 15:54:37  gadde
% Make some CVS info accessible through variables
%
% Revision 1.2  2003/06/30 16:35:39  michelich
% Use readmrold until function is updated for new readmr.
%
% Revision 1.1  2002/08/27 22:24:20  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2001/09/14. Changed one remaining readmr() to lowercase
% Charles Michelich, 2001/01/23. Changed function name to lowercase.
%                                Changed cropmr(), readmr() to lowercase.
% Francis Favorini,  1999/05/10. Use new form of readmr.
% Charles Michelich, 1999/05/04. Added GUI interface and automatic output decision.
% Charles Michelich, 1999/05/03. Found directories more efficiently.
%                                Added use of fullfile() to contruct file specifiers.
% Charles Michelich, 1999/11/19. Original
