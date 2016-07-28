function tsv=readtsv(srsSpec,params,zoom,timePts)
%READTSV Read MR time series of volumes (TSV) from disk.
%
%   NOTE: This function is deprecated.  Use READMR instead!
%
%   tsv=readtsv;
%   tsv=readtsv(srsSpec,params);
%   tsv=readtsv(srsSpec,params,zoom);
%   tsv=readtsv(srsSpec,params,zoom,timePts);
%	
%   srsSpec is a file specifier indicating the series of MR volumes to process.
%   params is a cell array of the READMR parameters (except fName).
%   zoom specifies how to zoom in on the volume after reading from disk.
%     This will reduce the size of the series in memory.
%     The format is [xo yo xs ys], where (xo,yo) is the new upper left corner,
%     and [xs ys] is the new dimensions of the zoomed volume.
%     Default is full size of volume.  If empty, use default.
%   timePts is a vector of the time points to load.
%     Default is all time points.  If empty, use default.
%
%   tsv is the 4-D time series of volumes.
%
%   With no input arguments, you are prompted to specify the series and
%     parameters graphically.
%
%   Examples:
%   >>tsv=readtsv('\\broca\data2\study\raw\run01\V*.img',{128,128,12,'volume'});
%   >>tsv=readtsv('\\broca\data2\study\raw\run01\V*.img',{128,128,12,'volume'},[33 33 64 64]);

% CVS ID and authorship of this code
% CVSId = '$Id: readtsv.m,v 1.7 2005/02/03 16:58:42 michelich Exp $';
% CVSRevision = '$Revision: 1.7 $';
% CVSDate = '$Date: 2005/02/03 16:58:42 $';
% CVSRCSFile = '$RCSfile: readtsv.m,v $';

% If no args, just read the data using readmr.
if nargin == 0
  tsv = readmr;
  % If user did not cancel, just return the data itself.
  if ~isempty(tsv), tsv = tsv.data; end
  return
end

% Arguments specifed, mimic the old readtsv behavior.
emsg=nargchk(2,4,nargin); error(emsg);
if nargin<3 | isempty(zoom), zoom=[1 1 params{1:2}]; end
if nargin<4, timePts=[]; end

% --- Convert old-style readmr parameters. ---
% Confirm that the params are valid Volume or Float parameters.
if ~(iscell(params) & length(params)==4 & any(strcmpi(params{4},{'Volume','Float'})) & ...
    isnumeric(params{1}) & isnumeric(params{2}) & isnumeric(params{3}))
  error('Invalid params!  readtsv only support Volume and Float formats!');
end    
typespec = {params{4},[params{1:3}]};

% Get volume file names
if isempty(timePts)
  % No timePts specified, let readmr to the wildcard match.
  fNames = srsSpec;
else
  % timePts specifed, construct a filename based on the the time point to
  %   match the behavior of the old readtsv.
  % TODO: Remove this and just use the wildcard match sorted file order???
  fNames = cell(length(timePts),1);
  for t = 1:length(timePts)
    [filepath name ext] = fileparts(sprintf(strrep(strrep(srsSpec,'*','%04d'),'\','\\'),timePts(t)));
    fNames{t} = fullfile(filepath,[name ext]);
  end
end

% Zoom window
if zoom(1) == 1 & zoom(2) == params{1}
  xWin = '';  % All data included
else
  xWin=zoom(1):zoom(1)+zoom(3)-1; % Use selected window.
end  
if zoom(2) == 1 & zoom(4) == params{2}
  yWin = ''; % All data included
else
  yWin=zoom(2):zoom(2)+zoom(4)-1; % Use selected window.
end

% Read in the MR volumes
% Note: fNames takes care of selecting the correct timePts.
%       Since info struct is not returned, this effect on the info struct
%       of selecting the time points this way is unimportant.
tsv = readmr(fNames,typespec,{xWin,yWin,'',''});
tsv = tsv.data;

% Modification History:
%
% $Log: readtsv.m,v $
% Revision 1.7  2005/02/03 16:58:42  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.6  2003/10/22 15:54:38  gadde
% Make some CVS info accessible through variables
%
% Revision 1.5  2003/06/30 16:54:31  michelich
% Updated for readmr name change.
%
% Revision 1.4  2003/06/27 21:19:38  michelich
% Implemented using readmrtest.
%
% Revision 1.3  2003/03/24 14:27:07  gadde
% Back out accidental commit.
%
% Revision 1.1  2002/08/27 22:24:24  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2001/01/23. Changed function name to lowercase.
%                                Changed getzoom(), readtsv(), and readmr() to lowercase.
% Francis Favorini,  1999/05/06. Return [] when user cancels readmr.
% Francis Favorini,  1999/05/05. Remember all readmr params.
% Francis Favorini,  1999/04/23. Eliminated ti variable.
%                                If zoom is empty, use default.
% Francis Favorini,  1999/04/22. Initialize timePts argument in GUI mode.
% Francis Favorini,  1998/12/14. Added timePts argument.
% Francis Favorini,  1998/11/24.
