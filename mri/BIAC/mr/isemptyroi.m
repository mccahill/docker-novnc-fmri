function [TF,err]=isemptyroi(ROIs)
%ISEMPTYROI  Returns true for each empty valid ROI in ROIs.
%
%   [TF,err]=isemptyroi(ROIs);
%
%   ROIs is an array or cell array of ROIs.
%   TF is a logical array the same shape as ROIs with
%     true for each empty valid ROI in ROIs.
%   err is an array the same shape as ROIs with
%     a numeric entry from a call to isroi indicating
%     the problem for each invalid ROI and 0 otherwise.
%
%   See also ISROI, ROIDEF, ROIGROW, ROICOORDS, ROISTATS

% CVS ID and authorship of this code
% CVSId = '$Id: isemptyroi.m,v 1.3 2005/02/03 16:58:39 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:39 $';
% CVSRCSFile = '$RCSfile: isemptyroi.m,v $';

error(nargchk(1,1,nargin));

[TF,err]=isroi(ROIs);
if isempty(ROIs), return; end

empties=TF;
% Want to preserve shape, so use for loop
for r=1:prod(size(ROIs))
  if TF(r)
    if iscell(ROIs)
      roi=ROIs{r};
    else
      roi=ROIs(r);
    end
    empties(r)=isempty(roi.slice);
  end
end

TF=TF&empties;

% Modification History:
%
% $Log: isemptyroi.m,v $
% Revision 1.3  2005/02/03 16:58:39  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:37  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/08/27 22:24:21  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2001/01/23 Changed function name to lowercase.
%                               Changed isroi() to lowercase.
%                               Updated see also to uppercase.
% Francis Favorini,  2000/05/05.
