function out=squaresrs(in,newSize)
%SQUARESRS Pad series with zeros to make images square.
%
%   out=squaresrs(srs);
%   out=squaresrs(srs,newSize);
%
%   srs is centered in out.
%   newSize specifies the new image size.
%     If the x or y dimension is already larger, newSize is ignored.
%   out will be 3D if srs is, otherwise 2D.

% CVS ID and authorship of this code
% CVSId = '$Id: squaresrs.m,v 1.3 2005/02/03 16:58:44 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:44 $';
% CVSRCSFile = '$RCSfile: squaresrs.m,v $';

error(nargchk(1,2,nargin));
if nargin<2, newSize=1; end
  
if ndims(in)>3
  error('Input srs must be at most 3D!');
end

x=size(in,1);
y=size(in,2);
z=size(in,3);
newSize=max([x y newSize]);

if x==newSize & y==newSize
  out=in;
else
  out=zeros(newSize,newSize,z);
  xo=ceil((newSize-x)/2);
  xc=xo+[1:x];
  yo=ceil((newSize-y)/2);
  yc=yo+[1:y];
  out(xc,yc,:)=in;
end

% Modification History:
%
% $Log: squaresrs.m,v $
% Revision 1.3  2005/02/03 16:58:44  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:39  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/08/27 22:24:26  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2001/01/25. Changed function name to lowercase and updated comments
% Francis Favorini,  1999/09/03. Actually handle 3D input.  (Why was this missing?)
%                                Added newSize arg.
% Francis Favorini,  1998/09/22.
