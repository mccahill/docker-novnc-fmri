function newroi=roisort(roi)
%ROISORT Sort the slices and X,Y,Z coords for specified ROI.
%
%   newroi=roisort(roi);
%
%   roi is an ROI returned by ROIDEF.
%   newroi has newroi.slice sorted ascending and
%     newroi.index is sorted to match.
%
%   Examples:
%   >>load D:\roi\mfg.roi -mat
%   >>sortedroi=roisort(roi);
%
%   See also ISROI, ROIDEF, ROIGROW, ROICOORDS, ROISTATS.

% CVS ID and authorship of this code
% CVSId = '$Id: roisort.m,v 1.3 2005/02/03 16:58:43 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:43 $';
% CVSRCSFile = '$RCSfile: roisort.m,v $';

error(nargchk(1,1,nargin));

newroi=roi;
[newroi.slice,neworder]=sort(newroi.slice);
newroi.index=newroi.index(neworder);

% Modification History:
%
% $Log: roisort.m,v $
% Revision 1.3  2005/02/03 16:58:43  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:39  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/08/27 22:24:25  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2001/01/25. Changed function name to lowercase.
%                                Changed isroi() to lowercase.
%                                Changed see also to uppercase
% Francis Favorini,  2000/05/05. Fixed comments.
% Francis Favorini,  2000/04/10.
