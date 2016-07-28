function y=movavg(x,m,dim)
%MOVAVG Calculate symmetric moving average of length m on vector x.
%         
%       y=MOVAVG(x,m,dim);
%
%       x is a vector or matrix.
%       m is a positve, odd integer.  Default is 3.
%       dim is the dimension (1,2, or 3) to average on.  Default is 1.
%       y is a vector with the same length as x.
%
%       For each point p, y(p) is the average of the m points centered on x(p).
%       (m-1)/2 points on each end are edge cases and are just copied from x to y.

% CVS ID and authorship of this code
% CVSId = '$Id: movavg.m,v 1.3 2005/02/03 16:58:34 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:34 $';
% CVSRCSFile = '$RCSfile: movavg.m,v $';

% Check args
if nargin<2, m=3; end
if nargin<3, dim=1; end
if m==1
  y=x;
  return;
end
if dim<1 | dim>3
  error('dim must be 1, 2 or 3.')
end
if m<1 | rem(m,2)~=1
  error('m must be positive and odd.')
end

% Run the filter on dimension dim
k=ones(m,1)/m;
y=filter(k,1,x,[],dim);

% Fix the edge cases (just copy from x)
edge=(m-1)/2;
switch dim,
  case 1,
    y(1:2*edge)=[];
    y=cat(dim,x(1:edge),y,x(end-edge+1:end));
  case 2,
    y(:,1:2*edge)=[];
    y=cat(dim,x(:,1:edge),y,x(:,end-edge+1:end));
  case 3,
    y(:,:,1:2*edge)=[];
    y=cat(dim,x(:,:,1:edge),y,x(:,:,end-edge+1:end));
end

% Modification History:
%
% $Log: movavg.m,v $
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
% Francis Favorini, 1997/07/24.
