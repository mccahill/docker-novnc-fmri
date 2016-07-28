function mask=roi2mask(roi)
% roi2mask - Convert a BIAC format ROI into a 3D mask
%
% mask = roi2mask(roi)
%
%      roi is the BIAC format ROI to convert
%      mask is a 3d logical mask where element values equal to 1
%              for each voxel in the ROI and 0 elsewhere
%
% See also ROI2IND, MASK2ROI, ISROI

% CVS ID and authorship of this code
% CVSId = '$Id: roi2mask.m,v 1.6 2005/02/22 20:02:15 michelich Exp $';
% CVSRevision = '$Revision: 1.6 $';
% CVSDate = '$Date: 2005/02/22 20:02:15 $';
% CVSRCSFile = '$RCSfile: roi2mask.m,v $';

% Check arguments
error(nargchk(1,1,nargin));
error(nargchk(0,1,nargout));
if length(roi) ~= 1
  emsg = 'Only one roi can be processed at a time!'; error(emsg);
end
if ~isroi(roi)
  emsg = 'ROI is not a valid BIAC format roi!'; error(emsg);
end

% Initialize mask 
% (use repmat instead of false for pre-MATLAB 6.5 compatibility)
mask = repmat(logical(0), roi.baseSize);

% Determine number of voxels in-plane
ninplanevoxels = prod(roi.baseSize(1:2));

% Loop through each slice in the roi
for n = 1:length(roi.index)
  % Set voxels in roi to 1 
  % Note: An offset to the current slice is added to each index
  mask(roi.index{n}+(roi.slice(n)-1).*ninplanevoxels)=1;
end

% Modification History:
%
% $Log: roi2mask.m,v $
% Revision 1.6  2005/02/22 20:02:15  michelich
% Remove MATLAB version dependency.  repmat performance is approximately the
% same as using false and avoids the MATLAB version check.
%
% Revision 1.5  2005/02/03 16:58:42  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.4  2003/10/22 15:54:38  gadde
% Make some CVS info accessible through variables
%
% Revision 1.3  2003/01/14 04:15:43  michelich
% Use false() to initialize array using MATLAB 6.5 & later
%
% Revision 1.2  2002/11/03 03:48:21  michelich
% Changed output mask to a logical mask.
% Simplified code.
%
% Revision 1.1  2002/08/27 22:24:24  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2001/01/25. changed isroi() to lowercase
% Charles Michelich, 2000/08/07. original
