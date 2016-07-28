function [h_axReturned,h_corReturned,h_sagReturned]=orthooverlay2(base,baseHeaderInfo,over1,over2,overlay2params)
% ORTHOOVERLAY2 - Load all three orientations of a srs and overlay into 3 overlay2 windows
%
%   orthooverlay2(base,baseHeaderInfo,over1,over2,overlay2params)
%   [h_ax,h_cor,h_sag]=orthooverlay2(base,baseHeaderInfo,over1,over2,overlay2params)
%
%   base is the base image.
%   over1 is the first overlay image, possibly empty.
%   over2 is the second overlay image, possibly empty.
%   baseHeaderInfo is a cell array containing {slicePlane, voxelSize} where
%     slicePlane is the slice plane of the input series ('axial','coronal','sagittal').
%       Only the first letter is checked, and case is insignificant.
%       All three images must be in the same orientation
%     voxelSize is a three element vector of the voxel size in the current orientation.
%       All three elements must be the same units. 
%       This is the voxelSize of the base image!
%   overlay2params is a cell array of the overlay2 parameters (except base, over1, over2)
%     See overlay2 for help.
%
%   Notes:
%   The images may not be in the desired orientation depending on the slice order 
%   (i.e. S to I vs I to S).  Use flipdim() to correct the orientation as desired.
%   See 2nd example.
%
%   The Montage and TIFF buttons in overlay2 do NOT work properly if the voxels are not isotropic!
%
%   The first three dimensions of images must have lengths > 0 (i.e. no single slice data)
%
%   Examples:
%   >> base=readmr; o1=readmr; o2=readmr;                                  % Axial scans collected S to I
%   >> base=flipdim(readmr,3); o1=flipdim(readmr,3); o2=flipdim(readmr,3); % Axial scans collected S to I
%   >> orthooverlay2(base,{'a',[0.9375,0.9375,5.0]},o1,o2)
%   >> orthooverlay2(base,{'a',[0.9375,0.9375,5.0]},o1,o2, ...
%        {gray(192),redpos(16),blueneg(16), [50 500], [2.5 5], [-5 -2.5]});

% CVS ID and authorship of this code
% CVSId = '$Id: orthooverlay2.m,v 1.6 2005/02/03 19:16:27 michelich Exp $';
% CVSRevision = '$Revision: 1.6 $';
% CVSDate = '$Date: 2005/02/03 19:16:27 $';
% CVSRCSFile = '$RCSfile: orthooverlay2.m,v $';

% TODO: Add ability to return fused images instead of just opening GUIs
% TODO: Add ability to overlay different base and overlay orientations
% TODO: Add ability to overlay base images with more slices (but same imaging volume) than overlays
% TODO: Add ability for overlays to be different sizes in-plane

% Check inputs
error(nargchk(2,5,nargin))
% Check outputs
if all(nargout ~= [0 3])
  error('Must have 0 or 3 output arguments!');
end

% Handle defaults
if nargin < 3, over1 = []; end
if nargin < 4, over2 = []; end
if nargin < 5, overlay2params = {}; end

% Check input images 
if ndims(base) ~= 3, error('base must have 3 dimensions!'); end
if any([size(base,1) size(base,2) size(base,3)] == 1)
  error('Size of first three dimensions of base must be > 0 (No single slice data)!');
end
if ~isempty(over1), 
  if size(base,3) ~= size(over1,3)
    error('base and over1 must have the same number of slices!');
  end
  if any([size(over1,1) size(over1,2) size(over1,3)] == 1)
    error('Size of first three dimensions of over1 must be > 0 (No single slice data)!');
  end 
end
if ~isempty(over2)
  if size(base,3) ~= size(over2,3)
    error('base and over2 must have the same number of slices!');
  end
  if any([size(over2,1) size(over2,2) size(over2,3)] == 1)
    error('Size of first three dimensions of over2 must be > 0 (No single slice data)!');
  end 
end
if ~isempty(over1) & ~isempty(over2)
  if any(size(over1) ~= size(over2))
    error('over1 and over2 must be the same size!');
  end
end

% Extract any necessary header information (handle different formats)
if iscell(baseHeaderInfo)
  % Header info passed as a cell array
  if ~(isequal(size(baseHeaderInfo) == [1 2]) | isequal(size(baseHeaderInfo) == [2 1]))
    error('baseHeaderInfo must be a cell array with two elements!')
  end
  % Extract relevant parameters
  slicePlane = baseHeaderInfo{1};
  voxelSize = baseHeaderInfo{2};
  
  if ~(isequal(size(voxelSize) == [1 3]) | isequal(size(voxelSize) == [3 1]))
    error('voxelSize must be a 3 element vector!');
  end
else
  % Header info not passed using a supported format
  error('baseHeaderInfo must be a cell array with two elements!');
end

if ~isempty(over1) | ~isempty(over2)
  % Interpolate the overlay to the base image size in-plane (if necessary)
  scale=[size(base,1)/size(over1,1), size(base,2)/size(over1,2), 1];
  if scale(1) ~= scale(2)
    % Warn user if there are different scale factors in x & y to avoid
    % inadvertant mistakes
    warning('Interpolation factor different in x & y dimensions!  Did you really mean to do this???');
  end
  
  if any(scale~=1)
    % Scale overlays only (assumes over1 & over2 are the same size!)
    if ~isempty(over1)
      over1=scale3(over1,scale(1),scale(2),scale(3));
    end
    if ~isempty(over2)
      over2=scale3(over2,scale(1),scale(2),scale(3));
    end
  end
end

% Reorient the images
[base_ax,base_cor,base_sag]=orthosrs(base,slicePlane);
if ~isempty(over1)
  [over1_ax,over1_cor,over1_sag]=orthosrs(over1,slicePlane);
else
  over1_ax=[]; over1_cor=[]; over1_sag=[];
end
if ~isempty(over2)
  [over2_ax,over2_cor,over2_sag]=orthosrs(over2,slicePlane);
else
  over2_ax=[]; over2_cor=[]; over2_sag=[];
end

% Bring up a showsrs for each
overlay2(base_ax,over1_ax,over2_ax,overlay2params{:});
h_ax=gcf;
overlay2(base_cor,over1_cor,over2_cor,overlay2params{:});
h_cor=gcf;
overlay2(base_sag,over1_sag,over2_sag,overlay2params{:});
h_sag=gcf;

% Set title to orientation and turn off title numbering so 
% that title appears on task bar (in Windows)
% Number all views with the figure number of the axial showsrs
set(h_ax,'Name',sprintf('%d-Axial Overlay Window',h_ax),'NumberTitle','Off');
set(h_cor,'Name',sprintf('%d-Coronal Overlay Window',h_ax),'NumberTitle','Off');
set(h_sag,'Name',sprintf('%d-Sagittal Overlay Window',h_ax),'NumberTitle','Off');

% Set the proper DataAspectRatio based on the voxel size
if upper(slicePlane(1))=='A'
  voxSzAx = voxelSize;
  voxSzCor = [voxelSize(1),voxelSize(3),voxelSize(2)];
  voxSzSag = [voxelSize(2),voxelSize(3),voxelSize(1)];
elseif upper(slicePlane(1))=='C'
  voxSzAx =  [voxelSize(1),voxelSize(3),voxelSize(2)]; 
  voxSzCor = voxelSize; 
  voxSzSag = [voxelSize(3),voxelSize(2),voxelSize(1)];
elseif upper(slicePlane(1))=='S'
  voxSzAx =  [voxelSize(3),voxelSize(1),voxelSize(2)];
  voxSzCor = [voxelSize(3),voxelSize(2),voxelSize(1)];
  voxSzSag = voxelSize;
else
  error('Unknown slice plane!');
end
set(findobj(h_ax,'Tag','ImageAxes'),'DataAspectRatio',voxSzAx([2 1 3]));
set(findobj(h_cor,'Tag','ImageAxes'),'DataAspectRatio',voxSzCor([2 1 3]));
set(findobj(h_sag,'Tag','ImageAxes'),'DataAspectRatio',voxSzSag([2 1 3]));

% Disable the tiff and montage buttons for any overlay2 windows that do not
% have square voxels in-plane
if diff(voxSzAx(1:2)) ~= 0, 
  set(findobj(h_ax,'Tag','TIFFButton'),'Enable','off');
  set(findobj(h_ax,'Tag','MontageButton'),'Enable','off');
end
if diff(voxSzCor(1:2)) ~= 0, 
  set(findobj(h_cor,'Tag','TIFFButton'),'Enable','off');
  set(findobj(h_cor,'Tag','MontageButton'),'Enable','off');
end
if diff(voxSzSag(1:2)) ~= 0, 
  set(findobj(h_sag,'Tag','TIFFButton'),'Enable','off');
  set(findobj(h_sag,'Tag','MontageButton'),'Enable','off');
end

% Assign outputs if requested
if nargout > 0
  h_axReturned=h_ax;
  h_corReturned=h_cor;
  h_sagReturned=h_sag;
end

% Modification History:
%
% $Log: orthooverlay2.m,v $
% Revision 1.6  2005/02/03 19:16:27  michelich
% Changed argument checking to be more clear and robust.
%
% Revision 1.5  2005/02/03 16:58:40  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.4  2003/10/22 15:54:37  gadde
% Make some CVS info accessible through variables
%
% Revision 1.3  2002/09/10 21:15:39  michelich
% Bug Fix: Scale factor was calculated incorrectly if in-plane overlay
%   size was not equal.
% Changed difference in in-plane scale factor to a warning.
%
% Revision 1.2  2002/09/06 22:31:24  michelich
% Corrected number of input arguements check
%
% Revision 1.1  2002/08/27 22:24:22  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2002/01/14. Fixed bug in Sagittal to Axial voxel size conversion.
% Charles Michelich, 2001/12/04. Added ability to return handles to overlay windows
% Charles Michelich, 2001/09/24. Added disabling of TIFF and Montage buttons in overlay2 windows
%                                  if voxels are not square in-plane.  The TIFF and Montage features
%                                  of overlay2 do respect the dataAspectRatio.
% Charles Michelich, 2001/09/22. Added check for empty array before interpolating.
% Charles Michelich, 2001/09/21. original. modified from orthoshowsrs
%                                Changed to pass overlay2 parameters in a cell array