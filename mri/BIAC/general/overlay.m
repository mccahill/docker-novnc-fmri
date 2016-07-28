function b=overlay(base,overlay,baseMap,overlayMap,mask,fullScale)
%OVERLAY Overlay one image over another using specified colormaps.
%
%       OVERLAY(base,overlay,baseMap,overlayMap,mask);
%       OVERLAY(base,overlay,baseMap,overlayMap,mask,fullScale);
%
%         base is the base image.
%         overlay is the overlay image.
%         baseMap is the colormap for the base image.
%         overlayMap is the colormap for the overlay image.
%         mask is a vector of indices into the overlay that
%           specifies which overlay pixels to show.
%         fullScale determines whether to scale the overlay
%           based on all pixels in the overlay image, or just
%           the ones being overlaid (1=use full overlay,
%           0=use masked overlay).  Default is 0.
%
%         The two images should be the same size.
%         The two colormaps shouldn't have to more than 256 entries combined.
%
%         Example:
%         >>overlay(b,o,gray(128),jet(128),find(o>1.5))

% CVS ID and authorship of this code
% CVSId = '$Id: overlay.m,v 1.4 2005/02/03 17:16:47 michelich Exp $';
% CVSRevision = '$Revision: 1.4 $';
% CVSDate = '$Date: 2005/02/03 17:16:47 $';
% CVSRCSFile = '$RCSfile: overlay.m,v $';

if (nargin<6), fullScale=0; end

b=normaliz(base,[1 length(baseMap)]);
if fullScale
  o=normaliz(overlay,[length(baseMap)+1 length(baseMap)+length(overlayMap)]);
  b(mask)=o(mask);
else
  o=normaliz(overlay(mask),[length(baseMap)+1 length(baseMap)+length(overlayMap)]);
  b(mask)=o;
end
if nargout==0
   imshow(b',[baseMap; overlayMap]);
end

% Modification History:
%
% $Log: overlay.m,v $
% Revision 1.4  2005/02/03 17:16:47  michelich
% M-lint: Add missing commas.
%
% Revision 1.3  2005/02/03 16:58:34  michelich
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
% Francis Favorini, 1997/01/21. Added fullScale parameter.
% Francis Favorini, 1996/10/18.

