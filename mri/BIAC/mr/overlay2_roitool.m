function gui_h = overlay2_roitool(varargin)
%OVERLAY2_ROITOOL - Tools for drawing and saving ROIs using OVERLAY2
%
%   gui_h = overlay2_roitool(h)
%      Launch roitool GUI for overlay2 figure h.  Or if GUI already 
%      exists, make it the current figure.  gui_h is the handle of
%      the transparency GUI.
%
%   overlay2_roitool('callback_name', ...) invoke the named callback.
%
%  This function is intended for internal use by overlay2.
%
% -----------------------------------------------------------------------------
% OVERLAY2 ROI Drawing Tool Configuration File format
%
% Users of the ROI Drawing Tool may generate a text file to set the ROI 
% Buttons and list of ROIs available in the ROI Drawing Tool of overlay2.
%
% This file can also be used to specify the default values for many of the 
% options in the GUI.
%
% The file consists of a plain text file of keyword, value pairs in the 
% format keyword=value.  Blank lines and those that start with % are ignored. 
%
% The required and optional keywords are listed below:
%
% Required Keywords:
%   ARFULL - Full list of anatomical ROIs to save
%          - Format is a three letter abbreviation followed
%              by a '-' then a decription (not case sensitive)
%              (i.e. ARFULL=MFG-middle frontal gyrus )
%          - There is not a limit on the number of ROI names 
%            that can be specified.
%
%   ARHOT  - Buttons for quickly saving ROIs
%          - Format is a three letter abbreviation (not case sensitive)
%              (i.e. ARHOT=MFG )
%          - The ARHOT abreviations must be in ARFULL
%          - There can be a maximum of 35 ARHOT buttons
%
% Optional Keywords (each can only occur once):
%   AutoExam     - Automatically determine exam number? (0-no,1-yes)
%   ExamNumber   - Default exam number (ignored if AutoExam is on)
%   AutoSlice    - Automatically determine slice number? (0-no,1-yes)
%   SliceNumber  - Default slice number (ignored if AutoSlice is on)
%   Orientation  - Default orientation (1-none,2-axial,3-coronal,4-saggital)
%   Hemisphere   - Default Hemisphere (1-none,2-right,3-left)
%   SameLimits   - Use the same limits for drawing next ROI as used for
%                  drawing last ROI (0-no,1-yes)
%   AutoDefine   - Automatically start defining a new ROI after
%                  saving an ROI? (0-no,1-yes)
%   SavePath     - Default path to save ROIs in.
%                  currentExperimentPath\Analysis\ROI used by default if
%                  pwe has been set with chexp.  Other pwd is used.
%   ROIFilenameFunction - String evaluated using eval() to generate filename
%                - The following strings variables are available for 
%                  use in constructing the filename:
%                    exam,slice,hemisphere,orientation,region
%               - Setting the hemisphere or orientation drop down menus
%                 to <none> will set their respective variables to ''
%               - If not specified or invalid, the default will be used.

% -----------------------------------------------------------------------------
%
% See Also: OVERLAY2, CHEXP, READKVF

% CVS ID and authorship of this code
% CVSId = '$Id: overlay2_roitool.m,v 1.17 2005/02/16 02:53:45 michelich Exp $';
% CVSRevision = '$Revision: 1.17 $';
% CVSDate = '$Date: 2005/02/16 02:53:45 $';
% CVSRCSFile = '$RCSfile: overlay2_roitool.m,v $';

if nargin == 0 | nargout ~= 0
  error('Incorrect arguments for overlay2_roitool!');
elseif ~ischar(varargin{1}) % LAUNCH GUI
  
  if str2double(strtok(strtok(version),'.')) < 6
    errordlg('ROI Drawing Tool will only work in MATLAB 6.0 or later!');
    return;
  end
  
  if ishandle(varargin{1})
    overlay2_h = varargin{1};
  else
    errordlg('Invalid Handle');        
  end
  
  % Check if a ROI Window is already open for this overlay2 window
  currROIWin = get(findobj(overlay2_h,'Tag','ROIToolItem'),'UserData');
  if ~isempty(currROIWin) & ishandle(currROIWin);
    % If one is open, bring it to the front
    figure(currROIWin)
  else
  % Otherwise open a new one
    
    fig = openfig(mfilename);

    % Generate a structure of handles to pass to callbacks, and store it. 
    handles = guihandles(fig);
    handles.overlay2_h = overlay2_h;
    guidata(fig, handles); % Store the structure

    % Put handle to ROI Window in uimenu UserData (in overlay2)
    set(findobj(handles.overlay2_h,'Tag','ROIToolItem'),'UserData',fig);
    
    %  --- Redirect the Define and Grow buttons to use overlay2_roitool ---
    overlay2_define_h = findobj(handles.overlay2_h,'Tag','ROIDefButton');
    % Store the original callback in the overlay2_roitool Define button userdata
    set(handles.DefineButton,'UserData',get(overlay2_define_h,'Callback'));
    % Set the new callback
    set(overlay2_define_h,'Callback', ...
      'overlay2_roitool(''DefineButton_Callback'',[],[],guidata(get(findobj(gcbf,''Tag'',''ROIToolItem''),''UserData'')))');    

    overlay2_grow_h = findobj(handles.overlay2_h,'Tag','ROIGrowButton');
    % Store the original callback in the overlay2_roitool Define button userdata
    set(handles.GrowButton,'UserData',get(overlay2_grow_h,'Callback'));
    % Set the new callback   
    set(overlay2_grow_h,'Callback', ...
      'overlay2_roitool(''GrowButton_Callback'',[],[],guidata(get(findobj(gcbf,''Tag'',''ROIToolItem''),''UserData'')))');
    
    % Initialize the GUI
    local_initgui(handles);
    
    if nargout > 0
      gui_h = fig;
    end
  end
else % INVOKE NAMED SUBFUNCTION OR CALLBACK
  try
    feval(varargin{:}); % FEVAL switchyard
  catch
    disp(lasterr);
  end
end

%| ABOUT CALLBACKS:
%| GUIDE automatically appends subfunction prototypes to this file, and 
%| sets objects' callback properties to call them through the FEVAL 
%| switchyard above. This comment describes that mechanism.
%|
%| Each callback subfunction declaration has the following form:
%| <SUBFUNCTION_NAME>(H, EVENTDATA, HANDLES, VARARGIN)
%|
%| The subfunction name is composed using the object's Tag and the 
%| callback type separated by '_', e.g. 'slider2_Callback',
%| 'figure1_CloseRequestFcn', 'axis1_ButtondownFcn'.
%|
%| H is the callback object's handle (obtained using GCBO).
%|
%| EVENTDATA is empty, but reserved for future use.
%|
%| HANDLES is a structure containing handles of components in GUI using
%| tags as fieldnames, e.g. handles.figure1, handles.slider2. This
%| structure is created at GUI startup using GUIHANDLES and stored in
%| the figure's application data using GUIDATA. A copy of the structure
%| is passed to each callback.  You can store additional information in
%| this structure at GUI startup, and you can change the structure
%| during callbacks.  Call guidata(h, handles) after changing your
%| copy to replace the stored original so that subsequent callbacks see
%| the updates. Type "help guihandles" and "help guidata" for more
%| information.
%|
%| VARARGIN contains any extra arguments you have passed to the
%| callback. Specify the extra arguments by editing the callback
%| property in the inspector. By default, GUIDE sets the property to:
%| <MFILENAME>('<SUBFUNCTION_NAME>', gcbo, [], guidata(gcbo))
%| Add any extra arguments after the last argument, before the final
%| closing parenthesis.

% --------------------------------------------------------------------
function ExamNumber_Callback(h, eventdata, handles)
% Callback for the exam number edit box

% Show feedback to user
set(handles.LastEventText,'ForegroundColor','default','String', ...
  sprintf('Exam Number changed to %s',get(handles.ExamNumber,'String')));

% Exam number changed, update the ROI name and clear the ROI pushbuttons
local_updateRoiFilename(handles);
local_ClearPushButtons(handles.overlay2_roitoolFig);

% --------------------------------------------------------------------
function AutoExam_Callback(h, eventdata, handles)
% Callback for AutoExam checkbox.
%
% If checked, attempt to calculate the exam number.
% If not, enable the edit box.
% If isempty(h) & AutoExam is off LastEventText will not be updated
%
% Updates ROI filename on all calls.

% Save the last exam string
lastExamString = get(handles.ExamNumber,'String');

if get(handles.AutoExam,'Value') == 1
  % Auto Exam is ON, attempt to determine the exam number
  
  if isempty(get(handles.SavePath,'String'))
    % If SavePath is not set, tell user and disable AutoExam
    set(handles.LastEventText,'ForegroundColor','red','String','ERROR: Please Select Save Directory first');
    set(handles.AutoExam,'Value',0);
    set(handles.ExamNumber,'enable','on');
  else
    
    % Get the deepest directory in the SavePath
    searchDir = get(handles.SavePath,'String');
    
    % Break the path at its file separators
    delim = filesep; if delim == '\', delim = '\\'; end  % Escape out a single \
    k=strread(searchDir,'%s','delimiter',delim);
    
    % Search for any numeric elements in the path 
    % TODO: Search for number_number also.
    for n=length(k):-1:1
      str = str2double(k{n});
      if ~isnan(str), break; end
    end
    
    if isnan(str), 
      % Unable to determine exam number.
      set(handles.LastEventText,'ForegroundColor','red','String','ERROR: Exam Number could not be determined');
      set(handles.AutoExam,'Value',0);
      set(handles.ExamNumber,'Enable','on');
    else
      % Found the exam number.
      set(handles.ExamNumber,'String',str);
      set(handles.ExamNumber,'Enable','off');
      set(handles.LastEventText,'ForegroundColor','default','String',sprintf('Exam Number changed to %d',str));
    end
  end
else
  % Auto Exam is OFF, enable the edit field.
  if ~isempty(h)
    % Only show this message this is a callback from checking the box
    set(handles.LastEventText,'ForegroundColor','default','String','Auto Exam Number turned off');
  end
  set(handles.ExamNumber,'enable','on');
end

% Update the ROI name
local_updateRoiFilename(handles);

% Clear ROI pushbuttons if exam number changed. 
if ~strcmp(lastExamString,get(handles.ExamNumber,'String'))
  local_ClearPushButtons(handles.overlay2_roitoolFig);
end

% --------------------------------------------------------------------
function SliceNumber_Callback(h, eventdata, handles)
% Callback for the slice number edit box

% Show feedback to user
set(handles.LastEventText,'ForegroundColor','default','String', ...
  sprintf('Slice Number changed to %s',get(handles.SliceNumber,'String')));

% Slice number changed, update the ROI name and clear the ROI pushbuttons
local_updateRoiFilename(handles);
local_ClearPushButtons(handles.overlay2_roitoolFig);

% --------------------------------------------------------------------
function AutoSlice_Callback(h, eventdata, handles)
% Callback for AutoSlice checkbox.
%
% If checked, attempt to calculate the slice string.
% If not, enable the edit box.
% If isempty(h) & AutoSlice is off LastEventText will not be updated
%
% Updates ROI filename on all calls.

% Save the last slice string
lastSliceString = get(handles.SliceNumber,'String');

if get(handles.AutoSlice,'Value') == 1
  % Auto Slice is ON, attempt to determine the slice number

  % Disable editing the slice number
  set(handles.SliceNumber,'Enable','off');
  
  % Get ROIs from overlay2 window
  ROIs = local_getROIs(handles.overlay2_h);
  
  if isempty(ROIs) | isempty(ROIs(1).slice)
    % If there are no ROIs, cannot determine slice number
    % tell user and set slice to ''
    set(handles.LastEventText,'ForegroundColor','red','String','ERROR: Can''t find slice number! Need an ROI!');
    set(handles.SliceNumber,'String','');
  else
    roi=ROIs(1); % Current ROI is first in the list

    % Construct the slice string
    minMaxSlices = minmax(roi.slice);
    if minMaxSlices(1) ~= minMaxSlices(2)
      % If there are multiple slices, construct slice string using min and
      % max slices numbers.
      sliceString = sprintf('%02d-%02d',minMaxSlices(1),minMaxSlices(2));
    else
      % Name using the only slice.
      sliceString = sprintf('%02d',minMaxSlices(1));
    end
    
    % Display the slice string
    set(handles.SliceNumber,'String',sliceString);
    if ~strcmp(lastSliceString,sliceString)
      % Only show this message if the slice number changed.
      set(handles.LastEventText,'ForegroundColor','default','String',sprintf('Slice Number set to %s',sliceString));
    end
  end
else
  % Auto Slice is OFF, enable the edit field.
  if ~isempty(h)
    % Only show this message this is a callback from checking the box
    set(handles.LastEventText,'ForegroundColor','default','String','Auto Slice Number turned off');
  end
  set(handles.SliceNumber,'Enable','on');
end

% Update the ROI name
local_updateRoiFilename(handles);

% Clear ROI pushbuttons if slice number changed. 
if ~strcmp(lastSliceString,get(handles.SliceNumber,'String'))
  local_ClearPushButtons(handles.overlay2_roitoolFig);
end

% --------------------------------------------------------------------
function Orientation_Callback(h, eventdata, handles)
% Callback for the orientation down down list

% Show feedback to user
names = get(handles.Orientation,'String');
set(handles.LastEventText,'ForegroundColor','default','String',...
  sprintf('Hemisphere changed to %s',names{get(handles.Orientation,'Value')}));

% Orientation changed, update the ROI name and clear the ROI pushbuttons
local_updateRoiFilename(handles);
local_ClearPushButtons(handles.overlay2_roitoolFig);

% --------------------------------------------------------------------
function Hemisphere_Callback(h, eventdata, handles)
% Callback for the hemisphere drop down list.

% Show feedback to user
names = get(handles.Hemisphere,'String');
set(handles.LastEventText,'ForegroundColor','default','String',...
  sprintf('Hemisphere changed to %s',names{get(handles.Hemisphere,'Value')}));

% Hemisphere changed, update the ROI name and clear the ROI pushbuttons
local_updateRoiFilename(handles);
local_ClearPushButtons(handles.overlay2_roitoolFig);

% --------------------------------------------------------------------
function AR_Callback(h, eventdata, handles)
% Callback for the ROI drop down list

% Show feedback to user
names = get(handles.AR,'String'); 
set(handles.LastEventText,'ForegroundColor','default','String',... 
  sprintf('ROI changed to %s',names{get(handles.AR,'Value')}));

% Update ROIname
local_updateRoiFilename(handles);

% --------------------------------------------------------------------
function ARButton_Callback(h, eventdata, handles)
% Callback for the ROI buttons
%
% h = handle of pushbutton pressed.

% Set the Anatomical region to the correct entry for the current button.
% (index stored in button's UserData)
set(handles.AR,'Value',get(h,'UserData'));

% Save the ROI.
SaveButton_Callback([], eventdata, handles);

% --------------------------------------------------------------------
function DefineButton_Callback(h, eventdata, handles)
% Callback for define ROI button
%
% Uses overlay2 callback for most of the work.
%

% Check number of ROIs before starting (to see if define was sucessful)
nROIs = length(local_getROIs(handles.overlay2_h));

% Attempt to define the ROI
set(handles.LastEventText,'ForegroundColor','default','String','Defining...Press Enter before clicking to Cancel');
overlay2('GUIROIDef',handles.overlay2_h,get(handles.SameLimits,'Value'));

% Check if an ROI was actually defined.
if nROIs == length(local_getROIs(handles.overlay2_h))
  set(handles.LastEventText,'ForegroundColor','red','String','ERROR: New ROI not defined');
else
  % Tell user it was defined
  set(handles.LastEventText,'ForegroundColor','default','String','ROI Definition Completed');
end

% Update same limits string (on sucess or failure because some
% failure paths can change the limits).
local_updateSameLimitsString(handles.overlay2_h,handles.SameLimits);

% --------------------------------------------------------------------
function GrowButton_Callback(h, eventdata, handles)
% Callback for grow ROI button
%
% Uses overlay2 callback for most of the work.
%

% Check number of voxels in current ROI before starting (to see if grow was sucessful)
ROIs = local_getROIs(handles.overlay2_h);
if isempty(ROIs)
  % Display error box for consistency with errors shown overlay2_roitool is not open.
  errorbox('There are no ROI''s to grow.');
  set(handles.LastEventText,'ForegroundColor','red','String','ERROR: There are no ROI''s to grow');
  return;
end
nVoxels=sum(cellfun('length',ROIs(1).index));

% Attempt to define the ROI
set(handles.LastEventText,'ForegroundColor','default','String','Growing ...Press Enter before clicking to Cancel');
overlay2('GUIROIGrow',handles.overlay2_h,get(handles.SameLimits,'Value'));

% Check if current ROI actual grew.
ROIs = local_getROIs(handles.overlay2_h);
if nVoxels == sum(cellfun('length',ROIs(1).index))
  set(handles.LastEventText,'ForegroundColor','red','String','ERROR: Current ROI did not grow');
else
  % Tell user it was defined
  set(handles.LastEventText,'ForegroundColor','default','String','Grow Current ROI Operation Complete');
end

% Update same limits string (on sucess or failure because some
% failure paths can change the limits).
local_updateSameLimitsString(handles.overlay2_h,handles.SameLimits);

% --------------------------------------------------------------------
function SaveButton_Callback(h, eventdata, handles)
% Callback for the Save button
%
%  Save an ROI using the current item selected from the anatomical
%  region drop down list.

% Get a list of ROIs from overlay2 windows
ROIs = local_getROIs(handles.overlay2_h);

% Tell user if there are no ROIs defined.
if isempty(ROIs)
  set(handles.LastEventText,'ForegroundColor','red','String','ERROR: ROI not defined!');
  return;
end

% Update ROI filename
local_updateRoiFilename(handles);

% Check that exam number, slice number, and output directory are set.
if isempty(get(handles.ExamNumber,'String'))
  set(handles.LastEventText,'ForegroundColor','red','String','ERROR: Please select Exam Number');
  return;
end
if isempty(get(handles.SliceNumber,'String'))
  set(handles.LastEventText,'ForegroundColor','red','String','ERROR: Please select Slice Number');
  return;
end
if isempty(get(handles.SavePath,'String'))
  set(handles.LastEventText,'ForegroundColor','red','String','ERROR: Please select Save Path');
  return;
end
if isempty(get(handles.SaveAs,'String'))
  set(handles.LastEventText,'ForegroundColor','red','String','ERROR: Unable to generate ROI filename!');
  return;
end

% --- Generate filename ---
filename = fullfile(get(handles.SavePath,'String'),get(handles.SaveAs,'String'));

% Check if file already exists.
overwrite = '';
while exist(filename,'file') & ~strcmp(overwrite,'Yes')
  % Continue checking filename until the filename does not exist,
  % the user gives permission to overwrite, or the save is canceled 
  overwrite=questdlg('File already exists. Overwrite?', ...
    'Confirm File Overwrite','Yes','Choose New File','Cancel Save','Choose New File');
  switch overwrite
    case 'Choose New File'
      % If they said no, give them a chance to save the file in a different path or filename.
      [fname,pname] = uiputfile(filename,'Please choose a new location for the file!');
      if ~pname==0
        % Generate new file name
        filename = fullfile(pname,fname);
      else
        % Cancel save
        set(handles.LastEventText,'ForegroundColor','default','String','Save Cancelled');
        return;
      end
    case 'Cancel Save'
      % Cancel save
      set(handles.LastEventText,'ForegroundColor','default','String','Save Cancelled');
      filename=''; return;
  end
end

% --- Save the file ---
try
  % Get current ROI (current ROI is the first in the list)
  roi=ROIs(1);
  if str2double(strtok(strtok(version),'.')) >=7
    % Save ROIs for MATLAB 5 & 6 compatibility
    save(filename,'roi','-V6');
  else
    save(filename,'roi');
  end
catch
  set(handles.LastEventText,'ForegroundColor','red','String','ERROR: Save File Error, Directory Unwritable');
  return;
end

% --- Give the user feedback ---
[pname,fname]=fileparts(filename);
SaveText = sprintf('Saved %s at %s',fname,datestr(fix(clock),14));
set(handles.LastSaveText,'ForegroundColor',[0 0 1.0],'String',SaveText);
set(handles.LastEventText,'ForegroundColor','default','String','');

% --- Set matching button color to blue if one exists ---
% Handles of ARButtons
ARButtons_h = findobj(handles.overlay2_roitoolFig,'Tag','ARButton');
% Set the button color to blue of a matching button
% (index into AR list for each button stored in button's UserData)
set(findobj(ARButtons_h,'flat','UserData',get(handles.AR,'Value')),...
  'BackgroundColor',[0.5 0.5 1.0]);

% --- Define new ROI if requested, until all buttons have been pushed. ---
% Number of button that have labels
numButtons = length(ARButtons_h) - length(find(strcmp(get(ARButtons_h,'String'),'')));
% Number of button that have been pushed
pushedButtons = length(findobj(ARButtons_h,'flat','BackgroundColor',[0.5 0.5 1.0]));
if get(handles.AutoDefine,'Value')==1 & numButtons > pushedButtons
  DefineButton_Callback([],[],handles);
end

% --------------------------------------------------------------------
function ChangeDir_Callback(h, eventdata, handles)
% Callback for Path button to change save path.

% Prompt user for path to save file in (start with current path)
[fname, pname] = uiputfile(fullfile(get(handles.SavePath,'String'),'Save Files Here'));

if pname ~= 0
  % If user did not cancel, change the save path and tell the user.
  set(handles.SavePath,'String',pname);
  set(handles.LastEventText,'ForegroundColor','default','String','Save Directory Changed');
end

% Attempt to regenerate the exam number. (Also updates the ROI filename)
AutoExam_Callback([],[],handles)

% --------------------------------------------------------------------
function SavePath_Callback(h, eventdata, handles)
% Callback for the save path edit field.

% User Feedback
set(handles.LastEventText,'ForegroundColor','default','String','Save Directory Changed');

% Attempt to regenerate the exam number. (Also updates the ROI filename)
AutoExam_Callback([],[], handles)

% --------------------------------------------------------------------
function SaveAs_Callback(h, eventdata, handles)
%TODO: update text values according to whats typed, separated by underscores?


% --------------------------------------------------------------------
function SameLimits_Callback(h, eventdata, handles)
% Callback for Use same ROI limits checkbox
if get(handles.SameLimits,'Value')==1
  set(handles.LastEventText,'ForegroundColor','default','String','Use Same ROI Limits turned on');
else
  set(handles.LastEventText,'ForegroundColor','default','String','Use Same ROI Limits turned off');
end

% --------------------------------------------------------------------
function AutoDefine_Callback(h, eventdata, handles)
% Callback for AutoDefine checkbox
if get(handles.AutoDefine,'Value') == 1
  set(handles.LastEventText,'ForegroundColor','default','String','Auto Define after Save turned on');
else
  set(handles.LastEventText,'ForegroundColor','default','String','Auto Define after Save turned off');
end

% --------------------------------------------------------------------
function ProfileButton_Callback(h, eventdata, handles)
% Callback for Load Config button
%
% Loads personal configuration file.

% Prompt user for file
[fname, pname] = uigetfile('*.txt','Load Personal Configuration File');

if pname ~= 0
  % Load file
  local_loadsettings(handles,fullfile(pname,fname));
else
  % User Cancelled
  set(handles.LastEventText,'ForegroundColor','red','String','ERROR: Load Profile Cancelled');
end

% --------------------------------------------------------------------
function overlay2_roitool_CloseRequestFcn(h, eventdata, handles)
% Close request function for figure
%
% (1) Update overlay2 ROIToolItem button to show that it closed.
% (2) Restore original callback for ROI Define and Grow buttons.
% (2) Close the overlay2_roitool figure.

try
  if ishandle(handles.overlay2_h)
    % Set the ROI Window handle in the overlay2 window to empty (if the overlay2 window is still open
    set(findobj(handles.overlay2_h,'Tag','ROIToolItem'),'UserData',[]);
  end
catch
  % Issue warning
  warning('Unable to update overlay2 properly!  ROI Drawing Tool will not work for this overlay2 anymore!');
end

try
  if ishandle(handles.overlay2_h)
    % Restore the original callback for the Define button 
    % (stored in overlay2_roitool define button handle)
    set(findobj(handles.overlay2_h,'Tag','ROIDefButton'),'Callback', ...
      get(handles.DefineButton,'UserData'));
    
    % Restore the original callback for the Define button 
    % (stored in overlay2_roitool define button handle)   
    set(findobj(handles.overlay2_h,'Tag','ROIGrowButton'),'Callback', ...
      get(handles.GrowButton,'UserData'));
  end
catch
  % Issue warning
  warning('Unable to update overlay2 properly!  Define and Grow buttons will not work for this overlay2 anymore!');
end

shh = get(0,'ShowHiddenHandles');
set(0,'ShowHiddenHandles','on');
currFig = get(0,'CurrentFigure');
set(0,'ShowHiddenHandles',shh);
delete(currFig);

% -------------------------------------------------------------------
% ----------------------- Local Functions ---------------------------
% -------------------------------------------------------------------

function local_initgui(handles)
% local_initgui - Initialize GUI for first use.

% Set the figure position
local_setFigurePosition(handles.overlay2_h,handles.overlay2_roitoolFig);

% Get info from current experiment
currExp = chexp('settings');

% Set the default path to save ROIs at.
savePath = pwd; % Default
if ~isempty(currExp)
  % Attempt to set the SavePath based on the current experiment.
  [status,emsg] = makedir(fullfile(currExp.Path,'Analysis','ROI'));
  if status, savePath=fullfile(currExp.Path,'Analysis','ROI'); end
end
set(handles.SavePath,'String',savePath);

% Update same limits string
local_updateSameLimitsString(handles.overlay2_h,handles.SameLimits);

% Make the ARHOT buttons and ARFULL names
k = local_getDefaultRoiNames;
warnMsgFlag=local_setupAnatomicalRegions(handles,k.ARFULL,k.ARHOT);

% Attempt to regenerate the exam and slice number.
% Do this even if AutoExam and AutoSlice are not set in order to get the
% enable properties setup correctly in case they changed from on to off
AutoExam_Callback([],[],handles); 
AutoSlice_Callback([],[],handles);

% Update the current ROI name.
local_updateRoiFilename(handles);

% Update feedback string.
if warnMsgFlag
  set(handles.LastEventText,'ForegroundColor','Red','String','Warnings during initialization! See command window.');
else
  set(handles.LastEventText,'ForegroundColor','default','String','Initialization Successful');
end

% -------------------------------------------------------------------
function local_setFigurePosition(overlay2_h,overlay2_roitool_h)
% local_setFigurePosition - Automatically Position figure on left side of overlay2 window.
%
% local_setFigurePosition(overlay2_h,overlay2_roitool_h)
%    overlay2_h - handle of overlay2 figure
%    overlay2_roitool_h - handle of overlay2 ROI drawing tool figure.
%

%position ROI window to the left of overlay2
oldsaveunits=get(overlay2_roitool_h,'Units');
oldoverlayunits = get(overlay2_h,'Units');
set(overlay2_h,'Units','Pixels');
set(overlay2_roitool_h,'Units','Pixels');

savepos = get(overlay2_roitool_h,'Position');
overpos = get(overlay2_h,'Position');

scrsize = get(0,'ScreenSize');
%if display settings modified, restart Matlab to get correct ScreenSize

%get screensize, check to see if doesn't work on left side, then do right.
xpix = overpos(1)-savepos(3)-7;
if xpix < 0
  xpix = overpos(1)+overpos(3)+7;
  if (xpix+savepos(3))>scrsize(3)
    %flush with left side of screen
    xpix = 10;
  end
end

rect = [xpix overpos(2)-1 savepos(3) savepos(4)];
set(overlay2_roitool_h,'Position',rect);

%reset all units
set(overlay2_roitool_h,'Units',oldsaveunits);
set(overlay2_h,'Units',oldoverlayunits);

% -------------------------------------------------------------------
function local_loadsettings(handles,fname)
% local_loadsettings - Load and apply settings for GUI.
%
%   local_loadsettings(handles,fname)
%     handles - structure of handles from guidata
%     fname   - filename of configuration to load

try
  % Load the specified file
  reqKeys = {'ARHOT','ARFULL'};  % Must be in profile
  optKeys = {'AutoExam','ExamNumber','AutoSlice','SliceNumber', ...
      'Orientation','Hemisphere','SameLimits','AutoDefine','SavePath', ...
      'ROIFilenameFunction'}; % May be in profile
  k = readkvf(fname,reqKeys,optKeys);
  
  % Put single results into cell arrays for uniform handling
  if ~iscell(k.ARHOT) == 1, k.ARHOT = {k.ARHOT}; end
  if ~iscell(k.ARFULL) == 1, k.ARFULL = {k.ARFULL}; end
  
  % Make the ARHOT buttons and ARFULL names
  warnMsgFlag=local_setupAnatomicalRegions(handles,k.ARFULL,k.ARHOT);
  
  % Set other fields specified in profile 
  % (use original figure values if properties not specified in profile)
  if isfield(k,'AutoExam'), set(handles.AutoExam,'Value',str2num(k.AutoExam)); end
  if isfield(k,'AutoSlice'), set(handles.AutoSlice,'Value',str2num(k.AutoSlice)); end
  if isfield(k,'Orientation'),set(handles.Orientation,'Value',str2num(k.Orientation)); end
  if isfield(k,'Hemisphere'), set(handles.Hemisphere,'Value',str2num(k.Hemisphere)); end
  if isfield(k,'SameLimits'), set(handles.SameLimits,'Value',str2num(k.SameLimits)); end
  if isfield(k,'AutoDefine'), set(handles.AutoDefine,'Value',str2num(k.AutoDefine)); end
  if isfield(k,'SavePath'), set(handles.SavePath,'String',k.SavePath); end

  % Only set passed exam and slice number if AutoExam and AutoSlice are off
  if isfield(k,'ExamNumber') & ~get(handles.AutoExam,'Value'), 
    set(handles.ExamNumber,'String',k.ExamNumber);
  end
  if isfield(k,'SliceNumber') & ~get(handles.AutoSlice,'Value'), 
    set(handles.SliceNumber,'String',k.SliceNumber);
  end
catch
  set(handles.LastEventText,'ForegroundColor','red','String','ERROR: Invalid Profile');
  waitfor(errordlg(sprintf('Error Loading Profile\n%s',lasterr)));
  return;
end

% Attempt to regenerate the exam and slice number.
% Do this even if AutoExam and AutoSlice are not set in order to get the
% enable properties setup correctly in case they changed from on to off
% These functions both also update the ROI filename.
AutoExam_Callback([],[],handles);
AutoSlice_Callback([],[],handles);

if isfield(k,'ROIFilenameFunction')
  % User specified a ROIFilenameFunction
  set(handles.SaveAs,'UserData',k.ROIFilenameFunction);
  % Test it to make sure it works
  local_updateRoiFilename(handles);
  if isempty(get(handles.SaveAs,'String'))
    % Did not work.  Use default instead and tell user.
    set(handles.SaveAs,'UserData','');
    local_updateRoiFilename(handles);
    waitfor(errordlg(sprintf('Invalid ROIFilenameFunction.  Using default.\nError was %s',lasterr)));
  end
end

% Update feedback string.
if warnMsgFlag
  set(handles.LastEventText,'ForegroundColor','Red','String','Warnings during load config! See main window.');
else
  set(handles.LastEventText,'ForegroundColor','default','String','Load Profile Successful');
end

% -------------------------------------------------------------------------
function ROIs = local_getROIs(overlay2_h)
% Get the list of ROIs from the overlay2 window.
%
%  overlay2_h - overlay2 figure handle

params = get(overlay2_h,'UserData');
ROIs = params{27};

% -------------------------------------------------------------------------
function local_updateRoiFilename(handles)
% local_updateRoiFilename - Update ROI filename based on current ROI settings
%
% local_updateRoiFilename(handles)
%
%          handles - structure of handles returned by guidata()
%
% ROI filename generated by evaluting a string stored in SaveAs button UserData
%   See ROIFilenameFunction section of "OVERLAY2 ROI Drawing Tool Configuration File format"
%   for details.
%
% Updates SaveAs string with results

% Get roifilenameFunc from SaveAs userdata
ROIFilenameFunction = get(handles.SaveAs,'UserData');

if isempty(ROIFilenameFunction)
  % Default function to construct filename
  % TODO: Make better default format!
  ROIFilenameFunction='strcat(orientation,region,hemisphere,''_'',exam,''_'',''s'',slice,''.roi'');';
end

% --- Determine the exam number string ---
exam = get(handles.ExamNumber,'String');

% --- Determine the slice string ---
slice = get(handles.SliceNumber,'String');

% --- Determine the side ---
hemispheres = get(handles.Hemisphere,'String');
switch hemispheres{get(handles.Hemisphere,'Value')}
  case 'Right'
    hemisphere = 'r'; 
  case 'Left'
    hemisphere = 'l';
  otherwise
    hemisphere = ''; % None
end
clear hemispheres

% --- Determine the orientation ---
orientations = get(handles.Orientation,'String');
switch orientations{get(handles.Orientation,'Value')}
  case 'Coronal'
    orientation = 'cor';
  case 'Sagittal'
    orientation = 'sag';
  case 'Axial'
    orientation = 'axl';
  otherwise
    orientation = '';  % None
end
clear orientations

% ---  Determine the region ---
ARList = get(handles.AR,'String');
region = lower(strtok(ARList{get(handles.AR,'Value')},'-'));
clear ARList

try
  % Generate roiname
  roifilename = eval(ROIFilenameFunction);
catch
  set(handles.LastEventText,'ForegroundColor','red','String','ERROR: Unable to generate ROI filename!');
  roifilename = '';
end  
set(handles.SaveAs,'String', roifilename);

% -------------------------------------------------------------------------------------
function local_ClearPushButtons(overlay2_roitool_h)
% Set all of the ROI pushbuttons back to their default colors
set(findobj(overlay2_roitool_h,'Tag','ARButton'),'BackgroundColor','default');

% -------------------------------------------------------------------------------------
function local_updateSameLimitsString(overlay2_h,sameLimits_h)
% This function update the SameLimits string passed on the current saved
% settings in the overlay2 figure.
%

% Get saveROILimits from overlay2 window
params=get(overlay2_h,'UserData');
saveROILimits=params{30};
  
% Generate string
srs = saveROILimits{4};
limits = saveROILimits{srs+1};
srsNames = {'Base' 'Overlay1' 'Overlay2'};
if isempty(limits),
  msg = 'Use Same ROI Limits (No limits)';
else
  msg = sprintf('Use Same ROI Limits (%s, [%g to %g])',srsNames{srs+1},limits(1),limits(2));
end
set(sameLimits_h,'String',msg);

% --------------------------------------------------------------------------
function warnMsgFlag=local_setupAnatomicalRegions(handles,ARList,ARButtons)
% Setup Anatomical Regions full list and buttons.
%
%   ARList - (n x 1) Cell array
%          - Full list of anatomical ROIs to save
%          - Format is a three letter abbreviation followed
%              by a '-' then a decription (not case sensitive)
%              (i.e. ARFULL=MFG-middle frontal gyrus )
%          - There is not a limit on the number of ROI names 
%            that can be specified.
%
%   ARButtons - (m x 1) Cell array 
%          - Buttons for quickly saving ROIs
%          - Format is a three letter abbreviation (not case sensitive)
%              (i.e. ARHOT=MFG )
%          - The ARHOT abreviations must be in ARFULL
%          - There can be a maximum of 16 ARHOT buttons
%
% warnMsgFlag - Were warning messages sent to the command window?

if ~iscellstr(ARList) | ~iscellstr(ARButtons)
  close(handles.overlay2_roitoolFig)
  error('ARList and ARButtons must be cell arrays of strings!');
end

warnMsgFlag=0;  %Initalize to no warning messages encountered.

% GUI specifications
maxGrid = [7 5];            % Largest usable grid
maxButtons = prod(maxGrid); % Hence, max number of buttons

% Convert all buttons to uppercase
ARButtons=upper(ARButtons);

% Get abbreviations for each anatomical region string
ARabbrev = cell(1,length(ARList));
for n=1:length(ARList)
  ARabbrev{n} = upper(strtok(ARList{n},'-'));
end

% Check format of ARList, warn user of incorrect formats
% and exclude from the list.
ii=find(cellfun('length',ARabbrev) ~= 3);
if ~isempty(ii)
  warning([sprintf('%s\n', ...
      'The following anatomical regions are NOT in the', ...
      'correct format (XYZ-Description) and will be excluded',...
      'from the list of regions:'),...
      sprintf('  %s\n',ARList{ii})]);
  warnMsgFlag=1;
  ARList(ii)=[];
  ARabbrev(ii)=[];
end

% Check for any duplicate abbreviations
% TODO: Remove duplicates automatically.
if length(unique(ARabbrev)) ~= length(ARabbrev)
  warning(sprintf('%s\n', ...
    'The anatomical region abbreviations are not unique!', ...
    'Please correct your configuration!'));
  warnMsgFlag=1;
end

% Set anatomical region list 
set(handles.AR,'String',ARList)

% Check format of ARButtons, warn user of incorrect formats
% and exclude from buttons.
ii=find(cellfun('length',ARButtons) ~= 3);
if ~isempty(ii)
  warning([sprintf('%s\n', ...
      'The following anatomical regions buttons are NOT in the', ...
      'correct format (XYZ) and will not be created:'), ...
      sprintf('  %s\n',ARButtons{ii})]);
  warnMsgFlag=1;
  ARButtons(ii)=[];
end

% Find index into ARList for each ARButton
ARButtons_listIndex = zeros(length(ARButtons),1);
for n=1:length(ARButtons)
  currIndex = find(strcmp(ARabbrev,ARButtons{n})==1);
  if length(currIndex) == 1
    % Put it in the list if there was one and only one match
    ARButtons_listIndex(n) = currIndex;
  elseif isempty(currIndex)
    % No matches
    warning(sprintf('%s%s\n', ...
      'There are no anatomical regions matching the button: ',...
      ARButtons{n},'This button will not be created.'));
    warnMsgFlag=1;
  else
    % Multiple matches
    warning(sprintf(...
      'There are %d anatomical regions matching the button: %s\n%s',...
      length(currIndex),ARButtons{n},'This button will not be created.'));
    warnMsgFlag=1;
  end
end
% Exclude all buttons with zero or multiple matches
ii=find(ARButtons_listIndex==0);
ARButtons(ii) = [];
ARButtons_listIndex(ii) = [];

% Check for any duplicate buttons
% TODO: Remove duplicates automatically.
if length(unique(ARButtons)) ~= length(ARButtons)
  warning(sprintf('%s\n', ...
    'The anatomical region buttons are not unique!', ...
    'Please correct your configuration!'));
  warnMsgFlag=1;
end

% Check that there are only maxButtons remaining
if length(ARButtons) > maxButtons
  % Only use first maxButtons if there are too many
  warning(sprintf('More than %d buttons requested.  Only creating the first %d',maxButtons,maxButtons));
  warnMsgFlag=1;
  ARButtons = ARButtons(1:maxButtons);
end

% Delete any buttons that already exist.
delete(findobj(handles.overlay2_roitoolFig,'Tag','ARButton'));

% Setup grid
% Calculate rectangular grid
% preferring larger width.
nButtons = length(ARButtons);
grid(1)=ceil(sqrt(nButtons));
grid(2)=ceil(nButtons/grid(1));
if grid(2) > maxGrid(2)
  grid(2) = maxGrid(2);
  grid(1) = ceil(nButtons/grid(2));
end
  
% GUI Settings  
xinit = 1;                    % Start here (upper right)
yinit = 21.5;
totalWidth = 47;              % Total area available
totalHeight = 6.3;
width = totalWidth/grid(1);   % Calculate button sizes
height = totalHeight/grid(2);

% Generate all of the hot buttons
nButtons = length(ARButtons);
for b=1:prod(grid)
  if b > nButtons
    % Blank out all of the extra buttons
    name = '';
    tooltip = 'Unused button';
    callback = '';
    userdata = 0;
    enable = 'off';
  else
    name = ARButtons{b};
    tooltip = ['Save current ROI as ' name];
    callback = 'overlay2_roitool(''ARButton_Callback'',gcbo, [], guidata(gcbo))';
    userdata = ARButtons_listIndex(b); % Store the index into the ARList array
    enable = 'on';
  end
  [x,y] = ind2sub(grid,b);
  pos = [xinit+(x-1)*width yinit-y*height width height];
  uicontrol('Style','pushbutton','Tag','ARButton','Units','Characters', ...
    'Position', pos,'String', name, 'ToolTipString', tooltip,...
    'Callback', callback, 'UserData',userdata,'Enable',enable);
end

% --------------------------------------------------------------------
function names = local_getDefaultRoiNames
% local_getDefaulRoiNames - Get the default ROI names.
%
%   names - structure containing two fields:
%           ARFULL - Cell array anatomical ROI descriptions
%           ARHOT - Cell array of buttons labels for quickly saving ROIs
%
% See OVERLAY2 ROI Drawing Tool Configuration File format for 
% the required format of ARFULL and ARHOT.
names = struct( ...
  'ARHOT',{{'ACG','CER','FFG','IFG','IPS','MFG','MOT','SFG','SMA','STS','WHM'}'}, ... 
  'ARFULL',{{'ACG-anterior cingulate gyrus', ...
    'CER-cerebellum', ...
    'CUN-cuneus', ...
    'FFG-fusiform gyrus', ...
    'FMS-frontomarginal sulcus', ...
    'IFG-inferior frontal gyrus', ...
    'IPS-intraparietal sulcus', ...
    'ITS-inferior temporal sulcus', ...
    'ITG-inferior temporal gyrus', ...
    'LOG-lateral occipital gyrus', ...
    'LOS-lateral orbital sulcus', ...
    'MFG-middle frontal gyrus', ...
    'MOG-medial orbital gyrus', ...
    'MOT-primary motor area', ...
    'MTG-middle temporal gyrus', ...
    'OFG-orbitofrontal gyrus', ...
    'PCG-precentral gyrus', ...
    'PCS-precentral sulcus', ...
    'POS-parieto occipital sulcus', ...
    'SFG-superior frontal gyrus', ...
    'SFS-superior frontal sulcus', ...
    'SMA-supplementary motor area', ...
    'SMG-supramarginal gyrus', ...
    'SPL-superior parietal lobule', ...
    'STG-superior temporal gyrus', ...
    'STS-superior temporal sulcus', ...
    'TOS-temporo occipital sulcus', ...
    'WHM-white matter'}'});

% Modification History:
%
% $Log: overlay2_roitool.m,v $
% Revision 1.17  2005/02/16 02:53:45  michelich
% Use more robust version parsing code.
%
% Revision 1.16  2005/02/16 01:51:22  michelich
% Simplify version check code.
%
% Revision 1.15  2005/02/03 16:58:41  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.14  2004/10/26 21:52:20  michelich
% Save ROIs for MATLAB 5 & 6 compatibility when using MATLAB 7.
%
% Revision 1.13  2003/10/22 15:54:38  gadde
% Make some CVS info accessible through variables
%
% Revision 1.12  2002/11/16 21:22:03  michelich
% Use - instead of _ for multislice slice number.
%
% Revision 1.11  2002/11/16 20:56:37  michelich
% Changed Axial abbreviation for uniform abbreviation length.
%
% Revision 1.10  2002/11/06 15:21:26  michelich
% Changed default save path to pwd if pwe not set.
% Update roiname if ROIFilenameFunction fails.
%
% Revision 1.9  2002/11/03 08:41:22  michelich
% updatesavecell - Major rewrite.
% - Renamed local_updateRoiFilename
% - Allow user to specify ROIFilenameFunction.
% local_setupAnatomicalRegions
% - Dynamically generate button matrix size (up to 35 buttons).
% AutoExam,ChangeDir,SavePath callbacks - small UI changes.
% SameLimits callback - don't update limits when checkbox state changes.
% Removed UpdateButton_Callback.
% Added proper handling of single ARHOT and ARFULL entries in config files.
% Enabled orientation field.
% AutoSlice_Callback - Moved code from updatesavecell and rewrote.
% Check for empty ROI filename before saving.
%
% Revision 1.8  2002/11/03 04:23:45  michelich
% Store original grow button callback correctly!
% Use GUI error on grow button error for consistency with overlay2 behavior.
%
% Revision 1.7  2002/11/03 01:36:55  michelich
% Removed redundant and unnecessary code throughout.
% Removed unused srs and limits fields from handles & changed figno to overlay2_h.
% Use the overlay2_roitool callbacks from the overlay2 buttons when the tool is open.
% Implemented Orientation_Callback
% Removed unnecessary varargin from Callback function definitions.
% ARButton_Callback
% - Added eventdata and handles to function definition.
% - Use buttons user data for finding matching Full AR entry.
% - Use SaveButton_Callback to do the save.
% SaveButton_Callback
% - Major code cleanup
% - Set proper ARButton to blue on save
% DefineButton_Callback & GrowButton_Callback
% - Major code cleanup
% - Use modified overlay2 to do most of the work instead of replicating the code here.
% AutoExam_Callback & AutoSlice_Callback
% - Only clear the push buttons if the exam number actually changed.
% makebuttons
% - Renamed to local_setupAnatomicalRegions.
% - Added making list & error handling
% - Store index into ARList in buttons
% - Disable unused buttons.
% ClearPushButtons
% - Renamed to local_ClearPushButtons
% - Passed roitool handle as argument instead of assuming it is the current figure.
% updatesavecell
% - Removed unnecessary second argument and return variable.
% Removed unnecessary local functions: newROI(),getParams(),setParams(),getROIColors()
% Call AutoExam and AutoSlice on initalization and configuration load.
%
% Revision 1.6  2002/11/01 23:26:28  michelich
% Cleaned up auto exam and exam number callbacks.
%
% Revision 1.5  2002/11/01 22:07:56  michelich
% Reordered functions in file more logically.  NO code changes!
%
% Revision 1.4  2002/11/01 22:02:26  michelich
% Added more robust handling of inputs.
% Removed unnecessary varargout from all callbacks.
% Separate handling of user profiles and gui initialization.
% Removed unused handles.profile variable.
% Updated GUI initialization
% - Made separate function for GUI positioning.
% - Use overlay2_roitool.fig values for defaults.
% - Default to have SameLimits turned off.
% - Use default save path if cannot create directory in pwe.
% - Call AutoExam callback before updating current ROI name.
% Updated handling of user profiles
% - Added checking for required and optional keys when loading profile.
% - Removed unused fields (LastEventText,LastSaveText,Srs,ROILimits).
% - Removed field ARValue - default of 1 is fine.
% - Removed profile file OrientEnable - Use none option instead
% - Do not include field in profile to use default instead of using -1.
% - Issue warning if user attempts to set orientation field since it
%   is not implemented yet.
%
% Revision 1.3  2002/10/28 22:44:43  michelich
% Corrected all breaks that are actually returns.
% MATLAB 6.5 warning: A BREAK statement appeared outside of a loop.  This
%   statement is currently treated as a RETURN statement, but future
%   versions of MATLAB will error instead.
%
% Revision 1.2  2002/10/28 22:23:18  michelich
% Corrected close request function callback name.
% Corrected callback for ARHOT Buttons.
% Updated comments for new function name.
% Added local function to define default profile so that
%   the default.txt file does not need to exist.
% Fixed bugs in determining that an ARHOT button is not in ARFULL.
%
% Revision 1.1  2002/10/28 21:14:58  michelich
% Initial CVS Import of Jimmy Dias's original ROI drawing tool.
% Changes made before checkin:
% - Changed name to overlay2_roitool.
% - Updated tag to ROIToolItem.
% - Updated help comments.
%
%
% Pre CVS History Entries:
% Jimmy Dias,        2002/01/14. Implemented Close Request Function.
%                                Handled multiple occurances of this GUI.
% Jimmy Dias,        2001/11/15. if current experiment defined using chexp, override profile SavePath with
%                                that of current experiment directory + \Analysis\ROIs\
% Jimmy Dias,        2001/11/15. Changed Convention to Hemisphere_Callback
% Francis Favorini,  2001/11/14. Renamed generically-named uicontrols to reflect their functions.
%                                Changed SubjectNumber to ExamNumber.
%                                Changed PreString to SavePath.
%                                Updated makebuttons to allow configurable grid of buttons.
%                                Added tooltips to hot buttons.
%                                Use fullfile instead of strcat to build filenames.
%                                Changed layout of window.  Made Path an edit box.
%                                Fixed auto slice behavior.
% Jimmy Dias,        2001/11/14. Initial version.
