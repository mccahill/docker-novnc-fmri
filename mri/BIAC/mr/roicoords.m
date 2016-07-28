function [varargout]=roicoords(roi)
%ROICOORDS Return X,Y,Z coords for specified ROI.
%
%   [x,y,z]=roicoords(roi);
%   coords=roicoords(roi);
%
%   roi is an ROI as defined by isroi.
%   x, y, z are column vectors of the appropriate coordinates.
%   coords is the matrix [x y z].
%
%   Examples:
%   >>load D:\roi\mfg.roi -mat
%   >>coords=roicoords(roi);
%
%   See also ROIDEF, ROIGROW, ROISORT, ROISTATS, ISROI.

% CVS ID and authorship of this code
% CVSId = '$Id: roicoords.m,v 1.3 2005/02/03 16:58:43 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:43 $';
% CVSRCSFile = '$RCSfile: roicoords.m,v $';

error(nargchk(1,1,nargin));
if ~isroi(roi), error('You must specify a valid ROI.'); end

XY=[];
Z=[];
for i=1:length(roi.slice)
  [x,y]=ind2sub(roi.baseSize(1:2),roi.index{i});
  z=zeros(length(x),1);
  z(:)=roi.slice(i);
  XY=[XY;sortrows([x y],[2 1])];
  Z=[Z;z];
end
if nargout==3
  varargout={XY(:,1) XY(:,2) Z};
else
  varargout={[XY Z]};
end

% Modification History:
%
% $Log: roicoords.m,v $
% Revision 1.3  2005/02/03 16:58:43  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:39  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/08/27 22:24:24  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2001/01/25. Changed function name to lowercase.
%                                Changed isroi() to lowercase.
%                                Changed see also to uppercase
% Francis Favorini,  2000/05/05. Added isroi check.
% Francis Favorini,  2000/04/10. Added proper comments above.
% Francis Favorini,  2000/04/07.
