function cmapmenu
%CMAPMENU Add a color map menu to the current figure.
%	Each of the menu choices changes the current colormap:
%	HOT, PINK, COOL, BONE, JET, COPPER, FLAG and PRISM are color maps.
%	Rand is a random color map.
%	Brighten increases the brightness.
%	Darken decreases the brightness.
% SwapRG exchanges the red and green components.
% SwapGB exchanges the green and blue components.
%	SwapRB exchanges the red and blue components.
%	PermuteRGB moves red to green, green to blue, blue to red. 

%	Copyright (c) 1984-94 by The MathWorks, Inc.

% CVS ID and authorship of this code
% CVSId = '$Id: cmapmenu.m,v 1.4 2005/02/03 16:58:32 michelich Exp $';
% CVSRevision = '$Revision: 1.4 $';
% CVSDate = '$Date: 2005/02/03 16:58:32 $';
% CVSRCSFile = '$RCSfile: cmapmenu.m,v $';

maps=str2mat('HSV','Hot','Pink','Cool','Bone','Jet','Copper','Flag','Prism');
colormenuh=uimenu(gcf,'Label','Colormaps');
for k=1:size(maps,1);
   uimenu(colormenuh,'Label',maps(k,:),'CallBack',['colormap(' maps(k,:) ');']);
end
uimenu(colormenuh,'Label','Rand', 'CallBack','colormap(rand(length(colormap),3))');
uimenu(colormenuh,'Label','Brighten','CallBack','brighten(.25)');
uimenu(colormenuh,'Label','Darken','CallBack','brighten(-.25)');
uimenu(colormenuh,'Label','SwapRG',...
       'CallBack','c=colormap; colormap(c(:,[2 1 3])); clear c');
uimenu(colormenuh,'Label','SwapGB',...
       'CallBack','c=colormap; colormap(c(:,[1 3 2])); clear c');
uimenu(colormenuh,'Label','SwapRB',...
       'CallBack','c=colormap; colormap(c(:,[3 2 1])); clear c');
uimenu(colormenuh,'Label','PermuteRGB',...
       'CallBack','c=colormap; colormap(c(:,[3 1 2])); clear c');
%uimenu(colormenuh,'Label','Help','CallBack','help cmapmenu');

% Modification History:
%
% $Log: cmapmenu.m,v $
% Revision 1.4  2005/02/03 16:58:32  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.3  2003/10/22 15:54:34  gadde
% Make some CVS info accessible through variables
%
% Revision 1.2  2003/09/15 17:24:55  michelich
% Correct capitalization of function name.
%
% Revision 1.1  2002/08/27 22:24:14  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Francis Favorini, 1996/11/14. Modified original Mathworks implementation
