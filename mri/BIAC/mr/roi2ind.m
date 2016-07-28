function ind=roi2ind(roi)
% roi2ind - Convert a BIAC format ROI into linear indicies
%
% ind=roi2ind(roi)
%
%      roi is the BIAC format ROI to convert
%      ind is a vector of the linear indicies of the voxels contained
%             in the roi into a matrix of size roi.baseSize.
%
% See also ROI2MASK, MASK2ROI, ISROI

% CVS ID and authorship of this code
% CVSId = '$Id: roi2ind.m,v 1.4 2005/02/03 16:58:42 michelich Exp $';
% CVSRevision = '$Revision: 1.4 $';
% CVSDate = '$Date: 2005/02/03 16:58:42 $';
% CVSRCSFile = '$RCSfile: roi2ind.m,v $';

% Check arguments
error(nargchk(1,1,nargin));
error(nargchk(0,1,nargout));
if length(roi) ~= 1
  emsg = 'Only one roi can be processed at a time!'; error(emsg);
end
if ~isroi(roi)
  emsg = 'ROI is not a valid BIAC format roi!'; error(emsg);
end

% Determine number of voxels in ROI in each slice
roivoxelsinslice = cellfun('length',roi.index);

% Initialize index output
ind = zeros(sum(roivoxelsinslice),1);

% Determine number of voxels in-plane
ninplanevoxels = prod(roi.baseSize(1:2));

% Initialize the output array index to the first free element
currPt = 1;

% Loop through each slice in the roi
for n = 1:length(roi.index)
  % Add an offset to each index for the current slice and store the results
  ind(currPt:currPt+roivoxelsinslice(n)-1) = roi.index{n}+(roi.slice(n)-1).*ninplanevoxels;

  % Update the output array index to the next free element
  currPt = currPt+roivoxelsinslice(n);
end

% Modification History:
%
% $Log: roi2ind.m,v $
% Revision 1.4  2005/02/03 16:58:42  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.3  2003/10/22 15:54:38  gadde
% Make some CVS info accessible through variables
%
% Revision 1.2  2002/11/03 03:45:41  michelich
% Updated comments
%
% Revision 1.1  2002/11/03 03:41:58  michelich
% Initial version. Based on private version coded 2000-08-09.
%
