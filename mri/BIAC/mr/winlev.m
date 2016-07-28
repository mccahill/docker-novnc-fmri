function actReturned_h=winlev(action)
% WINLEV - GUI to window and level an image interactively
%
%  WINLEV_H = WINLEV(HANDLE)
%  
%  handle - Handle of the image(s) to be windowed and leveled
%         - OR handle of the axes containing the image
%         - OR handle of the figure containing the image
%  
%  winlev_h - Handle of the window & level GUI figure 
%
%  Note: If the figure or axes specified contain more than one image,
%        the function will generate an appropriate error.
%
%  Note: If more than one image handle is passed, the winlev will 
%        control all of the images.  The current clipping levels will
%        be taken from the first image, but the histogram will be generated
%        using all three images.  Invalid handles are ignored if multiple
%        handles are passed.
%
%  WINLEV with no arguments in the same as WINDOWLEVEL(gco)
%         
% See also: ISWINLEV, ISWINLEVFORFIG
%

%  GUI Function documentation - Callbacks from the GUI are implemented in this function also
%
%  Callbacks from the GUI are implemented as a string switch in this function.  These functions can 
%  only be accessed from callbacks.  The following are valid cases for the switch (HANDLE)
%
%    %These 3 functions are used to graphically move the upper clipping limit
%      'startUpperClim' - Start moving the upper clipping limit (on a button down)
%      'moveUpperClim'  - Update the upper clipping limit as the cursor moves
%      'stopMotion'     - Stop moving the upper clipping limit (on a button up)
%
%    % These 3 functions are used to graphically move the lower clipping limit
%       'startLowerClim' - Start moving the lower clipping limit (on a button down)
%       'moveLowerClim'  - Update the lower clipping limit as the cursor moves
%       'stopMotion'     - Stop moving the lower clipping limit (on a button up)  
%
%       'setClim' - Update the upper and lower clipping limits from the values in the text boxes
%

% PUBLIC INFORMATION
%
%  Do not change the functionality of the following statements without making appropriate modifications
%  to the listed functions.
%
%  Used by iswinlev & iswinlevforfig:
%  strcmp(get(winlev_h,'Tag'),'winlevGUI') => True if a window & level GUI
%                get(winlev_h,'UserData') => Returns a vector of the image handles controlled by this winlev GUI
%
%   where winlev_h is the handle to the winlev GUI

% CVS ID and authorship of this code
% CVSId = '$Id: winlev.m,v 1.3 2005/02/03 16:58:45 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:45 $';
% CVSRCSFile = '$RCSfile: winlev.m,v $';

% Check the number of arguments
error(nargchk(0,1,nargin));

% If no arguments are given, look for an image in the current figure
if nargin == 0
  action = gco;
  if isempty(action), action = gcf; end
end

returned_h = []; % Initialize returned_h to empty so that returned value is always exists

% If a handle has been passed, bring up the GUI

if any(ishandle(action))
  
  if length(action) > 1
    % More than one handle passed.
    % Only allow elimination of bad handles 
    %   and multiple handles if handles passed
    %   are 'image' handles 
    
    % Eliminate invalid handles
    action = action(ishandle(action));
  
    % Make sure that all handles are 'image' handles
    % Find out what type each action handles is
    if any(~strcmp(get(action,'Type'),'image'));
      error('Please specify an single handle to search for images!')
    end          

    % All of the valid handles passed are images, keep all valid handles
    image_h = action;
  else
    % A single handle was passed, search for images in it
    
    % Find all 'image' objects in action and action's children
    image_h = findobj(action,'Type','image');
    
    % Check for images in parent of specified handle (if no images have been found yet)
    parent_h = action;
    n=1;              % Limit search to 30 loops
    while length(image_h) == 0 & ~isempty(get(parent_h,'Parent')) & n < 30
      n=n+1;
      parent_h=get(parent_h,'Parent');
      image_h = findobj(parent_h,'Type','image');
    end
    
    % If there are zero or more than one 'image' objects, generate an appropriate error msg
    if length(image_h) >1
      switch get(action,'Type')     
      case 'figure'
        error('More than one image in figure! Please click on image desired and type winlev again.')
      case 'axes'
        error('More than one image in axes! Please click on image desired and type winlev again.')
      otherwise
        error('More than one image specified! Please click on image desired and type winlev again.');
      end
    elseif length(image_h) == 0
      error('Handle specified contains no valid images. Please click on image desired and type winlev again.');      
    end
  end
  
  % Check to see a winlev GUI is already open for this image
  % Note: Must show all hidden handles to allow us to check for winlevGUI's
  currState = get(0,'ShowHiddenHandles');                  % Read current state
  set(0,'ShowHiddenHandles','on');                         % Make all handles visible
  currGUI = findobj('UserData',image_h,'Tag','winlevGUI'); % Check for gui's for this image
  set(0,'ShowHiddenHandles',currState);                    % Set back to previous state
  
  if ~isempty(currGUI);
    % If a winlev GUI is already open for this image, make it the active figure
    figure(currGUI);
    
    % Return the currentGUI handle
    returned_h = currGUI;
    
  else  
    % Otherwise, open a winlevGUI for this image
    
    % Check to see if the CDataMapping mode is scaled
    if any(~strcmp(get(image_h,'CDataMapping'),'scaled'))
      error('This function will not work on this image type (Must use ''scaled'' CDataMapping)');
    end
    
    % Find the axes and figure of the image handle
    imageaxes_h = get(image_h,'Parent');
    if iscell(imageaxes_h), imageaxes_h = [imageaxes_h{:}]; end       % Convert handle from cell to numeric array
    imagefigure_h = get(imageaxes_h,'Parent');
    if iscell(imagefigure_h), imagefigure_h = [imagefigure_h{:}]; end % Convert handle from cell to numeric array
    
    % Bring up the Window and Level GUI
    gui_h = local_winlevGUI;
    set(gui_h,'Name',['Window & Level GUI for Figure ' num2str(imagefigure_h)]);
    
    % Generate the histogram and initialize the text boxes
    local_generateHist(image_h,gui_h);
    
    % Store the handle of the image for use in later function calls
    set(gui_h,'UserData',image_h);
    
    % Turn the handle visiblity to callback on the GUI to prevent
    % the user from accidentally changing the GUI
    % Note: This must be done after local_generateHist because this function
    %       needs to find the children of gui_h.
    set(gui_h,'HandleVisibility','callback');

    % Return the new GUI handle
    returned_h = gui_h;
  end
  %---------If a string is passed through a callback, update the GUI appropriately---------- 
elseif ischar(action) & ~isempty(gcbf) 
  % Get handle to GUI (gcbf) since is it lost duing local_generateHist().
  gui_h = gcbf; 

  % The return the window & level GUI handle by default
  returned_h = gui_h;
  
  % Get the handles for the image
  image_h = get(gui_h,'UserData');
  
  % Make sure the image is still present
  if all(~ishandle(image_h))
    % All images gone
    close(gui_h)
    disp('Image is no longer present');
    
    % Handle the case when the image is still present   
  else
    % Remove the any missing image handles from the list (Don't attempt to update these windows)
    % and update the winlev GUI to reflect these changes (store new image_h, update histogram,
    % and update window title.    
    if any(~ishandle(image_h))
      image_h(~ishandle(image_h))=[];    % Remove missing handles      
      set(gui_h,'UserData',image_h);     % Update stored info
      local_generateHist(image_h,gui_h); % Update histogram (gcbf lost here for some reason???)
      
      % Update Window & Level GUI title
      imageaxes_h = get(image_h,'Parent');
      if iscell(imageaxes_h), imageaxes_h = [imageaxes_h{:}]; end       % Convert handle from cell to numeric array
      imagefigure_h = get(imageaxes_h,'Parent');
      if iscell(imagefigure_h), imagefigure_h = [imagefigure_h{:}]; end % Convert handle from cell to numeric array
      set(gui_h,'Name',['Window & Level GUI for Figure ' num2str(imagefigure_h)]);
    end
        
    % Get the other handles for the image parents
    imageaxes_h = get(image_h,'Parent');
    if iscell(imageaxes_h), imageaxes_h = [imageaxes_h{:}]; end         % Convert handle from cell to numeric array

    % Get the handles for the elements of the gui
    upperLimitText_h = findobj(gui_h,'Tag','UpperLimitText');
    windowText_h = findobj(gui_h,'Tag','WindowText');
    levelText_h = findobj(gui_h,'Tag','LevelText');
    updateImageCheckbox_h = findobj(gui_h,'Tag','UpdateImageCheckbox');
    winlevModeCheckbox_h = findobj(gui_h,'Tag','WinlevModeCheckbox');
    
    % Get the handles for the lines in the gui
    lowerLimitLine_h = findobj(gui_h,'Tag','LowerClimLine');
    upperLimitLine_h = findobj(gui_h,'Tag','UpperClimLine');
    
    switch action
      
    case 'startUpperClim'
      set(gui_h,'WindowButtonMotionFcn','winlev moveUpperClim');
      set(gui_h,'WindowButtonUpFcn','winlev stopMotion');
      
    case 'startLowerClim'
      set(gui_h,'WindowButtonMotionFcn','winlev moveLowerClim');
      set(gui_h,'WindowButtonUpFcn','winlev stopMotion');
      
    case 'moveUpperClim'
      currPt=get(gca,'CurrentPoint');      % Get the cursor Position
      currClim=get(imageaxes_h(1),'CLim'); % Get the current Clim settings (Use the first imageaxes_h if there are mulitple)
      clim=[currClim(1) currPt(1,1)];      % Set new clim
      
      % Don't allow user to move Upper limit past lower limit
      if clim(2) <= clim(1)
        clim(2) = clim(1)+0.001;
      end
      
      % Draw a new Threshold line at that level
      set(upperLimitLine_h,'XData',clim(2)*ones(1,11));
      
      % Update the Window and Upper Limit Text box
      set(windowText_h,'String',num2str(clim(2)-clim(1)));
      set(upperLimitText_h,'String',num2str(clim(2)));
      
      % Update the clipping limits on the image
      if get(updateImageCheckbox_h,'Value') == 1
        set(imageaxes_h,'CLim',clim);
      end
      
      drawnow;
      
    case 'moveLowerClim'
      currPt=get(gca,'CurrentPoint');      % Get the cursor Position
      currClim=get(imageaxes_h(1),'CLim'); % Get the current Clim settings  (Use the first imageaxes_h if there are mulitple)
      
      if get(winlevModeCheckbox_h,'Value') == 1  % Keep constant window (Winlev Mode)
        % Calculate new clim (Keep a constant window)
        clim=[currPt(1,1),currPt(1,1)+currClim(2)-currClim(1)];
        
        % Draw a new UpperLimit line
        set(upperLimitLine_h,'XData',clim(2).*ones(1,11));
        
        % Update the Window and Upper Limit Text box
        set(upperLimitText_h,'String',num2str(clim(2)));
      else    
        % Calculate new clim
        clim=[currPt(1,1),currClim(2)];
        
        % Don't allow user to move lower limit past upper limit
        if clim(1) >= clim(2)
          clim(1) = clim(2)-0.001;
        end
        
        % Update the Window Text Box
        set(windowText_h,'String',num2str(clim(2)-clim(1)));
      end
      
      % Draw a new Threshold line at that level
      set(lowerLimitLine_h,'XData',clim(1)*ones(1,11));
      
      % Update the Level Text boxes
      set(levelText_h,'String',num2str(clim(1)));
      
      % Update the clipping limits on the image
      if get(updateImageCheckbox_h,'Value') == 1
        set(imageaxes_h,'CLim',clim);
      end
      
    case 'stopMotion'
      set(gui_h,'WindowButtonMotionFcn','');
      set(gui_h,'WindowButtonUpFcn','');
      
      clim(1) = max(get(lowerLimitLine_h,'XData'));
      clim(2) = max(get(upperLimitLine_h,'XData'));
      
      set(imageaxes_h,'CLim',clim);
      
    case 'setClim'
      
      clim = get(imageaxes_h(1),'CLim');  % Get the current Clim settings  (Use the first imageaxes_h if there are mulitple)
      
      clim(1) = str2num(get(levelText_h,'String'));
      if get(winlevModeCheckbox_h,'Value') == 1           % Window and Level Mode  
        clim(2) = str2num(get(windowText_h,'String'))+str2num(get(levelText_h,'String'));
        set(upperLimitText_h,'String',num2str(clim(2)));
      else                                                % Upper and Lower Limit Mode
        clim(2) = str2num(get(upperLimitText_h,'String')); 
        set(windowText_h,'String',num2str(clim(2)-clim(1))); 
      end  
      
      % If the user tries to enter an invalid clim, return to original (of first imageaxes_h)
      % TODO: Return each image to its own original?
      if clim(1) >= clim(2)
        clim = get(imageaxes_h(1),'Clim');  % Get the current Clim settings  (Use the first imageaxes_h if there are mulitple)
        set(levelText_h,'String',num2str(clim(1)));
        set(windowText_h,'String',num2str(clim(2)-clim(1)));
        set(upperLimitText_h,'String',num2str(clim(2)));
      end
      % TODO: Give better feedback to user
      
      set(lowerLimitLine_h,'XData',clim(1)*ones(1,11));
      set(upperLimitLine_h,'XData',clim(2)*ones(1,11));
      
      set(imageaxes_h,'CLim',clim);
      
    case 'refreshHist'
      % Generate the histogram and initialize the text boxes
      local_generateHist(image_h,gui_h);
      
    case 'switchWinlevModes'
      if get(winlevModeCheckbox_h,'Value') == 1 % Window and Level Mode
        set(upperLimitText_h,'Enable','off')
        set(windowText_h,'Enable','on')
      else                                      % Upper and Lower Limit Mode
        set(upperLimitText_h,'Enable','on')
        set(windowText_h,'Enable','off')
      end  
  
    otherwise
      error('Callback action not recognized')
    end
    
    % Generate an appropriate error for an incorrect type of input 
  end
  
else
  error('Argument passed to function is not recognized')
end

% Assign returned handle if it was requested
if nargout == 1
  actReturned_h = returned_h;
end

%----------------------------------- local_generateHist -------------------------
function local_generateHist(image_h,gui_h)
% This function generates a histogram from the data at image_h on the GUI at gui_h
% The function retreives the clim from the image and updates the GUI appropriately
%

% Find the axes of the image handle and gui handle
imageaxes_h = get(image_h,'Parent');
if iscell(imageaxes_h), imageaxes_h = [imageaxes_h{:}]; end % Convert handle from cell to numeric array
guiaxes_h = findobj(gui_h,'Type','axes');

% Get the image data and the current clipping limits of the image
imagedata = get(image_h(1), 'CData');
if length(image_h) > 1
  % If there is more than one image handle, cat the image data from
  % each image into one long vector
  imagedata = reshape(imagedata,[prod(size(imagedata)),1]);
  for n=2:length(image_h)
    currimagedata = get(image_h(n),'CData');
    imagedata = cat(1,imagedata,reshape(currimagedata,[prod(size(currimagedata)),1]));
  end
end
clim = get(imageaxes_h(1),'CLim'); % Get the current Clim settings  (Use the first imageaxes_h if there are mulitple)

% Generate a histogram of the image
axes(guiaxes_h);
hist(imagedata(:),100);

% Find the limits of the Y axis of the histogram and plot lines at the 
% upper and lower clipping limits
ylim = get(gca,'YLim');

line(clim(1)*ones(1,11),ylim(1):(ylim(2)-ylim(1))/10:ylim(2), ...
  'Tag','LowerClimLine', ...
  'ButtonDownFcn','winlev startLowerClim', ...
  'LineWidth',2);

line(clim(2)*ones(1,11),ylim(1):(ylim(2)-ylim(1))/10:ylim(2), ...
  'Tag','UpperClimLine', ...
  'ButtonDownFcn','winlev startUpperClim', ...
  'LineWidth',2);

% Update the Upper and Lower Limit Text boxes in the GUI
windowText_h = findobj(gui_h,'Tag','WindowText');
levelText_h = findobj(gui_h,'Tag','LevelText');
upperLimitText_h = findobj(gui_h,'Tag','UpperLimitText');

set(windowText_h,'String',clim(2)-clim(1));
set(levelText_h,'String',clim(1));
set(upperLimitText_h,'String',clim(2));

%------------------------------------- local_winlevGUI --------------------------
function fig = local_winlevGUI()
% This function generates the GUI for the winlev function

labelBackground=[0.701960784313725 0.701960784313725 0.701960784313725];

% Get screen size
oldRootUnits=get(0,'Units');
set(0,'Units','points');
screenSz=get(0,'ScreenSize');
set(0,'Units',oldRootUnits);

% Main Figure
main_h = figure('Color',[0.8 0.8 0.8], ...
  'Units','points', ...
  'MenuBar','none', ...
  'Name','Window & Level GUI', ...
  'NumberTitle','off', ...
  'Tag','winlevGUI', ...
  'Position',[screenSz(3)-240, screenSz(4)-180, 230, 160]);

% Histgram Axes
axes('Parent',main_h, ...
  'Units','points', ...  
  'Position',[30 65 120 80], ...
  'Box','on', ...
  'Tag','HistAxes');

% Text Boxes and labels
% Upper Limit
uicontrol('Parent',main_h, ...
  'Units','points', ...
  'BackgroundColor',[1 1 1], ...
  'Callback','winlev setClim', ...
  'Enable','on', ...
  'Position',[170 135 50 15], ...
  'Style','edit', ...
  'Tag','UpperLimitText');
uicontrol('Parent',main_h, ...
  'Units','points', ...
  'BackgroundColor',labelBackground, ...
  'Position',[170 123 50 12], ...
  'String','Upper Limit', ...
  'Style','text', ...
  'Tag','UpperLimitStaticText');
% Window
uicontrol('Parent',main_h, ...
  'Units','points', ...
  'BackgroundColor',[1 1 1], ...
  'Callback','winlev setClim', ...
  'Enable','off',...
  'Position',[170 100 50 15], ...
  'Style','edit', ...
  'Tag','WindowText');
uicontrol('Parent',main_h, ...
  'Units','points', ...
  'BackgroundColor',labelBackground, ...
  'Position',[170 88 50 12], ...
  'String','Window', ...
  'Style','text', ...
  'Tag','WindowStaticText');
% Level
uicontrol('Parent',main_h, ...
  'Units','points', ...
  'BackgroundColor',[1 1 1], ...
  'Callback','winlev setClim', ...
  'Position',[170 65 50 15], ...
  'Style','edit', ...
  'Tag','LevelText');
uicontrol('Parent',main_h, ...
  'Units','points', ...
  'BackgroundColor',labelBackground, ...
  'Position',[170 53 50 12], ...
  'String','Level', ...
  'Style','text', ...
  'Tag','LevelStaticText');

% Checkboxes
uicontrol('Parent',main_h, ...
  'Units','points', ...
  'BackgroundColor',labelBackground, ...
  'Callback','winlev switchWinlevModes', ...
  'Position',[10 25 120 15], ...
  'String','Window and Level Mode', ...
  'Style','checkbox', ...
  'Value',0, ...
  'Tag','WinlevModeCheckbox');
uicontrol('Parent',main_h, ...
  'Units','points', ...
  'BackgroundColor',labelBackground, ...
  'Position',[10 10 120 15], ...
  'String','Update Image While Moving', ...
  'Style','checkbox', ...
  'Value',1, ...
  'Tag','UpdateImageCheckbox');

% Buttons
uicontrol('Parent',main_h, ...
  'Units','points', ...
  'Callback','winlev refreshHist', ...
  'BackgroundColor',labelBackground, ...
  'Position',[145 17 75 15], ...
  'String','Refresh Histogram', ...
  'Style','pushbutton', ...
  'Tag','RefreshHistButton');

if nargout > 0, fig = main_h; end

% Modification History:
%
% $Log: winlev.m,v $
% Revision 1.3  2005/02/03 16:58:45  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:40  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/08/27 22:24:26  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:

% History:
% Charles Michelich, 2001/09/27. Charles Michelich rev 11 Updated comments and got replaces tabs with spaces
%                                Added semicolon to local_generateHist(image_h,gui_h);
% Charles Michelich, 2001/09/21. Updated comments
%                                Fixed handling of multiple image_h.  Was searching for images even if there were multiple handles.
% Charles Michelich, 2001/09/15. Added explicit check for that only one handle passed must be valid.
%                                Don't search invalid handles for images.
%                                Added explicit check to not allow search for images in more than one handle.
%                                Changed to remove invalid image handles on callbacks 
%                                gcbf was changing to empty during local_generatehist (in removable of invalid images.)
%                                Copied into gcbf into gui_h and used that instead of all callbacks.
% Charles Michelich, 2001/09/15. Added option to return of window & level GUI handle
% Charles Michelich, 2001/09/14. Changed to allow multiple images to be updated with the same winlev GUI.
% Charles Michelich, 2001/07/01. Changed checkbox defaults to Window/Level Mode OFF and Update Image While Moving ON
% Charles Michelich, 2001/02/15. Increase width of lines on histogram to make them easier to grab
% Charles Michelich, 2000/02/23. Changed handle visibility of GUI to callback to prevent user from overwriting GUI
% Charles Michelich, 1999/11/12. Fixed search for image handles in parents
%                                Added feature to activate current tool  if the image already has a winlevGUI
%                                Corrected bug while using constant window during update while moving
% Charles Michelich, 1999/11/11. Changed EraseMode on Clim Lines to 'xor' for faster drawing
%                                Changed to use gco by default instead of gcf (allows user to click desired image)
%                                Added search through parents of of handle for images (max 30 levels)
%                                Added window and level mode
%                                Added Refresh histogram button
%                                Moved GUI into local function of winlev
% Charles Michelich, 1999/06/02. Changed to restrict user from crossing lines (clim(1) must be > clim(2))
% Charles Michelich, 1999/04/21. original
