function roicolor(roi)
%ROICOLOR Change ROI color.

% CVS ID and authorship of this code
% CVSId = '$Id: roicolor.m,v 1.3 2005/02/03 16:58:43 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:43 $';
% CVSRCSFile = '$RCSfile: roicolor.m,v $';

if nargin<1       % If no args, change current ROI
  % Get parameters
  imgWin=gcf;
  params=get(imgWin,'UserData');
  [ROIs]=params{27};
  if isempty(ROIs)
    roi=[];
  else
    roi=ROIs(1);  % First ROI is current ROI
  end
end
if isempty(roi)
  return;
else
  c=uisetcolor(roi.color);
  if length(c)==3
    roi.color=c;
    if nargin<1
      % Save parameters
      ROIs(1)=roi;
      params{27}=ROIs;
      set(imgWin,'UserData',params);
      % Update display
      overlay2('GUISlider');
    end
  end
end

% Modification History:
%
% $Log: roicolor.m,v $
% Revision 1.3  2005/02/03 16:58:43  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:39  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/08/27 22:24:24  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2001/01/25. Changed function name to lowercase.
% Francis Favorini,  1998/10/14.

