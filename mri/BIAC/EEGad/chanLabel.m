function label=chanLabel(chanNumber,chanName,numberVisible,nameVisible)
%CHANLABEL Return channel label based on name and/or number.
%
%       label=chanLabel(chanNumber,chanName,numberVisible,nameVisible);
%
%       chanNumber is the channel number.
%       chanName is the channel name.
%       numberVisible is non-zero if the number should be included in the label, else zero.
%       nameVisible is non-zero if the name should be included in the label, else zero.

% CVS ID and authorship of this code
% CVSId = '$Id: chanLabel.m,v 1.3 2005/02/03 16:58:19 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:19 $';
% CVSRCSFile = '$RCSfile: chanLabel.m,v $';

if numberVisible & nameVisible
  label=sprintf('#%d: %s',chanNumber,chanName);
elseif numberVisible
  label=sprintf('#%d',chanNumber);
elseif nameVisible
  label=chanName;
else
  label='';
end

% Modification History:
%
% $Log: chanLabel.m,v $
% Revision 1.3  2005/02/03 16:58:19  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:34  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/10/08 23:46:46  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Francis Favorini, 07/04/97.
