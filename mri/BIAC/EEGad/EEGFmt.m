function EEGFmt(action)
%EEGFmt Change formatting of EEG display axes.

% CVS ID and authorship of this code
% CVSId = '$Id: EEGFmt.m,v 1.3 2005/02/03 16:58:18 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:18 $';
% CVSRCSFile = '$RCSfile: EEGFmt.m,v $';

% Find EEG info
eeg=getfield(get(gcf,'UserData'),'eeg');
plots=getfield(get(gcf,'UserData'),'plots');
if length(plots)>eeg.nChannels, plots=plots(1:eeg.nChannels); end

axisFormat=findobj(gcf,'Tag','axisFormat');
boxFormat=findobj(gcf,'Tag','boxFormat');
nameFormat=findobj(gcf,'Tag','nameFormat');
numberFormat=findobj(gcf,'Tag','numberFormat');
hGridFormat=findobj(gcf,'Tag','hGridFormat');
vGridFormat=findobj(gcf,'Tag','vGridFormat');
bGridFormat=findobj(gcf,'Tag','bGridFormat');
baseFormat=findobj(gcf,'Tag','baseFormat');
taskFormat=findobj(gcf,'Tag','taskFormat');

if ~isempty(findstr('a',action))
  if strcmp(get(axisFormat,'Checked'),'on')
    set(plots,'Visible','off');
    set(axisFormat,'Checked','off');
  else
    set(plots,'Visible','on');
    set(axisFormat,'Checked','on');
  end
end

if ~isempty(findstr('o',action))
  if strcmp(get(boxFormat,'Checked'),'on')
    set(plots,'box','off');
    set(boxFormat,'Checked','off');
  else
    set(plots,'box','on');
    set(boxFormat,'Checked','on');
  end
end

if ~isempty(findstr('n',action))
  if strcmp(get(nameFormat,'Checked'),'on')
    set(nameFormat,'Checked','off');
  else
    set(nameFormat,'Checked','on');
  end
end

if ~isempty(findstr('u',action))
  if strcmp(get(numberFormat,'Checked'),'on')
    set(numberFormat,'Checked','off');
  else
    set(numberFormat,'Checked','on');
  end
end

if ~isempty(findstr('n',action)) | ~isempty(findstr('u',action))
  nameVisible=strcmp(get(findobj(gcf,'Tag','nameFormat'),'Checked'),'on');
  numberVisible=strcmp(get(findobj(gcf,'Tag','numberFormat'),'Checked'),'on');
  for aPlot=plots
    axes(aPlot);
    chan=get(gca,'UserData');
    label=chanLabel(chan,eeg.chanNames{chan},numberVisible,nameVisible);
    set(findobj(gca,'Tag','chanLabel'),'String',label);
  end
end

if ~isempty(findstr('h',action))
  if strcmp(get(hGridFormat,'Checked'),'on')
    set(hGridFormat,'Checked','off');
    set(plots,'YGrid','off');
  else
      set(hGridFormat,'Checked','on');
      set(vGridFormat,'Checked','off');
      set(bGridFormat,'Checked','off');
      set(plots,'YGrid','on');
      set(plots,'XGrid','off');
  end
end

if ~isempty(findstr('v',action))
  if strcmp(get(vGridFormat,'Checked'),'on')
    set(vGridFormat,'Checked','off');
    set(plots,'XGrid','off');
  else
    set(hGridFormat,'Checked','off');
    set(vGridFormat,'Checked','on');
    set(bGridFormat,'Checked','off');
    set(plots,'YGrid','off');
    set(plots,'XGrid','on');
  end
end

if ~isempty(findstr('b',action))
  if strcmp(get(bGridFormat,'Checked'),'on')
    set(bGridFormat,'Checked','off');
    set(plots,'YGrid','off');
    set(plots,'XGrid','off');
  else
    set(hGridFormat,'Checked','off');
    set(vGridFormat,'Checked','off');
    set(bGridFormat,'Checked','on');
    set(plots,'YGrid','on');
    set(plots,'XGrid','on');
  end
end

if ~isempty(findstr('x0',action))
  if strcmp(get(taskFormat,'Checked'),'on')
    delete(findobj(gcf,'Tag','x0'));
    set(taskFormat,'Checked','off');
  else
    for aPlot=plots
      axes(aPlot);
      hold on
      plot([0 0],get(gca,'YLim'),'Tag','x0','Color',get(gca,'XColor'),...
           'LineStyle',get(gca,'GridLineStyle'));
      hold off
    end
    set(taskFormat,'Checked','on');
  end
end

if ~isempty(findstr('y0',action))
  if strcmp(get(baseFormat,'Checked'),'on')
    delete(findobj(gcf,'Tag','y0'));
    set(baseFormat,'Checked','off');
  else
    for aPlot=plots
      axes(aPlot);
      hold on
      plot(get(gca,'XLim'),[0 0],'Tag','y0','Color',get(gca,'YColor'),...
           'LineStyle',get(gca,'GridLineStyle'));
      hold off
    end
    set(baseFormat,'Checked','on');
  end
end

% Modification History:
%
% $Log: EEGFmt.m,v $
% Revision 1.3  2005/02/03 16:58:18  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:33  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/10/08 23:46:44  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Francis Favorini, 10/28/96.
% Francis Favorini, 11/14/96.  Added x=0 and y=0 lines.
% Francis Favorini, 02/06/97.  Fixed unhiding unused axes bug.
% Francis Favorini, 07/02/97.  Changed to use eeg structure.
% Francis Favorini, 07/04/97.  Added channel names/numbers toggle.
