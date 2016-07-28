function BinName(name,bin)
%BINNAME Set bin's name.
%
%       BinName(name,bin);

% CVS ID and authorship of this code
% CVSId = '$Id: BinName.m,v 1.3 2005/02/03 16:58:17 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:17 $';
% CVSRCSFile = '$RCSfile: BinName.m,v $';

% Find EEG info
eeg=getfield(get(gcf,'UserData'),'eeg');

% Change name of bin in eeg, legend and menu
eeg.binNames{bin}=name;
set(gcf,'UserData',setfield(get(gcf,'UserData'),'eeg',eeg));
set(findobj(gcf,'Tag','binName','UserData',bin),'String',name);
binMenuItem=findobj(gcf,'Tag','binMenuItem','UserData',bin);
checked=get(binMenuItem,'Checked');   % Setting label resets checked state
set(binMenuItem,'Label',name,'Checked',checked);

% Modification History:
%
% $Log: BinName.m,v $
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
% Francis Favorini, 11/08/96.
% Francis Favorini, 07/02/97.  Changed to use eeg structure.
