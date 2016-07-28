function out=cubesrs(in,newSize)
%CUBESRS Pad series with zeros to make a cubic volume.
%
%   out=cubesrs(srs);
%   out=cubesrs(srs,newSize);
%
%   srs is centered in out.
%   newSize specifies the new volume size.
%     If the x, y or z dimension is already larger, newSize is ignored.
%   out will be 3D.

% CVS ID and authorship of this code
% CVSId = '$Id: cubesrs.m,v 1.3 2005/02/03 16:58:38 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:38 $';
% CVSRCSFile = '$RCSfile: cubesrs.m,v $';

error(nargchk(1,2,nargin));
if nargin<2, newSize=1; end
  
if ndims(in)>3
  error('Input srs must be at most 3D!');
end

x=size(in,1);
y=size(in,2);
z=size(in,3);
newSize=max([x y z newSize]);

if x==newSize & y==newSize & z==newSize
  out=in;
else
  out=zeros(newSize,newSize,newSize);
  xo=ceil((newSize-x)/2);
  xc=xo+[1:x];
  yo=ceil((newSize-y)/2);
  yc=yo+[1:y];
  zo=ceil((newSize-z)/2);
  zc=zo+[1:z];
  out(xc,yc,zc)=in;
end

% Modification History:
%
% $Log: cubesrs.m,v $
% Revision 1.3  2005/02/03 16:58:38  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:37  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/08/27 22:24:20  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2001/01/23. Changed function name to lowercase.
% Francis Favorini,  1999/09/03.
