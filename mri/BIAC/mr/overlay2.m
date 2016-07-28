function [fused,cmap]=overlay2(base,over1,over2,bColor,o1Color,o2Color,...
  bClip,o1Clip,o2Clip,bFill,o1Fill,o2Fill,bMap,o1Map,o2Map)
%OVERLAY2 Overlay one or two images over another using specified colormaps.
%
%   [fused,cmap]=OVERLAY2(base,over1,over2,bColor,o1Color,o2Color,...
%     bClip,o1Clip,o2Clip,bFill,o1Fill,o2Fill,bMap,o1Map,o2Map);
%
%   base is the base image.
%   over1 is the first overlay image, possibly empty.
%   over2 is the second overlay image, possibly empty.
%   bColor,o1Color,o2Color are the colormaps for the images.
%     Defaults are gray(192),redpos(16),bluneg(16).
%   bClip,o1Clip,o2Clip are the inclusive clipping limits [min max].
%     Pixels outside of these limits are set to the fill values.
%     Defaults are to use the 10-90% of range of values for the base,
%     and [2.5 5] for o1Clip and [-5 -2.5] for o2Clip.
%   bFill,o1Fill,o2Fill are the fill values [min max].
%     These are the values that are assigned to pixels outside the
%     clipping limits.  Use nan to make pixels transparent.
%     Defaults are [0 bClip(2)], [nan o1Clip(2)], [o2Clip(1) nan].
%   bMap,o1Map,o2Map are the inclusive mapping limits [min max].
%     After the images have been clipped, they are mapped to
%     these ranges, which are indices into their colormaps.
%     Defaults are to use the full colormap ranges.
%   fused is the image resulting from combining the input images.
%   cmap is the companion colormap.
%
%   Notes:
%   To get the GUI, either omit all input arguments or
%     omit all output arguments.
%   To get a default, set the argument to [] or omit it.
%   The images must be the same size.
%   The colormaps shouldn't have more than 224 entries combined.
%
%   Calling variations:
%     overlay2('LoadROIs',imgWin,ROIs);
%       Load specified ROIs.
%       imgWin is a handle to an existing overlay2 figure.
%         Default is current figure.
%       ROIs is an array of ROIs.
%     overlay2('ClearROIs',imgWin);
%       Clear all ROIs that are currently loaded.
%     overlay2('SetImageNum',imgWin,img);
%       Change currently displayed image.
%       img is the image number.  Default is 1.
%
%   Examples:
%   >>overlay2
%   >>overlay2(b,o,o,gray(192),redpos(16),bluneg(16),[200 3000],[2 5],[-5 -2]);
%   >>[fused,cmap]=overlay2(b,o,o);
%   >>overlay2 ClearROIs
%   >>overlay2('loadrois',gcf,[roi1 roi2]);
%   >>overlay2('setimagenum',gcf,1);

% CVS ID and authorship of this code
% CVSId = '$Id: overlay2.m,v 1.24 2006/10/27 16:12:58 gadde Exp $';
% CVSRevision = '$Revision: 1.24 $';
% CVSDate = '$Date: 2006/10/27 16:12:58 $';
% CVSRCSFile = '$RCSfile: overlay2.m,v $';

% TODO: Prob with invalid readmr params??
% TODO: Handle attempted load of invalid ROI file (check for roi var).  See next TODO.
% TODO: Better integration of isroi (use when loading ROI).
% TODO: Allow user to set filenames? (for use in scripts)
% TODO: Modify Montage to use DataAspectRatio (i.e. handle non-square voxels)
% TODO: Modify TIFF to use DataAspectRatio (i.e. handle non-square voxels)

% The following parameters will be remembered for each instance of overlay2
% Initialize saved directories to current working directory
saveTIFFPath=cd;
saveROIPath=cd; saveROILimits={[] [] [] 0};
saveBasePath=cd; saveBaseParams={}; saveBaseZoom=[];
saveO1Path=cd; saveO1Params={}; saveO1Zoom=[];
saveO2Path=cd; saveO2Params={}; saveO2Zoom=[];

% Color and ROI parameters
maxColors=256;
%ROIColors=[0 1 0; 0 .5 0; 1 0 1; .5 0 1];  % Green, Dk. Green, Magenta, Purple
ROIColors=getROIColors;
ROIMax=size(ROIColors,1);
ROIVals=[maxColors:-1:maxColors-ROIMax+1];
o1ColorsDef=16;
o2ColorsDef=16;
baseColorsDef=maxColors-(o1ColorsDef+o2ColorsDef+ROIMax);

% Check number of args
error(nargchk(0,15,nargin));

% Set up defaults
GUIupdate=0;
interp=0;
if nargin==0 | ~ischar(base)
  % Check input arguments and set defaults
  % TODO: Check the rest of the input arguments
  % TODO: Make smarter about 1 vs. 2 overlays (or pos. vs neg.)
  if nargin<1, base=[]; end
  if isstruct(base) & isfield(base,'data'), base=base.data; end % Support readmr struct
  if ~isnumeric(base) | ndims(base) > 3
    error('base or base.data must be a numeric array with 3 or fewer dimensions!');
  end
  if nargin<2, over1=[]; end
  if isstruct(over1) & isfield(over1,'data'), over1=over1.data; end % Support readmr struct
  if ~isnumeric(over1) | ndims(over1) > 3
    error('over1 or over1.data must be a numeric array with 3 or fewer dimensions!');
  end
  if nargin<3, over2=[]; end
  if isstruct(over2) & isfield(over2,'data'), over2=over2.data; end % Support readmr struct
  if ~isnumeric(over2) | ndims(over2) > 3
    error('over2 or over2.data must be a numeric array with 3 or fewer dimensions!');
  end
  if nargin<4 | isempty(bColor), bColor=gray(baseColorsDef); end
  if nargin<5 | isempty(o1Color), o1Color=redpos(o1ColorsDef); end
  if nargin<6 | isempty(o2Color), o2Color=bluneg(o2ColorsDef); end
  if isempty(base)
    imgPos=[1 1 1 1];
    bClip=[200 3000];
  else
    imgPos=[1 1 size(base,1) size(base,2)];
    if nargin<7 | isempty(bClip)
      [bMin bMax]=minmax(base);
      bClip=(bMax-bMin)*[0.1 0.9]+bMin;
    end
  end
  if nargin<8 | isempty(o1Clip), o1Clip=[3.6 8.0]; end      % .001 probability
  if nargin<9 | isempty(o2Clip), o2Clip=[-8.0 -3.6]; end    % .001 probability
  if nargin<10 | isempty(bFill), bFill=[0 bClip(2)]; end
  if nargin<11 | isempty(o1Fill), o1Fill=[nan o1Clip(2)]; end
  if nargin<12 | isempty(o2Fill), o2Fill=[o2Clip(1) nan]; end
  if nargin<13 | isempty(bMap), bMap=[1 size(bColor,1)]; end
  if nargin<14 | isempty(o1Map), o1Map=[bMap(2)+1 bMap(2)+size(o1Color,1)]; end
  if nargin<15 | isempty(o2Map), o2Map=[o1Map(2)+1 o1Map(2)+size(o2Color,1)]; end
end

% Handle GUI
if nargin==0 | (~ischar(base) & nargout==0)
  % GUI-only defaults
  [bRange,o1Range,o2Range]=deal([0 0]);
  [bFillType,o1FillType,o2FillType]=deal([1 2],[1 2],[2 1]);
  [bColorName,o1ColorName,o2ColorName]=deal('gray','redpos','bluneg');
  ROIs=[];
  
  % Initialize image window
  overlaygui;
  imgWin=gcf;
  set(imgWin,'DoubleBuffer','On');
  % Just show a black image for now
  axes(findobj(imgWin,'Tag','ImageAxes'));
  set(gca,'DrawMode','Fast');
  image(1,'Tag','TheImage','ButtonDownFcn','roiselect','EraseMode','Normal');
  axes(findobj(imgWin,'Tag','ColorBarAxes'));
  image(1,'Tag','ColorBarImage','EraseMode','None');
  
  % Set up ROI context menu
  h=uicontextmenu;
  uimenu(h,'Label','Change ROI Color','Enable','Off','Tag','ROIColorItem','CallBack','ROIColor;');
  uimenu(h,'Label','Save ROI to Disk','Enable','Off','Tag','ROISaveItem','CallBack','overlay2(''GUIROISave'');');
  uimenu(h,'Label','Load ROI from Disk','Tag','ROILoadItem','CallBack','overlay2(''GUIROILoad'');');
  uimenu(h,'Label','Delete All ROIs','Tag','ROIClearItem','CallBack','overlay2(''GUIROIClear'');');
  uimenu(h,'Label','Open ROI Drawing Tool','Enable','On','Tag','ROIToolItem','CallBack','overlay2_roitool(gcf);','Separator','on');
  if exist('overlay2_roiloader')==2 % Only include this button if the loading tool is in the path
    uimenu(h,'Label','Open ROI Loading Tool (beta)','Enable','On','Tag','ROILoaderItem','CallBack','overlay2_roiloader(gcf);');
  else
    uimenu(h,'Label','Open ROI Loading Tool (beta)','Enable','Off','Tag','ROILoaderItem');
  end
  uimenu(h,'Label','No Current ROI','Enable','Off','Separator','on','Tag','ROIImgVoxItem');
  uimenu(h,'Label','','Visible','off','Tag','ROISrsVoxItem');
  for r=1:ROIMax
    m=uimenu(h,'Label',sprintf('Select ROI %d',r),'Enable','Off','Tag','ROISelectItem','UserData',ROIVals(r),...
      'CallBack',sprintf('roiselect(%d);',ROIVals(r)));
    if r==1, set(m,'Separator','on'); end
  end
  set(findobj(imgWin,'Tag','CurrentROI'),'UIContextMenu',h);

  % Instead of padding srs with zeros to make it square, set DataAspectRatio.
  set(findobj(imgWin,'Tag','ImageAxes'),'DataAspectRatio',[1 1 1]);
  
  % Save parameters
  setParams(imgWin,{base,over1,over2,bColor,o1Color,o2Color,...
      bClip,o1Clip,o2Clip,bFill,o1Fill,o2Fill,bMap,o1Map,o2Map,...
      bRange,o1Range,o2Range,bFillType,o1FillType,o2FillType,...
      bColorName,o1ColorName,o2ColorName,imgPos,interp,ROIs,...
      saveTIFFPath,saveROIPath,saveROILimits,saveBasePath,saveBaseParams,saveBaseZoom,...
      saveO1Path,saveO1Params,saveO1Zoom,saveO2Path,saveO2Params,saveO2Zoom});
  
  if nargin==0
    % Just initializing GUI
    return;
  else
    % User specified parameters and wants to start in GUI mode
    % Clear clone option
    set(findobj(imgWin,'Tag','CloneCheckBox'),'Value',0);
    % Load base
    [base,bRange,bClip,bFill,imgPos]=newGUISeries(imgWin,['=' inputname(1)],'BaseName',...
      base,bClip,bFill,bFillType,imgPos,size(base));
    % Load overlays
    if ~isempty(over1)
      [over1,o1Range,o1Clip,o1Fill]=newGUISeries(imgWin,['=' inputname(2)],'Over1Name',...
        over1,o1Clip,o1Fill,o1FillType,imgPos,size(base));
    end
    if ~isempty(over2)
      [over2,o2Range,o2Clip,o2Fill]=newGUISeries(imgWin,['=' inputname(3)],'Over2Name',...
        over2,o2Clip,o2Fill,o2FillType,imgPos,size(base));
    end

    GUIupdate=2;
    % Now fall through to overlay code
  end
elseif strcmpi(base,'SetImageNum')
  % Change to specified image number
  % User may call overlay2('SetImageNum',imgWin,img) from a script
  if nargin<2 | isempty(over1), over1=gcf; end
  if nargin<3 | isempty(over2), over2=1; end
  imgWin=over1;
  img=over2;
  if ~ishandle(imgWin), emsg='You must specify a valid figure.'; error(emsg); end
  h=findobj(imgWin,'Tag','ImageNum');
  if isempty(h), emsg='You must specify an overlay2 figure.'; error(emsg); end
  set(h,'String',num2str(img));
  figure(imgWin);
  overlay2('GUIImageNum');    % Handle invalid img value and update display
  return;
elseif strcmp(base,'GUIROIClear') | strcmpi(base,'ClearROIs')
  % User chose Delete All ROIs menu item or called overlay2('ClearROIs',imgWin) from a script
  inGUI=strcmp(base,'GUIROIClear');
  if inGUI
    imgWin=gcf;
  else
    if nargin<2 | isempty(over1), over1=gcf; end
    imgWin=over1;
    if ~ishandle(imgWin), emsg='You must specify a valid figure.'; error(emsg); end
    h=findobj(imgWin,'Tag','ImageNum');
    if isempty(h), emsg='You must specify an overlay2 figure.'; error(emsg); end
  end
  % Delete all ROIs
  params=getParams(imgWin);
  if ~isempty(params{27})
    params{27}=[];
    setParams(imgWin,params);
    % Update display
    overlay2('GUISlider');
  end
  return;
elseif strcmp(base,'GUIROILoad') | strcmpi(base,'LoadROIs')
  % User chose Load ROI menu item or called overlay2('LoadROIs',imgWin,ROIs) from a script
  inGUI=strcmp(base,'GUIROILoad');
  if inGUI
    imgWin=gcf;
  else
    if nargin<2 | isempty(over1), over1=gcf; end
    if nargin<3 | isempty(over2), over2=[]; end
    imgWin=over1;
  end
  % Get parameters
  params=getParams(imgWin);
  [base interp ROIs saveROIPath]=deal(params{[1 26 27 29]});
  % Check non-GUI args
  if inGUI
    newROIs=1;            % Placeholder so length(newROIs)==1 below
  else
    newROIs=over2(:)';    % Make sure it's a row vector (single structure is OK, too)
    if ~ishandle(imgWin), emsg='You must specify a valid figure.'; error(emsg); end
    h=findobj(imgWin,'Tag','ImageNum');
    if isempty(h), emsg='You must specify an overlay2 figure.'; error(emsg); end
    if isempty(newROIs) | ~all(isroi(newROIs)), emsg='You must specify a valid set of ROIs.'; error(emsg); end
  end
  % Make sure we can add an ROI
  if isempty(base)
    errorbox('You must load data before loading ROI''s.');
    return;
  end
  if interp
    errorbox('Sorry, you cannot load ROI''s when Interpolate is checked.');
    return;
  end
  if length(ROIs)+length(newROIs)>ROIMax
    errorbox(sprintf('Sorry, you cannot load more than %d ROI''s.',ROIMax));
    return;
  end
  % If we're in the GUI, get the ROI
  if inGUI
    % Get ROI file name
    [roiFile saveROIPath]=uigetfile(fullfile(saveROIPath,'*.roi'),'Load ROI File');
    if roiFile==0, return; end
    params{29}=saveROIPath;
    % Get ROI from file
    load(fullfile(saveROIPath,roiFile),'roi','-mat');
    newROIs=roi;
  end
  % Check base size(s)
  % Note: newROIs can be a row vector of one or more ROIs
  if ~isequal(newROIs.baseSize,[size(base,1),size(base,2),size(base,3)])
    errorbox(sprintf(['That ROI was defined on a volume of size %d x %d x %d, '...
        'which is different from the current volume size %d x %d x %d.'],...
      newROIs(1).baseSize(1),newROIs(1).baseSize(2),newROIs(1).baseSize(3),...
      size(base,1),size(base,2),size(base,3)),...
      'Error Loading ROI');
    return;
  end
  % Make first new ROI current & save parameters
  newROI(newROIs,ROIs,ROIVals,ROIColors,imgWin,params);
  return;
elseif strcmp(base,'GUIROISave')
  % User chose Save ROI menu item
  % Get parameters
  imgWin=gcf;
  params=getParams(imgWin);
  [ROIs saveROIPath]=deal(params{[27 29]});
  % Make sure we have an ROI to save
  if isempty(ROIs)
    errorbox('There are no ROI''s to save.');
    return;
  end
  % Get ROI file name
  [roiFile saveROIPath]=uiputfile(fullfile(saveROIPath,'*.roi'),'Save ROI File');
  if roiFile==0, return; end
  params{29}=saveROIPath;
  % BUG: MATLAB 5.3 uiputfile doesn't append .roi extension
  if isempty(findstr(roiFile,'.')), roiFile=[roiFile '.roi']; end
  % ENDBUG
  % Save the current ROI to file
  roi=ROIs(1);
  if str2double(strtok(strtok(version),'.')) >= 7
    % Save ROIs for MATLAB 5 & 6 compatibility
    save(fullfile(saveROIPath,roiFile),'roi','-V6');
  else
    save(fullfile(saveROIPath,roiFile),'roi');
  end
  % Save parameters
  setParams(imgWin,params);
  return;
elseif strcmp(base,'GUIROIDef')
  % User clicked define ROI button
  
  % Second argument is overlay2 window handle.
  if nargin < 2,
    imgWin=gcf;  % Use current figure by default
  else
    imgWin=over1;
  end
  % Third argument specifies whether to user saved ROI limits and srs
  % or prompt the user the the limits and srs
  if nargin < 3 | isempty(over2),
    useSavedLimits = 0; % Do NOT use same limits by default
  else
    useSavedLimits = over2;
  end
  
  % Get parameters
  params=getParams(imgWin);
  [base,over1,over2,o1Clip,o2Clip,o1Range,o2Range,interp,ROIs,saveROILimits]=deal(params{[1:3 8:9 17:18 26:27 30]});
  % See if we can create an ROI
  if interp
    errorbox('Sorry, you cannot define ROI''s when Interpolate is checked.');
    return;
  end
  if isempty(base)
    errorbox('You must load data before defining ROI''s.');
    return;
  end
  if length(ROIs)>=ROIMax
    errorbox(sprintf('Sorry, limited to %d ROI''s.',ROIMax));
    return;
  end
  if useSavedLimits
    % Use saved limits
    srs = saveROILimits{4};
    limits = saveROILimits{srs+1};
  else
    % Get limits (try to supply defaults)
    srs=0;
    if ~isempty(over2)
      srs=2;
      if isempty(saveROILimits{2})
        saveROILimits{3}=[floor(o2Range(1)) o2Clip(2)];
      end
    end
    if ~isempty(over1)
      srs=1;
      if isempty(saveROILimits{1})
        saveROILimits{2}=[o1Clip(1) ceil(o1Range(2))];
      end
    end
    [srs,limits]=roilimits(srs,saveROILimits{1:3});
    if isempty(srs)
      return;
    end
    saveROILimits{srs+1}=limits;
    saveROILimits{4}=srs;  % Save the last srs chosen for use in overlay2_roitool.
    params{30}=saveROILimits;
  end
  if ~isempty(srs)
    % Define ROI
    roi=roidef(srs,limits,imgWin);
    if ~isempty(roi)
      % Make ROI current & save parameters
      newROI(roi,ROIs,ROIVals,ROIColors,imgWin,params);
    end
  end
  return;
elseif strcmp(base,'GUIROIGrow')
  % User clicked grow ROI button
  
  % Second argument is overlay2 window handle.
  if nargin < 2,
    imgWin=gcf;  % Use current figure by default
  else
    imgWin=over1;
  end
  % Third argument specifies whether to user saved ROI limits and srs
  % or prompt the user the the limits and srs
  if nargin < 3 | isempty(over2),
    useSavedLimits = 0; % Do NOT use same limits by default
  else
    useSavedLimits = over2;
  end
  
  % Get parameters
  params=getParams(imgWin);
  [base,over1,over2,o1Clip,o2Clip,o1Range,o2Range,interp,ROIs,saveROILimits]=deal(params{[1:3 8:9 17:18 26:27 30]});
  % See if we can grow an ROI
  if interp
    errorbox('Sorry, you cannot grow ROI''s when Interpolate is checked.');
    return;
  end
  if isempty(ROIs)
    errorbox('There are no ROI''s to grow.');
    return;
  end
  if useSavedLimits
    % Use saved limits
    srs = saveROILimits{4};
    limits = saveROILimits{srs+1};
  else
    % Get limits (try to supply defaults)
    srs=0;
    if ~isempty(over2)
      srs=2;
      if isempty(saveROILimits{2})
        saveROILimits{3}=[floor(o2Range(1)) o2Clip(2)];
      end
    end
    if ~isempty(over1)
      srs=1;
      if isempty(saveROILimits{1})
        saveROILimits{2}=[o1Clip(1) ceil(o1Range(2))];
      end
    end
    [srs,limits]=roilimits(srs,saveROILimits{1:3});
    if isempty(srs)
      return;
    end
    saveROILimits{srs+1}=limits;
    saveROILimits{4}=srs;  % Save the last srs chosen for use in overlay2_roitool.
    params{30}=saveROILimits;
  end
  % Grow current ROI
  roi=roigrow(ROIs(1),srs,limits,imgWin);
  ROIs(1)=roi;
  params{27}=ROIs;
  % Save parameters
  setParams(imgWin,params);
  % Update display
  overlay2('GUISlider');
  return;
elseif strcmp(base,'GUIROIDelete')
  % User clicked delete ROI button
  % Get parameters
  imgWin=gcf;
  params=getParams(imgWin);
  ROIs=params{27};
  % Delete current ROI
  if isempty(ROIs)
    errorbox('There are no ROI''s to delete.');
    return;
  end
  % Delete current ROI
  ROIs(1)=[];
  params{27}=ROIs;
  % Save parameters
  setParams(imgWin,params);
  % Update display
  overlay2('GUISlider');
  return;
elseif strcmp(base,'GUIROIStats')
  % User clicked ROI stats checkbox
  % Get parameters
  imgWin=gcf;
  params=getParams(imgWin);
  [base,ROIs,saveBasePath,saveBaseParams,saveBaseZoom]=deal(params{[1 27 31:33]});
  if isempty(ROIs)
    errorbox('There are no ROI''s defined.');
    return;
  end
  roi=ROIs(1);
  % Get Run info from last time GUIROIStats was called 
  % & ask user if they want to use it.
  lastRunsInfo=get(findobj(imgWin,'Tag','ROIStatsButton'),'UserData');
  useSameRuns=0;
  if ~isempty(lastRunsInfo)
    useSameRuns=strcmp(questdlg('Use the same runs last used to calculate ROI stats?', ...
      'Use the same runs?','Yes','No','Yes'),'Yes');
  end
  if useSameRuns
    % Use info from last set of runs
    [names,MRparams,zooms]=deal(lastRunsInfo{:});
    nRuns=length(names);
  else
    % Select Runs
    waitfor(msgbox(sprintf(['The current ROI was defined on a volume with size %d x %d x %d.  The runs you '...
        'select will be interpolated in x, y, and z to match this size before calculating statistics on them.  '...
        'Click the "Cancel" button in the "Open MR Data File" dialog box when you are done selecting runs.'],...
      roi.baseSize(1),roi.baseSize(2),roi.baseSize(3)),'Information','help','modal'));
    % TODO: Get better user input (e.g., stat func)
    nRuns=0;
    while 1
      % Get the volume's params
      saveBaseParams=readmr('=>INFOONLY');
      if isempty(saveBaseParams), break; end
      name=saveBaseParams.info.displayname;
      % Check number of slices
      if ~isint(roi.baseSize(3)./saveBaseParams.info.dimensions(3).size)
        errorbox(['That volume has a different number of slices or non-integer factor number of slices ' ...
            'from the one on which the ROI was defined and will consequently be ignored.']);
      else
        % Allow user to zoom in on volume
        if isempty(saveBaseZoom), saveBaseZoom=[1 1 saveBaseParams.info.dimensions(1:2).size]; end
        saveBaseZoom=getzoom(saveBaseZoom,[1 1 saveBaseParams.info.dimensions(1:2).size]);
        if isempty(saveBaseZoom), break; end
        % Add volume to list to run stats on
        nRuns=nRuns+1;
        names{nRuns}=name;
        MRparams{nRuns}=saveBaseParams;
        zooms{nRuns}=saveBaseZoom;
      end
    end
  end
    
  if nRuns==0
    errorbox('You didn''t select any runs to calculate ROI statistics on.');
  else
    % Save parameters & currently selected runs (if we selected new runs)
    if ~useSameRuns
      params{31}=saveBasePath;
      params{32}=MRparams{nRuns};  %saveBaseParams from last run selected
      params{33}=saveBaseZoom;
      setParams(imgWin,params);
      set(findobj(imgWin,'Tag','ROIStatsButton'),'UserData',{names,MRparams,zooms});
    end
    
    % Calculate stats
    p=progbar(sprintf('Calculating statistics on run %d of %d...',0,nRuns),[-1 0.65 -1 -1]);
    ptr=get(imgWin,'pointer');
    set(imgWin,'pointer','watch');
    set(p,'pointer','watch');
    drawnow;
    data=cell(1,nRuns);
    for r=1:nRuns
      if ~ishandle(p), set(imgWin,'pointer',ptr); return; end  % User aborted
      progbar(p,sprintf('Calculating statistics on run %d of %d...',r,nRuns));
      srsSpec{r}=name2spec(names{r});
      try data{r}=roistats(MRparams{r},{},zooms{r},roi,'mean');
      catch if ~isempty(findstr('User abort',lasterr)), delete(p); else error(lasterr); end, end
      if ~ishandle(p), set(imgWin,'pointer',ptr); return; end  % User aborted
      progbar(p,r/nRuns);
    end
    delete(p);
    % Display data
    % TODO: Deal better with srs that can't be read in?  Maybe remove from data?
    fig_h=figure;
    colordef(fig_h,'none');  % Setup axes for BIAC standard colors
    hold on;
    colors='ymcrgb';
    for r=1:nRuns
      plot(data{r},colors(mod(r-1,length(colors))+1));
    end
    set(gcf,'DefaultTextInterpreter','none');  % Backslashes confuse Tex interpreter
    % The DefaultTextInterpreter is not used by legend in MATLAB 5.3 to 7.0
    % and possibly other versions also.  As a work around, turn off
    % warnings to supress the Tex warning message and then set the text
    % interpreter 'by-hand'.  Note: State of warning NOT preserved!
    warning off
    [legh,objh] = legend(srsSpec{:},1);                      % Upper right (auto never seems to be smart)
    warning on
    set(findobj(objh,'Type','text'),'Interpreter','none');
    clear legh objh
    
    uicontrol('Style','PushButton','String','ToExcel','Position',[10 10 60 20],...
      'CallBack', ...
      ['tmp__data=get(gcbf,''UserData'');' ...           % Callback vars use base workspace, so pick unlikely names
        'toexcel(tmp__data(1:2,:),1,1,inf);' ...
        'for tmp__c=1:size(tmp__data,2),' ...
        '  toexcel(tmp__data{3,tmp__c},3,tmp__c);' ...   % Extract vectors of voxels separately (may be diff sizes)
        'end, clear tmp__data tmp__c']);                 % Must clear tmp__ vars
    % Get ROI voxel count
    ROISize=0;
    for s=1:length(roi.slice)
      ROISize=ROISize+length(roi.index{s});
    end
    % Save data to UserData
    ud=[cell(size(srsSpec));srsSpec;data];     % Store whole vectors in cell since they might be diff sizes
    ud(1,:)={ROISize};                         % Stick ROI size at top of each column
    set(gcf,'UserData',ud);
    % Save data to base workspace
    assignin('base','ROISize',ROISize);
    assignin('base','ROINames',srsSpec);
    assignin('base','ROIData',data);
    set(imgWin,'pointer',ptr);
  end
  return;
elseif strcmp(base,'GUIROIShow')
  % User clicked show ROI checkbox
  % Update display
  overlay2('GUISlider');
  return;
elseif strcmp(base,'GUIMontage')
  % User clicked Montage button
  % Get parameters
  imgWin=gcf;
  params=getParams(imgWin);
  [base imgPos ROIs]=deal(params{[1 25 27]});
  if isempty(base)
    errorbox('There is nothing to show.');
    return;
  end
  fused=get(findobj(imgWin,'Tag','ImageAxes'),'UserData');
  if get(findobj(imgWin,'Tag','ROIShowCheckBox'),'Value')
    for img=1:size(fused,3)
      fused(:,:,img)=roifuse(fused(:,:,img),img,imgPos,ROIs);
    end
  end
  mrmontage(fused,get(imgWin,'ColorMap'));
  return;
elseif strcmp(base,'GUISaveTIFF')
  % User clicked TIFF button
  % Get parameters
  imgWin=gcf;
  params=getParams(imgWin);
  [base,saveTIFFPath]=deal(params{[1 28]});
  if isempty(base)
    msgbox('There is nothing to save.','Error','error','modal');
    return;
  end
  img=get(findobj(imgWin,'Tag','TheImage'),'CData');
  if get(findobj(imgWin,'Tag','ColorBarType'),'Value')~=1
    % Scale colorbar, pad with ones, and concatenate with image
    cbar=flipud(get(findobj(imgWin,'Tag','ColorBarImage'),'CData'));
    rows=size(img,1);          % img is in row x col format
    scale=rows/256;
    if scale<1
      cbar=cbar(1:1/scale:end);
    elseif scale>1
      scale=fix(scale);
      cbar=reshape(repmat(cbar',scale,1),scale*length(cbar),1);
    end
    cbar=[cbar; ones(rows-length(cbar),1)];
    % Make 8% of img width (with 5 pixels minimum)
    cbar=repmat(cbar,1,max(5,round(0.08*size(img,2))));
    img=[cbar img];
  end
  cmap=get(imgWin,'Colormap');
  [fName,saveTIFFPath]=uiputfile(fullfile(saveTIFFPath,'*.tif'),'Save as TIFF File');
  if fName==0, return; end
  params{28}=saveTIFFPath;
  TIFFWrite(img,cmap,fullfile(saveTIFFPath,fName));
  % Save parameters
  setParams(imgWin,params);
  return;
elseif strcmp(base,'GUIColorBarType')
  % User changed colorbar type
  updColorBar(gcf);
  return;
elseif strcmp(base,'GUIColorBarLabels')
  % User toggled colorbar labels
  updColorBar(gcf);
  return;
elseif strcmp(base,'GUIInterp')
  % User clicked on Interpolate checkbox
  % Restore saved parameters
  imgWin=gcf;
  params=getParams(imgWin);
  [base,over1,over2,bColor,o1Color,o2Color,...
   bClip,o1Clip,o2Clip,bFill,o1Fill,o2Fill,bMap,o1Map,o2Map,...
   bRange,o1Range,o2Range,bFillType,o1FillType,o2FillType,...
   bColorName,o1ColorName,o2ColorName,imgPos,interp,ROIs,...
   saveTIFFPath,saveROIPath,saveROILimits,saveBasePath,saveBaseParams,saveBaseZoom,...
   saveO1Path,saveO1Params,saveO1Zoom,saveO2Path,saveO2Params,saveO2Zoom]=deal(params{:});

  interp=get(findobj(imgWin,'Tag','InterpCheckBox'),'Value');
  if interp & ~isempty(ROIs)
    qbutt=questdlg('Sorry, you cannot have ROI''s in Interpolated mode.  Clear ROI''s?','','OK','Cancel','OK');
    if strcmp(qbutt,'Cancel')
      set(findobj(imgWin,'Tag','InterpCheckBox'),'Value',0);
      return;
    end
    ROIs=[];
  end
  
  % Set pointer to watch
  imgWinPtr=get(imgWin,'pointer');
  set(imgWin,'pointer','watch');
  drawnow;
  
  % Update displayed image
  set(findobj(imgWin,'Tag','TheImage'),'EraseMode','normal');  % Avoid visible axes scaling
  GUIupdate=1;
  % Now fall through to overlay code
elseif strncmp(base,'GUILoad',7)
  % User clicked on a Load button
  button=base;
  
  % Restore saved parameters
  imgWin=gcf;
  params=getParams(imgWin);
  [base,over1,over2,bColor,o1Color,o2Color,...
   bClip,o1Clip,o2Clip,bFill,o1Fill,o2Fill,bMap,o1Map,o2Map,...
   bRange,o1Range,o2Range,bFillType,o1FillType,o2FillType,...
   bColorName,o1ColorName,o2ColorName,imgPos,interp,ROIs,...
   saveTIFFPath,saveROIPath,saveROILimits,saveBasePath,saveBaseParams,saveBaseZoom,...
   saveO1Path,saveO1Params,saveO1Zoom,saveO2Path,saveO2Params,saveO2Zoom]=deal(params{:});

  % Must have base before overlays
  if ~strcmp(button,'GUILoadBase') & isempty(base)
    errorbox('You must load a base image series first.');
    return;
  end
  
  % Get the image series and remember params
  mrstruct=readmr;
  srs=mrstruct.data;
  MRparam=mrstruct.info;
  name=MRparam.displayname;
  if isempty(srs), return; end
  x=size(srs,1);
  y=size(srs,2);
  imgs=size(srs,3);
  if strcmp(button,'GUILoadBase')
    saveBasePath=fileparts(name);
    saveBaseParams=MRparam;
  elseif strcmp(button,'GUILoadOver1')
    saveO1Path=fileparts(name);
    saveO1Params=MRparam;
  elseif strcmp(button,'GUILoadOver2')
    saveO2Path=fileparts(name);
    saveO2Params=MRparam;
  end
  
  % Check for wrong number of slices in overlays
  if strncmp(button,'GUILoadOver',11) & imgs~=size(base,3)
    errorbox('That series has a different number of slices from the base series.');
    return;
  end
  
  % Allow user to zoom in on new series
  if strcmp(button,'GUILoadBase')
    if isempty(saveBaseZoom), saveBaseZoom=[1 1 x y]; end
    zoom=getzoom(saveBaseZoom,[1 1 x y]);
  elseif strcmp(button,'GUILoadOver1')
    if isempty(saveO1Zoom), saveO1Zoom=[1 1 x y]; end
    zoom=getzoom(saveO1Zoom,[1 1 x y]);
  elseif strcmp(button,'GUILoadOver2')
    if isempty(saveO2Zoom), saveO2Zoom=[1 1 x y]; end
    zoom=getzoom(saveO2Zoom,[1 1 x y]);
  end
  if isempty(zoom), return; end
  if strcmp(button,'GUILoadBase')
    saveBaseZoom=zoom;
  elseif strcmp(button,'GUILoadOver1')
    saveO1Zoom=zoom;
  elseif strcmp(button,'GUILoadOver2')
    saveO2Zoom=zoom;
  end
  xWin=zoom(1):zoom(1)+zoom(3)-1;
  yWin=zoom(2):zoom(2)+zoom(4)-1;
  
  x=size(srs,1);
  y=size(srs,2);
  
  % No need to pad image with zeros, DataAspectRatio (set at initialization) handles voxel size
  
  % Now, check size of the series that was loaded
  if strcmp(button,'GUILoadBase')
    if isempty(base)
      imgPos=[1 1 x y];
    elseif ~isequal(size(base),size(srs))
      % Maybe clear overlays if base is a new size
      if ~(isempty(over1) & isempty(over2))
        qbutt=questdlg('The new base series is a different size.  Clear overlays?','','OK','Cancel','OK');
        if strcmp(qbutt,'Cancel')
          return;
        end
        over1=[];
        over2=[];
      end
      imgPos=[1 1 x y];
      ROIs=[];
    end
  end
  
  % Set pointer to watch
  imgWinPtr=get(imgWin,'pointer');
  set(imgWin,'pointer','watch');
  drawnow;
  
  if strcmp(button,'GUILoadBase')
    % Update GUI with loaded base
    [base,bRange,bClip,bFill,imgPos]=newGUISeries(imgWin,name,'BaseName',srs,[],bFill,bFillType,imgPos,size(srs));
  else
    % Update GUI with loaded overlay (if clone is set, update both overlays)
    clone=get(findobj(imgWin,'Tag','CloneCheckBox'),'Value');
    if clone | strcmp(button,'GUILoadOver1')
      [over1,o1Range,o1Clip,o1Fill]=newGUISeries(imgWin,name,'Over1Name',srs,o1Clip,o1Fill,o1FillType,imgPos,size(base));
    end
    if clone | strcmp(button,'GUILoadOver2')
      [over2,o2Range,o2Clip,o2Fill]=newGUISeries(imgWin,name,'Over2Name',srs,o2Clip,o2Fill,o2FillType,imgPos,size(base));
    end
  end
  
  % Update displayed image
  set(findobj(imgWin,'Tag','TheImage'),'EraseMode','normal');  % Avoid visible axes scaling
  GUIupdate=2;
  % Now fall through to overlay code
elseif strcmp(base,'GUIImageNum')
  % User changed image number
  imgWin=gcf;
  img=floor(str2num(get(findobj(imgWin,'Tag','ImageNum'),'String')));
  % Make sure img is valid
  fused=get(findobj(imgWin,'Tag','ImageAxes'),'UserData');
  imgs=size(fused,3);
  if isempty(img) | isnan(img), img=1; end
  if img>imgs, img=imgs; end
  if img<1, img=1; end
  % Update display
  set(findobj(imgWin,'Tag','ImageSlider'),'Value',img);
  set(findobj(imgWin,'Tag','ImageNum'),'String',num2str(img));
  overlay2('GUISlider');
  return;
elseif strcmp(base,'GUISlider')
  % User changed slider
  % Find image window
  h=get(gcf,'UserData');
  if ishandle(h), imgWin=h; else imgWin=gcf; end
  % Get parameters
  params=getParams(imgWin);
  [imgPos,ROIs]=deal(params{[25 27]});
  % Update image number
  img=round(get(findobj(imgWin,'Tag','ImageSlider'),'Value'));
  set(findobj(imgWin,'Tag','ImageSlider'),'Value',img)
  set(findobj(imgWin,'Tag','ImageNum'),'String',num2str(img));
  % Get selected image data
  fused=get(findobj(imgWin,'Tag','ImageAxes'),'UserData');
  sliceData=fused(:,:,img);
  % Show ROIs
  roicurrent(imgWin,ROIs);
  if get(findobj(imgWin,'Tag','ROIShowCheckBox'),'Value')
    sliceData=roifuse(sliceData,img,imgPos,ROIs);
  end
  % Show selected image
  set(findobj(imgWin,'Tag','TheImage'),'CData',sliceData','EraseMode','Normal');
  return;
elseif strcmp(base,'GUIConfig')
  % User hit Config button, initialize/find config window
  imgWin=gcf;
  cfgWin=findobj('Tag','OverlayCfgWin','UserData',imgWin);
  if isempty(cfgWin), cfgWin=overlaycfggui; end
  set(cfgWin,'UserData',imgWin);
  % Restore saved parameters
  params=getParams(imgWin);
  [base,over1,over2,bColor,o1Color,o2Color,...
   bClip,o1Clip,o2Clip,bFill,o1Fill,o2Fill,bMap,o1Map,o2Map,...
   bRange,o1Range,o2Range,bFillType,o1FillType,o2FillType,...
   bColorName,o1ColorName,o2ColorName,imgPos,interp,ROIs]=deal(params{[1:27]});
  % Fill in parameters
  % Image info
  if ~isempty(base)
    set(findobj(cfgWin,'Tag','BaseName'),'String',...
      get(findobj(imgWin,'Tag','BaseName'),'String'));
    set(findobj(cfgWin,'Tag','BaseActualMin'),'String',num2str(bRange(1)));
    set(findobj(cfgWin,'Tag','BaseActualMax'),'String',num2str(bRange(2)));
  end
  if ~isempty(over1)
    set(findobj(cfgWin,'Tag','Over1Name'),'String',...
      get(findobj(imgWin,'Tag','Over1Name'),'String'));
    set(findobj(cfgWin,'Tag','Over1ActualMin'),'String',num2str(o1Range(1)));
    set(findobj(cfgWin,'Tag','Over1ActualMax'),'String',num2str(o1Range(2)));
  end
  if ~isempty(over2)
    set(findobj(cfgWin,'Tag','Over2Name'),'String',...
      get(findobj(imgWin,'Tag','Over2Name'),'String'));
    set(findobj(cfgWin,'Tag','Over2ActualMin'),'String',num2str(o2Range(1)));
    set(findobj(cfgWin,'Tag','Over2ActualMax'),'String',num2str(o2Range(2)));
  end
  % Clipping info
  set(findobj(cfgWin,'Tag','BaseClipMin'),'String',num2str(bClip(1)));
  set(findobj(cfgWin,'Tag','BaseClipMax'),'String',num2str(bClip(2)));
  set(findobj(cfgWin,'Tag','Over1ClipMin'),'String',num2str(o1Clip(1)));
  set(findobj(cfgWin,'Tag','Over1ClipMax'),'String',num2str(o1Clip(2)));
  set(findobj(cfgWin,'Tag','Over2ClipMin'),'String',num2str(o2Clip(1)));
  set(findobj(cfgWin,'Tag','Over2ClipMax'),'String',num2str(o2Clip(2)));
  % Clipping fill info
  set(findobj(cfgWin,'Tag','BaseFillTypeMin'),'Value',bFillType(1));
  set(findobj(cfgWin,'Tag','BaseFillTypeMax'),'Value',bFillType(2));
  set(findobj(cfgWin,'Tag','Over1FillTypeMin'),'Value',o1FillType(1));
  set(findobj(cfgWin,'Tag','Over1FillTypeMax'),'Value',o1FillType(2));
  set(findobj(cfgWin,'Tag','Over2FillTypeMin'),'Value',o2FillType(1));
  set(findobj(cfgWin,'Tag','Over2FillTypeMax'),'Value',o2FillType(2));
  bFill(1)=index([0 bClip(1) bRange(1) bFill(1)],bFillType(1));
  bFill(2)=index([0 bClip(2) bRange(2) bFill(2)],bFillType(2));
  o1Fill(1)=index([nan o1Clip(1) o1Range(1) o1Fill(1)],o1FillType(1));
  o1Fill(2)=index([nan o1Clip(2) o1Range(2) o1Fill(2)],o1FillType(2));
  o2Fill(1)=index([nan o2Clip(1) o2Range(1) o2Fill(1)],o2FillType(1));
  o2Fill(2)=index([nan o2Clip(2) o2Range(2) o2Fill(2)],o2FillType(2));
  set(findobj(cfgWin,'Tag','BaseFillMin'),'String',num2str(bFill(1)));
  set(findobj(cfgWin,'Tag','BaseFillMax'),'String',num2str(bFill(2)));
  set(findobj(cfgWin,'Tag','Over1FillMin'),'String',num2str(o1Fill(1)));
  set(findobj(cfgWin,'Tag','Over1FillMax'),'String',num2str(o1Fill(2)));
  set(findobj(cfgWin,'Tag','Over2FillMin'),'String',num2str(o2Fill(1)));
  set(findobj(cfgWin,'Tag','Over2FillMax'),'String',num2str(o2Fill(2)));
  % Mapping info
  set(findobj(cfgWin,'Tag','BaseMapMin'),'String',num2str(bMap(1)));
  set(findobj(cfgWin,'Tag','BaseMapMax'),'String',num2str(bMap(2)));
  set(findobj(cfgWin,'Tag','Over1MapMin'),'String',num2str(o1Map(1)));
  set(findobj(cfgWin,'Tag','Over1MapMax'),'String',num2str(o1Map(2)));
  set(findobj(cfgWin,'Tag','Over2MapMin'),'String',num2str(o2Map(1)));
  set(findobj(cfgWin,'Tag','Over2MapMax'),'String',num2str(o2Map(2)));
  % Colormap info
  set(findobj(cfgWin,'Tag','BaseColorName'),'String',bColorName);
  set(findobj(cfgWin,'Tag','BaseColorNum'),'String',num2str(size(bColor,1)));
  set(findobj(cfgWin,'Tag','Over1ColorName'),'String',o1ColorName);
  set(findobj(cfgWin,'Tag','Over1ColorNum'),'String',num2str(size(o1Color,1)));
  set(findobj(cfgWin,'Tag','Over2ColorName'),'String',o2ColorName);
  set(findobj(cfgWin,'Tag','Over2ColorNum'),'String',num2str(size(o2Color,1)));
  % Image position info
  set(findobj(cfgWin,'Tag','XPos'),'String',num2str(imgPos(1)));
  set(findobj(cfgWin,'Tag','YPos'),'String',num2str(imgPos(2)));
  set(findobj(cfgWin,'Tag','XSize'),'String',num2str(imgPos(3)));
  set(findobj(cfgWin,'Tag','YSize'),'String',num2str(imgPos(4)));
  % Colorbar
  axes(findobj(cfgWin,'Tag','ColorBarAxes'));
  image(1,'Tag','ColorBarImage');
  cmap=[bColor; o1Color; o2Color];
  if ~isempty(cmap)
    set(cfgWin,'colormap',cmap);
    set(findobj(cfgWin,'Tag','ColorBarAxes'),'YLim',[1 size(cmap,1)+1]);
    set(findobj(cfgWin,'Tag','ColorBarImage'),...
      'XData',[0 1],'YData',0.5+[1 size(cmap,1)],'CData',[1:size(cmap,1)]');
  end
  return;
elseif strcmp(base,'GUICfgXPos')
  % User changed image position info
  cfgWin=gcf;
  set(findobj(cfgWin,'Tag','YPos'),'String',get(findobj(cfgWin,'Tag','XPos'),'String'));
  return;
elseif strcmp(base,'GUICfgXSize')
  % User changed image position info
  cfgWin=gcf;
  set(findobj(cfgWin,'Tag','YSize'),'String',get(findobj(cfgWin,'Tag','XSize'),'String'));
  return;
elseif strcmp(base,'GUICfgClipInfo')
  % User changed clipping info
  cfgWin=gcf;
  imgWin=get(cfgWin,'UserData');
  clipType=2;                  % Clipping limit fill type is 2nd choice in popup menu
  limit=get(gcbo,'String');
  % Update fill controls
  switch get(gcbo,'Tag')
    case 'BaseClipMin'
      type=get(findobj(cfgWin,'Tag','BaseFillTypeMin'),'Value');
      if type==clipType
        set(findobj(cfgWin,'Tag','BaseFillMin'),'String',limit);
      end
    case 'BaseClipMax'
      type=get(findobj(cfgWin,'Tag','BaseFillTypeMax'),'Value');
      if type==clipType
        set(findobj(cfgWin,'Tag','BaseFillMax'),'String',limit);
      end
    case 'Over1ClipMin'
      type=get(findobj(cfgWin,'Tag','Over1FillTypeMin'),'Value');
      if type==clipType
        set(findobj(cfgWin,'Tag','Over1FillMin'),'String',limit);
      end
    case 'Over1ClipMax'
      type=get(findobj(cfgWin,'Tag','Over1FillTypeMax'),'Value');
      if type==clipType
        set(findobj(cfgWin,'Tag','Over1FillMax'),'String',limit);
      end
    case 'Over2ClipMin'
      type=get(findobj(cfgWin,'Tag','Over2FillTypeMin'),'Value');
      if type==clipType
        set(findobj(cfgWin,'Tag','Over2FillMin'),'String',limit);
      end
    case 'Over2ClipMax'
      type=get(findobj(cfgWin,'Tag','Over2FillTypeMax'),'Value');
      if type==clipType
        set(findobj(cfgWin,'Tag','Over2FillMax'),'String',limit);
      end
  end
  return;
elseif strcmp(base,'GUICfgFillInfo')
  % User changed clipping fill info
  cfgWin=gcf;
  imgWin=get(cfgWin,'UserData');
  otherType=4;                  % "Other" fill type is 4th choice in popup menu
  % Get parameters
  params=getParams(imgWin);
  [bRange,o1Range,o2Range]=deal(params{[16:18]});
  % Clipping info
  bClip=[str2num(get(findobj(cfgWin,'Tag','BaseClipMin'),'String'))...
         str2num(get(findobj(cfgWin,'Tag','BaseClipMax'),'String'))];
  o1Clip=[str2num(get(findobj(cfgWin,'Tag','Over1ClipMin'),'String'))...
          str2num(get(findobj(cfgWin,'Tag','Over1ClipMax'),'String'))];
  o2Clip=[str2num(get(findobj(cfgWin,'Tag','Over2ClipMin'),'String'))...
          str2num(get(findobj(cfgWin,'Tag','Over2ClipMax'),'String'))];
  % Clipping fill info
  bFill=[str2num(get(findobj(cfgWin,'Tag','BaseFillMin'),'String'))...
         str2num(get(findobj(cfgWin,'Tag','BaseFillMax'),'String'))];
  o1Fill=[str2num(get(findobj(cfgWin,'Tag','Over1FillMin'),'String'))...
          str2num(get(findobj(cfgWin,'Tag','Over1FillMax'),'String'))];
  o2Fill=[str2num(get(findobj(cfgWin,'Tag','Over2FillMin'),'String'))...
          str2num(get(findobj(cfgWin,'Tag','Over2FillMax'),'String'))];
  % Update controls    
  type=get(gcbo,'Value');
  switch get(gcbo,'Tag')
    case 'BaseFillTypeMin'
      fill=index([0 bClip(1) bRange(1) bFill(1)],type);
      set(findobj(cfgWin,'Tag','BaseFillMin'),'String',num2str(fill));
    case 'BaseFillTypeMax'
      fill=index([0 bClip(2) bRange(2) bFill(2)],type);
      set(findobj(cfgWin,'Tag','BaseFillMax'),'String',num2str(fill));
    case 'Over1FillTypeMin'
      fill=index([nan o1Clip(1) o1Range(1) o1Fill(1)],type);
      set(findobj(cfgWin,'Tag','Over1FillMin'),'String',num2str(fill));
    case 'Over1FillTypeMax'
      fill=index([nan o1Clip(2) o1Range(2) o1Fill(2)],type);
      set(findobj(cfgWin,'Tag','Over1FillMax'),'String',num2str(fill));
    case 'Over2FillTypeMin'
      fill=index([nan o2Clip(1) o2Range(1) o2Fill(1)],type);
      set(findobj(cfgWin,'Tag','Over2FillMin'),'String',num2str(fill));
    case 'Over2FillTypeMax'
      fill=index([nan o2Clip(2) o2Range(2) o2Fill(2)],type);
      set(findobj(cfgWin,'Tag','Over2FillMax'),'String',num2str(fill));
    case 'BaseFillMin'
      set(findobj(cfgWin,'Tag','BaseFillTypeMin'),'Value',otherType);
    case 'BaseFillMax'
      set(findobj(cfgWin,'Tag','BaseFillTypeMax'),'Value',otherType);
    case 'Over1FillMin'
      set(findobj(cfgWin,'Tag','Over1FillTypeMin'),'Value',otherType);
    case 'Over1FillMax'
      set(findobj(cfgWin,'Tag','Over1FillTypeMax'),'Value',otherType);
    case 'Over2FillMin'
      set(findobj(cfgWin,'Tag','Over2FillTypeMin'),'Value',otherType);
    case 'Over2FillMax'
      set(findobj(cfgWin,'Tag','Over2FillTypeMax'),'Value',otherType);
  end
  return;
elseif strcmp(base,'GUICfgColorInfo')
  % User changed colormap info
  cfgWin=gcf;
  bColorName=get(findobj(cfgWin,'Tag','BaseColorName'),'String');
  bColor=feval(bColorName,str2num(get(findobj(cfgWin,'Tag','BaseColorNum'),'String')));
  o1ColorName=get(findobj(cfgWin,'Tag','Over1ColorName'),'String');
  o1Color=feval(o1ColorName,str2num(get(findobj(cfgWin,'Tag','Over1ColorNum'),'String')));
  o2ColorName=get(findobj(cfgWin,'Tag','Over2ColorName'),'String');
  o2Color=feval(o2ColorName,str2num(get(findobj(cfgWin,'Tag','Over2ColorNum'),'String')));
  cmap=[bColor; o1Color; o2Color];
  set(cfgWin,'colormap',cmap);
  set(findobj(cfgWin,'Tag','ColorBarAxes'),'YLim',[1 size(cmap,1)+1]);
  set(findobj(cfgWin,'Tag','ColorBarImage'),...
    'XData',[0 1],'YData',0.5+[1 size(cmap,1)],'CData',[1:size(cmap,1)]');
  % Update mapping info
  bMap=[1 size(bColor,1)];
  o1Map=[bMap(2)+1 bMap(2)+size(o1Color,1)];
  o2Map=[o1Map(2)+1 o1Map(2)+size(o2Color,1)];
  set(findobj(cfgWin,'Tag','BaseMapMin'),'String',num2str(bMap(1)));
  set(findobj(cfgWin,'Tag','BaseMapMax'),'String',num2str(bMap(2)));
  set(findobj(cfgWin,'Tag','Over1MapMin'),'String',num2str(o1Map(1)));
  set(findobj(cfgWin,'Tag','Over1MapMax'),'String',num2str(o1Map(2)));
  set(findobj(cfgWin,'Tag','Over2MapMin'),'String',num2str(o2Map(1)));
  set(findobj(cfgWin,'Tag','Over2MapMax'),'String',num2str(o2Map(2)));
  return;
elseif strcmp(base,'GUICfgCancel')
  delete(gcf);
  return;
elseif strcmp(base,'CloseRequest')
  % This case handles closing the window. 
  % (1) Close configuration & tools windows
  % (2) Close overlay2 window

  % Get handle of overlay2 window
  overlay2_h = gcf;

  % Close any open configuration or tool GUIs for this figure
  try
    % Find and delete ROI Drawing Tool
    h = get(findobj(overlay2_h,'Tag','ROIToolItem'),'UserData');
    if ~isempty(h) & ishandle(h), delete(h); end
  catch
    % If this fails, issue a warning and continue on to close finish close request function
    warning(sprintf('Failure attempting to automatically close ROI Drawing Tool.\nError was:\n%s',lasterr));
  end

  try
    % Find and delete ROI Loading Tool
    h = get(findobj(overlay2_h,'Tag','ROILoadItem'),'UserData');
    if ~isempty(h) & ishandle(h), delete(h); end
  catch
    % If this fails, issue a warning and continue on to close finish close request function
    warning(sprintf('Failure attempting to automatically close ROI Loading Tool.\nError was:\n%s',lasterr));
  end

  try
    % Find and delete overlaygui GUI
    h=findobj('Tag','OverlayCfgWin','UserData',overlay2_h);
    if ~isempty(h) & ishandle(h), delete(h); end
  catch
    % If this fails, issue a warning and continue on to close finish close request function
    warning(sprintf('Failure attempting to automatically close overlay2 configuration GUI.\nError was:\n%s',lasterr));
  end
  
  % Close overlay2 GUI
  delete(overlay2_h);
  return;
elseif strcmp(base,'GUICfgOK') | strcmp(base,'GUICfgApply')
  % Get parameters (everything not set in Config window)
  button=base;
  cfgWin=gcf;
  imgWin=get(cfgWin,'UserData');
  params=getParams(imgWin);
  [base,over1,over2,bRange,o1Range,o2Range,interp,ROIs,...
   saveTIFFPath,saveROIPath,saveROILimits,saveBasePath,saveBaseParams,saveBaseZoom,...
   saveO1Path,saveO1Params,saveO1Zoom,saveO2Path,saveO2Params,saveO2Zoom]=deal(params{[1:3 16:18 26:39]});
  
  % Clipping info
  bClip=[str2num(get(findobj(cfgWin,'Tag','BaseClipMin'),'String'))...
         str2num(get(findobj(cfgWin,'Tag','BaseClipMax'),'String'))];
  o1Clip=[str2num(get(findobj(cfgWin,'Tag','Over1ClipMin'),'String'))...
          str2num(get(findobj(cfgWin,'Tag','Over1ClipMax'),'String'))];
  o2Clip=[str2num(get(findobj(cfgWin,'Tag','Over2ClipMin'),'String'))...
          str2num(get(findobj(cfgWin,'Tag','Over2ClipMax'),'String'))];
  % Clipping fill info
  bFill=[str2num(get(findobj(cfgWin,'Tag','BaseFillMin'),'String'))...
         str2num(get(findobj(cfgWin,'Tag','BaseFillMax'),'String'))];
  o1Fill=[str2num(get(findobj(cfgWin,'Tag','Over1FillMin'),'String'))...
          str2num(get(findobj(cfgWin,'Tag','Over1FillMax'),'String'))];
  o2Fill=[str2num(get(findobj(cfgWin,'Tag','Over2FillMin'),'String'))...
          str2num(get(findobj(cfgWin,'Tag','Over2FillMax'),'String'))];
  bFillType=[get(findobj(cfgWin,'Tag','BaseFillTypeMin'),'Value')...
             get(findobj(cfgWin,'Tag','BaseFillTypeMax'),'Value')];
  o1FillType=[get(findobj(cfgWin,'Tag','Over1FillTypeMin'),'Value')...
              get(findobj(cfgWin,'Tag','Over1FillTypeMax'),'Value')];
  o2FillType=[get(findobj(cfgWin,'Tag','Over2FillTypeMin'),'Value')...
              get(findobj(cfgWin,'Tag','Over2FillTypeMax'),'Value')];
  % Mapping info
  bMap=[str2num(get(findobj(cfgWin,'Tag','BaseMapMin'),'String'))...
        str2num(get(findobj(cfgWin,'Tag','BaseMapMax'),'String'))];
  o1Map=[str2num(get(findobj(cfgWin,'Tag','Over1MapMin'),'String'))...
         str2num(get(findobj(cfgWin,'Tag','Over1MapMax'),'String'))];
  o2Map=[str2num(get(findobj(cfgWin,'Tag','Over2MapMin'),'String'))...
         str2num(get(findobj(cfgWin,'Tag','Over2MapMax'),'String'))];
  % Colormap info
  bColorName=get(findobj(cfgWin,'Tag','BaseColorName'),'String');
  bColor=feval(bColorName,str2num(get(findobj(cfgWin,'Tag','BaseColorNum'),'String')));
  o1ColorName=get(findobj(cfgWin,'Tag','Over1ColorName'),'String');
  o1Color=feval(o1ColorName,str2num(get(findobj(cfgWin,'Tag','Over1ColorNum'),'String')));
  o2ColorName=get(findobj(cfgWin,'Tag','Over2ColorName'),'String');
  o2Color=feval(o2ColorName,str2num(get(findobj(cfgWin,'Tag','Over2ColorNum'),'String')));
  % Image position info
  imgPos=[str2num(get(findobj(cfgWin,'Tag','XPos'),'String')) ...
          str2num(get(findobj(cfgWin,'Tag','YPos'),'String')) ...
          str2num(get(findobj(cfgWin,'Tag','XSize'),'String')) ...
          str2num(get(findobj(cfgWin,'Tag','YSize'),'String'))];
  
  %TODO: Validate params:
  %imgPos should only be positive integers
  maxx=max([size(base,1) size(over1,1) size(over2,1)]);
  maxy=max([size(base,2) size(over1,2) size(over2,2)]);
  if ~(isempty(base) & isequal(imgPos,[1 1 1 1])) & ...
     (any(imgPos<1) | any(~isint(imgPos)) | any([imgPos(1:2)+imgPos(3:4)-1]>[maxx maxy]))
    msgbox('Specified series zoom parameters are invalid!','Error','error','modal');
    return;
  end
  
  % Set pointers to watches
  cfgWinPtr=get(cfgWin,'pointer');
  set(cfgWin,'pointer','watch');
  imgWinPtr=get(imgWin,'pointer');
  set(imgWin,'pointer','watch');
  figure(imgWin);
  drawnow;
  if strcmp(button,'GUICfgOK'), delete(cfgWin); end
  
  % Update displayed image
  set(findobj(imgWin,'Tag','TheImage'),'EraseMode','normal');  % Avoid visible axes scaling
  GUIupdate=2;
  % Now fall through to overlay code
elseif ischar(base)
  error('Invalid first argument.');
end

% Do the overlay
fused=[];
cmap=[];
if ~isempty(base)
  % Zoom images to imgPos
  xWin=imgPos(1):imgPos(1)+imgPos(3)-1;
  yWin=imgPos(2):imgPos(2)+imgPos(4)-1;
  fused=base(xWin,yWin,:);
  if ~isempty(over1), o1=over1(xWin,yWin,:); end
  if ~isempty(over2), o2=over2(xWin,yWin,:); end
  xLim=[0.5 imgPos(3)+0.5];
  yLim=[0.5 imgPos(4)+0.5];
  
  % Interpolate images
  % TODO: add user-specified scale factor
  % Caution: if xScale and yScale are not equal, the DataAspectRatio must be modified
  %          to account for the change in relative voxel size.
  %          Currently, the code guarantees that xScale == yScale
  if interp
    x=size(fused,1); y=size(fused,2); z=size(fused,3);  % Current size
    if x == y
      % If the series are square, increase the matrix size to 256      
      newx=256; newy=256;                               % Interpolated size
      xScale=newx/x; yScale=newy/y;
    else
      % Otherwise, double the matrix size
      xScale=2; yScale=2;
    end
    xLim=[0.5 xScale*imgPos(3)+0.5];
    yLim=[0.5 yScale*imgPos(4)+0.5];
    % Scale
    fused=scale3(fused,xScale,yScale,1);
    if ~isempty(over1), o1=scale3(o1,xScale,yScale,1); end
    if ~isempty(over2), o2=scale3(o2,xScale,yScale,1); end
  end
  
  % Clip images (inclusive range) & get limits
  fused(find(fused<bClip(1)))=bFill(1);
  fused(find(fused>bClip(2)))=bFill(2);
  dispLimits=minmax(fused);
  if isempty(over1)
    dispLimits(3:4)=[nan nan];
  else
    o1(find(o1<o1Clip(1)))=o1Fill(1);
    o1(find(o1>o1Clip(2)))=o1Fill(2);
    dispLimits(3:4)=minmax(o1);
  end
  if isempty(over2)
    dispLimits(5:6)=[nan nan];
  else
    o2(find(o2<o2Clip(1)))=o2Fill(1);
    o2(find(o2>o2Clip(2)))=o2Fill(2);
    dispLimits(5:6)=minmax(o2);
  end
  
  % Map images (inclusive range)
  fused=normaliz(fused,bMap);
  cmap=bColor;
  if ~isempty(over1)
    o1=normaliz(o1,o1Map);
    cmap=[cmap; o1Color];
  end
  if ~isempty(over2)
    o2=normaliz(o2,o2Map);
    cmap=[cmap; o2Color];
  end
  
  % Overlay images
  if ~isempty(over1)
    o1Mask=~isnan(o1);
    fused(o1Mask)=o1(o1Mask);
  end
  if ~isempty(over2)
    o2Mask=~isnan(o2);
    fused(o2Mask)=o2(o2Mask);
  end
  
  % If using GUI, save parameters and show fused image
  if GUIupdate
    % Find image window
    h=get(gcf,'UserData');
    if ishandle(h), imgWin=h; else imgWin=gcf; end
    % Save parameters
    setParams(imgWin,{base,over1,over2,bColor,o1Color,o2Color,...
        bClip,o1Clip,o2Clip,bFill,o1Fill,o2Fill,bMap,o1Map,o2Map,...
        bRange,o1Range,o2Range,bFillType,o1FillType,o2FillType,...
        bColorName,o1ColorName,o2ColorName,imgPos,interp,ROIs,...
        saveTIFFPath,saveROIPath,saveROILimits,saveBasePath,saveBaseParams,saveBaseZoom,...
        saveO1Path,saveO1Params,saveO1Zoom,saveO2Path,saveO2Params,saveO2Zoom});
    % Update file name display
    if isempty(base), set(findobj(gcf,'Tag','BaseName'),'String',''); end
    if isempty(over1), set(findobj(gcf,'Tag','Over1Name'),'String',''); end
    if isempty(over2), set(findobj(gcf,'Tag','Over2Name'),'String',''); end
    % Update image and colorbar
    fMin=dispLimits(1); fMax=dispLimits(2);
    if fMax==fMin, fMin=fMin-1; fMax=fMax+1; end
    set(findobj(imgWin,'Tag','ImageAxes'),'UserData',fused,...
      'CLim',[fMin fMax],'XLim',xLim,'YLim',yLim);
    set(imgWin,'colormap',cmap);
    overlay2('GUISlider');
    if GUIupdate==2, updColorBar(imgWin,dispLimits); end
  end
end % ~isempty(base)

% Reset window pointers
if GUIupdate
  if exist('imgWinPtr')==1
    set(imgWin,'pointer',imgWinPtr);
  end
  if exist('cfgWinPtr')==1 & ishandle(cfgWin)
    set(cfgWin,'pointer',cfgWinPtr);
  end
end
  
if nargout<1, clear fused; end
if nargout<2, clear cmap; end

%--------------------------------------------------
function [srsOut,range,clip,fill,imgPos]=newGUISeries(imgWin,name,nameField,srs,clipIn,fillIn,fillType,imgPos,baseSz)
% Adjust GUI after loading a new series
% Note: clip and imgPos only apply if base series is input

% Adjust imgPos or scale
x=size(srs,1);
y=size(srs,2);
imgs=size(srs,3);
if strcmp(nameField,'BaseName')
  % Shrink to fit base
  if imgPos(1)+imgPos(3)-1>x | imgPos(2)+imgPos(4)-1>y
    imgPos=[1 1 x y];
  end
else
  % Scale overlays only
  % TODO: Determine why min scale used instead of actual scale for each
  % axis.  Perhaps use actual scale factors and warn user if they are
  % different?
  scale=min([baseSz(1)/x baseSz(2)/y]);
  if scale~=1
    srs=scale3(srs,scale,scale,1);
  end
end

% Set range, clip, fill, etc.
range=minmax(srs);
fill=fillIn;
clip=clipIn;
clipVal=nan;
if strcmp(nameField,'BaseName')
  if isempty(clip)
    clip=(range(2)-range(1))*[0.1 0.9]+range(1);    % Clip to 10-90% of range
  end
  clipVal=0;
end
fill(1)=index([clipVal clip(1) range(1) fill(1)],fillType(1));
fill(2)=index([clipVal clip(2) range(2) fill(2)],fillType(2));
set(findobj(imgWin,'Tag',nameField),'String',name,'TooltipString',name);

% Set slider
if imgs>1
  set(findobj(imgWin,'Tag','ImageSlider'),'Min',1,'Max',imgs,'Value',1,...
    'SliderStep',[min(0.999,1/(imgs-1)) max(0.1,min(1,2/(imgs-1)))]);
else
  set(findobj(imgWin,'Tag','ImageSlider'),'Min',0.999,'Max',1.001,'Value',1,...
    'SliderStep',[0 0.001]);
end
srsOut=srs;

%--------------------------------------------------
function updColorBar(imgWin,limits)

if nargin<2, limits=[]; end

% Restore saved parameters
params=getParams(imgWin);
[base,over1,over2,bColor,o1Color,o2Color,...
 bClip,o1Clip,o2Clip,bFill,o1Fill,o2Fill,imgPos,interp]=deal(params{[1:12 25 26]});
xWin=imgPos(1):imgPos(1)+imgPos(3)-1;
yWin=imgPos(2):imgPos(2)+imgPos(4)-1;

% Update colorbar
type=get(findobj(imgWin,'Tag','ColorBarType'),'Value');
cbImage=findobj(imgWin,'Tag','ColorBarImage');
cbAxes=findobj(imgWin,'Tag','ColorBarAxes');
if type==1                      % None
  set(cbImage,'Visible','Off');
  set(cbAxes,'Visible','Off');
else
  % Build colormap
  cmap=[];
  if type==2                    % Just overlays
    skip=size(bColor,1);
  else                          % Base and overlays
    if ~isempty(base), cmap=[bColor]; end
    skip=0;
  end
  if ~isempty(over1), cmap=[cmap; o1Color]; end
  if ~isempty(over2), cmap=[cmap; o2Color]; end
  if ~isempty(cmap)
    % Show colormap
    set(cbAxes,'YLim',[skip+1 skip+size(cmap,1)+1]);
    set(cbImage,'XData',[0 1],'YData',0.5+[skip+1 skip+size(cmap,1)],...
      'CData',[skip+1:skip+size(cmap,1)]');
  else
    % No colormap, so make it black
    set(cbAxes,'YLim',[0 1]);
    set(cbImage,'XData',[0 1],'YData',[0 1],...
      'CData',[0 0]');
  end
  set(cbImage,'Visible','On');
  set(cbAxes,'Visible','On');
  
  %Update labels
  if ~get(findobj(imgWin,'Tag','ColorBarLabels'),'Value')
    set(cbAxes,'YTick',[],'YTickLabel','');
  else
    if size(cmap,1)<64
      margin=0;
    elseif size(cmap,1)<=128
      margin=1;
    else
      margin=2;
    end
    ticks=[];
    labels={};
    if ~isempty(base) & type==3
      if ~isempty(limits)
        lo=limits(1); hi=limits(2);
      else
        data=base(xWin,yWin,:);
        data(find(data<bClip(1)))=bFill(1);
        data(find(data>bClip(2)))=bFill(2);
        [lo hi]=minmax(data);
      end
      if size(bColor,1)==1
        ticks=[1];
        if hi==fix(hi), fmt='%7d'; else fmt='%.1f'; end
        labels={labels{:} num2str(hi,fmt)};
      else
        m=min(margin,floor(size(bColor,1)/4));
        ticks=[1+m size(bColor,1)-m];
        if lo==fix(lo) & hi==fix(hi), fmt='%7d'; else fmt='%.1f'; end
        labels={labels{:} num2str(lo,fmt) num2str(hi,fmt)};
      end
    end
    skip=size(bColor,1);
    if ~isempty(over1)
      if ~isempty(limits)
        lo=limits(3); hi=limits(4);
      else
        data=over1(xWin,yWin,:);
        data(find(data<o1Clip(1)))=o1Fill(1);
        data(find(data>o1Clip(2)))=o1Fill(2);
        [lo hi]=minmax(data);
      end
      if size(o1Color,1)==1
        ticks=[ticks skip+1];
        if hi==fix(hi), fmt='%7d'; else fmt='%.1f'; end
        labels={labels{:} num2str(hi,fmt)};
      else
        m=min(margin,floor(size(o1Color,1)/4));
        ticks=[ticks skip+1+m skip+size(o1Color,1)-m];
        if lo==fix(lo) & hi==fix(hi), fmt='%7d'; else fmt='%.1f'; end
        labels={labels{:} num2str(lo,fmt) num2str(hi,fmt)};
      end
    end
    skip=skip+size(o1Color,1);
    if ~isempty(over2)
      if ~isempty(limits)
        lo=limits(5); hi=limits(6);
      else
        data=over2(xWin,yWin,:);
        data(find(data<o2Clip(1)))=o2Fill(1);
        data(find(data>o2Clip(2)))=o2Fill(2);
        [lo hi]=minmax(data);
      end
      if size(o2Color,1)==1
        ticks=[ticks skip+1];
        if hi==fix(hi), fmt='%7d'; else fmt='%.1f'; end
        labels={labels{:} num2str(hi,fmt)};
      else
        m=min(margin,floor(size(o2Color,1)/4));
        ticks=[ticks skip+1+m skip+size(o2Color,1)-m];
        if lo==fix(lo) & hi==fix(hi), fmt='%7d'; else fmt='%.1f'; end
        labels={labels{:} num2str(lo,fmt) num2str(hi,fmt)};
      end
    end
    if ~isempty(ticks)
      ticks=0.5+ticks;
      ticks(1)=ticks(1)-margin;
      ticks(end)=ticks(end)+margin;
    end
    set(cbAxes,'TickLength',[0 0],'YTick',ticks,'YTickLabel',labels,'FontSize',8);
  end
end

%--------------------------------------------------
function newROI(newROIs,ROIs,ROIVals,ROIColors,imgWin,params)
% Make first element of newROIs current, save params and update display
% newROIs must be a row vector of one or more ROIs.
% There must be enough ROI slots available.

oldROIs=ROIs;
for r=1:length(newROIs)
  if ~isfield(newROIs(r),'val') | isempty(newROIs(r).val) | (~isempty(ROIs) & ismember(newROIs(r).val,[ROIs.val]))
    % No value assigned for newROIs(r) or newROIs(r) value is already used.    
    % Assign first unused ROI value & color
    if isempty(ROIs)
      n=1;
    else
      n=find(ROIVals==max(setdiff(ROIVals,[ROIs.val])));
    end
    newROIs(r).val=ROIVals(n);
    newROIs(r).color=ROIColors(n,:);
  end
  ROIs=[newROIs(1:r) oldROIs];
end
  
% Save parameters
params{27}=ROIs;
setParams(imgWin,params);

% Update display
overlay2('GUISlider');

%--------------------------------------------------
function map=getROIColors
% Define ROI colors.  There must currently be 32!

map=[
 1.00  0     1.00;    % Blue Purples
 0.70  0     1.00;
 0.55  0     1.00;
 0.40  0     1.00;
 0     1.00  0;       % Greens
 0     0.70  0;
 0     0.55  0;
 0     0.40  0;
 1.00  0     0.50;    % Red Purples
 0.80  0     0.50;
 0.60  0     0.50;
 0.40  0     0.50;
 0.80  0.75  0.05;    % Olives
 0.63  0.58  0.05;
 0.47  0.42  0.05;
 0.40  0.25  0.05;
 0.90  0.75  0.90;    % Light Purples
 0.80  0.63  0.80;
 0.80  0.47  0.80;
 0.80  0.30  0.80;
 0.65  1.00  0.60;    % Light Greens
 0.51  0.95  0.46;
 0.38  0.90  0.33;
 0.25  0.80  0.20;
 1.00  0.75  0.75;    % Light Reds
 1.00  0.63  0.63;
 1.00  0.47  0.47;
 0.80  0.30  0.30;
 0.35  0.95  0.65;    % Blue Greens
 0.30  0.80  0.55;
 0.25  0.65  0.45;
 0.20  0.50  0.35;
];

% Pick the first color in each group of 4, then the 2nd, etc.
i=reshape(reshape(1:32,4,8)',1,32);
% Same as first one, but with each of the latter four groups in reverse order
%i=reshape(reshape([1:16 20:-1:17 24:-1:21 28:-1:25 32:-1:29],4,8)',1,32);
% Same as first one, but keep 4 lightest colors at the end
%i=reshape(reshape([1:16 18:20 17 22:24 21 26:28 25 30:32 29],4,8)',1,32)
map=map(i,:);


%--------------------------------------------------
function params=getParams(imgWin)
% Get saved parameters for this instance of overlay2
% TODO: Maybe read a preferences file from the user's home directory

params=get(imgWin,'UserData');


%--------------------------------------------------
function setParams(imgWin,params)
% Set saved parameters for this instance of overlay2
% TODO: Maybe write a preferences file to the user's home directory

set(imgWin,'UserData',params);

% Modification History:
%
% $Log: overlay2.m,v $
% Revision 1.24  2006/10/27 16:12:58  gadde
% Move away from readmrold.
%
% Revision 1.23  2005/02/16 01:51:22  michelich
% Simplify version check code.
%
% Revision 1.22  2005/02/03 20:17:46  michelich
% M-Lint: Replace deprecated isstr with ischar.
%
% Revision 1.21  2005/02/03 16:58:40  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.20  2004/10/26 21:52:19  michelich
% Save ROIs for MATLAB 5 & 6 compatibility when using MATLAB 7.
%
% Revision 1.19  2004/08/20 01:13:38  michelich
% Added work around for a Mathworks legend bug so that Mathworks legend
% function does not have to be changed.
%
% Revision 1.18  2004/02/23 17:23:12  michelich
% Bug Fix: Extract data field from correct variable for second overlay.
%
% Revision 1.17  2003/10/22 15:54:38  gadde
% Make some CVS info accessible through variables
%
% Revision 1.16  2003/06/30 16:35:39  michelich
% Use readmrold until function is updated for new readmr.
%
% Revision 1.15  2003/06/29 21:01:36  michelich
% Updated error messages.
%
% Revision 1.14  2003/06/02 22:14:26  michelich
% Support new readmr structure from command line interface.
%
% Revision 1.13  2003/06/02 22:02:52  michelich
% Fix base size checking when loading ROIs on single slice images.
% Check type and ndims of input images.
%
% Revision 1.12  2003/04/25 16:44:13  michelich
% Fixed loading multiple ROIs without val fields using 'LoadROIs'.
%
% Revision 1.11  2003/03/20 22:12:55  michelich
% In GUIROIStats Callback:
% - Fixed storing and using savedBasePath,saveBaseParam,saveBaseZoom.
% - Cache last selected runs & give user option to use them.
%
% Revision 1.10  2003/02/10 22:42:23  michelich
% Include disabled roiloader menu item for better user experience.
%
% Revision 1.9  2003/02/10 22:37:49  michelich
% Only show roiloader menu item if overlay2_roiloader is in the path.
% (overlay2_roiloader is still has bugs so it won't be included in the 2.2 release)
%
% Revision 1.8  2002/12/11 21:08:00  michelich
% Corrected instructions in GUIROIStats callback.
%
% Revision 1.7  2002/12/11 21:03:01  michelich
% Allow integer factor number of slices in GUIROIStats callback since roistats
%   now supports this.
%
% Revision 1.6  2002/11/03 00:22:39  michelich
% Changes to allow overlay2_roitool to call define and grow.
% - Added arguments for figure handle and same limits flag to GUIROIDef and GUIROIGrow callbacks.
% - Save srs limits defined on in saveROILimits.
% - Pass overlay2 handle to roidef and roigrow.
%
% Revision 1.5  2002/10/31 16:55:50  michelich
% Added close request function to automatically close related GUIs.
%
% Revision 1.4  2002/10/30 15:15:53  michelich
% Merged changes for ROI loading tool made by Jer-Yee John Chuang's 2002-06-13.
% - Added menu choice for ROI loader
% Other changes
% - Changed function call in menu item to overlay2_roiloader()
% - Changed menu item description.
% - Changed location of advanced ROI tools in ROI menu.
%
% Revision 1.3  2002/10/28 20:25:17  michelich
% Merged changes for advanced ROI dialog box made by Jimmy Dias 2002/11/14.
% - Added menu choice for ROI window.
% Other changes
% - Changed function call in menu item to overlay2_roitool().
% - Changed menu item tag to ROIToolItem.
%
% Revision 1.2  2002/09/10 21:16:23  michelich
% Added note about min(scale factor).
%
% Revision 1.1  2002/08/27 22:24:22  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2001/09/27. Moved set DataAspectRatio to [1 1 1] to initialization of GUI (from 'GUILoad' callback)
% Charles Michelich, 2001/09/24. Added comments to interpolation section and TODO's related to setting DataAspectRatio
%                                  for anisotropic voxels.  No code changes.
% Charles Michelich, 2001/09/14. Changed case of 'GUIroistats' & 'roiselectItem' back to 'GUIROIStats' & 'ROISelectItem'
%                                Also updated case 'GUIROIStats' & 'ROIStatsButton' in overlaygui.m
% Charles Michelich, 2001/08/23. Changed colordef on roistats graph to 'none'
% Charles Michelich, 2001/04/27. Changed overlaygui to display proper colors when colordef != none
% Charles Michelich, 2001/04/13. Changed [name,saveBaseParams]=readmr(['Params;'saveBasePath],saveBaseParams{:});
%                                to add a comma between 'Params;' and saveBasePath (MATLAB 6 warning)
% Charles Michelich, 2001/01/23. Changed function name to lowercase.
%                                Changed scale3(), toexcel(), mrmontage(), roilimits(), and getzoom() to lowercase.
%                                Changed overlaycfggui(), isroi() ,overlaygui(), roistats(), and readmr() to lowercase.
%                                Changed roiselect(), roidef(), roifuse(), roigrow(), and roicurrent() to lowercase.
% Francis Favorini,  2000/05/10. Can no longer call toexcel with any empty or matrix cell elements, so don't try.
% Francis Favorini,  2000/05/05. Documented LoadROIs, ClearROIs and SetImageNum calling variations.
% Francis Favorini,  2000/05/04. Fixed bug: opening Config window caused loss of saved paths/params.
% Francis Favorini,  2000/04/26. Fixed bug: bad indexes into params cell array, which prevented saving ROIs and TIFFs.
%                                Fixed bug: not using saveROIPath when loading ROI.
%                                Added LoadROIs, ClearROIs and SetImageNum calling variations to use in scripts.
%                                Allow user to cancel ROI define/grow by canceling/closing roilimits.
%                                Fixed bug: allowed user to load ROI when in interp mode.
% Francis Favorini,  2000/04/18. Remember saved directories/params for each instance of overlay2.
%                                Added getParams and setParams local functions.
% Charles Michelich, 2000/04/14. Changed interpolation size to double the matrix size if the series is not square.
%                                This prevents distortion of non-square series.
% Francis Favorini,  2000/04/14. Don't need to CD to saved dirs, now that readmr takes default dir as arg.
% Francis Favorini,  2000/04/07. Handle bug in MATLAB 5.3 uiputfile, which doesn't append extension to filename.
% Francis Favorini,  2000/03/31. Changed to set DataAspectRatio and allow MATLAB to calculate PlotBoxAspectRatio.
% Charles Michelich, 2000/03/27. Removed requirement for power of two x&y sizes in 'GUICfgOK' callback
% Charles Michelich, 2000/03/25. In 'GUILoad', instead of padding image to a square series,
%                                adjust the aspect ratio of the axis to match of that of the image.
%                                This allows user to draw roi on non-square images (ex: SPM normalized images).
%                                Previously, the image basesize would be incorrect in the saved roi.
% Francis Favorini,  2000/03/23. Fixed bug: ignoring bClip when passed as argument for GUI mode.
% Francis Favorini,  2000/03/22. If there are input args, but no output args, start GUI.
% Francis Favorini,  1999/10/12. Make sure saved paths exist before CD'ing to them.
% Francis Favorini,  1999/05/04. Allow a total of 32 ROI's (with unique colors).
%                                Remember separate path and parameters for base and each overlay.
% Francis Favorini,  1998/11/23. Made name2spec an external function.
% Francis Favorini,  1998/11/20. Fixed bug when comparing new base size to old base size on load.
% Francis Favorini,  1998/11/19. Use scale3 for interpolation.
% Francis Favorini,  1998/11/11. Handle user abort of roistats.
%                                Use delete on progbar instead close.
% Francis Favorini,  1998/11/09. Don't create more than one config window per overlay window.
%                                Correctly handle small colormaps.
% Francis Favorini,  1998/10/30. Don't allow loading of ROI whose baseSize doesn't match current volume.
% Francis Favorini,  1998/10/29. Added ROI Save and Load.
%                                Added newROI local function.
% Francis Favorini,  1998/10/26. Added limits to updColorBar for speed.
% Francis Favorini,  1998/10/14. Added Change ROI Color context menu.
% Francis Favorini,  1998/10/13. Added Montage button.
% Francis Favorini,  1998/09/30. Added roicurrent and ROI TooltipString.
%                                Added ToExcel button to roistats display.
%                                Added Clone checkbox.
% Francis Favorini,  1998/09/28. Added zoom on loading series for roistats.
% Francis Favorini,  1998/09/23. Fixed bug with zoom loading base.
%                                Fixed bug with reloading base image and clearing overlays.
%                                Remember path for saving TIFF files.
% Francis Favorini,  1998/09/22. Changed EraseMode to none for image.
% Francis Favorini,  1998/09/21. Handle ROI's in zoomed mode.
% Francis Favorini,  1998/09/18. Pad series to be square.
%                                Scale overlays to fit base.
% Francis Favorini,  1998/09/14. Set imgPos when not using GUI.
% Francis Favorini,  1998/09/01. Added ROI's.
% Francis Favorini,  1998/08/28. Remembers base size when loading overlays.
% Francis Favorini,  1998/06/24. Fixed/improved colorbar labels.
%                                Fixed bad display when all pixels are clipped to one value.
% Francis Favorini,  1998/06/10. Added GUI!
% Francis Favorini,  1998/06/09. Added second overlay and lots of params.
% Francis Favorini,  1997/01/21. Added fullScale parameter.
% Francis Favorini,  1996/10/18. Bare bones overlay function.
