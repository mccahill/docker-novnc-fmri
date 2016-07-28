function guistrf(question,default,ansLen,func,args)
%GUISTRF Display question, get answer from user, and pass to function.
%
%       guistrf(question,default,ansLen,func);
%       guistrf(question,default,ansLen,func,args);
%
%       question is a string containing a prompt for the user.
%       default is the default answer.
%       ansLen is the number of characters to allow for in the answer.
%       func is the name of a function which takes a string and optional other args.
%       args are optional args.

% CVS ID and authorship of this code
% CVSId = '$Id: guistrf.m,v 1.4 2005/02/03 20:17:45 michelich Exp $';
% CVSRevision = '$Revision: 1.4 $';
% CVSDate = '$Date: 2005/02/03 20:17:45 $';
% CVSRCSFile = '$RCSfile: guistrf.m,v $';

if ~ischar(question)
  if question==1                        % OK button
  	str=get(findobj(gcf,'Style','edit'),'String');
  	close(gcf);
    if isempty(args)
      eval([func '(''' str ''');']);
    else
      eval([func '(''' str ''',' args ');']);
    end
  else                                  % Cancel button
  	close(gcf);
  end
else
  % Defaults
  if nargin<5, args=[]; end
  chrWidth=7;
  chrHeight=20;
  qWidth=chrWidth*length(question);
  aWidth=chrWidth*ansLen;
  fWidth=max(qWidth+aWidth+5*chrWidth,16*chrWidth);
  fHeight=5*chrHeight;
  scr=get(0,'ScreenSize');
  scrWidth=scr(3);
  scrHeight=scr(4);

	figure('Position',[(scrWidth-fWidth)/2 (scrHeight-fHeight)/2 fWidth fHeight],...
	       'Color',[0.5 0.5 0.5],'MenuBar','None','Resize','off','NumberTitle','off');
	uicontrol('Style','Text','String',question,...
	          'Position',[2*chrWidth 3*chrHeight qWidth chrHeight],...
	          'ForegroundColor',[0 0 0],'BackgroundColor',[0.5 0.5 0.5]);
	uicontrol('Style','Edit','Position',[qWidth+3*chrWidth 3*chrHeight aWidth chrHeight],...
            'HorizontalAlignment','Left','FontName','Arial','FontSize',8,...
	          'String',default,'ForegroundColor',[0 0 0],'BackgroundColor',[0.75 0.75 0.75]);
  uicontrol('Style','Push','String','OK','CallBack',['guistrf(1,1,1,''' func ''',''' args ''');'],...
            'FontName','Arial','FontSize',8,...
            'Position',[(fWidth-14*chrWidth)/2 chrHeight 6*chrWidth chrHeight]);
  uicontrol('Style','Push','String','Cancel','CallBack','guistrf(0);',...
            'FontName','Arial','FontSize',8,...
            'Position',[(fWidth-14*chrWidth)/2+8*chrWidth chrHeight 6*chrWidth chrHeight]);
end

% Modification History:
%
% $Log: guistrf.m,v $
% Revision 1.4  2005/02/03 20:17:45  michelich
% M-Lint: Replace deprecated isstr with ischar.
%
% Revision 1.3  2005/02/03 16:58:34  michelich
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
% Charles Michelich, 2001/01/23. Changed filename to lowercase
% Francis Favorini,  1997/07/03. Changed font/fontsize.
% Francis Favorini,  1996/11/08.
