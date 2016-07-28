function [out,out2]=xmr(srs,xTrans,yTrans,zTrans,xScale,yScale,zScale,xRot,yRot,zRot,matOnly)
%XMR    Transform series using transformation parameters.  Returns new series and/or matrix.
%
%   out=xmr(srs,xTrans,yTrans,zTrans,xScale,yScale,zScale,xRot,yRot,zRot);
%   [out,mat]=xmr(srs,xTrans,yTrans,zTrans,xScale,yScale,zScale,xRot,yRot,zRot);
%   mat=xmr(srs,xTrans,yTrans,zTrans,xScale,yScale,zScale,xRot,yRot,zRot,matOnly);
%
%   srs should be a 3-D volume (X by Y by Z) or a set of coordinates.
%   Translations are in voxels.
%   Scale of 2 will double the size of the volumes.
%   Rotations are in degrees.
%   matOnly is set to 1 to return just the transform matrix.  Default is 0.
%   mat is the transform matrix.
%   out is the transformed volume or coords.
%
%   Order of operations:
%   1) Scaling
%   2) Rotation (relative to the scaled volume's center)
%   3) Translation
%
%   If srs is a set of coordinates (N by 3 or N by 2), returns just the transformed coords.
%   The coordinates must be 1-based.  I.e., the origin is (1,1,1).
%
%   Examples:
%   >>out=xmr(in,0,0,0,1,2,2,-90,0,0);
%   >>out=xmr(in,0,0,0,1,2,2,-90,0,0);
%   >>out=xmr([1 4 6; 3 4 5; 6 9 7; 4 3 2],-10,-10,-10,1,1,1/2,0,0,0);

% NB: The transformation code only deals with 0-based coords!

% CVS ID and authorship of this code
% CVSId = '$Id: xmr.m,v 1.3 2005/02/03 16:58:45 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:45 $';
% CVSRCSFile = '$RCSfile: xmr.m,v $';

% Process arguments
if nargin<10 | nargin>11, error('xmr requires 10 or 11 arguments.'); end
if nargin<11, matOnly=0; end
doInterp=1;
if length(size(srs))==2 & size(srs,2)==3   % Just transform specified coords
  doInterp=0;
end

% Change sign on translations so positive moves volume in positive direction.
xTrans=-xTrans;
yTrans=-yTrans;
zTrans=-zTrans;

% Take reciprocal of scale factors so 2 doubles size.
xScale=1/xScale;
yScale=1/yScale;
zScale=1/zScale;

% Convert to radians (-2*pi to 2*pi)
[xR,yR,zR]=deal(rem(xRot,360)*pi/180,rem(yRot,360)*pi/180,rem(zRot,360)*pi/180);

% Original coords (converted to 0-based!)
if doInterp
  % All srs coords
  xSz=size(srs,1);
  ySz=size(srs,2);
  zSz=size(srs,3);
  x=0:xSz-1;
  y=0:ySz-1;
  z=0:zSz-1;
else
  % User-specified
  cSz=size(srs,1);
  srs=srs-1;                               % Convert to 0-based
  x=srs(:,1)';
  y=srs(:,2)';
  z=srs(:,3)';
end
[xMin xMax]=minmax(x);
[yMin yMax]=minmax(y);
[zMin zMax]=minmax(z);

% Scaling matrix
scaleMat=...
  [xScale   0      0     0;
     0    yScale   0     0;
     0      0    zScale  0;
     0      0      0     1];

% Centering matrix (puts origin in center of scaled image)
ctrMat=...
  [1  0  0  -(xMax-xMin)/2*xScale;
   0  1  0  -(yMax-yMin)/2*yScale;
   0  0  1  -(zMax-zMin)/2*zScale;
   0  0  0          1       ];

% Rotation matrix
rotMat=...
  [cos(zR)*cos(yR)+sin(zR)*sin(xR)*sin(yR)  sin(zR)*cos(yR)-cos(zR)*sin(xR)*sin(yR)  cos(xR)*sin(yR)  0;
              -sin(zR)*cos(xR)                          cos(zR)*cos(xR)                  sin(xR)      0;
   sin(zR)*sin(xR)*cos(yR)-cos(zR)*sin(yR) -cos(zR)*sin(xR)*cos(yR)-sin(zR)*sin(yR)  cos(xR)*cos(yR)  0;
                      0                                        0                            0         1];

% Translation matrix
transMat=...
  [1  0  0  xTrans;
   0  1  0  yTrans;
   0  0  1  zTrans;
   0  0  0     1  ];

% Uncentering matrix (puts origin back in corner of transformed image)
unctrMat=...
  [1  0  0  (xMax-xMin)/2*xScale;
   0  1  0  (yMax-yMin)/2*yScale;
   0  0  1  (zMax-zMin)/2*zScale;
   0  0  0         1       ];

% Complete transform matrix
mat=unctrMat*transMat*rotMat*ctrMat*scaleMat;
mat=mat';

if matOnly
  out=mat;
else
  if doInterp
    % Generate new coords, so scaling will change size of new volume
    % TODO: Eliminate out of range coords by replicating last row, col, slice
    xnSz=floor(xSz/xScale);
    ynSz=floor(ySz/yScale);
    znSz=floor(zSz/zScale);
    xyzt=hcoords(0:xnSz-1,0:ynSz-1,0:znSz-1);
  else
    xyzt=[x(:) y(:) z(:) ones(cSz,1)];
  end
  
  % Do the transform
  ixyzt=xyzt*mat;
  
  % Return output
  if doInterp
    % Interpolate using new coords
    xi=reshape(ixyzt(:,1),xnSz,ynSz,znSz);
    yi=reshape(ixyzt(:,2),xnSz,ynSz,znSz);
    zi=reshape(ixyzt(:,3),xnSz,ynSz,znSz);
    out=trilinear(x,y,z,srs,xi,yi,zi);
  else
    out=ixyzt(:,1:3)+1;                      % Back to 1-based coords
  end
  if nargout>1, out2=mat; end
end

% Modification History:
%
% $Log: xmr.m,v $
% Revision 1.3  2005/02/03 16:58:45  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:40  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/08/27 22:24:27  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Francis Favorini,  2002/03/28. Added matOnly option.
% Charles Michelich, 2001/04/17. Changed function name to lowercase.
% Francis Favorini,  2001/04/04. Fixed bug in transforming coords only.  Wasn't centering correctly.
% Francis Favorini,  1998/11/18. Use trilinear (MEX file) interpolation only.
%                                Use hcoords (MEX file).
% Francis Favorini,  1998/11/11. Handle coords only case properly.
% Francis Favorini,  1998/10/98. Based on ResliceAIR.
