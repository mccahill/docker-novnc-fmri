%HCOORDS Return homogeneous coordinate array from X, Y, and Z coordinates.
%
%   XYZT=HCOORDS(X,Y,Z);
%
%   X, Y, and Z are vectors specifying the coordinates.
%     They are expanded as if by NDGRID.
%   XYZT is a 4-column array of the homogeneous coordinates, as in
%     [x y z 1] where x, y, and z are the corresponding coordinates
%     from the expanded X, Y, and Z arrays.
%
%   See also XMR, NDGRID.

% Implemented as a MEX file.
