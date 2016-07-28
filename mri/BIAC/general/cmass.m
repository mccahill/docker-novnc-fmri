function [coords]=cmass(A)
%CMASS  Calculate center of mass of array.
%
%   COORDS=CMASS(A);
%
%   A is a 1-D, 2-D or 3-D array.
%   COORDS are the X, Y, and Z coordinates of the center of mass.
%
%   Note:
%   The center of mass takes into account the value (or weight)
%   of each point in the array.
%
%   See also CENTROID, IMFEATURE.

% CVS ID and authorship of this code
% CVSId = '$Id: cmass.m,v 1.3 2005/02/03 16:58:32 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:32 $';
% CVSRCSFile = '$RCSfile: cmass.m,v $';

% Check args
error(nargchk(1,1,nargin));
if isempty(A), coords=[]; return; end

% Generate coordinates
x=1:size(A,1);
y=1:size(A,2);
z=1:size(A,3);
[X Y Z]=ndgrid(x,y,z);

% Calculate sums
A=abs(A(:));                                   % Negative values count the same as positive
xWeight=sum(A.*X(:));
yWeight=sum(A.*Y(:));
zWeight=sum(A.*Z(:));
total=sum(A);

% Return center of mass
if total==0                                    % If A is all zeros
  coords=[mean(x) mean(y) mean(z)];            % return centroid of A
else
  coords=[xWeight yWeight zWeight]./total;
end

% Modification History:
%
% $Log: cmass.m,v $
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
