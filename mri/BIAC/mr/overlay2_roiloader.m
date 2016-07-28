function varargout = overlay2_roiloader(varargin)
%OVERLAY2_ROILOADER - Tools loading ROIs using OVERLAY2
%
%   gui_h = OVERLAY2_ROILOADER(h)
%      Launch ROI loader GUI for overlay2 figure h.  Or if GUI already 
%      exists, make it the current figure.  gui_h is the handle of
%      the ROI loader GUI.
%
%   OVERLAY2_ROILOADER('callback_name', ...) invoke the named callback.
%
%  This function is intended for internal use by overlay2.
%
% See Also: OVERLAY2

% CVS ID and authorship of this code
% CVSId = '$Id: overlay2_roiloader.m,v 1.8 2005/02/16 02:53:45 michelich Exp $';
% CVSRevision = '$Revision: 1.8 $';
% CVSDate = '$Date: 2005/02/16 02:53:45 $';
% CVSRCSFile = '$RCSfile: overlay2_roiloader.m,v $';

%TODO: Clean up code.
%TODO: BUG: Handle multislice ROIs properly.
%TODO: Allow reading roitool config file to get ROI names.
%TODO: Handle different orientations.
%TODO: Handle different ROI filename formats???

if nargin == 0
  % we need overlay's window handle, so don't start without it
  errordlg('overlay2_roiloader requires overlay window handle as its argument.','ERROR');
    
elseif ishandle(varargin{1}) %nargin == 1 % LAUNCH GUI

  % check matlab version
  if str2double(strtok(strtok(version),'.')) < 6
    errordlg('overlay2_roiloader will only work on Matlab 6.0+ machines');
    return;
  end

  % make sure we got a valid handle
  if (~ishandle(varargin{1}))
    errordlg('Invalid Handle');
    return;
  end
  
  % Warn user of status of code.
  waitfor(warndlg('Use ROI Loading Tool with CAUTION!  It has bugs and is still under development.', ...
    'ROI Loading Tool WARNING','modal')); 

  % Check if a ROI Loader Tool is already open for this overlay2 window
  currROIWin = get(findobj(varargin{1},'Tag','ROILoadItem'),'UserData');
  if ~isempty(currROIWin);
    % If one is open, bring it to the front
    figure(currROIWin)
  else
    % Otherwise open a new one
    
    % Open the window
    fig = openfig(mfilename);
    
    % Set the figure close request function
    set(fig,'CloseRequestFcn','overlay2_roiloader(''overlay2_roiloader_CloseRequestFcn'',gcbo,[],guidata(gcbo))');
    
    % Save shared variables in UserData of ROI Loader Window
    ud.OverlayWindowHandle = varargin{1};  % initialize overlay's handle
    ud.BaseDirectory = [];                 % initialize the base directory
    ud.BaseFilelist= [];                   % initialize lists of ROI files
    ud.AvailFilelist= [];
    ud.AppliedFilelist= [];  
    set(fig,'UserData',ud);                % store UserData struct
    
    % Put handle to ROI Window in uimenu UserData (in overlay2)
    set(findobj(ud.OverlayWindowHandle,'Tag','ROILoadItem'),'UserData',fig);
    
    % Generate a structure of handles to pass to callbacks, and store it. 
    handles = guihandles(fig);
    guidata(fig, handles);
  end
    
  if nargout > 0
    varargout{1} = fig;
  end

elseif ischar(varargin{1}) % INVOKE NAMED SUBFUNCTION OR CALLBACK

  try
    [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
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


%------------------------------------------------------------------------------

% Listbox to select ROIs to apply
function varargout = listbox_roi_avail_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.listbox_roi_avail
% Enable the Apply button if something is selected
if (~isempty(get(handles.listbox_roi_avail,'Value')) & ...
    get(handles.radio_roi_avail,'Value'))
  set(handles.push_apply,'Enable','On');
else
  set(handles.push_apply,'Enable','Off');
end

% Listbox to select ROIs to remove
function varargout = listbox_roi_applied_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.listbox_roi_applied
% Enable the Remove button if something is selected
if (~isempty(get(handles.listbox_roi_applied,'Value')) & ...
    get(handles.radio_roi_applied,'Value'))
  set(handles.push_remove,'Enable','On');
else
  set(handles.push_remove,'Enable','Off');
end

%------------------------------------------------------------------------------

% Dropdown menu for selecting gyrus
function varargout = menu_gyrus_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.menu_gyrus
ud=get(gcbf,'UserData');                        % get UserData struct
if (get(handles.radio_roi_avail,'Value'))
  % update ROIs available
  set(handles.listbox_roi_avail,'String',roi_loader_update_filelist(handles,...
    ud.AvailFilelist));
else
  % update ROIs applied
  set(handles.listbox_roi_applied,'String',roi_loader_update_filelist(handles,...
    ud.AppliedFilelist));
end


% Dropdown menu for selecting exam number
function varargout = menu_exam_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.menu_exam
ud=get(gcbf,'UserData');                        % get UserData struct
if (get(handles.radio_roi_avail,'Value'))
  % update ROIs available
  set(handles.listbox_roi_avail,'String',roi_loader_update_filelist(handles,...
    ud.AvailFilelist));
else
  % update ROIs applied
  set(handles.listbox_roi_applied,'String',roi_loader_update_filelist(handles,...
    ud.AppliedFilelist));
end


% Dropdown menu for selecting hemisphere
function varargout = menu_hemi_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.menu_hemi
ud=get(gcbf,'UserData');                        % get UserData struct
if (get(handles.radio_roi_avail,'Value'))
  % update ROIs available
  set(handles.listbox_roi_avail,'String',roi_loader_update_filelist(handles,...
    ud.AvailFilelist));
else
  % update ROIs applied
  set(handles.listbox_roi_applied,'String',roi_loader_update_filelist(handles,...
    ud.AppliedFilelist));
end


% Dropdown menu for selecting slice number
function varargout = menu_slice_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.menu_slice
ud=get(gcbf,'UserData');                        % get UserData struct
if (get(handles.radio_roi_avail,'Value'))
  % update ROIs available
  set(handles.listbox_roi_avail,'String',roi_loader_update_filelist(handles,...
    ud.AvailFilelist));
else
  % update ROIs applied
  set(handles.listbox_roi_applied,'String',roi_loader_update_filelist(handles,...
    ud.AppliedFilelist));
end


%------------------------------------------------------------------------------

% Browse for base directory
function varargout = push_browse_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.push_browse
ud=get(gcbf,'UserData');                        % get UserData struct
[fname,pname]=uigetfile('*.roi','Directory Browser');
if (~pname | strcmp(pname,ud.BaseDirectory))
  return;       % user clicked cancel, or just selected current base directory
end

% new base directory, so clear all existing ROIs
button=questdlg('Changing a Base Directory will delete all ROIs from Overlay window.  Continue?',...
  'WARNING','Yes','No','Yes');  
if (strcmp(button,'No'))
  return
end
overlay2('ClearROIs',ud.OverlayWindowHandle);  % clear all ROIs
set(handles.text_directory,'String',pname);    % update the base directory setting
ud.BaseDirectory= pname;                  
ud.BaseFilelist= roi_loader_update_menus(handles); % update popup menu lists
ud.AvailFilelist= ud.BaseFilelist;          % copy base list as available
ud.AppliedFilelist= [];                     % start with empty applied list
set(gcbf,'UserData',ud);                    % update the UserData structure
set(handles.check_thresh,'Value',0);        % uncheck threshhold (default)
set(handles.radio_roi_avail,'Value',1);     % set avail roi filelist as active (default)
set(handles.radio_roi_applied,'Value',0);
set(handles.listbox_roi_avail,'String',roi_loader_update_filelist(handles,...
  ud.AvailFilelist));
set(handles.listbox_roi_applied,'String',[]);


% Apply the selected ROIs
function varargout = push_apply_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.push_apply
ud=get(gcbf,'UserData');                        % get UserData struct
select= get(handles.listbox_roi_avail,'Value'); % get vector of selected ROIs
if (~isempty(select))
  set(handles.push_apply,'Enable','Off');
    
  % move selected items into applied side
  select_list= get(handles.listbox_roi_avail,'String');
  ud.AppliedFilelist= strvcat(ud.AppliedFilelist,deblank(select_list(select,:)));
  ud.AppliedFileist= sortrows(ud.AppliedFilelist);
  set(handles.listbox_roi_applied,'String',roi_loader_update_filelist(handles,...
    ud.AppliedFilelist));

  % update the list of available ROIs
  temp=[];
  for i=[1:size(ud.AvailFilelist,1)]
    if (isempty(strmatch(ud.AvailFilelist(i,:),select_list(select,:))))
      temp= [temp; ud.AvailFilelist(i,:)];
    end
  end
  ud.AvailFilelist=temp;
  set(handles.listbox_roi_avail,'Value',[]);
  set(handles.listbox_roi_avail,'String',roi_loader_update_filelist(handles,...
    ud.AvailFilelist));
  set(gcbf,'UserData',ud);      % update the UserData structure
end
roi_loader_apply_filelist(gcbf,select_list(select,:));


% Remove the selected RIOs
function varargout = push_remove_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.push_remove
ud=get(gcbf,'UserData');                          % get UserData struct
select= get(handles.listbox_roi_applied,'Value'); % get vector of selected ROIs
if (~isempty(select))
  set(handles.push_remove,'Enable','Off');
  % move selected items into avail side
  select_list= get(handles.listbox_roi_applied,'String');
  ud.AvailFilelist= strvcat(ud.AvailFilelist,deblank(select_list(select,:)));
  ud.AvailFilelist= sortrows(ud.AvailFilelist);
  set(handles.listbox_roi_avail,'String',roi_loader_update_filelist(handles,...
    ud.AvailFilelist));
  
  % update the list of applied ROIs
  temp=[];
  for i=[1:size(ud.AppliedFilelist,1)]
    if (isempty(strmatch(ud.AppliedFilelist(i,:),select_list(select,:))))
      temp= [temp; ud.AppliedFilelist(i,:)];
    end
  end
  ud.AppliedFilelist=temp;
  set(handles.listbox_roi_applied,'Value',[]);
  set(handles.listbox_roi_applied,'String',roi_loader_update_filelist(handles,...
    ud.AppliedFilelist));
  set(gcbf,'UserData',ud);      % update the UserData structure
end
overlay2('ClearROIs',ud.OverlayWindowHandle);   % clear all ROIs then reapply
roi_loader_apply_filelist(gcbf,ud.AppliedFilelist);

% Dismiss the window
function varargout = push_dismiss_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.push_dismiss
close(handles.roi_loader_root);


%------------------------------------------------------------------------------

% Radio button to activate Apply pushbutton, and inactivate Remove pushbutton
function varargout = radio_roi_avail_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.radio_roi_avail
ud=get(gcbf,'UserData');                    % get UserData struct
set(handles.radio_roi_applied,'Value',0);   % disable the other radio button
set(handles.push_remove,'Enable','Off');
set(handles.listbox_roi_avail,'String',roi_loader_update_filelist(handles,...
  ud.AvailFilelist));

% enable the current button is something in the listbox is selected
if (~isempty(get(handles.listbox_roi_avail,'Value')))
  set(handles.push_apply,'Enable','On');
end


% Radio button to activate Remove pushbutton, and inactivate Apply pushbutton
function varargout = radio_roi_applied_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.radio_roi_applied
ud=get(gcbf,'UserData');                    % get UserData struct
set(handles.radio_roi_avail,'Value',0);     % disable the other radio button
set(handles.push_apply,'Enable','Off');
set(handles.listbox_roi_applied,'String',roi_loader_update_filelist(handles,...
  ud.AppliedFilelist));

% enable the current button is something in the listbox is selected
if (~isempty(get(handles.listbox_roi_applied,'Value')))
  set(handles.push_remove,'Enable','On');
end


% --------------------------------------------------------------------
function varargout = check_thresh_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.check_thresh
% update the appropriate filelist
ud=get(gcbf,'UserData');                        % get UserData struct
if (get(handles.radio_roi_avail,'Value'))
  set(handles.listbox_roi_avail,'String',roi_loader_update_filelist(handles,...
    ud.AvailFilelist));
else
  set(handles.listbox_roi_applied,'String',roi_loader_update_filelist(handles,...
    ud.AppliedFilelist));
end

% --------------------------------------------------------------------
function varargout = overlay2_roiloader_CloseRequestFcn(h, eventdata, handles, varargin)

% Get handle of current figure
shh = get(0,'ShowHiddenHandles');
set(0,'ShowHiddenHandles','on');
currFig = get(0,'CurrentFigure');
set(0,'ShowHiddenHandles',shh);

try
  ud = get(currFig,'UserData');
  if ishandle(ud.OverlayWindowHandle)
    % Set the ROI Loader handle in the overlay2 window to empty (if the overlay2 window is still open)
    set(findobj(ud.OverlayWindowHandle,'Tag','ROILoadItem'),'UserData',[]);
  end
catch
  % Issue warning
  warning(sprintf('Unable to update overlay2 properly!  ROI Loader Tool will not work for this overlay2 anymore!\n Error was %s', lasterr));
end

delete(currFig);

% --------------------------------------------------------------------
% Local functions
% --------------------------------------------------------------------
function descrip= roi_loader_abbrv_get_descrip(abbrv)

% get description for anatomical abbreviation
abbrv=upper(abbrv);

abbrv_list= ...
['ACG-anterior cingulate gyrus';
'CER-cerebellum              ';
'CUN-cuneus                  ';
'FFG-fusiform gyrus          ';
'FMS-frontomarginal sulcus   ';
'IFG-inferior frontal gyrus  ';
'IPS-intraparietal sulcus    ';
'ITS-inferior temporal sulcus';
'ITG-inferior temporal gyrus ';
'LOG-lateral occipital gyrus ';
'LOS-lateral orbital sulcus  ';
'MFG-middle frontal gyrus    ';
'MOG-medial orbital gyrus    ';
'MOT-primary motor area      ';
'MTG-middle temporal gyrus   ';
'OFG-orbitofrontal gyrus     ';
'PCG-precentral gyrus        ';
'PCS-precentral sulcus       ';
'POS-parieto occipital sulcus';
'SFG-superior frontal gyrus  ';
'SFS-superior frontal sulcus ';
'SMA-supplementary motor area';
'SMG-supramarginal gyrus     ';
'SPL-superior parietal lobule';
'STG superior temporal gyrus ';
'STS-superior temporal sulcus';
'TOS-temporo occipital sulcus';
'WHM-white matter            '];

descrip=[];
for i=[1:size(abbrv_list,1)]
  if (strcmp(abbrv,abbrv_list(i,1:3)))
    descrip=abbrv_list(i,5:end);
    return
  end
end

% default
descrip='NO DESCRIPTION FOUND';

% --------------------------------------------------------------------
function roi_loader_apply_filelist(roiLoader_h,filelist)

% if empty, just return
if (isempty(filelist))
  return
end

% necessary variables from UserData struct
ud=get(roiLoader_h,'UserData');                        % get UserData struct
base_directory= ud.BaseDirectory;
overlay_window_handle= ud.OverlayWindowHandle;

% load all the ROIs into the workspace
empty_flag=0;
for i=[1:size(filelist,1)]
  load([base_directory,deblank(filelist(i,:)),'.roi'],'-mat');

  % skip over the empty RIO files
  if (isempty(roi.slice))
    empty_flag=1;
    continue
  end
  
  % make call to overlay2 to draw them
  overlay2('LoadROIs',overlay_window_handle,roi);
end

if (empty_flag)
  warndlg('One or more Loaded/Unloaded ROIs is empty.','WARNING');
end
%
% Code below creates a vector of ROIs to load, but each ROI read from file
% may not be the same type.  roi_loader_clean_roi_struct uses isroi to try
% to remove the extra fields, but is limited to just two types of ROI
% currently
%
% % load all the ROIs into the workspace
% load([deblank(filelist(1,:)),'.roi'],'-mat');
% rois= roi_loader_clean_roi_struct(roi);
% for i=[2:size(filelist,1)]
%   load([deblank(filelist(i,:)),'.roi'],'-mat');
%   rois(i) = roi_loader_clean_roi_struct(roi);
% end
% 
% % make call to overlay2 to draw them
% overlay2('LoadROIs',gcf,rois);
% 
% % clear the rois
% clear rois


% --------------------------------------------------------------------
function clean_roi= roi_loader_clean_roi_struct(roi)

% check the form of the ROI and remove the val and color fields
[TF,err,form]=isroi(roi);
if (form==1)
  clean_roi= roi;
elseif (form==2)
  % remove the 'val' and 'color' fields
  roi= rmfield(roi,'val')
  roi= rmfield(roi,'color')
else
  % roi format not supported
  errordlg('ROI format not currently supported','ERROR');
  clean_roi=[];
end

% --------------------------------------------------------------------
function roi_loader_create(roiLoader_h)

ud=get(roiLoader_h,'UserData');               % get UserData struct
ud
% disable appropriate menu items in the overlay window
set(findobj(ud.OverlayWindowHandle,'Tag','ROILoaderItem'),'Enable','Off');
set(findobj(ud.OverlayWindowHandle,'Tag','ROILoadItem'),'Enable','Off');
set(findobj(ud.OverlayWindowHandle,'Tag','ROIClearItem'),'Enable','Off');

% --------------------------------------------------------------------
function avail_list= roi_loader_update_filelist(handles,avail_list)

%disp('updating listbox');
temp_list=[];                   % temporary storage

% query settings of each dropbox
gyr= get(handles.menu_gyrus,'Value');
gyr_list= get(handles.menu_gyrus,'String');
exam= get(handles.menu_exam,'Value');
exam_list= get(handles.menu_exam,'String');
hemi= get(handles.menu_hemi,'Value');
hemi_list= get(handles.menu_hemi,'String');
slice= get(handles.menu_slice,'Value');
slice_list= get(handles.menu_slice,'String');

%disp(['Selected Gyrus: ' gyr_list(gyr,:)]);
%disp(['Selected Exam Number: ' exam_list(exam,:)]);
%disp(['Selected Hemisphere: ' hemi_list(hemi,:)]);
%disp(['Selected Slice Number: ' slice_list(slice,:)]);

% apply gyrus settings
if (~strcmp('ALL',deblank(gyr_list(gyr,:))))
  for i=[1:size(avail_list,1)]
    if (strcmp(upper(avail_list(i,1:3)),gyr_list(gyr,1:3)))
      temp_list= strvcat(temp_list,avail_list(i,:));
    end
  end
  avail_list= temp_list;
  temp_list= [];
end

% apply hemisphere settings
if (~strcmp('BOTH',deblank(hemi_list(hemi,:))))
  for i=[1:size(avail_list,1)]
    if (strcmp(deblank(hemi_list(hemi,1:end)),'LEFT'))
      % left hemisphere
      if (upper(avail_list(i,4))=='L');
        temp_list= strvcat(temp_list,avail_list(i,:));
      end
    elseif (strcmp(deblank(hemi_list(hemi,1:end)),'RIGHT'))
      % right hemisphere
      if (upper(avail_list(i,4))=='R');
        temp_list= strvcat(temp_list,avail_list(i,:));
      end
    elseif (strcmp(deblank(hemi_list(hemi,1:end)),'MIDDLE'))
      % middle hemisphere
      if (upper(avail_list(i,4))=='M');
        temp_list= strvcat(temp_list,avail_list(i,:));
      end         
    end
  end
  avail_list= temp_list;
  temp_list= [];    
end

% apply exam number settings
if (~strcmp('ANY',deblank(exam_list(exam,:))))
  for i=[1:size(avail_list,1)]
    if (strcmp(upper(avail_list(i,6:10)),deblank(exam_list(exam,:))))
      temp_list= strvcat(temp_list,avail_list(i,:));
    end
  end
  avail_list= temp_list;
  temp_list= [];
end

% apply slice number settings
if (~strcmp('ALL',deblank(slice_list(slice,:))))
  for i=[1:size(avail_list,1)]
    [t,r]=strtok(avail_list(i,13:end),'_');
    if (str2num(t)==str2num(slice_list(slice,:)))
      temp_list= strvcat(temp_list,avail_list(i,:));
    end
  end
  avail_list= temp_list;
  temp_list= [];    
end

% apply the threshhold filter
if (~get(handles.check_thresh,'Value'))
  for i=[1:size(avail_list,1)]
    [t,r]=strtok(avail_list(i,13:end),'_');
    if (isempty(r))
      temp_list= strvcat(temp_list,avail_list(i,:));
    end
  end
  avail_list= temp_list;
  temp_list= [];    
end

% --------------------------------------------------------------------
function filelist= roi_loader_update_menus(handles)

%get_roi_info(get(handles.text_directory,'String'));
d=dir([get(handles.text_directory,'String'),filesep,'*.roi']);

% bail out if no ROI files available
if (isempty(d))
  warndlg('No ROI files found!  Please choose another base directory.','Warning');
  filelist=[];
  return
end

% remove the directories to get filelist
d_files=[];
for i=[1:size(d,1)]
  if ~(d(i).isdir)
    d_files= strvcat(d_files,d(i).name(1:end-4));
  end
end
filelist=d_files;   % save a copy to be returned

% update gyrus list
d_files= sortrows(d_files,1:3); % sort by abbrv
gyr_list= ['ALL'];
last_gyr=['ALL'];
for i=[1:size(d_files,1)]
  gyr= upper(d_files(i,1:3));
  if (~strcmp(gyr,last_gyr)) % new gyrus label
    last_gyr= gyr;
    gyr=[gyr,' - ',roi_loader_abbrv_get_descrip(gyr)];  % include label description
    gyr_list= strvcat(gyr_list,gyr);
  end
end
set(handles.menu_gyrus,'String',gyr_list);
set(handles.menu_gyrus,'Value',1);


% update exam number list
d_files= sortrows(d_files,6:10); % sort by exam number
exam_list= ['ANY'];
last_exam=['ANY'];
for i=[1:size(d_files,1)]
  exam= d_files(i,6:10);
  if (~strcmp(exam,last_exam)) % new exam number
    last_exam= exam;
    exam_list= strvcat(exam_list,exam);
  end
end
set(handles.menu_exam,'String',exam_list);
set(handles.menu_exam,'Value',1);


% update hemisphere list
d_files= sortrows(d_files,4); % sort by abbrv
hemi_list= ['BOTH'];
last_hemi=['BOTH'];
for i=[1:size(d_files,1)]
  % determine the hemisphere
  if ('l'==lower(d_files(i,4)))
    hemi='LEFT';
  elseif ('r'==lower(d_files(i,4)))
    hemi='RIGHT';
  elseif ('m'==lower(d_files(i,4)))
    hemi='MIDDLE';
  end
  if (~strcmp(hemi,last_hemi)) % new hemisphere label
    last_hemi= hemi;
    hemi_list= strvcat(hemi_list,hemi);
  end
end
set(handles.menu_hemi,'String',hemi_list);
set(handles.menu_hemi,'Value',1);


% update slice list
d_files= sortrows(d_files,13:size(d_files,2)); % sort by slice number
slice_list= ['ALL'];
last_slice=['ALL'];
for i=[1:size(d_files,1)]
  [t,r]=strtok(d_files(i,13:end),'_');
  t=deblank(t);
  if (~strcmp(t,last_slice)) % new slice number
    last_slice= t;
    slice_list= strvcat(slice_list,t);
  end
end

% convert to number, sort, convert back to string
slice_list= num2str(sort(str2num(slice_list(2:end,:))));
slice_list= strvcat('ALL',slice_list);
set(handles.menu_slice,'String',slice_list);
set(handles.menu_slice,'Value',1);

% Modification History:
%
% $Log: overlay2_roiloader.m,v $
% Revision 1.8  2005/02/16 02:53:45  michelich
% Use more robust version parsing code.
%
% Revision 1.7  2005/02/03 16:58:40  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.6  2003/10/22 15:54:38  gadde
% Make some CVS info accessible through variables
%
% Revision 1.5  2002/11/16 21:29:59  michelich
% Added notes and warning dialog.
%
% Revision 1.4  2002/11/01 19:30:22  michelich
% Added close request function to update overlay2 window properly.
%
% Revision 1.3  2002/10/31 17:34:11  michelich
% Added support for opening roiloader tools for multiple overlay2 windows.
%
% Revision 1.2  2002/10/31 16:58:57  michelich
% Corrected tag of overlay2 menu item.
%
% Revision 1.1  2002/10/30 15:08:38  michelich
% Initial CVS Import of Jer-Yee John Chuang's original ROI loading tool.
% Changes made before checkin:
% - Changed name to overlay2_roiloader.
% - Updated help comments & feedback strings.
% - Inserted the following functions as local functions:
%   roi_loader_abbrv_get_descrip
%   roi_loader_apply_filelist
%   roi_loader_clean_roi_struct
%   roi_loader_create
%   roi_loader_update_filelist
%   roi_loader_update_menus
%
% 
% Pre CVS History Entries:
% Jer-Yee John Chuang, 2002/06/13. Original.