function [ind,peaks] = findpeaks(y)
% FINDPEAKS  Find peaks in real vector.
%  ind = findpeaks(y) finds the indices (ind) which are
%  local maxima in the sequence y.  
%
%  [ind,peaks] = findpeaks(y) returns the value of the peaks at 
%  these locations, i.e. peaks=y(ind);

% CVS ID and authorship of this code
% CVSId = '$Id: findpeaks.m,v 1.3 2005/02/03 16:58:20 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:20 $';
% CVSRCSFile = '$RCSfile: findpeaks.m,v $';

y = y(:)';
dy = diff(y);
ind = find( ([dy 0]<0) & ([0 dy]>=0) );

if y(end-1)<y(end)
    ind = [ind length(y)];
end

if nargout > 1
    peaks = y(ind);
end

% Modification History:
%
% $Log: findpeaks.m,v $
% Revision 1.3  2005/02/03 16:58:20  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:34  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/10/08 23:46:46  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% No history entry in original file.