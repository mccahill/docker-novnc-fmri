function fusedData=roifuse(imgData,img,imgPos,ROIs)
%ROIFUSE Fuse ROI's with MR image.

% CVS ID and authorship of this code
% CVSId = '$Id: roifuse.m,v 1.3 2005/02/03 16:58:43 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:43 $';
% CVSRCSFile = '$RCSfile: roifuse.m,v $';

fusedData=imgData;
% Loop through ROIs from last to first (current)
for r=length(ROIs):-1:1
  if ~isemptyroi(ROIs(r))
    s=find(img==ROIs(r).slice);
    if ~isempty(s) 
      % Handle ROI's in zoomed mode
      [x,y]=ind2sub(ROIs(r).baseSize(1:2),ROIs(r).index{s});
      x=x-imgPos(1)+1;
      y=y-imgPos(2)+1;
      onScreen=find(x>=1 & x<=imgPos(3) & y>=1 & y<=imgPos(4));
      if ~isempty(onScreen)
        ind=sub2ind([size(imgData,1) size(imgData,2)],x(onScreen),y(onScreen));
        fusedData(ind)=ROIs(r).val;
        c=colormap;
        c(ROIs(r).val,:)=ROIs(r).color;
        colormap(c);
      end
    end
  end
end

% Modification History:
%
% $Log: roifuse.m,v $
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
%                                Changed isemptyroi() to lowercase.
% Francis Favorini,  2000/05/05. Modified to handle empty ROIs.
% Francis Favorini,  1998/10/29. Start from last ROI, so first is on top.
% Francis Favorini,  1998/10/14.
