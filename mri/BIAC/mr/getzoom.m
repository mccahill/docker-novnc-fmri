function srsZoom=getzoom(defZoom,fullZoom)
%GETZOOM Get MR series zoom parameters using GUI.
%
%   srsZoom=getzoom(defZoom,fullZoom);
%
%   defZoom is the default zoom.
%   fullZoom is the full size of the images.
%   srsZoom is the zoom parameters the user specified.
%
%   For 2-dimensional zooming:
%   zoom parameters are of the form [xo yo xs ys],
%     where (xo,yo) is the upper left corner and
%     [xs ys] is the dimensions of the new zoomed series.
%
%   For 3-dimensional zooming:
%   zoom parameters are of the form [xo yo zo xs ys zs],
%     where (xo,yo,zo) is the upper left corner of the first slice and
%     [xs ys zs] is the dimensions of the new zoomed series.
%
%   For 4-dimensional zooming:
%   zoom parameters are of the form [xo yo zo to xs ys zs ts],
%     where (xo,yo,zo) is the upper left corner of the first slice,
%     [xs ys zs] is the dimensions of the new zoomed series, and
%     t0 and ts are the starting time points and number of time points
%     respectively.

% CVS ID and authorship of this code
% CVSId = '$Id: getzoom.m,v 1.3 2005/02/03 16:58:39 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:39 $';
% CVSRCSFile = '$RCSfile: getzoom.m,v $';

% Check args
error(nargchk(2,2,nargin));
if length(defZoom)==4
   dimen=2;
elseif length(defZoom)==6
   dimen=3;
elseif length(defZoom)==8
   dimen=4;
else
   emsg='Incorrect size for defZoom argument.'; error(emsg);
end

% Initialize GUI
fig=zoomgui;
set(fig,'WindowStyle','modal');
local_setGUIzoom(fig,defZoom);		% Set text fields to default values 
if dimen>=3										
   % Make Z fields visible
   set(findobj(fig,'Tag','ZPos'),'Visible','on');
   set(findobj(fig,'Tag','ZSize'),'Visible','on');
   set(findobj(fig,'Tag','ZString'),'Visible','on'); 
end
if dimen==4
   % Make t fields visible
   set(findobj(fig,'Tag','tPos'),'Visible','on');
   set(findobj(fig,'Tag','tSize'),'Visible','on');
   set(findobj(fig,'Tag','tString'),'Visible','on'); 
   
   % Make zoomgui bigger
   set(fig,'Position',get(fig,'Position')+[0 0 15 0]);
end

% Wait for user
while 1
   waitfor(fig,'UserData');                      % Wait for window to close or UserData to change
   if ishandle(fig)
      ud=get(fig,'UserData');
      set(fig,'UserData',[]);
   else
      ud='Cancel';                                % Closed window = Cancel
   end
   if ~isempty(ud)
      if strcmp(ud,'KeyPress')
         switch get(fig,'CurrentCharacter')
         case {char(13)}, ud='OK';               % Return = OK
         case {char(27)}, ud='Cancel';           % Esc = Cancel
         end
      end
      switch ud
      case 'OK'
         srsZoom=local_getGUIzoom(fig,dimen);	% Get current zoom
         % zoom should only be positive integers and sizes must be smaller than the full size
         if any(srsZoom<1) | any(~isint(srsZoom)) ...
               | any([srsZoom(1:dimen)+srsZoom(dimen+1:2*dimen)-1]>fullZoom(dimen+1:2*dimen))
            msgbox({'Specified series zoom parameters are invalid!' ...
                  '' ...
                  'You must use positive integers that are less than the full size'},...
               	'Error','error','modal');
      	else
            break;
         end
      case 'Cancel'
         srsZoom=[];
         break;
      case 'XPos'
         set(findobj(fig,'Tag','YPos'),'String',get(findobj(fig,'Tag','XPos'),'String'));
         set(findobj(fig,'Tag','FullSizeCheckbox'),'Value',0);
      case 'XSize'
         set(findobj(fig,'Tag','YSize'),'String',get(findobj(fig,'Tag','XSize'),'String'));
         set(findobj(fig,'Tag','FullSizeCheckbox'),'Value',0);
      case 'YPos'
         set(findobj(fig,'Tag','FullSizeCheckbox'),'Value',0);
      case 'YSize'
         set(findobj(fig,'Tag','FullSizeCheckbox'),'Value',0);
      case 'ZPos'
         set(findobj(fig,'Tag','FullSizeCheckbox'),'Value',0);
      case 'ZSize'
         set(findobj(fig,'Tag','FullSizeCheckbox'),'Value',0);      
      case 'tPos'
         set(findobj(fig,'Tag','FullSizeCheckbox'),'Value',0);
      case 'tSize'
         set(findobj(fig,'Tag','FullSizeCheckbox'),'Value',0);  
      case 'FullSize'
         if get(findobj(fig,'Tag','FullSizeCheckbox'),'Value')			
            srsZoom=fullZoom;									
            oldZoom=local_getGUIzoom(fig,dimen);					
         else
            srsZoom=oldZoom;
         end
         local_setGUIzoom(fig,srsZoom);
      end % switch
      figure(fig);
   end % if ~isempty
end % while 1

if ishandle(fig)
   close(fig);
end

%--------------------------------------------------
% Local function to retrieve current zoom values from text boxes in GUI
function currzoom=local_getGUIzoom(fig,dimen)
if dimen ==4 % 4 dimensions
   currzoom=[str2num(get(findobj(fig,'Tag','XPos'),'String')) ...
         str2num(get(findobj(fig,'Tag','YPos'),'String')) ...
         str2num(get(findobj(fig,'Tag','ZPos'),'String')) ...
         str2num(get(findobj(fig,'Tag','tPos'),'String')) ...
         str2num(get(findobj(fig,'Tag','XSize'),'String')) ...
         str2num(get(findobj(fig,'Tag','YSize'),'String')) ... 
         str2num(get(findobj(fig,'Tag','ZSize'),'String')) ...
         str2num(get(findobj(fig,'Tag','tSize'),'String'))]; 
elseif dimen ==3 % 3 dimensions
   currzoom=[str2num(get(findobj(fig,'Tag','XPos'),'String')) ...
         str2num(get(findobj(fig,'Tag','YPos'),'String')) ...
         str2num(get(findobj(fig,'Tag','ZPos'),'String')) ...
         str2num(get(findobj(fig,'Tag','XSize'),'String')) ...
         str2num(get(findobj(fig,'Tag','YSize'),'String')) ... 
         str2num(get(findobj(fig,'Tag','ZSize'),'String'))]; 
else % 2 dimensions
   currzoom=[str2num(get(findobj(fig,'Tag','XPos'),'String')) ...
         str2num(get(findobj(fig,'Tag','YPos'),'String')) ...
         str2num(get(findobj(fig,'Tag','XSize'),'String')) ...
         str2num(get(findobj(fig,'Tag','YSize'),'String'))]; 
end 

%--------------------------------------------------
% Local function to set GUI zoom text boxes to specified values 
function local_setGUIzoom(fig,nextZoom)
if length(nextZoom) == 8 % 4 dimensions
   set(findobj(fig,'Tag','XPos'),'String',num2str(nextZoom(1)));
   set(findobj(fig,'Tag','YPos'),'String',num2str(nextZoom(2)));
   set(findobj(fig,'Tag','ZPos'),'String',num2str(nextZoom(3)));
   set(findobj(fig,'Tag','tPos'),'String',num2str(nextZoom(4)));
   set(findobj(fig,'Tag','XSize'),'String',num2str(nextZoom(5)));
   set(findobj(fig,'Tag','YSize'),'String',num2str(nextZoom(6)));
   set(findobj(fig,'Tag','ZSize'),'String',num2str(nextZoom(7)));
   set(findobj(fig,'Tag','tSize'),'String',num2str(nextZoom(8)));
elseif length(nextZoom) == 6 % 3 dimensions
   set(findobj(fig,'Tag','XPos'),'String',num2str(nextZoom(1)));
   set(findobj(fig,'Tag','YPos'),'String',num2str(nextZoom(2)));
   set(findobj(fig,'Tag','ZPos'),'String',num2str(nextZoom(3)));
   set(findobj(fig,'Tag','XSize'),'String',num2str(nextZoom(4)));
   set(findobj(fig,'Tag','YSize'),'String',num2str(nextZoom(5)));
   set(findobj(fig,'Tag','ZSize'),'String',num2str(nextZoom(6)));  
else % 2 dimensions
   set(findobj(fig,'Tag','XPos'),'String',num2str(nextZoom(1)));
   set(findobj(fig,'Tag','YPos'),'String',num2str(nextZoom(2)));
   set(findobj(fig,'Tag','XSize'),'String',num2str(nextZoom(3)));
   set(findobj(fig,'Tag','YSize'),'String',num2str(nextZoom(4))); 
end

% Modification History:
%
% $Log: getzoom.m,v $
% Revision 1.3  2005/02/03 16:58:39  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:37  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/08/27 22:24:20  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2001/01/23. Changed function name to lowercase.
%                                Changed zoomgui() to lowercase.
% Charles Michelich, 2000/03/25. Removed requirement that x & y sizes be powers of 2
% Charles Michelich, 1999/05/31. Added support for 4D zooming.
% Francis Favorini,  1999/05/10. Deselect controls after user interacts with them.
% Charles Michelich, 1999/05/03. Added support for 3D zooming.
%                                Added check for non-integer zoom.
% Francis Favorini,  1998/09/28. Added error checking.
% Francis Favorini,  1998/09/23. Added Full Size option and made smarter.
% Francis Favorini,  1998/09/18.
