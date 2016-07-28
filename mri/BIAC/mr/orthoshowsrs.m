function orthoshowsrs(srs,headerInfo,cmap)
% ORTHOSHOWSRS - Load all three orientations of a tsv into 3 showsrs windows
%
%   orthoshowsrs(srs,headerInfo,cmap)
%   
%   tsv is the image volume(s) (must be have 3 or more dimensions)
%   headerInfo is a cell array containing {slicePlane, voxelSize} where
%     slicePlane is the slice plane of the input series ('axial','coronal','sagittal').
%       Only the first letter is checked, and case is insignificant.
%     voxelSize is a three element vector of the voxel size in the current orientation.
%       All three elements must be the same units.
%   cmap is a colormap to use (default is gray, empty cmap uses default)
%
%   Notes:
%   The images may not be in the desired orientation depending on the slice order 
%   (i.e. S to I vs I to S).  Use flipdim() to correct the orientation as desired.
%   See 2nd example.
%
%   The first three dimensions of tsv must have lengths > 0 (i.e. no single slice data)
%
%   Examples:
%   >> orthoshowsrs(readmr,{'a',[0.9375,0.9375,5.0]});             % Axial scans collected S to I
%   >> orthoshowsrs(flipdim(readmr,3),{'a',[0.9375,0.9375,5.0]});  % Axial scans collected I to S
%   >> orthoshowsrs(readmr,{'cor',[3.75,3.75,5.0]});

% CVS ID and authorship of this code
% CVSId = '$Id: orthoshowsrs.m,v 1.5 2005/02/03 19:16:27 michelich Exp $';
% CVSRevision = '$Revision: 1.5 $';
% CVSDate = '$Date: 2005/02/03 19:16:27 $';
% CVSRCSFile = '$RCSfile: orthoshowsrs.m,v $';

%TODO: Handle auto placement of windows more intelligently

% Check inputs
error(nargchk(2,3,nargin))
if ~any(ndims(srs) == [3 4])
  error('Input tsv must have 3 or 4 dimensions!');
end
if any([size(srs,1) size(srs,2) size(srs,3)] == 1)
  error('Size of first three dimensions of input tsv must be > 0 (No single slice data)!');
end
% Extract any necessary header information (handle different formats)
if iscell(headerInfo)
  % Header info passed as a cell array
  if ~(isequal(size(headerInfo) == [1 2]) | isequal(size(headerInfo) == [2 1]))
    error('headerInfo must be a cell array with two elements!')
  end
  % Extract relevant parameters
  slicePlane = headerInfo{1};
  voxelSize = headerInfo{2};
  
  if ~((size(voxelSize) == [1 3]) | (size(voxelSize) == [3 1]))
    error('voxelSize must be a 3 element vector!');
  end
else
  % Header info not passed using a supported format
  error('headerInfo must be a cell array with two elements!');
end
if nargin == 2 | isempty(cmap)
  cmap = gray(256);
end

% Reorient the images
[srs_ax,srs_cor,srs_sag]=orthosrs(srs,slicePlane);

% Bring up a showsrs for each
h_ax=showsrs(srs_ax,cmap);
h_cor=showsrs(srs_cor,cmap);
h_sag=showsrs(srs_sag,cmap);

% Set title to orientation and turn off title numbering so 
% that title appears on task bar (in Windows)
% Number all views with the figure number of the axial showsrs
set(h_ax,'Name',sprintf('%d - Axial (Figure No. %d)',h_ax,h_ax),'NumberTitle','Off');
set(h_cor,'Name',sprintf('%d - Coronal (Figure No. %d)',h_ax,h_cor),'NumberTitle','Off');
set(h_sag,'Name',sprintf('%d - Sagittal (Figure No. %d)',h_ax,h_sag),'NumberTitle','Off');

% Set the proper DataAspectRatio based on the voxel size
if upper(slicePlane(1))=='A'
  voxSzAx = voxelSize;
  voxSzCor = [voxelSize(1),voxelSize(3),voxelSize(2)];
  voxSzSag = [voxelSize(2),voxelSize(3),voxelSize(1)];
elseif upper(slicePlane(1))=='C'
  voxSzAx =  [voxelSize(1),voxelSize(3),voxelSize(2)]; 
  voxSzCor = voxelSize; 
  voxSzSag = [voxelSize(3),voxelSize(2),voxelSize(1)];
elseif upper(slicePlane(1))=='S'
  voxSzAx =  [voxelSize(3),voxelSize(1),voxelSize(2)];
  voxSzCor = [voxelSize(3),voxelSize(2),voxelSize(1)];
  voxSzSag = voxelSize;
else
  error('Unknown slice plane!');
end
set(findobj(h_ax,'Tag','imgAx'),'DataAspectRatio',voxSzAx([2 1 3]));
set(findobj(h_cor,'Tag','imgAx'),'DataAspectRatio',voxSzCor([2 1 3]));
set(findobj(h_sag,'Tag','imgAx'),'DataAspectRatio',voxSzSag([2 1 3]));

% --- Put figures in standard positions ---
% "Constants" (by platform) for window sizes (Only tested on Windows currently)
topBorder = 41;    % Window top border (pixels)
leftBorder = 4;    % Window left border (pixels)
rightBorder = 11;  % Window right border (pixels)
bottomBorder = 5;  % Window bottom border (pixels)
taskBar = 30;      % Height of Windows Taskbar (pixels)

% Get screen size
oldRootUnits=get(0,'Units');
set(0,'Units','pixels');
screenSize=get(0,'ScreenSize');
set(0,'Units',oldRootUnits);

% Calculate largest figures that will fit on the screen
if screenSize(3) < screenSize(4)
  figSize = (screenSize(3)/2)-leftBorder-rightBorder;
else
  figSize = (screenSize(4)-taskBar)/2-topBorder-bottomBorder;
end

% Coronal in upper left corner
oldUnits=get(h_cor,'Units');
set(h_cor,'Units','Pixels');
set(h_cor,'Position',[leftBorder+1 screenSize(4)-figSize-topBorder figSize figSize]);
set(h_cor,'Units',oldUnits);
showsrs('Resize',h_cor);  % Call resize function to update window

% Axial in lower left corner
oldUnits=get(h_ax,'Units');
set(h_ax,'Units','Pixels');
set(h_ax,'Position',[leftBorder+1 screenSize(4)-(figSize+topBorder)*2-bottomBorder figSize figSize]);
set(h_ax,'Units',oldUnits);
showsrs('Resize',h_ax);  % Call resize function to update window

% Sagittal in upper right corner
oldUnits=get(h_sag,'Units');
set(h_sag,'Units','Pixels');
set(h_sag,'Position',[rightBorder+leftBorder*2+figSize+1 screenSize(4)-figSize-topBorder figSize figSize]);
set(h_sag,'Units',oldUnits);
showsrs('Resize',h_sag);  % Call resize function to update window

% Link the window and level GUI together for all three series
showsrs('LinkWinlev',[h_ax, h_cor, h_sag]);

% Modification History:
%
% $Log: orthoshowsrs.m,v $
% Revision 1.5  2005/02/03 19:16:27  michelich
% Changed argument checking to be more clear and robust.
%
% Revision 1.4  2005/02/03 16:58:40  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.3  2003/10/22 15:54:37  gadde
% Make some CVS info accessible through variables
%
% Revision 1.2  2003/10/15 15:51:49  michelich
% Updated help to use new readmr.
%
% Revision 1.1  2002/08/27 22:24:22  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2002/01/14. Fixed bug in Sagittal to Axial voxel size conversion.
% Charles Michelich, 2001/09/21. Added size to default gray colormap.  (to avoid gray opening a figure to get size of colormap)
% Charles Michelich, 2001/09/19. Encapsulated voxelSize and slicePlane in a cell array for future 
%                                  support of passing header information.
%                                Added support for passing a colormap.
% Charles Michelich, 2001/09/19. Added check to disallow singular dimension in first 3D
%                                  since showsrs requires x & y sizes to be > 1
%                                Added figure number to title of each showsrs window.
% Charles Michelich, 2001/09/14. Need to transpose voxel size 1st & 2nd items since
%                                images are transposed at display.
%                                Added axial figure number to title of all showsrs windows
%                                Added comments to help with reorienting
%                                Linked window and level of all three series together
% Charles Michelich, 2001/09/13. original
