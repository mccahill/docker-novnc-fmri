function [map]=emap
%EMAP   Return Erik's colormap of size 211.

% CVS ID and authorship of this code
% CVSId = '$Id: emap.m,v 1.3 2005/02/03 16:58:32 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:32 $';
% CVSRCSFile = '$RCSfile: emap.m,v $';

r=[0.58 0.7 0.95 0.9 0.6 0.0 0.0 0.0 0.0 0.3  0.6 1.0 1.0  1.0 1.0 1.0];
g=[0.0  0.3 0.6  0.5 0.6 0.7 0.0 0.3 0.5 0.75 0.9 1.0 0.85 0.7 0.4 0.0];
b=[0.63 0.7 0.8  0.7 0.9 0.9 1.0 0.7 0.5 0.0  0.0 0.0 0.0  0.0 0.0 0.0];

c2=1;
for c=1:15 
  for c1=1:15 
    cr(c2)=(r(c)*(15-c1)+r(c+1)*c1)/15;
    cg(c2)=(g(c)*(15-c1)+g(c+1)*c1)/15;
    cb(c2)=(b(c)*(15-c1)+b(c+1)*c1)/15;
    c2=c2+1;
  end
  c2=c2-1;
end
map=[cr' cg' cb'];

% Modification History:
%
% $Log: emap.m,v $
% Revision 1.3  2005/02/03 16:58:32  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:35  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/08/27 22:24:14  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Francis Favorini, 1997/04/04. Converted from Erik's EEG program.

