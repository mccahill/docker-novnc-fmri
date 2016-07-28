function currExp=pwe
% PWE - Present working experiment
%
%  pwe
%    Displays the current experiment, current exeperiment directory,
%    and current working directory.
%
%  currExp = pwe
%    Returns information on the current experiment. Nothing is displayed.
%    (same as currExp = chexp('settings');)
%
% See Also: CHEXP, ADDSCRIPTSPATH, RMSCRIPTSPATH, RMEXPPATH

% CVS ID and authorship of this code
% CVSId = '$Id: pwe.m,v 1.3 2005/02/03 16:58:35 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:35 $';
% CVSRCSFile = '$RCSfile: pwe.m,v $';

currExp = chexp('settings');
 
if nargout == 0
  if isempty(currExp)
    disp(sprintf('No record of current experiment.\nCurrent working directory is "%s"\n',pwd));
  else
    disp(sprintf('Current experiment "%s" is located at "%s"\nCurrent working directory is "%s"\n', ...
      currExp.Name,currExp.Path,pwd));
  end
  clear currExp; % Clear current experiment variable if it was not requested
end

% Modification History:
%
% $Log: pwe.m,v $
% Revision 1.3  2005/02/03 16:58:35  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:36  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/08/27 22:24:18  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2001/10/25. Added See Also section.
% Charles Michelich, 2001/06/22. added optional return of currExp
% Charles Michelich, 2001/06/21. original
