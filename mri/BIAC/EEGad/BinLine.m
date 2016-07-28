function BinLine(line,bin)
%BINLINE Set bin's line properties.
%
%       BinLine(name,bin);

% CVS ID and authorship of this code
% CVSId = '$Id: BinLine.m,v 1.3 2005/02/03 16:58:17 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:17 $';
% CVSRCSFile = '$RCSfile: BinLine.m,v $';

% Find EEG info
binColors=getfield(get(gcf,'UserData'),'binColors');

% Get line properties
color=get(line,'Color');
style=get(line,'LineStyle');
width=get(line,'LineWidth');
marker=get(line,'Marker');
msize=get(line,'MarkerSize');

% Change bin line properties in binColors, legend and plots
bi=rem(bin-1,length(binColors))+1;
binColors(bi)=struct('Color',color,'LineStyle',style,'LineWidth',width,...
                     'Marker',marker,'MarkerSize',msize);
set(findobj(gcf,'Tag','binName','UserData',bin),'Color',color);
set(findobj(gcf,'Tag','binLegend','UserData',bin),...
    'Color',color,'LineStyle',style,'LineWidth',width,'Marker',marker,'MarkerSize',msize);
set(findobj(gcf,'Tag','bin','UserData',bin),...
    'Color',color,'LineStyle',style,'LineWidth',width,'Marker',marker,'MarkerSize',msize);
set(gcf,'UserData',setfield(get(gcf,'UserData'),'binColors',binColors));

% Modification History:
%
% $Log: BinLine.m,v $
% Revision 1.3  2005/02/03 16:58:17  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:33  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/10/08 23:46:43  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Francis Favorini, 11/11/96.
% Francis Favorini, 11/13/96.  Only modify existing entries in binColors.
% Francis Favorini, 02/05/97.  Changed binColors to a structure.
% Francis Favorini, 07/04/97.  Use binColors field of UserData.
