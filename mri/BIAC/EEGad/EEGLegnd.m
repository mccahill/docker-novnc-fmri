function EEGLegnd(bins)
%EEGLEGND Display legend for EEG data.
%
%       EEGLEGND(bins)
%
%       bins is a vector of bins for the legend.

% CVS ID and authorship of this code
% CVSId = '$Id: EEGLegnd.m,v 1.3 2005/02/03 16:58:18 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:18 $';
% CVSRCSFile = '$RCSfile: EEGLegnd.m,v $';

% Find EEG info
eeg=getfield(get(gcf,'UserData'),'eeg');
binColors=getfield(get(gcf,'UserData'),'binColors');

legend=findobj(gcf,'Tag','Legend');
if isempty(legend)
  legend=axes('Tag','Legend','Units','Normalized','Position',[0.01 0.08 0.12 0.84],...
              'XLim',[0 10],'YLim',[0 max(10,eeg.nBins)+0.5],...
              'XTick',[],'YTick',[],'XTickLabel',[],'YTickLabel',[],...
              'Box','On','YDir','Reverse');
else
  axes(legend);
  delete(get(legend,'Children'));
end

% Plot lines
hold on
bi=0;
for b=bins
  bi=bi+1;
  ci=rem(b-1,length(binColors))+1;
  h=plot([7.5 9.5],[bi bi]);
  set(h,'Tag','binLegend','UserData',b,'Color',binColors(ci).Color,...
        'LineStyle',binColors(ci).LineStyle,'LineWidth',binColors(ci).LineWidth,...
        'Marker',binColors(ci).Marker,'MarkerSize',binColors(ci).MarkerSize);
end      
hold off

% Add text
text('String','Legend','Units','Normalized','Position',[0.5 0.99],'FontName','Arial',...
     'FontSize',10,'HorizontalAlignment','Center','VerticalAlignment','Top');
if length(bins)==1
  binNames=text(0.5,1,eeg.binNames{bins});
else
  binNames=text(0.5*ones(1,length(bins)),1:length(bins),eeg.binNames(bins));
end
bi=0;
for b=bins
  bi=bi+1;
  ci=rem(b-1,length(binColors))+1;
  set(binNames(bi),'FontName','Arial Narrow','FontSize',9,'Color',binColors(ci).Color,...
      'Tag','binName','UserData',b);
end

% Add figure title "ExpName (ExpDate)"
pos=get(legend,'Position');
text('String',sprintf('%s (%s)',eeg.expName,eeg.expDate),'Units','Normal',...
     'Position',[0.56/pos(3)-pos(1) 0.97/pos(4)-pos(2)],...
     'FontName','Arial','FontSize',10,'HorizontalAlignment','Center');

% Modification History:
%
% $Log: EEGLegnd.m,v $
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
% Francis Favorini, 10/02/96.
% Francis Favorini, 10/22/96.  Simplified params.
% Francis Favorini, 02/05/97.  Changed binColors to a structure.
% Francis Favorini, 07/01/97.  Changed to use eeg structure.
% Francis Favorini, 07/07/97.  Check for single bin case (with 1x1 cell array,
%                              text assigns a cell to string.)
