function showsrs2_goto(fig1,currPoint)
%SHOWSRS2_GOTO Go to particular x,y,z coordinates in a showsrs2 window
%   SHOWSRS2_GOTO(FIGURE1,COORDS) will move the cursors of a showsrs2
%   window figure (FIGURE1) to the coordinates in the array COORDS.  
%   Any linked showsrs2 figures will also have the coordinates changed.
%
%   Example:
%   This will move showsrs2 figure1 to coordinates x-32,y-55,z-12
%     anat = readmr('\\Server\Data\Study.01\Anat\Sub1\anat.bxh');
%     tmap1 = readmr('\\Server\Data\Study.01\Analysis\Sub1\tmap1.bxh');
%     fig1 = showsrs2(anat,tmap1);
%     newcoords = [32,55,12];
%     showsrs2_goto(fig1,newcoords);
%
%   WARNING - Crude code.  No error checking.  
%   If you find any bugs, please send to bizzell@biac.duke.edu

%   Josh Bizzell, 15-Dec-2005.  Original version. 

allhandles = {};
handles1 = guihandles(fig1);
handles1.fig = fig1;
allhandles{1} = handles1;

figUD1 = get(handles1.fig,'UserData');
linkedFigIDs = figUD1.linkedFigIDs;
for linkedFigID = linkedFigIDs
  % Grab showsrs2 figure handle
  linkedFig = getparentfigure(linkedFigID);
  linkedFigUD = get(linkedFig, 'UserData');
  handles1 = linkedFigUD.handles;
  allhandles{end+1} = handles1;
end

for i = 1:length(allhandles)
  %currPoint=get(handles1.Slider,'UserData');
  currhandle = allhandles{i};

  if ~any(currPoint<0) & ~all(currPoint==1)
    if strcmp(get(currhandle.Slider,'Enable'),'on')
      % Slider enabled, find out which slice to show from slice slider
      % Find out which image to show
      slice=currPoint(3);
      set(currhandle.Slider,'Value',-slice);
      set(currhandle.ImgNum,'String',num2str(slice));
      % Update the slice in the currPoint
      % Note: the primary image axis (handles.imgAx) contains a vector
      %       of the mapping of the stored plane to the displayed image
      %       in the structure field toScreenPlane.  The third value is
      %       the dimension which is slice in the displayed image
      ax_ud=get(currhandle.imgAx,'UserData');
      currPoint(ax_ud.toScreenPlane(3))=slice;
    end
    set(currhandle.Slider,'UserData',currPoint);
    % Refresh display
    showsrs2('Refresh_Callback',currhandle.fig);
    % Refresh time series display
    showsrs2('RefreshPlotTimeSrs_Callback',currhandle.fig);
    % Turn on markers when you click
    showsrs2('ShowMarkersMenu_Callback',currhandle.fig,'on');
    % Update markers
    local_updatemarker(currhandle,currPoint(1),currPoint(2),currPoint(3));
  end
end

%------------------------LOCAL_UPDATEMARKER------------------------------------------
function local_updatemarker(handles,x,y,z)
% LOCAL_UPDATEMARKER Update the marker to the current point specified
%
%   local_updatemarker(imgFig,x,y,z)
%     handles - structure of handles for each of the elements in the showsrs2 GUI
%      (returned by function guihandles)
%     x,y,z  = x,y,z point to plot
%

% Point to plot
currPoint=[x y z];

% Get figure UserData
fig_ud=get(handles.fig,'UserData');
imsize=fig_ud.imageSize3D;

% Get the handles of the image axes
imageAxes_h=get([fig_ud.image_h(1), fig_ud.image_h_otherImages{1}],'parent');
if iscell(imageAxes_h), imageAxes_h=[imageAxes_h{:}]; end  % Convert from cell to numeric array

clear('fig_ud'); % Done with Figure UserData, clear it.

% Loop through each axes
for ax=1:length(imageAxes_h)
  % Get mapping to screen plane for each axes
  toScreenPlane=subsref(get(imageAxes_h(ax),'UserData'),struct('type','.','subs','toScreenPlane'));
  currPointScreen=currPoint(toScreenPlane);
  imsizePlane=imsize(toScreenPlane);

  % Make axes current
  axes(imageAxes_h(ax));

  % Find horizontal & vertical lines
  xLine_h=findobj(imageAxes_h(ax),'Type','Line','Tag','HorzMarker');
  yLine_h=findobj(imageAxes_h(ax),'Type','Line','Tag','VertMarker');

  % Setup contextual menu, callback, marker color, marker style if a line
  % needs to be created.
  if isempty(xLine_h) | ~ishandle(xLine_h) | isempty(yLine_h) | ~ishandle(yLine_h)
    % Generate contextual menu items to change cross hair style
    contextMenu_h=uicontextmenu('Tag','MarkerLineMenu');
    uimenu('Parent',contextMenu_h,'Label','-- Cross Hair Style --');
    uimenu('Parent',contextMenu_h,'Label','Solid','Callback', ...
      [ 'set(findobj(gcbf,''Type'',''Line'',''Tag'',''HorzMarker''),''LineStyle'',''-'');' ...
      'set(findobj(gcbf,''Type'',''Line'',''Tag'',''VertMarker''),''LineStyle'',''-'');']);
    uimenu('Parent',contextMenu_h,'Label','Dashed','Callback', ...
      [ 'set(findobj(gcbf,''Type'',''Line'',''Tag'',''HorzMarker''),''LineStyle'',''--'');' ...
      'set(findobj(gcbf,''Type'',''Line'',''Tag'',''VertMarker''),''LineStyle'',''--'');']);
    uimenu('Parent',contextMenu_h,'Label','Dash-Dotted','Callback', ...
      [ 'set(findobj(gcbf,''Type'',''Line'',''Tag'',''HorzMarker''),''LineStyle'',''-.'');' ...
      'set(findobj(gcbf,''Type'',''Line'',''Tag'',''VertMarker''),''LineStyle'',''-.'');']);
    uimenu('Parent',contextMenu_h,'Label','Dotted','Callback', ...
      [ 'set(findobj(gcbf,''Type'',''Line'',''Tag'',''HorzMarker''),''LineStyle'','':'');' ...
      'set(findobj(gcbf,''Type'',''Line'',''Tag'',''VertMarker''),''LineStyle'','':'');']);
    uimenu('Parent',contextMenu_h,'Label','-- Cross Hair Color --');
    uimenu('Parent',contextMenu_h,'Label','Red','Callback', ...
      [ 'set(findobj(gcbf,''Type'',''Line'',''Tag'',''HorzMarker''),''Color'',''r'');' ...
      'set(findobj(gcbf,''Type'',''Line'',''Tag'',''VertMarker''),''Color'',''r'');']);
    uimenu('Parent',contextMenu_h,'Label','Green','Callback', ...
      [ 'set(findobj(gcbf,''Type'',''Line'',''Tag'',''HorzMarker''),''Color'',''g'');' ...
      'set(findobj(gcbf,''Type'',''Line'',''Tag'',''VertMarker''),''Color'',''g'');']);
    uimenu('Parent',contextMenu_h,'Label','Blue','Callback', ...
      [ 'set(findobj(gcbf,''Type'',''Line'',''Tag'',''HorzMarker''),''Color'',''b'');' ...
      'set(findobj(gcbf,''Type'',''Line'',''Tag'',''VertMarker''),''Color'',''b'');']);
    uimenu('Parent',contextMenu_h,'Label','White','Callback', ...
      [ 'set(findobj(gcbf,''Type'',''Line'',''Tag'',''HorzMarker''),''Color'',''w'');' ...
      'set(findobj(gcbf,''Type'',''Line'',''Tag'',''VertMarker''),''Color'',''w'');']);

    % If you click on the line, execute button down function for the image
    cb='eval(get(index(findobj(get(gcbo,''Parent''),''Type'',''image''),1),''ButtonDownFcn''));';

    % Take line color and style from any lines that exist
    anyLine_h=[findobj(handles.fig,'Type','Line','Tag','HorzMarker'); ...
      findobj(handles.fig,'Type','Line','Tag','VertMarker')];
    if isempty(anyLine_h), % Defaults
      markerLineColor='r';
      markerLineStyle='-';
    else % Take from first line
      markerLineColor=get(anyLine_h(1),'Color');
      markerLineStyle=get(anyLine_h(1),'LineStyle');
    end
  end

  % Make (if necessary) & update horizontal line
  if isempty(xLine_h) | ~ishandle(xLine_h)
    line([0.5 imsizePlane(1)+0.5],[currPointScreen(2),currPointScreen(2)], ...
      'Color',markerLineColor,'LineStyle',markerLineStyle,'Tag','HorzMarker','ButtonDownFcn',cb, ...
      'Visible',get(handles.ShowMarkersMenu,'Checked'),'uicontextmenu',contextMenu_h);
  else
    set(xLine_h,'XData',[0.5 imsizePlane(1)+0.5],'YData',[currPointScreen(2),currPointScreen(2)]);
  end

  % Make (if necessary) & update vertical line
  if isempty(yLine_h) | ~ishandle(yLine_h)
    line([currPointScreen(1),currPointScreen(1)],[0.5 imsizePlane(2)+0.5], ...
      'Color',markerLineColor,'LineStyle',markerLineStyle,'Tag','VertMarker','ButtonDownFcn',cb, ...
      'Visible',get(handles.ShowMarkersMenu,'Checked'),'uicontextmenu',contextMenu_h);
  else
    set(yLine_h,'XData',[currPointScreen(1),currPointScreen(1)],'YData',[0.5 imsizePlane(2)+0.5]);
  end
end

% $Log: showsrs2_goto.m,v $
% Revision 1.1  2007/04/13 15:31:14  gadde
% Neat tool from Josh.
%
