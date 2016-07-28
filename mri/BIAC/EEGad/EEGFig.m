function EEGFig
%EEGFig Create new EEG figure.
%
%       EEGFig;

% CVS ID and authorship of this code
% CVSId = '$Id: EEGFig.m,v 1.4 2005/02/03 16:58:18 michelich Exp $';
% CVSRevision = '$Revision: 1.4 $';
% CVSDate = '$Date: 2005/02/03 16:58:18 $';
% CVSRCSFile = '$RCSfile: EEGFig.m,v $';

% Create figure and set properities
colordef(figure,'none');
screen=get(0,'ScreenSize');
set(gcf,'Position',screen+[3 31 -8 -74],...
        'PaperOrientation','Landscape','PaperPosition',[0.25 0.25 10.5 8],...
        'DefaultUIMenuInterruptible','off');

% Modification History:
%
% $Log: EEGFig.m,v $
% Revision 1.4  2005/02/03 16:58:18  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.3  2004/02/23 17:18:08  michelich
% Changed color defaults so line colors are visible.
%
% Revision 1.2  2003/10/22 15:54:33  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/10/08 23:46:44  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Francis Favorini, 07/08/97.
