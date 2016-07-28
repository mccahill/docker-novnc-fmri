function ret=evalif(testExp,trueExp,falseExp)
%EVALIF  Conditional eval.
%
%   ret=evalif(testExp,trueExp,falseExp);
%
%   testExp is a string containing an expression
%     which is evaluated in the caller's workspace.
%     If the result is true, trueExp is evaluated
%     and its result is returned in ret, otherwise
%     falseExp is evaluated.
%
%   Notes
%     Exactly one of trueExp and falseExp will be evaluated.
%     The expressions are evaluated with EVALIN('caller',...).
%
%   Example
%     >>x=[];
%     >>evalif('isempty(x)','NaN','mean(x)')
%     ans =
%        NaN
%
%   See also IF, EVALIN, EVAL

% CVS ID and authorship of this code
% CVSId = '$Id: evalif.m,v 1.3 2005/02/03 16:58:33 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:33 $';
% CVSRCSFile = '$RCSfile: evalif.m,v $';

% Check args
error(nargchk(3,3,nargin));
if ~ischar(testExp) | ~ischar(trueExp) | ~ischar(falseExp)
  error('All arguments must be strings.');
end

if evalin('caller',testExp)
  ret=evalin('caller',trueExp);
else
  ret=evalin('caller',falseExp);
end

% Modification History:
%
% $Log: evalif.m,v $
% Revision 1.3  2005/02/03 16:58:33  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:35  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/08/27 22:24:14  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Francis Favorini, 2000/05/09.
