function EEGTopo(bin,latency,gridSize,margin,chanFile)
%EEGTopo Generate topographical map of EEG data at specified latency.
%
%       EEGTopo;
%       EEGTopo(bin,latency);
%       EEGTopo(bin,latency,gridSize);
%       EEGTopo(bin,latency,gridSize,margin);
%       EEGTopo(bin,latency,gridSize,margin,chanFile);
%
%       bin is the bin to plot.
%         Default the bin the crosshairs are on,
%         else the first bin on screen, else bin 1.
%       latency is the latency to plot.
%         Default is latency the crosshairs are on, else 0.
%       gridSize defines the dimensions of the interpolation grid.
%         Default is 200.
%       margin is the data-free margin around the inside of the grid.
%         Default is gridSize/10.
%       chanFile contains the coordinates of each electrode.
%         Coordinates are space-delimited x and y (and optional z).
%         If not specified and no coord info is already stored, will ask for file.

% CVS ID and authorship of this code
% CVSId = '$Id: EEGTopo.m,v 1.3 2005/02/03 16:58:19 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:19 $';
% CVSRCSFile = '$RCSfile: EEGTopo.m,v $';

if nargin<1, action=''; else action=bin; end

switch action
  case 'uVolts'
    if get(gco,'Value'), state='on'; else state='off'; end
    set(findobj(gcf,'Tag','ElectrodeVolts'),'Visible',state);
    figure(gcf);
    return;
  case 'Names'
    if get(gco,'Value'), state='on'; else state='off'; end
    set(findobj(gcf,'Tag','ElectrodeNames'),'Visible',state);
    figure(gcf);
    return;
  case 'CRange'
    if strncmp(get(gco,'Tag'),'CM',2)                             % User entered min or max
      set(findobj(gcf,'Tag','Auto'),'Value',0)                    % Turn off auto range
    end
    if get(findobj(gcf,'Tag','Auto'),'Value')                     % Auto range turned on
      caxis('auto');
      [cMin cMax]=caxis;
    else                                                          % Auto range turned off
      cMin=str2num(get(findobj(gcf,'Tag','CMin'),'String'));
      cMax=str2num(get(findobj(gcf,'Tag','CMax'),'String'));
      if isempty(cMin), cMin=-1; end
      if isempty(cMax), cMax=-cMin; end
      caxis([cMin cMax]);
    end
    set(findobj(gcf,'Tag','CMin'),'String',num2str(cMin,3));
    set(findobj(gcf,'Tag','CMax'),'String',num2str(cMax,3));
    colorbar;
    figure(gcf);
    return;
  case 'Spline'
    d=get(gcf,'UserData');
    % Don't need to do anything here
    return;        % Doesn't work yet
  case 'Laplacian'
    d=get(gcf,'UserData');
    % Don't need to do anything here
  case 'Bin'
    d=get(gcf,'UserData');
    d.bin=get(findobj(gcf,'Tag','Bin'),'Value');
  case 'Latency'
    d=get(gcf,'UserData');
    d.latency=str2num(get(findobj(gcf,'Tag','Latency'),'String'));
  case '<'
    d=get(gcf,'UserData');
    eeg=getfield(get(d.EEGFig,'UserData'),'eeg');
    d.latency=d.latency-eeg.sampling;
  case '>'
    d=get(gcf,'UserData');
    eeg=getfield(get(d.EEGFig,'UserData'),'eeg');
    d.latency=d.latency+eeg.sampling;
  case 'GridSize'
    d=get(gcf,'UserData');
    d.gridSize=str2num(get(findobj(gcf,'Tag','GridSize'),'String'));
  case 'Margin', error('Not implemented yet.');
  otherwise   % Create figure
    if nargin<1, bin=[]; end
    if nargin<2, latency=[]; end
    if nargin<3, gridSize=[]; end
    if nargin<4, margin=[]; end
    if nargin<5, chanFile=[]; end
    
    % Which figure has EEG data?
    if strcmp(get(gcf,'Tag'),'TopoFig')
      d=get(gcf,'UserData');
      figure(d.EEGFig);
    end
    if ~strcmp(get(gcf,'Tag'),'EEGFig')
      error('Current figure is not an EEG figure.');
    end
    d.EEGFig=gcf;

    % Find EEG info
    eeg=getfield(get(gcf,'UserData'),'eeg');

    % Get bin and latency from crosshairs if not specified
    if isempty(bin) | isempty(latency)
      handles=findobj(findobj(gcf,'Tag','Legend'),'Tag','binName')';
      bins=[];
      for h=handles
        bins=[bins; get(h,'UserData')];
      end
      bins=sort(bins);
      if isempty(bins), bin=1; end                                  % No bins turned on
      if get(findobj(gcf,'Tag','Crosshairs Checkbox'),'Value')~=1   % Cross hairs off
        if isempty(bin), bin=bins(1); end
        if isempty(latency), latency=0; end
      else                                                          % Cross hairs on
        if isempty(bin)
          bin=bins(get(findobj(gcf,'Tag','binSelector'),'Value'));
        end
        if isempty(latency)
          coords=findobj(gcf,'Tag','xCoords');                      % Use cross hairs' latency
          coords=sscanf(get(coords(1),'String'),'(%d,%f)');
          latency=coords(1);
        end
      end
    end

    % Get chanFile, if not specified and don't have coord info from header file
    if isempty(chanFile)
      coords=eeg.coords;
      if isempty(coords)
        [name,path]=uigetfile('*.chn','Select channel position file');
        if name==0, return, end                                       % User hit Cancel button.
        chanFile=[path name];
        cd(path);                                                     % Remember this directory
      end
    end

    % Read coords from file, if specified
    if ~isempty(chanFile)
      fid=fopen(chanFile);
      coords=fscanf(fid,'%d %d\n',[2 Inf])';
      fclose(fid);
    end

    % Create figure and store params
    figure('Tag','TopoFig');
    colormap(jet(256));
    d.bin=bin;
    d.latency=latency;
    d.gridSize=gridSize;
    d.margin=margin;
    d.chanFile=chanFile;
    d.coords=coords;

    % Add uVolts checkbox
    uicontrol('Style','CheckBox','Tag','uVolts','String','uVolts','Value',0,...
      'Units','Normalized','Position',[0.01 0.17 0.09 0.04],...
      'FontName','Arial','FontSize',8,...
      'CallBack','EEGTopo(''uVolts'');');

    % Add Names checkbox
    uicontrol('Style','CheckBox','Tag','Names','String','Names','Value',1,...
      'Units','Normalized','Position',[0.01 0.12 0.09 0.04],...
      'FontName','Arial','FontSize',8,...
      'CallBack','EEGTopo(''Names'');');

    % Add Spline checkbox
%    uicontrol('Style','CheckBox','Tag','Spline','String','Spline','Value',0,...
%      'Units','Normalized','Position',[0.01 0.07 0.09 0.04],...
%      'FontName','Arial','FontSize',8,...
%      'CallBack','EEGTopo(''Spline'');');

    % Add Laplacian checkbox
    uicontrol('Style','CheckBox','Tag','Laplacian','String','Laplacian','Value',0,...
      'Units','Normalized','Position',[0.01 0.02 0.1 0.04],...
      'FontName','Arial Narrow','FontSize',9,...
      'CallBack','EEGTopo(''Laplacian'');');
    
    % Add Bin popup menu
    uicontrol('Style','Text','String','Bin:',...
      'Units','Normalized','Position',[0.12 0.02 0.05 0.04],...
      'FontName','Arial','FontSize',8);
    uicontrol('Style','PopupMenu','Tag','Bin','String',eeg.binNames,'Value',d.bin,...
      'Units','Normalized','Position',[0.18 0.025 0.21 0.04],...
      'HorizontalAlignment','Right','FontName','Arial','FontSize',8,...
      'CallBack','EEGTopo(''Bin'');');

    % Add Latency text box
    uicontrol('Style','Text','String','Latency:',...
      'Units','Normalized','Position',[0.41 0.02 0.09 0.04],...
      'FontName','Arial','FontSize',8);
    uicontrol('Style','Edit','Tag','Latency','String',num2str(d.latency),...
      'Units','Normalized','Position',[0.51 0.02 0.07 0.04],...
      'HorizontalAlignment','Right','FontName','Arial','FontSize',8,...
      'CallBack','EEGTopo(''Latency'');');
    uicontrol('Style','Text','String','ms',...
      'Units','Normalized','Position',[0.59 0.02 0.03 0.04],...
      'FontName','Arial','FontSize',8);

    % Add Latency buttons
    uicontrol('Style','Push','Tag','< Button','String','<',...
      'Units','Normalized','Position',[0.51 0.065 0.03 0.035],...
      'FontName','Arial Narrow','FontSize',12,...
      'CallBack','EEGTopo(''<'');');
    uicontrol('Style','Push','Tag','> Button','String','>',...
      'Units','Normalized','Position',[0.55 0.065 0.03 0.035],...
      'FontName','Arial Narrow','FontSize',12,...
      'CallBack','EEGTopo(''>'');');

    % Add Grid text box
    uicontrol('Style','Text','String','Grid:',...
      'Units','Normalized','Position',[0.64 0.02 0.06 0.04],...
      'FontName','Arial','FontSize',8);
    uicontrol('Style','Edit','Tag','GridSize','String',num2str(d.gridSize),...
      'Units','Normalized','Position',[0.71 0.02 0.06 0.04],...
      'HorizontalAlignment','Right','FontName','Arial','FontSize',8,...
      'CallBack','EEGTopo(''GridSize'');');

    % Add Auto checkbox
    uicontrol('Style','CheckBox','Tag','Auto','String','Auto','Value',1,...
      'Units','Normalized','Position',[0.79 0.02 0.07 0.04],...
      'FontName','Arial','FontSize',8,...
      'CallBack','EEGTopo(''CRange'');');

    % Add Min text box
    uicontrol('Style','Text','String','Min:',...
      'Units','Normalized','Position',[0.87 0.005 0.05 0.04],...
      'FontName','Arial','FontSize',8);
    uicontrol('Style','Edit','Tag','CMin','String','',...
      'Units','Normalized','Position',[0.93 0.005 0.06 0.04],...
      'HorizontalAlignment','Right','FontName','Arial Narrow','FontSize',8,...
      'CallBack','EEGTopo(''CRange'');');

    % Add Max text box
    uicontrol('Style','Text','String','Max:',...
      'Units','Normalized','Position',[0.87 0.05 0.05 0.04],...
      'FontName','Arial','FontSize',8);
    uicontrol('Style','Edit','Tag','CMax','String','',...
      'Units','Normalized','Position',[0.93 0.05 0.06 0.04],...
      'HorizontalAlignment','Right','FontName','Arial Narrow','FontSize',8,...
      'CallBack','EEGTopo(''CRange'');');
end

set(gcf,'Pointer','watch'); drawnow;

% Find EEG info
eeg=getfield(get(d.EEGFig,'UserData'),'eeg');
plots=getfield(get(d.EEGFig,'UserData'),'plots');
channels=get(plots,'UserData');
if length(channels)>1
  channels=cat(1,channels{:});    % Turn cell array into numeric array
end

% Make sure bin is valid
if d.bin<1 | d.bin>eeg.nBins, d.bin=1; end
set(findobj(gcf,'Tag','Bin'),'Value',d.bin);

% Make sure latency is valid
latMin=-eeg.onset;
latMax=(eeg.nPoints-1)*eeg.sampling-eeg.onset;
if d.latency<latMin, d.latency=latMin; end
if d.latency>latMax, d.latency=latMax; end
if rem(d.latency+eeg.onset,eeg.sampling)
  % Make sure it's a multiple of eeg.sampling from eeg.onset
  d.latency=ceil((d.latency+eeg.onset)/eeg.sampling)*eeg.sampling-eeg.onset;
end;
set(findobj(gcf,'Tag','Latency'),'String',num2str(d.latency));

% Make sure gridSize is valid
if isempty(d.gridSize), d.gridSize=200; end
if d.gridSize<50, d.gridSize=50; end
if d.gridSize>1000, d.gridSize=1000; end
set(findobj(gcf,'Tag','GridSize'),'String',num2str(d.gridSize));

% Make sure margin is valid
d.margin=d.gridSize/10;

% Save params
set(gcf,'UserData',d);

% Extract data points
v=squeeze(eeg.data(d.bin,:,(eeg.onset+d.latency)/eeg.sampling+1)/eeg.uvunits)';
if length(v)~=length(d.coords)
  error('Number of channels in channel file does not match current data.');
end

% Remove channels that are not on screen or have [-1 -1] as coords
ci=setdiff(1:eeg.nChannels,channels);             % Not on screen
d.coords(ci,:)=repmat([-1 -1],length(ci),1);
ci=find(d.coords(:,1)==-1 & d.coords(:,2)==-1);   % [-1 -1] means ignore
chanNames=eeg.chanNames;
chanNames(ci)=[];
d.coords(ci,:)=[];
v(ci)=[];

% Scale data (maintaining aspect ratio) and make grid for pcolor
x=d.coords(:,1);
y=d.coords(:,2);
xRange=max(x)-min(x)+1;
yRange=max(y)-min(y)+1;
gRange=d.gridSize-2*d.margin;
if xRange>yRange
  x=normaliz(x,[d.margin+1 d.gridSize-d.margin]);
  nMargin=(d.gridSize-gRange*yRange/xRange)/2;
  y=normaliz(y,[nMargin+1 d.gridSize-nMargin]);
else
  y=normaliz(y,[d.margin+1 d.gridSize-d.margin]);
  nMargin=(d.gridSize-gRange*xRange/yRange)/2;
  x=normaliz(x,[nMargin+1 d.gridSize-nMargin]);
end
x=round(x);
y=round(y);

% Interpolate data
xi=1:d.gridSize;                        % New grid for interpolation
yi=1:d.gridSize;
if ~get(findobj(gcf,'Tag','Laplacian'),'Value')
%  if ~get(findobj(gcf,'Tag','Spline'),'Value')
    vi=griddata(x,y,v,xi,yi');          % Use linear triangulation
%  else
%    k=4;                                % Use a cubic (order=4) spline
%    xKnots=augknt([1 (1:d.gridSize-1)+0.5 d.gridSize],k);
%    yKnots=xKnots
%    spline=tspapi(xKnots,yKnots,x,y,v);
%    vi=fnval(spline,xi,yi);
%  end
else                                    % Calculate Laplacian
  vi=griddata(x,y,v,xi,yi','invdist');  % Use inverse distance

  % Compute convex hull
  ki=convhull(x,y);

  % Remove points outside convex hull
  [xx,yy]=meshgrid(xi);
  ki=inpolygon(xx,yy,x(ki),y(ki));
  if ~isempty(ki)
    ki=find(ki==0);
    vi(ki)=nan*ones(length(ki),1);
  end

  % Calculate Laplacian
  vi=4*del2(vi);
end

% Setup chanVolts
chanVolts=cellstr(num2str(v,'%.2f'));

% Clear any old plots
delete(findobj(gcf,'Type','axes'));

% Plot data
axes('Position',[0.12 0.11 0.775 0.815],'Color',[.5 .5 .5],'Box','On',...
     'XTick',[],'YTick',[],'YDir','Reverse');
title(sprintf('%s at %d ms',eeg.binNames{d.bin},d.latency));
hold on
pcolor((1:d.gridSize)-0.5,(1:d.gridSize)-0.5,vi);   % Center cells on points
shading flat
plot(x,y,'ok','MarkerSize',5,'Tag','Electrodes');
text(x,y+(d.gridSize/40),chanNames,'FontName','Arial Narrow','FontSize',8,'Color','k',...
  'HorizontalAlignment','Center','Tag','ElectrodeNames','Visible','off');
if get(findobj(gcf,'Tag','Names'),'Value')
  set(findobj(gcf,'Tag','ElectrodeNames'),'Visible','on');
end
text(x,y-(d.gridSize/40),chanVolts,'FontName','Arial Narrow','FontSize',8,'Color','k',...
  'HorizontalAlignment','Center','Tag','ElectrodeVolts','Visible','off');
if get(findobj(gcf,'Tag','uVolts'),'Value')
  set(findobj(gcf,'Tag','ElectrodeVolts'),'Visible','on');
end
hold off
EEGTopo('CRange');         % Set CAxis range and add colorbar

set(gcf,'Pointer','arrow');
figure(gcf);

% Modification History:
%
% $Log: EEGTopo.m,v $
% Revision 1.3  2005/02/03 16:58:19  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:34  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/10/08 23:46:45  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Francis Favorini, 11/22/96.
% Francis Favorini, 01/29/97.  MATLAB 5 compliance.
% Francis Favorini, 02/05/97.  Can get bin and latency from crosshairs in EEG window,
%                              if not specified.  Also prompts for chanFile if needed.
% Francis Favorini, 02/06/97.  Only show channels that are on screen.
%                              Added names checkbox and latency edit box.
% Francis Favorini, 02/12/97.  Complains if can't find EEG window.
% Francis Favorini, 02/14/97.  Added GUI adjustment of params to Topo figure.
% Francis Favorini, 02/17/97.  Added Laplacian and uVolts options.
%                              Fixed aspect ratio bug in coord scaling.
% Francis Favorini, 02/19/97.  Now handles no bins on screen (plots bin 1).
% Francis Favorini, 02/20/97.  Handles electrode coords in header file.
% Francis Favorini, 02/21/97.  Changed Laplacian to use inverse distance interpolation.
%                              (Triangulation caused artifacts.)
% Francis Favorini, 04/02/97.  Added hooks for spline interpolation of data.
%                              Changed default colormap to jet(256).
% Francis Favorini, 07/03/97.  Changed to use eeg structure.
% Francis Favorini, 07/07/97.  Added latency buttons.
% Francis Favorini, 07/08/97.  cd handles UNC names now.
