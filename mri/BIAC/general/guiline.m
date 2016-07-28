function guiline(line,func,arg)
%GUILINE Display line, allow user to change attributes, and pass to function.
%
%       guiline(line,func);
%       guiline(line,func,arg);
%
%       line is a handle to a line.
%       func is the name of a function which takes a handle to a line
%         and an optional arg.
%       arg is the optional arg.  (Gets converted by mat2str.)

% CVS ID and authorship of this code
% CVSId = '$Id: guiline.m,v 1.4 2005/02/03 20:17:45 michelich Exp $';
% CVSRevision = '$Revision: 1.4 $';
% CVSDate = '$Date: 2005/02/03 20:17:45 $';
% CVSRCSFile = '$RCSfile: guiline.m,v $';

% Defaults
if nargin<3, arg=[]; end

if ischar(line)
	sample=findobj(gcf,'Tag','Sample');
  if strcmp(line,'OK')                  % OK button
	  line=get(gcf,'UserData');
    set(line,'Color',get(sample,'Color'));
    set(line,'LineStyle',get(sample,'LineStyle'));
    set(line,'LineWidth',get(sample,'LineWidth'));
    set(line,'Marker',get(sample,'Marker'));
    set(line,'MarkerSize',get(sample,'MarkerSize'));
  	close(gcf);
    if isempty(arg)
      feval(func,line);
    else
      feval(func,line,arg);
    end
  elseif strcmp(line,'Revert')
	  old=findobj(gcf,'Tag','Old');
    color=get(old,'Color');
    set(sample,'Color',color);
    set(sample,'LineStyle',get(old,'LineStyle'));
    set(sample,'LineWidth',get(old,'LineWidth'));
    set(sample,'Marker',get(old,'Marker'));
    set(sample,'MarkerSize',get(old,'MarkerSize'));
    set(findobj(gcf,'Tag','R'),'String',num2str(color(1)));
    set(findobj(gcf,'Tag','G'),'String',num2str(color(2)));
    set(findobj(gcf,'Tag','B'),'String',num2str(color(3)));
    set(findobj(gcf,'Tag','LineStyle'),'Color','yellow');
    set(findobj(gcf,'Tag','LineWidth'),'Color','yellow');
    set(findobj(gcf,'Tag','Marker'),'Color','yellow');
    set(findobj(gcf,'Tag','MarkerSize'),'Color','yellow');
    set(findobj(gcf,'Tag','LineStyle','LineStyle',get(sample,'LineStyle')),'Color','red');
    set(findobj(gcf,'Tag','LineWidth','LineWidth',get(sample,'LineWidth')'),'Color','red');
    set(findobj(gcf,'Tag','Marker','Marker',get(sample,'Marker')),'Color','red');
    set(findobj(gcf,'Tag','MarkerSize','MarkerSize',get(sample,'MarkerSize')),'Color','red');
  	arefresh(findobj(gcf,'Tag','SampleAx'));
  elseif strcmp(line,'Color')
    if strcmp(get(gco,'Type'),'image')
    	click=get(findobj(gcf,'Tag','ColorAx'),'CurrentPoint');
    	map=colormap;
      color=max(1,min(length(map),round(click(1,1))));    % Restrict to legit range
    	color=map(color,:);
    elseif strcmp(get(gco,'Type'),'patch')
      color=get(gco,'FaceColor');
    else
      color=[max(0,min(1,str2num(get(findobj(gcf,'Tag','R'),'String')))),...
             max(0,min(1,str2num(get(findobj(gcf,'Tag','G'),'String')))),...
             max(0,min(1,str2num(get(findobj(gcf,'Tag','B'),'String'))))];
      figure(gcf);
    end
    set(findobj(gcf,'Tag','R'),'String',num2str(color(1)));
    set(findobj(gcf,'Tag','G'),'String',num2str(color(2)));
    set(findobj(gcf,'Tag','B'),'String',num2str(color(3)));
  	set(sample,'Color',color);
  	arefresh(findobj(gcf,'Tag','SampleAx'));
  elseif strcmp(line,'LineStyle')
    set(findobj(get(gco,'Parent'),'Tag','LineStyle'),'Color','yellow');
    if strcmp(get(gco,'Type'),'line')
      set(gco,'Color','red');
      set(sample,'LineStyle',get(gco,'LineStyle'));
    else
      set(findobj(get(gco,'Parent'),'Tag','LineStyle','Type','text'),'Color','red');
      set(sample,'LineStyle','None');
    end
		arefresh(findobj(gcf,'Tag','SampleAx'));
  elseif strcmp(line,'LineWidth')
    set(findobj(get(gco,'Parent'),'Tag','LineWidth'),'Color','yellow');
    set(gco,'Color','red');
 		set(sample,'LineWidth',get(gco,'LineWidth'));
		arefresh(findobj(gcf,'Tag','SampleAx'));
  elseif strcmp(line,'Marker')
    set(findobj(get(gco,'Parent'),'Tag','Marker'),'Color','yellow');
    if strcmp(get(gco,'Type'),'line')
      set(gco,'Color','red');
      set(sample,'Marker',get(gco,'Marker'));
    else
      set(findobj(get(gco,'Parent'),'Tag','Marker','Type','text'),'Color','red');
      set(sample,'Marker','None');
    end
		arefresh(findobj(gcf,'Tag','SampleAx'));
  elseif strcmp(line,'MarkerSize')
    set(findobj(get(gco,'Parent'),'Tag','MarkerSize'),'Color','yellow');
    set(gco,'Color','red');
 		set(sample,'MarkerSize',get(gco,'MarkerSize'));
		arefresh(findobj(gcf,'Tag','SampleAx'));
  else                                  % Cancel button
  	close(gcf);
  end
else
	% Defaults
  scr=get(0,'ScreenSize');
  scrWidth=scr(3);
  scrHeight=scr(4);
  fWidth=scrWidth*0.8;
  fHeight=scrHeight*0.8;

  % Create figure window and sample line
	figure('Position',[(scrWidth-fWidth)/2 (scrHeight-fHeight)/2 fWidth fHeight],...
	       'Color',[0.5 0.5 0.5],'MenuBar','None','Resize','off','NumberTitle','off',...
	       'Name','Change Line Properties','UserData',line);
  axes('Position',[0.1 0.8 0.8 0.15],'Box','On','Tag','SampleAx');
  hold on;
  text(3,2,'Old');
	old=plot([6:45],2*ones(1,40),'Color',get(line,'Color'),'Tag','Old',...
	         'LineStyle',get(line,'LineStyle'),'LineWidth',get(line,'LineWidth'),...
    	     'Marker',get(line,'Marker'),'MarkerSize',get(line,'MarkerSize'));
  text(3,1,'New');
	sample=plot([6:45],ones(1,40),'Color',get(line,'Color'),'Tag','Sample',...
	           'LineStyle',get(line,'LineStyle'),'LineWidth',get(line,'LineWidth'),...
       	     'Marker',get(line,'Marker'),'MarkerSize',get(line,'MarkerSize'));
  set(findobj(gca,'Type','text'),'FontName','Arial','FontSize',8');
  set(gca,'XLimMode','Manual','XLim',[1 48],'YLimMode','Manual','YLim',[0 3],...
          'XTick',[],'YTick',[],'Color','black');
	set(old,'ButtonDownFcn','guiline(''Revert'');');

	% Color controls
	axes('Position',[0.1 0.5 0.35 0.2],'Box','On','Tag','ColorAx');
  clen=length(colormap);
  image(1:clen);                     % y values from 0.5 to 1.5
  set(gca,'Tag','ColorAx');          % Bug: image clobbers Tag property 
  y1=1.5;
  y2=1.75;
  xi=clen/5;
  x=[0.5  0.5  xi+0.5 xi+0.5];
  y=[y1 y2 y2 y1];
  patch('XData',x,     'YData',y,      'FaceColor',[1   0    0]);  % red
  patch('XData',x+xi,  'YData',y,      'FaceColor',[0   1    0]);  % green
  patch('XData',x+2*xi,'YData',y,      'FaceColor',[1   0    1]);  % magenta
  patch('XData',x+3*xi,'YData',y,      'FaceColor',[0   1    1]);  % cyan
  patch('XData',x+4*xi,'YData',y,      'FaceColor',[1   0.5  0]);  % orange
  patch('XData',x,     'YData',y+y2-y1,'FaceColor',[0   0.25 1]);  % blue
  patch('XData',x+xi,  'YData',y+y2-y1,'FaceColor',[0.5 0    0]);  % dark red
  patch('XData',x+2*xi,'YData',y+y2-y1,'FaceColor',[0.5 0    1]);  % purple
  patch('XData',x+3*xi,'YData',y+y2-y1,'FaceColor',[0.5 0.5  0]);  % olive green
  patch('XData',x+4*xi,'YData',y+y2-y1,'FaceColor',[1   1    1]);  % white
  set(gca,'YLim',[0.5 2.0],'XTick',[],'YTick',[],'Color','black');
  title('Line Color','FontName','Arial','FontSize',9,'Color','black');
	set(get(gca,'Children'),'ButtonDownFcn','guiline(''Color'');');
  cmapmenu;

  % RGB edit controls
  color=get(findobj(gcf,'Tag','Sample'),'Color');
  uicontrol('Style','Text','String','R:',...
            'Units','Normalized','Position',[0.14 0.45 0.02 0.03],...
            'FontName','Arial Narrow','FontSize',8);
  uicontrol('Style','Edit','String',num2str(color(1)),'Tag','R','BackgroundColor','white',...
            'Units','Normalized','Position',[0.16 0.45 0.05 0.03],...
            'FontName','Arial Narrow','FontSize',8,...
            'CallBack','guiline(''Color'');');
  uicontrol('Style','Text','String','G:',...
            'Units','Normalized','Position',[0.24 0.45 0.02 0.03],...
            'FontName','Arial Narrow','FontSize',8);
  uicontrol('Style','Edit','String',num2str(color(2)),'Tag','G','BackgroundColor','white',...
            'Units','Normalized','Position',[0.26 0.45 0.05 0.03],...
            'FontName','Arial Narrow','FontSize',8,...
            'CallBack','guiline(''Color'');');
  uicontrol('Style','Text','String','B:',...
            'Units','Normalized','Position',[0.34 0.45 0.02 0.03],...
            'FontName','Arial Narrow','FontSize',8);
  uicontrol('Style','Edit','String',num2str(color(3)),'Tag','B','BackgroundColor','white',...
            'Units','Normalized','Position',[0.36 0.45 0.05 0.03],...
            'FontName','Arial Narrow','FontSize',8,...
            'CallBack','guiline(''Color'');');

	% LineStyle controls
	axes('Position',[0.1 0.1 0.35 0.25],'Box','On');
  hold on;
	plot([6:25],ones(1,20)*6,'Tag','LineStyle','LineStyle','-');
	plot([6:25],ones(1,20)*5,'Tag','LineStyle','LineStyle',':');
	plot([6:25],ones(1,20)*4,'Tag','LineStyle','LineStyle','-.');
	plot([6:25],ones(1,20)*3,'Tag','LineStyle','LineStyle','--');
  text(15,2,'None','Tag','LineStyle','FontName','Arial','FontSize',8,...
            'Color','y','HorizontalAlignment','Center');
  set(gca,'XLimMode','Manual','XLim',[1 30],'XTick',[],...
          'YLimMode','Manual','YLim',[1 7],'YTick',[],'Color','black');
  title('Line Style','FontName','Arial','FontSize',9,'Color','black');
  set(findobj(gca,'Tag','LineStyle','LineStyle',get(sample,'LineStyle')),'Color','red');
	set(findobj(gca,'Tag','LineStyle'),'ButtonDownFcn','guiline(''LineStyle'');');

	% Marker controls
	axes('Position',[0.55 0.1 0.35 0.25],'Box','On');
  hold on;
	plot([6:25],ones(1,20)*15,'Tag','Marker','Marker','.');
	plot([6:25],ones(1,20)*14,'Tag','Marker','Marker','x');
	plot([6:25],ones(1,20)*13,'Tag','Marker','Marker','o');
	plot([6:25],ones(1,20)*12,'Tag','Marker','Marker','+');
	plot([6:25],ones(1,20)*11,'Tag','Marker','Marker','*');
	plot([6:25],ones(1,20)*10,'Tag','Marker','Marker','s');
	plot([6:25],ones(1,20)*9,'Tag','Marker','Marker','d');
	plot([6:25],ones(1,20)*8,'Tag','Marker','Marker','^');
	plot([6:25],ones(1,20)*7,'Tag','Marker','Marker','v');
	plot([6:25],ones(1,20)*6,'Tag','Marker','Marker','>');
	plot([6:25],ones(1,20)*5,'Tag','Marker','Marker','<');
	plot([6:25],ones(1,20)*4,'Tag','Marker','Marker','p');
	plot([6:25],ones(1,20)*3,'Tag','Marker','Marker','h');
  text(15,2,'None','Tag','Marker','FontName','Arial','FontSize',8,...
            'Color','y','HorizontalAlignment','Center');
  set(findobj(gca,'Type','line'),'LineStyle','none','MarkerSize',3);
  set(gca,'XLimMode','Manual','XLim',[1 30],'XTick',[],...
          'YLimMode','Manual','YLim',[1 16],'YTick',[],'Color','black');
  title('Marker Style','FontName','Arial','FontSize',9,'Color','black');
  set(findobj(gca,'Tag','Marker','Marker',get(sample,'Marker')),'Color','red');
	set(findobj(gca,'Tag','Marker'),'ButtonDownFcn','guiline(''Marker'');');

	% LineWidth controls
	axes('Position',[0.55 0.45 0.15 0.25],'Box','On');
  hold on;
  text(2,9,'6'); plot([6:14],ones(1,9)*9,'Tag','LineWidth','LineWidth',6);
  text(2,8,'5'); plot([6:14],ones(1,9)*8,'Tag','LineWidth','LineWidth',5);
  text(2,7,'4'); plot([6:14],ones(1,9)*7,'Tag','LineWidth','LineWidth',4);
  text(2,6,'3'); plot([6:14],ones(1,9)*6,'Tag','LineWidth','LineWidth',3);
  text(2,5,'2'); plot([6:14],ones(1,9)*5,'Tag','LineWidth','LineWidth',2);
  text(2,4,'1'); plot([6:14],ones(1,9)*4,'Tag','LineWidth','LineWidth',1);
  text(2,3,'0.5'); plot([6:14],ones(1,9)*3,'Tag','LineWidth','LineWidth',0.5);
  text(2,2,'0.25'); plot([6:14],ones(1,9)*2,'Tag','LineWidth','LineWidth',0.25);
  set(findobj(gca,'Type','text'),'FontName','Arial','FontSize',8');
  set(gca,'XLimMode','Manual','XLim',[1 15],'XTick',[],...
          'YLimMode','Manual','YLim',[1 10],'YTick',[],'Color','black');
  title('Line Width','FontName','Arial','FontSize',9,'Color','black');
  set(findobj(gca,'Tag','LineWidth','LineWidth',get(sample,'LineWidth')'),'Color','red');
	set(findobj(gca,'Tag','LineWidth'),'ButtonDownFcn','guiline(''LineWidth'');');

	% MarkerSize controls
	axes('Position',[0.75 0.45 0.15 0.25],'Box','On');
  hold on;
  text(2,9,'8'); plot([4:11],ones(1,8)*9,'Tag','MarkerSize','MarkerSize',8);
  text(2,8,'7'); plot([4:11],ones(1,8)*8,'Tag','MarkerSize','MarkerSize',7);
  text(2,7,'6'); plot([4:11],ones(1,8)*7,'Tag','MarkerSize','MarkerSize',6);
  text(2,6,'5'); plot([4:11],ones(1,8)*6,'Tag','MarkerSize','MarkerSize',5);
  text(2,5,'4'); plot([4:11],ones(1,8)*5,'Tag','MarkerSize','MarkerSize',4);
  text(2,4,'3'); plot([4:11],ones(1,8)*4,'Tag','MarkerSize','MarkerSize',3);
  text(2,3,'2'); plot([4:11],ones(1,8)*3,'Tag','MarkerSize','MarkerSize',2);
  text(2,2,'1'); plot([4:11],ones(1,8)*2,'Tag','MarkerSize','MarkerSize',1);
  set(findobj(gca,'Type','text'),'FontName','Arial','FontSize',8');
  set(findobj(gca,'Type','line'),'LineStyle','none','Marker','x');
  set(gca,'XLimMode','Manual','XLim',[1 12],'XTick',[],...
          'YLimMode','Manual','YLim',[1 10],'YTick',[],'Color','black');
  title('Marker Size','FontName','Arial','FontSize',9,'Color','black');
  set(findobj(gca,'Tag','MarkerSize','MarkerSize',get(sample,'MarkerSize')),'Color','red');
	set(findobj(gca,'Tag','MarkerSize'),'ButtonDownFcn','guiline(''MarkerSize'');');

  % OK and Cancel buttons
  uicontrol('Style','Push','String','OK',...
            'Units','Normalized','Position',[0.375 0.025 0.1 0.05],...
            'FontName','Arial','FontSize',12,...
            'CallBack',['guiline(''OK'',''' func ''',' mat2str(arg) ');']);
  uicontrol('Style','Push','String','Cancel',...
            'Units','Normalized','Position',[0.525 0.025 0.1 0.05],...
            'FontName','Arial','FontSize',12,...
            'CallBack','guiline(''Cancel'');');
end

% Modification History:
%
% $Log: guiline.m,v $
% Revision 1.4  2005/02/03 20:17:45  michelich
% M-Lint: Replace deprecated isstr with ischar.
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
%                                Changed arefresh() to lowercase.
% Francis Favorini,  1997/07/04. Changed layout.
% Francis Favorini,  1997/02/05. Changed layout and added marker type.
% Francis Favorini,  1997/01/30. MATLAB 5 compliance.
% Francis Favorini,  1996/12/09. Changed from eval to feval to avoid converting
%                                handles to strings (which didn't always work).
% Francis Favorini,  1996/11/13. Added color patches, revert, and
%                                highlight of current properties.
% Francis Favorini,  1996/11/11.
