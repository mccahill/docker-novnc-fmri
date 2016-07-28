function [item,itemIndex]=listgui(items,figtitle,multiSelectFlag)
% LISTGUI - Choose an item from a list using a GUI
%
% This function displays a GUI with a list box of items and returns
% the item selected by the user.
%
% Usage:
%    [item,itemIndex]=listgui(items)
%    [item,itemIndex]=listgui(items,figtitle)
%    [item,itemIndex]=listgui(items,figtitle,multiSelectFlag)
%
%    where items is a cell array of strings (1 x N or N x 1)
%          figtitle is the figure title (default is 'Please select...')
%          multiSelectFlag is a flag specifying whether multiple items can be
%            selected (0 - no, 1 - yes).  Defaults to 0. 
%          item is the item(s) selected by the user
%             if the user cancels, item is ''
%             if multiSelectFlag is false, item is a string
%             if multiSelectFlag is true, item is a cell array of strings
%          itemIndex is the indices of the item(s) selected by the user 
%            (or 0 if the user cancels)
%
% Note: If the user selects no items and then 'OK', item will be {} and
%       itemIndex will be [].  User can only select no items when
%       multiSelectFlag is true. 

% CVS ID and authorship of this code
% CVSId = '$Id: listgui.m,v 1.6 2005/02/03 16:58:34 michelich Exp $';
% CVSRevision = '$Revision: 1.6 $';
% CVSDate = '$Date: 2005/02/03 16:58:34 $';
% CVSRCSFile = '$RCSfile: listgui.m,v $';

% BUG: The Esc key does not 'Cancel' the GUI if the user has clicked an item in the listbox.
%      The 'KeyPressFcn' for the figure is not executed when the user has clicked an item 
%      in the listbox.  The return key works because MATLAB treats 'click,return' as a 'double click'
%      Note that using the 'KeyPressFcn' callback for the listbox callback does not result
%      in proper behavior either.  The keystrokes appear to be ignored except for the "built-in"
%      behavior in the listbox.
%
%TODO: Find out how to make list navigation keys work when GUI opens.
%      Currently the arrow keys and letters work as expected only after the user has clicked 
%      on any item in the list or tabbed into the list.
%TODO: Add this to the comments once the ESC bug has been resolved.
%   Note: Double clicking or pressing return in the GUI is equivalent to pressing OK
%         Pressing Esc in the GUI is equivalent to pressing Cancel
%TODO: Figure out how to calculate GUI element sizes better. (Scale and margins were chosen through trial and error)

% Check input
error(nargchk(1,3,nargin))
if nargin == 1
  figtitle = 'Please select...';
end
if nargin < 3, multiSelectFlag = 0; end

if ~iscellstr(items) | isempty(items)
  error('Items must be cell array of strings (not empty)!');
end
if ~ischar(figtitle)
  error('Figure title must be a string!');
end
if any(size(multiSelectFlag) ~= 1) | ~(isnumeric(multiSelectFlag) | islogical(multiSelectFlag))
  error('multiSelectFlag must be a numeric or logical scalar (1 or 0)');
end

% GUI element sizes
buttonwidth=10;                         % Width of button in characters
buttonheight=2;                         % Height of button in characters
minwidth=30;                            % Minimum width of figure
titlemargin = 5; titlescale=1.25;       % Scale and offset for determining width of title
listboxmargin = 5; listboxscale=1.1;    % Scale and offset for determining width of listbox

% Determine the width of the figure in characters
% Make sure tha title and list items are displayed
figurewidth=max([minwidth, ...
    listboxscale*(max(cellfun('length',items))+listboxmargin), ...
    titlescale*(length(figtitle)+titlemargin)]);

% Determine list height in characters 
% If less than 16 lines, size the figure for the whole list, otherwise size for 15 lines
if length(items) < 16
  listheight=length(items)+1;
else
  listheight=16;
end

figureheight=listheight+buttonheight+2; % Height of figure in characters
listwidth=figurewidth;                  % Width of list in characters

% Get screen size in characters
rootUnits=get(0,'Units');
set(0,'Units','characters');
screenSize=get(0,'ScreenSize');
set(0,'Units',rootUnits);

% Bring up the figure in the center of the screen
% Press Return to select 'OK' and Esc to select 'Cancel'
CBString='k=double(get(gcbf,''CurrentCharacter''));if isempty(k),elseif k==13,set(gcbf,''UserData'',''OK'');uiresume;elseif k==27,set(gcbf,''UserData'',''Cancel'');uiresume;end';
h=dialog('Units','Characters', 'Menubar','None','Name',figtitle,...
  'KeyPressFcn',CBString, ...
  'Position',[(screenSize(3)-figurewidth)/2,(screenSize(4)-figureheight)/2,figurewidth,figureheight]);

figposition=get(h,'Position');

% Double click on an item selects OK also.
CBString='if strcmp(get(gcbf,''SelectionType''),''open''),set(gcbf,''UserData'',''OK'');uiresume;end;';
h_list=uicontrol(h,'Style','listbox','String',items,'Units','characters',...
  'Callback',CBString, ...
  'Position',[0,figposition(4)-listheight,listwidth,listheight]);

if multiSelectFlag, set(h_list, 'Min', 0, 'Max', 2); end

CBString='set(gcbf,''UserData'',''OK'');uiresume';
h_okbutton=uicontrol(h,'Style','pushbutton','String','Ok','Units','characters', ...
  'Position', [(figposition(3)-2*buttonwidth)/3,1,buttonwidth,buttonheight], ...
  'Callback',CBString);

CBString='set(gcbf,''UserData'',''Cancel'');uiresume';
h_cancelbutton=uicontrol(h,'Style','pushbutton','String','Cancel','Units','characters', ...
  'Position', [(figposition(3)-2*buttonwidth)*2/3+buttonwidth,1,buttonwidth,buttonheight], ...
  'Callback',CBString);

% Wait for response
drawnow;
try
  uiwait(h);
catch
  delete(h);
end

% Get results
if ~ishandle(h)
  item =''; % If figure was closed, return empty
  itemIndex = 0;
else
  switch get(h,'UserData')
  case 'OK'
    itemIndex = get(h_list,'Value');
    if multiSelectFlag
      item = items(itemIndex);
    else
      item = items{itemIndex};
    end
  case 'Cancel'
    item = ''; % If user hit cancel, return empty
    itemIndex = 0;
  otherwise
    item = ''; % Return empty if there is any other value (such as closing the window)
    itemIndex = 0;
  end
  delete(h); % Close figure
end

if nargout < 2, clear('itemIndex'); end

% Modification History:
%
% $Log: listgui.m,v $
% Revision 1.6  2005/02/03 16:58:34  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.5  2004/06/15 00:17:07  michelich
% Updated help.
%
% Revision 1.4  2004/04/29 18:08:52  michelich
% Amin's additions.  Added support for multiple selections.
%
% Revision 1.3  2003/10/22 15:54:36  gadde
% Make some CVS info accessible through variables
%
% Revision 1.2  2002/11/07 19:55:13  michelich
% Optionally return the index into the list of the item chosen.
%
% Revision 1.1  2002/08/27 22:24:16  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2001/09/27. Added bug and todo's from findexp()
%                                Changed titlescale=1.25 (was 1.2) so that findexp title displays properly
% Charles Michelich, 2001/08/13. original (adapted from expName subfunction)
