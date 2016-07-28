function [coords]=centroid(A,thresh)
%CENTROID Calculate centroid of array.
%
%   COORDS=CENTROID(A,THRESH);
%
%   A is a 1-D, 2-D or 3-D array.
%   THRESH defines the minimum value of points in A to include.
%   COORDS are the X, Y, and Z coordinates of the centroid.
%
%   Note:
%   The centroid does not take into account the value (or weight)
%   of each point in the array.  All points at or above the
%   threshhold are considered equally.
%
%   See also CMASS, IMFEATURE.

% CVS ID and authorship of this code
% CVSId = '$Id: centroid.m,v 1.3 2005/02/03 16:58:32 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:32 $';
% CVSRCSFile = '$RCSfile: centroid.m,v $';

% Check args
error(nargchk(2,2,nargin));
if isempty(A), coords=[]; return; end

% Generate coordinates
x=1:size(A,1);
y=1:size(A,2);
z=1:size(A,3);
[X Y Z]=ndgrid(x,y,z);

% Apply threshhold
pts=find(A>=thresh);

% Return centroid
if isempty(pts)
  coords=[];
else
  coords=[mean(X(pts)) mean(Y(pts)) mean(Z(pts))];
end

% Modification History:
%
% $Log: centroid.m,v $
% Revision 1.3  2005/02/03 16:58:32  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:34  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/08/27 22:24:14  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Francis Favorini, 1998/11/24.
