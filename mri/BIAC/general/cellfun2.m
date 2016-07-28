function tf = cellfun2(fun, c)
%CELLFUN2 Extended cell array functions.  Based on MATLAB's CELLFUN.
%
%   TF = CELLFUN2(FUN, C) where FUN is one of 
%
%     'isnumeric'   -- true for numeric cell
%     'isfinite'    -- true for double cell, with all elements finite
%     'isnotfinite' -- true for double cell, with all elements not finite
%     'isinf'       -- true for double cell, with all elements infinite
%     'isnan'       -- true for double cell, with all elements NaN
%
%   and C is the cell array, returns the results of
%   applying the specified function to each element
%   of the cell array. TF is a logical array the same
%   size as C containing the results of applying FUN on
%   the corresponding cell elements of C.
%
%   Complex numbers are handled the same way that the built-in MATLAB
%   ISFINITE, ISINF, and ISNAN functions handles them.  If either the
%   real of imaginary parts are Inf or NaN, the element is considered
%   to be infinite or Not-a-Number repectively.
%
%   Note that a logical array is NOT a double, numerical array in
%   MATLAB R13, but is a double, numerical array in earlier versions.
%   CELLFUN2 behaves the same as the ISNUMERIC and ISA functions of
%   the MATLAB version in which CELLFUN2 is executed.
%
%   See Also: CELLFUN, ISNUMERIC, ISFINITE, ISINF, ISNAN

% CVS ID and authorship of this code
% CVSId = '$Id: cellfun2.m,v 1.11 2005/02/22 20:18:24 michelich Exp $';
% CVSRevision = '$Revision: 1.11 $';
% CVSDate = '$Date: 2005/02/22 20:18:24 $';
% CVSRCSFile = '$RCSfile: cellfun2.m,v $';

% Implemented as a MEX file also (faster)
persistent lessThan65 haveWarned

% Check number of arguments here to avoid "Input argument undefined" errors on MEX file calls
error(nargchk(2,2,nargin));
if nargout > 1, error('Too many output arguments.'); end

% Cache version check for performance.
if isempty(lessThan65)
  [majorVer, minorVer] = strtok(strtok(version),'.');
  majorVer = str2double(majorVer);
  minorVer = str2double(strtok(minorVer,'.'));
  lessThan65 = majorVer < 6 | (majorVer == 6 & minorVer < 5);
  clear majorVer minorVer
end

if lessThan65 & exist('cellfun2NLT') == 3
  % MEX implementation compiled without logical type support
  % (MATLAB versions prior to 6.5)
  tf = cellfun2NLT(fun, c);
elseif exist('cellfun2LT') == 3
  % MEX implementation compiled with logical type support
  tf = cellfun2LT(fun, c);
else
  % m-file implementation
  
  % Warn user to build MEX the first time it is used.
  if isempty(haveWarned)
    warning('Using m-file version of cellfun2().  Compile cellfun2.c for better performance!');
    haveWarned = 1;
  end
  
  % Check arguments 
  if ~ischar(fun), error('Function name must be a string.'); end
  if ~iscell(c), error('CELLFUN2 only works on cells.'); end
  
  % Initialize output (all false by default)
  tf = logical(zeros(size(c)));
  
  % To match MEX implementation, treat empty cells as follows:
  %  isnumeric  - treat empty cells as true (same as MATLAB behavior)
  %  All others - treat empty cells as false (MATLAB returns empty for these functions)
  
  switch fun
    case 'isnumeric'
      for n = 1:numel(c)
        tf(n) = isnumeric(c{n});
      end
      
    case 'isnotfinite'
      for n = 1:numel(c)
        if isa(c{n},'double') & ~isempty(c{n})
          tf(n) = all(~isfinite(c{n}(:))); 
        end
      end
      
    case 'isinf'
      for n = 1:numel(c)
        if isa(c{n},'double') & ~isempty(c{n})
          tf(n) = all(isinf(c{n}(:))); 
        end
      end
        
    case 'isnan'
      for n = 1:numel(c)
        if isa(c{n},'double') & ~isempty(c{n})
          tf(n) = all(isnan(c{n}(:))); 
        end
      end
        
    case 'isfinite'
      for n = 1:numel(c)
        if isa(c{n},'double') & ~isempty(c{n})
          tf(n) = all(isfinite(c{n}(:))); 
        end
      end
      
    otherwise
      error('Unknown option.');
  end
end

% Modification History:
%
% $Log: cellfun2.m,v $
% Revision 1.11  2005/02/22 20:18:24  michelich
% Use more robust version parsing code.
%
% Revision 1.10  2005/02/03 16:58:32  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.9  2004/11/12 16:18:58  michelich
% Move persistent variable declaration to top level of function (mlint warning).
%
% Revision 1.8  2004/07/26 23:34:12  michelich
% Cache MATLAB version.
% Check number of arguments even when using MEX file.
%
% Revision 1.7  2004/05/06 16:34:53  michelich
% Compile cellfun2 with and without logical type support using two different
% output names instead of placing the MEX files into the fix directories.
% Modify cellfun2.m to handle calling the correct MEX file.
%
% Revision 1.6  2004/05/06 15:15:27  gadde
% Remove all dependencies on ispc and nargoutchk (for compatibility
% with Matlab 5.3).
%
% Revision 1.5  2004/03/23 16:43:21  michelich
% Implemented as m-file.
%
  