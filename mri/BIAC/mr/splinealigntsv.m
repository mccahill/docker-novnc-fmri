function tsvOut=splinealigntsv(tsv,TR,order)
%splinealigntsv Temporally align slices within a TR using spline interpolation
%
%   tsvOut=splinealigntsv(tsv,TR)
%   tsvOut=splinealigntsv(tsv,TR,order)
%
%   tsv is a time series of volumes as read by READMR.
%   TR is the TR in seconds with which the data in tsv was acquired.
%   order specifies the acquisition order of slices as a vector of
%     slice numbers in chronological order.
%     The default is all odds first, then evens, each in ascending order.
%   tsvOut is the aligned version of tsv.
%
%   Examples
%     aligned=splinealigntsv(tsv,3);
%     aligned=splinealigntsv(tsv,1.5,[1:size(tsv,3)]);
%
%   See also SPLINEALIGNMR

% CVS ID and authorship of this code
% CVSId = '$Id: splinealigntsv.m,v 1.4 2005/02/03 16:58:44 michelich Exp $';
% CVSRevision = '$Revision: 1.4 $';
% CVSDate = '$Date: 2005/02/03 16:58:44 $';
% CVSRCSFile = '$RCSfile: splinealigntsv.m,v $';

% Check arguments and set defaults
tsvOut=[];
error(nargchk(2,3,nargin));
if ndims(tsv)~=4, error('TSV must be 4-dimensional.'); end
if length(TR)~=1 | ~isnumeric(TR) | ~isfinite(TR), error('TR must be a scalar.'); end
xSize=size(tsv,1);
ySize=size(tsv,2);
nSlices=size(tsv,3);
runLength=size(tsv,4);
offset=TR/nSlices;
if nargin<3 | isempty(order), order=[1:2:nSlices 2:2:nSlices]; end  % Default order is odds then evens.
if length(order)~=nSlices, error('order must have one entry for each slice.'); end

% Define TR times for the whole time series. All slices will be adjusted to these times.
lastTime=(runLength-1)*TR;
adjustedTimes=0:TR:lastTime;

% Loop through slices in acquired order (i.e., by time)
p=progbar(sprintf(' Interpolating 0 of %d slices... ',nSlices));
for i=2:nSlices
  if ~ishandle(p), error('User abort'); end
  progbar(p,sprintf('Interpolating %d of %d slices...',i,nSlices));
  sliceOffset=(i-1)*offset;
  sliceTimes=sliceOffset+adjustedTimes;
  sliceNum=order(i);                                        % The slice number acquired at this time
  for xi=1:xSize
    mat=squeeze(tsv(xi,:,sliceNum,:));                      % Time is in rows of mat
    imat=interp1(sliceTimes,mat',adjustedTimes,'*cubic');   % INTERP1 works on columns, so transpose mat
    tsv(xi,:,sliceNum,:)=imat';                             % Transpose imat and put back in run
  end
  if ~ishandle(p), error('User abort'); end
  progbar(p,i/nSlices);
end
delete(p);
tsvOut=tsv;

% Modification History:
%
% $Log: splinealigntsv.m,v $
% Revision 1.4  2005/02/03 16:58:44  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.3  2003/10/22 15:54:39  gadde
% Make some CVS info accessible through variables
%
% Revision 1.2  2003/10/15 15:51:49  michelich
% Updated help to use new readmr.
%
% Revision 1.1  2002/08/27 22:24:26  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2001/01/25. Changed function name to lowercase.
%                                Updated comments
% Francis Favorini,  2000/04/25. Added comments.
% Francis Favorini,  2000/02/22. Turned into function.
% Gregory McCarthy & Francis Favorini, 2000/02/04.   Original script.
