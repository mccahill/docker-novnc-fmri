function newroi=roigrow(oldroi,srs,limits,imgWin)
%ROIGROW Add to ROI for MR series in overlay2 window.
%
%   newroi=roigrow(oldroi);
%   newroi=roigrow(oldroi,srs,limits);
%   newroi=roigrow(oldroi,srs,limits,imgWin);
%
%   oldroi is the ROI to grow.
%   srs is 0 for the base series, 1 for overlay 1, 2 for overlay 2 and
%     indicates which series the limits apply to.
%   limits is [min max] of raw pixel values to include in ROI.
%     [] means no limits.
%   imgWin is the handle of the overlay window (default = gcf)
%
%   See also ROIDEF, ROICOORDS, ROISTATS.

% CVS ID and authorship of this code
% CVSId = '$Id: roigrow.m,v 1.4 2005/02/03 16:58:43 michelich Exp $';
% CVSRevision = '$Revision: 1.4 $';
% CVSDate = '$Date: 2005/02/03 16:58:43 $';
% CVSRCSFile = '$RCSfile: roigrow.m,v $';

% IMPORTANT NOTE: This function should ensure the following:
% 1) Each vector of indices in roi.index is sorted (ascending).
% 2) Each vector of indices is a column vector.
% 3) roi.slice is a row vector.
% 4) The order and orientation of roi.index corresponds to roi.slice.
% However, roi.slice is not sorted (currently).
% Same applies to roidef.

% Process arguments
if nargin==1
  srs=0;
  limits=[];
elseif nargin==3 | nargin==4
  if ~isempty(srs) & (~isnumeric(srs) | srs<0 | srs>2)
    error('srs must be 0, 1 or 2!');
  end
  if ~isempty(limits) & (~isnumeric(limits) | length(limits)~=2 | limits(1)>=limits(2))
    error('limits must be [min max]!');
  end
else
  error('Incorrect number of arguments!');
end
if nargin < 4
    imgWin = gcf;  % Set overlay window to current figure by default
end
if ~ishandle(imgWin) % Check handle
    error('imgWin is not a valid handle!');
end


if isempty(limits)
  roi=roidef(0,[],imgWin);
else
  roi=roidef(srs,limits,imgWin);
end
if isempty(roi)
  newroi=oldroi;
else
  if ~isequal(roi.baseSize,oldroi.baseSize)
    errordlg('ROI addition must be based on same size series as original.');
    return;
  end
  newroi=roiunion(oldroi,roi);
end

% Modification History:
%
% $Log: roigrow.m,v $
% Revision 1.4  2005/02/03 16:58:43  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.3  2003/10/22 15:54:39  gadde
% Make some CVS info accessible through variables
%
% Revision 1.2  2002/10/25 14:21:02  michelich
% Merged changes for advanced ROI dialog box made by Jimmy Dias 2001/11/07.
% - Added option to pass overlay2 handle (for advanced ROI drawing dialog box).
% - if limits are empty, roidef called with default values and overlay figure handle.
%
% Revision 1.1  2002/08/27 22:24:25  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2001/01/25. Changed function name to lowercase.
%                                Changed overlay2(), roidef(), and roiunion() to lowercase
%                                Updated case of See also functions to uppercase.
% Francis Favorini,  2000/05/05. Fixed bug: was using ~= instead of isequal to compare baseSizes.
%                                Use roiunion.
% Francis Favorini,  2000/04/10. Added comments.
% Francis Favorini,  1999/10/12. Fixed bug when growing from or by 1 pixel ROI.
% Francis Favorini,  1998/10/14. Return newroi=oldroi when ROI is not actually grown.
% Francis Favorini,  1998/09/01. Properly handle no limits.
% Francis Favorini,  1998/08/25. Spun off from roidef.
