function roi=roidef(srs,limits,imgWin)
%ROIDEF Define ROI for MR series in overlay2 window.
%
%   roi=roidef;
%   roi=roidef(srs,limits);
%   roi=roidef(srs,limits,imgWin)
%
%   srs is 0 for the base series, 1 for overlay 1, 2 for overlay 2 and
%     indicates which series the limits apply to.
%   limits is [min max] of raw pixel values to include in ROI.
%     [] means no limits.
%   imgWin is the handle of the overlay window (default = gcf)
%
%   See also ISROI, ROIGROW, ROICOORDS, ROISTATS.

% CVS ID and authorship of this code
% CVSId = '$Id: roidef.m,v 1.7 2005/02/03 16:58:43 michelich Exp $';
% CVSRevision = '$Revision: 1.7 $';
% CVSDate = '$Date: 2005/02/03 16:58:43 $';
% CVSRCSFile = '$RCSfile: roidef.m,v $';

% IMPORTANT NOTE: This function should ensure the following:
% 1) Each vector of indices in roi.index is sorted (ascending).
% 2) Each vector of indices is a column vector.
% 3) roi.slice is a row vector.
% 4) The order and orientation of roi.index corresponds to roi.slice.
% However, roi.slice is not sorted (currently).
% Same applies to roigrow.

% Process arguments
if nargin==0
  limits=[];
elseif nargin==2 | nargin==3
  if ~isempty(srs) & (~isnumeric(srs) | srs<0 | srs>2)
    error('srs must be 0, 1 or 2!');
  end
  if ~isempty(limits) & (~isnumeric(limits) | length(limits)~=2 | limits(1)>=limits(2))
    error('limits must be [min max]!');
  end
else
  error('Incorrect number of arguments!');
end
if nargin < 3
    imgWin = gcf;  % Set overlay window to current figure by default
end
if ~ishandle(imgWin) % Check handle
    error('imgWin is not a valid handle!');
end

roi=[];
mask=[];
img=findobj(imgWin,'Tag','TheImage');
if ~isempty(img)
  % ROIPoly will operate on the current axes, so we must set it here.
  axes(get(img,'Parent'));
  slice=get(findobj(imgWin,'Tag','ImageSlider'),'Value');
  mask=roipoly;
  if any(mask(:))
    % Get parameters
    params=get(imgWin,'UserData');
    imgPos=params{25};
    mask=mask';                   % Image data is rotated for display
    if ~isempty(limits)
      % Apply limits to pixel mask, correcting for zoomed mode
      sliceData=params{srs+1};
      if ~isempty(sliceData)
        sliceData=squeeze(sliceData(:,:,slice));
        xWin=imgPos(1):imgPos(1)+imgPos(3)-1;
        yWin=imgPos(2):imgPos(2)+imgPos(4)-1;
        sliceData=sliceData(xWin,yWin,:);
        mask=mask & sliceData>=limits(1) & sliceData<=limits(2);
      end
    end
    if any(mask(:))
      % Save ROI params, correcting for zoomed mode
      base=params{1};
      [x,y]=ind2sub(size(mask),find(mask));
      x=x+imgPos(1)-1;
      y=y+imgPos(2)-1;
      % Use separate size() calls for each dimension to always list a 3D base size
      roi.baseSize=[size(base,1),size(base,2),size(base,3)];
      roi.index={sub2ind(roi.baseSize(1:2),x,y)};
      roi.slice=slice;
    end
  end
end

% Modification History:
%
% $Log: roidef.m,v $
% Revision 1.7  2005/02/03 16:58:43  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.6  2004/10/26 21:52:45  michelich
% Correct case of roipoly function call.
%
% Revision 1.5  2003/10/22 15:54:39  gadde
% Make some CVS info accessible through variables
%
% Revision 1.4  2002/12/03 20:53:00  michelich
% Add third size (1) to baseSize when defining on a single slice.
%
% Revision 1.3  2002/10/25 14:29:09  michelich
% Updated help comments
%
% Revision 1.2  2002/10/25 14:14:27  michelich
% Merged changes for advanced ROI dialog box made by Jimmy Dias 2002/10/30.
% - Added option to pass overlay2 handle (for advanced ROI drawing dialog box).
%
% Revision 1.1  2002/08/27 22:24:24  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2001/01/25. Changed function name to lowercase.  Updated comments.
%                                Changed isroi(), overlay2() to lowercase.
%                                Changed see also to uppercase.
% Francis Favorini,  2000/04/10. No need to reset KeypressFcn now that uirestore bug has been fixed.
% Francis Favorini,  1998/09/28. Correct for zoomed mode with limits.
% Francis Favorini,  1998/09/22. Store 3D size in baseSize.
% Francis Favorini,  1998/09/21. Correct for zoomed mode.
% Francis Favorini,  1998/09/01. Integrated with overlay2.
% Francis Favorini,  1998/08/25. Tweaked to work with roigrow.
% Francis Favorini,  1998/08/24. Added limits.
% Francis Favorini,  1998/08/18.
