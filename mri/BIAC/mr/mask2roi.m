function roi=mask2roi(mask)
% mask2roi - Convert a 3D mask into a BIAC format ROI
%
% roi = mask2roi(mask)
%
%      mask is a 3d mask where element values not equal to 0
%              should be included in the ROI
%      roi is the BIAC format ROI corresponding to the mask input
%

% CVS ID and authorship of this code
% CVSId = '$Id: mask2roi.m,v 1.4 2005/02/03 16:58:39 michelich Exp $';
% CVSRevision = '$Revision: 1.4 $';
% CVSDate = '$Date: 2005/02/03 16:58:39 $';
% CVSRCSFile = '$RCSfile: mask2roi.m,v $';

% Check arguments
error(nargchk(1,1,nargin));
error(nargchk(0,1,nargout));
if ndims(mask) ~= 3 | ~(isnumeric(mask) | islogical(mask)) | ~all(isfinite(mask(:)))
  emsg = 'Mask must be a 3D array of finite numbers!'; error(emsg);
end

% Initialize output variables
slices = [];
indicies = {};

% Loop through each slice
for z = 1:size(mask,3)
  % Find indicies in current slice ~= 0
  currindex = find(mask(:,:,z));
  
  % If there were roi voxels in this slice,
  % include the slice in the roi
  if ~isempty(currindex)
    slices = [slices z];
    indicies = [indicies,{currindex}];
  end
end

% Place results in an roi structure
roi.baseSize = [size(mask)];
roi.index = indicies;
roi.slice = slices;

% Check to make sure that it is a valid roi
if ~isroi(roi)
  roi = [];
  emsg ='This roi is not valid'; error(emsg);
end

% Modification History:
%
% $Log: mask2roi.m,v $
% Revision 1.4  2005/02/03 16:58:39  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.3  2003/10/22 15:54:37  gadde
% Make some CVS info accessible through variables
%
% Revision 1.2  2002/09/25 22:40:53  michelich
% Allow logical masks (logical is not numeric as of MATLAB 6.5)
%
% Revision 1.1  2002/08/27 22:24:21  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2001/12/17. Added check that array contains only finite elements
% Charles Michelich, 2001/01/25. Changed isroi() to lowercase.
% Charles Michelich, 2000/08/07. original
