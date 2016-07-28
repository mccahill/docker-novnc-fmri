function roiselect(v)
%ROISELECT Select ROI for MR series in overlay2 window.

% With no args, user clicked on an ROI, so make it current.
% Attached to ButtonDownFcn of fused image.
% With one arg, select the ROI with value v.

% CVS ID and authorship of this code
% CVSId = '$Id: roiselect.m,v 1.3 2005/02/03 16:58:43 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:43 $';
% CVSRCSFile = '$RCSfile: roiselect.m,v $';

% Get parameters
imgWin=gcf;
params=get(imgWin,'UserData');
[imgPos ROIs]=deal(params{[25 27]});

roi=[];
if nargin==1
  for r=1:length(ROIs)
    if ROIs(r).val==v
      roi=ROIs(r);
      break;
    end
  end
else
  % Get the point clicked
  x=round(index(get(gca,'CurrentPoint'),1));
  y=round(index(get(gca,'CurrentPoint'),3));
  
  % Correct for zoomed mode
  x=x+imgPos(1)-1;
  y=y+imgPos(2)-1;
  
  % Get current img number
  img=get(findobj(imgWin,'Tag','ImageSlider'),'Value');
  
  % Check ROI's
  for r=1:length(ROIs)
    if ~isemptyroi(ROIs(r))
      s=find(img==ROIs(r).slice);
      if ~isempty(s) 
        if any(sub2ind(ROIs(r).baseSize(1:2),x,y)==ROIs(r).index{s})
          roi=ROIs(r);
          break;
        end
      end
    end
  end
end

if ~isempty(roi)
  % Move new current ROI to head of list
  ROIs(r)=[];
  ROIs=[roi ROIs];
  params{27}=ROIs;
  set(imgWin,'UserData',params);
  
  % Update current ROI
  roicurrent(imgWin,ROIs);
  
  % Update display
  overlay2('GUISlider');
end

% Modification History:
%
% $Log: roiselect.m,v $
% Revision 1.3  2005/02/03 16:58:43  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:39  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/08/27 22:24:25  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2001/01/23. Changed function name to lowercase.  
%                                Changed isemptyroi() and roicurrent() to lowercase.
%                                Changed overlay2() to lowercase in comments
% Francis Favorini,  2000/05/05. Modified to handle empty ROIs.
% Francis Favorini,  1998/10/30. Pass all ROIs to roicurrent.
% Francis Favorini,  1998/10/14. Update display in case we select an ROI behind another.
% Francis Favorini,  1998/10/14. Added arg v to specify ROI without clicking on it.
% Francis Favorini,  1998/09/30. Added roicurrent.
% Francis Favorini,  1998/09/22. baseSize is now 3D.
% Francis Favorini,  1998/09/21. Correct for zoomed mode.
% Francis Favorini,  1998/08/31.
