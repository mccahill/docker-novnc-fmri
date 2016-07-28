function params=mrmontage(varargin)
%MRMONTAGE Show montage of MR images.
%
%   mrmontage(srs,dims,pgSize,axSize,axMargin);
%   mrmontage(srs,cMap,dims,pgSize,axSize,axMargin);
%   mrmontage(action,srs,dims,pgSize,axSize,axMargin);
%   mrmontage(action,srs,cMap,dims,pgSize,axSize,axMargin);

% TODO: Deal with margins better for non-square.

% CVS ID and authorship of this code
% CVSId = '$Id: mrmontage.m,v 1.4 2005/02/03 20:17:46 michelich Exp $';
% CVSRevision = '$Revision: 1.4 $';
% CVSDate = '$Date: 2005/02/03 20:17:46 $';
% CVSRCSFile = '$RCSfile: mrmontage.m,v $';

% Handle args
error(nargchk(1,7,nargin));
action='Montage';
if ischar(varargin{1})
  action=varargin{1};
  varargin=varargin(2:end);
else
  if nargin==1 | (nargin==2 & size(varargin{2},2)==3)
    action='GUI';
  end
end
if nargin>=2 & size(varargin{2},2)==3
  error(nargchk(1,6,length(varargin)));
  cMap=varargin{2};
  varargin(2)=[];
else
  error(nargchk(0,5,length(varargin)));
  cMap=gray(256);
end

if strcmp(action,'Montage') | strcmp(action,'GUI') | strcmp(action,'Params')
  % Check args and apply defaults
  args=length(varargin);
  varargin(args+1:5)={[]};                                % Pad with []
  [srs dims pgSize axSize axMargin]=deal(varargin{:});
  if isempty(srs)
    if nargout>0, params={}; end
    return;
  end
  autoBoxes=[args>=2 & isempty(dims) isempty(pgSize) args>=4 & isempty(axSize)]; % Which checkboxes will be checked
  if isempty(dims) & isempty(pgSize)
    dims=ceil(sqrt(size(srs,3)));                         % Make as square as possible
    dims=[ceil(size(srs,3)/dims) dims];
  end
  if isempty(axSize) & (isempty(dims) | isempty(pgSize)), axSize=128; end
  if isempty(axMargin), axMargin=0; end
  if ~isempty(dims)
    [cols rows]=deal(dims(1),dims(2));
    if cols<1, cols=1; end
    if rows<1, rows=1; end
  end
  if ~isempty(pgSize)
    [pgWidth pgHeight]=deal(pgSize(1),pgSize(2));
    if pgWidth<1, rowpgWidth=1; end
    if pgHeight<1, pgHeight=1; end
  end
  if ~isempty(axSize) & axSize<1, axSize=1; end
  if axMargin<0, axMargin=0; end
  
  % Calculate missing parameter
  if isempty(dims)
    cols=floor((pgWidth-axMargin)/(axSize+axMargin));
    if cols<1
      cols=1;
      pgWidth=cols*(axSize+axMargin)+axMargin;
    end
    rows=floor((pgHeight-axMargin)/(axSize+axMargin));
    if rows<1
      rows=1;
      pgHeight=rows*(axSize+axMargin)+axMargin;
    end
  elseif isempty(pgSize)
    pgWidth=cols*(axSize+axMargin)+axMargin;
    pgHeight=rows*(axSize+axMargin)+axMargin;
  elseif isempty(axSize)
    axSize=min(floor((pgWidth-axMargin)/cols-axMargin),...
               floor((pgHeight-axMargin)/rows-axMargin));
    if axSize<1
      axSize=1;
      axMargin=min(floor((pgWidth-cols*axSize)/(cols+1)),...
                   floor((pgWidth-cols*axSize)/(cols+1)));
    end           
  end
  xMargin=axMargin;
  yMargin=axMargin;
  
  if strcmp(action,'Params')
    % Just return params
    params={[cols rows] [pgWidth pgHeight] axSize axMargin};
    return;
  elseif strcmp(action,'GUI')
    % Setup GUI
    fig=montagegui;
    set(fig,'UserData',{srs cMap});
    set(findobj(fig,'Tag','AutoGridCheckbox'),'Value',autoBoxes(1));
    if autoBoxes(1), enable='Off'; else enable='On'; end
    set(findobj(fig,'Tag','GridX'),'String',num2str(cols),'Enable',enable);
    set(findobj(fig,'Tag','GridY'),'String',num2str(rows),'Enable',enable);
    set(findobj(fig,'Tag','AutoPageCheckbox'),'Value',autoBoxes(2));
    if autoBoxes(2), enable='Off'; else enable='On'; end
    set(findobj(fig,'Tag','PageX'),'String',num2str(pgWidth),'Enable',enable);
    set(findobj(fig,'Tag','PageY'),'String',num2str(pgHeight),'Enable',enable);
    set(findobj(fig,'Tag','AutoImageCheckbox'),'Value',autoBoxes(3));
    if autoBoxes(3), enable='Off'; else enable='On'; end
    set(findobj(fig,'Tag','ImageSize'),'String',num2str(axSize),'Enable',enable);
    set(findobj(fig,'Tag','ImageMargin'),'String',num2str(axMargin));
    return;
  end
  
  % Create figure
  scrSz=get(0,'ScreenSize');
  menubarHeight=40; taskbarHeight=35; winframeWidth=5;    % Windows window characteristics
  xPos=winframeWidth;                                     % Left edge of screen
  yPos=max(taskbarHeight,(scrSz(4)-pgHeight)/2);          % Center vertically
  pgWidth=min(scrSz(3)-xPos-winframeWidth,pgWidth);       % Don't go off screen
  pgHeight=min(scrSz(4)-yPos-menubarHeight,pgHeight);     % Don't go off screen
  figure('Position',[xPos yPos pgWidth pgHeight],'MenuBar','None','Color',[0 0 0]);
  m=uimenu('Label','&Edit');
  uimenu(m,'Label','Copy &Figure','Callback','mrmontage(''Copy'');','Accelerator','C');
  uimenu(m,'Label','&White Background','Callback','mrmontage(''WhiteBkgrd'');','Accelerator','W',...
    'Tag','WhiteBkgrd');
  colormap(cMap);
  xLim=[0.5 size(srs,1)+0.5];
  yLim=[0.5 size(srs,2)+0.5];
  
  % Find color limits
  [sMin sMax]=minmax(srs);
  if sMax==sMin, sMin=sMin-1; sMax=sMax+1; end
  
  % Build montage
  i=0;
  for y=0:rows-1
    for x=0:cols-1
      axes('Units','Pixels','Visible','off','Box','on','Layer','Top',...
        'DataAspectRatio',[1 1 1],...
        'Position',[x*(axSize+axMargin)+xMargin+1 pgHeight-((y+1)*(axSize+axMargin))+1 axSize axSize],...
        'XTickMode','manual','YTickMode','manual',...
        'XLimMode','manual', 'YLimMode','manual',...
        'XLim',xLim,         'YLim',yLim,...
        'CLim',[sMin sMax],  'YDir','reverse',...
        'nextplot','replacechildren');
      i=i+1;
      if i<=size(srs,3)
        % TODO: add ROI's
        image(srs(:,:,i)');
      end
    end
  end
elseif strcmp(action,'Copy')
  % BUG: In MATLAB 5.3.x black figure background turns white when pasting, 
  % but 'none' causes wierd display, so only set it temporarily.
  c=get(gcf,'Color');
  set(gcf,'Color','None');
  print -dbitmap
  set(gcf,'Color',c);
  return;
elseif strcmp(action,'WhiteBkgrd')
  if strcmpi(get(gcbo,'Checked'),'off')
    set(gcbo,'Checked','on');
    map=colormap;
    map(1,:)=[1 1 1];
    colormap(map);
  else
    set(gcbo,'Checked','off');
    map=colormap;
    map(1,:)=[0 0 0];
    colormap(map);
  end
  return;
else
  % User changed params in dialog box
  [srs cMap]=cindex(get(gcbf,'UserData'),1:2);
  dims=[str2num(get(findobj(gcbf,'Tag','GridX'),'String')) ...
        str2num(get(findobj(gcbf,'Tag','GridY'),'String'))];
  dims(length(dims)+1:2)=1;       % Make sure we have two numeric dims
  pgSize=[str2num(get(findobj(gcbf,'Tag','PageX'),'String')) ...
          str2num(get(findobj(gcbf,'Tag','PageY'),'String'))];
  pgSize(length(pgSize)+1:2)=1;   % Make sure we have two numeric pgSizes
  axSize=str2num(get(findobj(gcbf,'Tag','ImageSize'),'String'));
  if isempty(axSize), axSize=1; end
  axMargin=str2num(get(findobj(gcbf,'Tag','ImageMargin'),'String'));
  if isempty(axMargin), axMargin=0; end
  
  % Fill in auto-params
  if get(findobj(gcbf,'Tag','AutoGridCheckbox'),'Value'), dims=[]; end
  if get(findobj(gcbf,'Tag','AutoPageCheckbox'),'Value'), pgSize=[]; end
  if get(findobj(gcbf,'Tag','AutoImageCheckbox'),'Value'), axSize=[]; end
  params=mrmontage('Params',srs,dims,pgSize,axSize,axMargin);
  [dims pgSize axSize axMargin]=deal(params{:});
  if get(findobj(gcbf,'Tag','AutoGridCheckbox'),'Value'), enable='Off'; else enable='On'; end
  set(findobj(gcbf,'Tag','GridX'),'String',num2str(dims(1)),'Enable',enable);
  set(findobj(gcbf,'Tag','GridY'),'String',num2str(dims(2)),'Enable',enable);
  if get(findobj(gcbf,'Tag','AutoPageCheckbox'),'Value'), enable='Off'; else enable='On'; end
  set(findobj(gcbf,'Tag','PageX'),'String',num2str(pgSize(1)),'Enable',enable);
  set(findobj(gcbf,'Tag','PageY'),'String',num2str(pgSize(2)),'Enable',enable);
  if get(findobj(gcbf,'Tag','AutoImageCheckbox'),'Value'), enable='Off'; else enable='On'; end
  set(findobj(gcbf,'Tag','ImageSize'),'String',num2str(axSize),'Enable',enable);
  set(findobj(gcbf,'Tag','ImageMargin'),'String',num2str(axMargin));
  
  % Show montage or cancel, if user hit button
  if strcmp(action,'OK')
    delete(gcbf);
    mrmontage(srs,cMap,dims,pgSize,axSize,axMargin);
  elseif strcmp(action,'Cancel')
    delete(gcbf);
  end
end

% Modification History:
%
% $Log: mrmontage.m,v $
% Revision 1.4  2005/02/03 20:17:46  michelich
% M-Lint: Replace deprecated isstr with ischar.
%
% Revision 1.3  2005/02/03 16:58:40  michelich
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
% Charles Michelich, 2001/04/27. Explicitly set montage figure background to black .
% Charles Michelich, 2001/01/25. Changed function name to lowercase.
%                                Changed associated GUI to lowercase (montagegui).
% Francis Favorini,  2000/04/28. Support non-square images by setting DataAspectRatio.
%                                Set figure background to 'None' before copy to workaround MATLAB bug.
% Francis Favorini,  1999/05/04. Added White Background menu item.
% Francis Favorini,  1998/10/14. Added Copy menu item.
% Francis Favorini,  1998/10/13. Added some more error checking.
% Francis Favorini,  1998/10/12. Added GUI.
% Francis Favorini,  1998/10/09.
