function outSrs=vol2montage(srs,montSz)
% vol2montage - Generate a montage of slices from a 3D or 4D series
%
%   outSrs=vol2montage(srs,gridDims)
%     srs - input series
%     montSz - dimensions of grid to tile images onto.
%              default: automatically calculate.
%              empty or not specified uses default.
%     outSrs - output series
%
%  Slices count horizontally starting from upper left corner
%

% CVS ID and authorship of this code
% CVSId = '$Id: vol2montage.m,v 1.5 2005/02/03 16:58:45 michelich Exp $';
% CVSRevision = '$Revision: 1.5 $';
% CVSDate = '$Date: 2005/02/03 16:58:45 $';
% CVSRCSFile = '$RCSfile: vol2montage.m,v $';

% Check inputs
error(nargchk(1,2,nargin))
if nargin < 2, montSz = []; end % Default to auto calculate
if all(ndims(srs) ~= [3 4]) | ~isnumeric(srs) | ~isa(srs,'double')
  error('Input series must be 3D or 4D array of doubles!');
end

% Get sizes of matrix
xSz = size(srs,1);
ySz = size(srs,2);
zSz = size(srs,3);
tSz = size(srs,4);

% Auto calculate montage size.
if isempty(montSz)
  % Find the nearest power of two larger than current number of slices
  montSz = ceil(sqrt(zSz));
  montSz(2) = ceil(zSz/montSz);  % Make vertical size smaller if possible.
end

% Check that montSz is valid
if ndims(montSz) > 2 | any(size(montSz) ~= [1 2]) | any(~isint(montSz)) | any(montSz < 1)
  error('Montage size must be a two element vector of positive integers!');
end
if prod(montSz) < zSz
  error('Montage size is not large enough for all slices!');
end

% Calculate the number of slice for the output.
zSzOut = prod(montSz);

% Pad out the input to have enough slices for a square output
if zSz ~= zSzOut
  srs(:,:,(zSz+1):zSzOut,:) = zeros(xSz,ySz,zSzOut-zSz,tSz);
end

% Reshape to a montage of slices on the X & Y axis
if tSz == 1
  % 3D version (faster)
  %   1) Switch X & Y                                                             x,y,z -> y,x,z
  %   2) Reshape to ySz,xSz*montSz(1),montSz(2) (i.e. tile height to montSz)      y,x,z -> y,x*z/m,m
  %   3) Switch X & Z  (so that next reshape fill Y from Z dimension)         y,x*z/m,m -> y,m,x*z/m
  %   4) Reshape to ySz*montSz(2),xSz*montSz(1) (i.e. tile width to montSz)   y,m,x*z/m -> y*z/m,x*z/m,1
  %   5) Switch X & Y                                                     y*z/m,x*z/m,1 -> x*z/m,y*z/m,1
  outSrs=permute(reshape(permute(reshape(permute(srs,[2 1 3]),[ySz xSz*montSz(1) montSz(2)]),[1 3 2]),[ySz*montSz(2) xSz*montSz(1)]),[2 1]);
else
  % 4D version
  %   1) Switch X & Y and move t to the beginning so that it is not affected         x,y,z,t -> t,y,x,z
  %   2) Reshape to tSz,ySz,xSz*montSz(1),montSz(2) (i.e. tile height to montSz)     t,y,x,z -> t,y,x*z/m,m
  %   3) Switch X & Z  (so that next reshape fill Y from Z dimension)            t,y,x*z/m,m -> t,y,m,x*z/m
  %   4) Reshape to tSz,ySz*montSz(2),xSz*montSz(1) (i.e. tile width to montSz)  t,y,m,x*z/m -> t,y*z/m,x*z/m,1
  %   5) Switch X & Y & t back                                               t,y*z/m,x*z/m,1 -> x*z/m,y*z/m,1,t
  outSrs=permute(reshape(permute(reshape(permute(srs,[4 2 1 3]),[tSz ySz xSz*montSz(1) montSz(2)]),[1 2 4 3]),[tSz ySz*montSz(2) xSz*montSz(1)]),[3 2 4 1]);
end

% Modification History:
%
% $Log: vol2montage.m,v $
% Revision 1.5  2005/02/03 16:58:45  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.4  2003/10/22 15:54:39  gadde
% Make some CVS info accessible through variables
%
% Revision 1.3  2003/07/08 17:41:50  michelich
% Support non-square and user specified montSz.
% Reduce auto-calculated vertical size of montage if possible.
%
% Revision 1.2  2002/10/18 01:22:07  michelich
% Fixed calculation of montage size.
%
% Revision 1.1  2002/08/27 22:24:26  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2002/05/09. original
