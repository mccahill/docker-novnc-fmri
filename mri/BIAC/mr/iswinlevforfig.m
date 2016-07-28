function figwinlev_h=iswinlevforfig(fig)
% ISWINLEVFORFIG - Is there a window & level GUI for a particular figure?
%
%	WINLEV_H = ISWINLEVFORFIG(FIG)
%	
%	winlev_h - handle(s) of winlev GUIs controlling FIGURE (empty if none)
%  figure -  handle of figure to test for open winlev GUIs
%
% See also: WINLEV, ISWINLEV

% CVS ID and authorship of this code
% CVSId = '$Id: iswinlevforfig.m,v 1.3 2005/02/03 16:58:39 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:39 $';
% CVSRCSFile = '$RCSfile: iswinlevforfig.m,v $';

%TODO: Optimize search

% Check the number of arguments
error(nargchk(1,1,nargin));

% Check for winlev GUIs
% Note: Must show all hidden handles to allow us to check for winlevGUI's
currState = get(0,'ShowHiddenHandles');		% Read current state
set(0,'ShowHiddenHandles','on');					% Make all handles visible
winlev_h = findobj('Tag','winlevGUI');		% Check for winlev GUIs
set(0,'ShowHiddenHandles',currState);			% Set back to previous state

% Initialize output to empty
figwinlev_h = [];

if ~isempty(winlev_h) 
  % There is a winlev GUI

  % Get images controlled by winlev GUIs
  if length(winlev_h) == 1 
    image_h = {get(winlev_h,'UserData')}; % Put in a cell for consistent handling
  else
    image_h = get(winlev_h,'UserData');
  end
  
  % Check each winlev for current figure handle
  for n = 1:length(winlev_h)
    image_fig_h = getParentFigure(image_h{n});    
    if any(image_fig_h == fig) 
      % Figure is controlled by this GUI
      figwinlev_h = [figwinlev_h; winlev_h(n)];
    end
  end  
end

%------------------------GETPARENTFIGURE----------------------------------
function fig = getParentFigure(handle)
% getParentFigure - return the parent figure for the passed handle
%
%   fig=getParentFigure(handle)
%
%   Returns the parents figure for the specified handle(s)
%
% Charles Michelich, 2001/09/21, copied from guidata.m
%                                modified to handle a vector of handles & added error checking

% Make sure that input are valid, non-root handles
if any(~ishandle(handle(:))) | any(handle(:) == 0)
  emsg = 'getParentFigure requires valid handles other than root handle'; error(emsg)
end

% Loop through each handle passed
fig = handle;  % Start with handles passed;
for n = 1:length(handle(:))
  % if the object is a figure or figure descendent, return the
  % figure.  Otherwise return [].
  while ~isempty(fig(n)) & ~strcmp('figure', get(fig(n),'type'))
    fig(n) = get(fig(n),'parent');
  end
end

% Modification History:
%
% $Log: iswinlevforfig.m,v $
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
% Charles Michelich, 2001/09/21. Use new multiple getParentFigure function.
% Charles Michelich, 2001/09/15. Original.
