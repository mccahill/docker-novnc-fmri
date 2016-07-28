function out=iswinlev(winlev_h)
% ISWINLEV - Is the figure a window & level gui (WINLEV)
%
%	OUT = ISWINLEV(WINLEV_H)
%	
%	winlev_h - Handle(s) to test
%      out - cell array of size handle
%            each cell is:
%               empty if not valid winlev GUI handle
%               image handle(s) controlled by winlev GUI if valid winlev GUI handle
%
% See also: WINLEV

% CVS ID and authorship of this code
% CVSId = '$Id: iswinlev.m,v 1.3 2005/02/03 16:58:39 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:39 $';
% CVSRCSFile = '$RCSfile: iswinlev.m,v $';

% Check the number of arguments
error(nargchk(1,1,nargin));

% Initialize to false (True if valid winlev handle, false if not)
validwinlev=logical(zeros(size(winlev_h)));
out = cell(size(winlev_h));

% Check if 'Tag' is 'winlevGUI'
% Only check valid handles!
validwinlev(ishandle(winlev_h)) = strcmp(get(winlev_h(ishandle(winlev_h)),'Tag'),'winlevGUI');

% Check get handles of images controlled by winlev GUIs
if length(validwinlev) == 1
  out(validwinlev) = {get(winlev_h(validwinlev),'UserData')};
else
  out(validwinlev) = get(winlev_h(validwinlev),'UserData');
end

% Modification History:
%
% $Log: iswinlev.m,v $
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
% Charles Michelich, 2001/09/15. Original
