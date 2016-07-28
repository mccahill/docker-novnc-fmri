function roicurrent(imgWin,ROIs)
%ROICURRENT Update display to indicate that ROIs(1) is the current ROI.

% CVS ID and authorship of this code
% CVSId = '$Id: roicurrent.m,v 1.7 2005/02/03 16:58:43 michelich Exp $';
% CVSRevision = '$Revision: 1.7 $';
% CVSDate = '$Date: 2005/02/03 16:58:43 $';
% CVSRCSFile = '$RCSfile: roicurrent.m,v $';

cm=get(findobj(imgWin,'Tag','CurrentROI'),'UIContextMenu');
set(get(cm,'Children'),'Checked','Off');
if isempty(ROIs)
  set(findobj(imgWin,'Tag','CurrentROI'),'BackgroundColor','white');
  set(findobj(imgWin,'Tag','CurrentROI'),'TooltipString','No Current ROI');
  set(findobj(cm,'Tag','ROIColorItem'),'Enable','Off');
  set(findobj(cm,'Tag','ROISaveItem'),'Enable','Off');
  set(findobj(cm,'Tag','ROIClearItem'),'Enable','Off');
  set(findobj(cm,'Tag','ROIImgVoxItem'),'Label','No Current ROI','Enable','Off');
  set(findobj(cm,'Tag','ROISrsVoxItem'),'Visible','Off');
  set(findobj(cm,'Tag','ROISelectItem'),'Enable','Off');
else
  roi=ROIs(1);  % First ROI is current ROI
  set(findobj(imgWin,'Tag','CurrentROI'),'BackgroundColor',roi.color);
  slice=get(findobj(imgWin,'Tag','ImageSlider'),'Value');
  sliceVox=0;  % ROI voxel count on current slice
  totalVox=0;  % Total ROI voxel count
  for s=1:length(roi.slice)
    cnt=length(roi.index{s});
    if roi.slice(s)==slice, sliceVox=cnt; end
    totalVox=totalVox+cnt;
  end
  set(findobj(imgWin,'Tag','CurrentROI'),'TooltipString',sprintf('%d/%d voxels',sliceVox,totalVox));
  set(findobj(cm,'Tag','ROIColorItem'),'Enable','On');
  set(findobj(cm,'Tag','ROISaveItem'),'Enable','On');
  set(findobj(cm,'Tag','ROIClearItem'),'Enable','On');
  set(findobj(cm,'Tag','ROIImgVoxItem'),'Label',sprintf('%d voxels in image',sliceVox),'Enable','On');
  set(findobj(cm,'Tag','ROISrsVoxItem'),'Label',sprintf('%d voxels in series',totalVox),'Visible','On');
  set(findobj(cm,'Tag','ROISelectItem'),'Enable','Off');
  for r=ROIs
    set(findobj(cm,'Tag','ROISelectItem','UserData',r.val),'Enable','On');
  end
  set(findobj(cm,'Tag','ROISelectItem','UserData',roi.val),'Checked','On');
  
  % Update ROI tool window if one is open
  roiWindow_h = get(findobj(imgWin,'Tag','ROIToolItem'),'UserData');
  if ~isempty(roiWindow_h)
    % Update ROI filename (Slice Number may have changed)
    overlay2_roitool('AutoSlice_Callback',[],[],guidata(roiWindow_h));
  end
end

% Modification History:
%
% $Log: roicurrent.m,v $
% Revision 1.7  2005/02/03 16:58:43  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.6  2003/10/22 15:54:39  gadde
% Make some CVS info accessible through variables
%
% Revision 1.5  2002/11/03 08:33:15  michelich
% Call AutoSlice_Callback to update overlay2_roitool GUI instead of doing it here.
%
% Revision 1.4  2002/11/03 01:38:48  michelich
% Updated arguments to updatesavecell callback.
%
% Revision 1.3  2002/10/28 22:18:20  michelich
% Corrected function name for Jimmy's ROI tool
%
% Revision 1.2  2002/10/28 20:57:01  michelich
% Merged changes for advanced ROI dialog box made by Jimmy Dias
% - If ROI window open, update SliceNumber field to current ROI (2002/11/14)
% - Call updatesavecell after ROI drawn. (2002/01/14)
% - Implement changes for multiple ROI windows. (2002/01/14)
% Other changes
% - Changed menu item tag to ROIToolItem.
%
% Revision 1.1  2002/08/27 22:24:24  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2001/09/14. Changed 'roiselectitem' back to 'ROISelectItem'
% Charles Michelich, 2001/01/25. Changed function name to lowercase.
%                                Changed roiselect() to lowercase.
% Francis Favorini,  2000/04/26. Added ROIClearItem.
% Francis Favorini,  1998/10/30. Take care of enabling/disabling Select ROI menu items.
% Francis Favorini,  1998/10/29. Use 'Tag' to find menu items.
% Francis Favorini,  1998/10/14. Changed from TooltipString to UIContextMenu.
% Francis Favorini,  1998/09/30.
