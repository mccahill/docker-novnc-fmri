function answer=guigets(question,ansLen)
%GUIGETS Display question and get answer from user.
%
%       answer=guigets(question);
%       answer=guigets(question,ansLen);
%
%       question is a string containing a prompt for the user.
%       ansLen is the number of characters to allow for in the answer.

% CVS ID and authorship of this code
% CVSId = '$Id: guigets.m,v 1.5 2005/02/03 20:17:45 michelich Exp $';
% CVSRevision = '$Revision: 1.5 $';
% CVSDate = '$Date: 2005/02/03 20:17:45 $';
% CVSRCSFile = '$RCSfile: guigets.m,v $';

if ~ischar(question)
	set(gcf,'UserData',question);                   % User clicked button
else
  if nargin<2, ansLen=10; end
  chrWidth=6;
  chrHeight=15;
  qWidth=chrWidth*length(question);
  aWidth=chrWidth*ansLen;
  fWidth=max(qWidth+aWidth+5*chrWidth,18*chrWidth);
  fHeight=5*chrHeight;
  scr=get(0,'ScreenSize');
  scrWidth=scr(3);
  scrHeight=scr(4);

	figure('Position',[200 200 fWidth fHeight],'Color',[0.5 0.5 0.5],...
	       'MenuBar','None','Resize','off','NumberTitle','off');
	uicontrol('Style','Text','String',question,...
	          'Position',[2*chrWidth 3*chrHeight qWidth chrHeight],...
	          'ForegroundColor',[0 0 0],'BackgroundColor',[0.5 0.5 0.5]);
	ans_h=uicontrol('Style','Edit','Position',[qWidth+3*chrWidth 3*chrHeight aWidth chrHeight+5],...
	              'ForegroundColor',[0 0 0],'BackgroundColor',[0.75 0.75 0.75]);
  uicontrol('Style','Push','String','OK','CallBack','guigets(1)',...
            'Position',[(fWidth-15*chrWidth)/2 chrHeight 7*chrWidth chrHeight+2]);
  uicontrol('Style','Push','String','Cancel','CallBack','guigets(0)',...
            'Position',[(fWidth-15*chrWidth)/2+8*chrWidth chrHeight 7*chrWidth chrHeight+2]);

	while isempty(get(gcf,'UserData'))
		drawnow;
	end
  if get(gcf,'UserData')==1                       % OK
  	answer=get(ans_h,'String');
  else                                            % Cancel
    answer=0;
  end
	close(gcf);
end

% Modification History:
%
% $Log: guigets.m,v $
% Revision 1.5  2005/02/03 20:17:45  michelich
% M-Lint: Replace deprecated isstr with ischar.
%
% Revision 1.4  2005/02/03 17:21:31  michelich
% M-lint: Do not use ANS as a variable because ANS is frequently overwritten by MATLAB.
%
% Revision 1.3  2005/02/03 16:58:33  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:35  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/08/27 22:24:15  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2001/01/23. Changed function name to lowercase.
% Francis Favorini,  1998/06/08. Changed to use isempty.
% Francis Favorini,  1996/11/08.

