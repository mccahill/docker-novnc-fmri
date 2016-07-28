function [cmap]=magentagrad(n,startVal,stopVal)
%MAGENTAGRAD Generate colormap of magenta with increasing intensity.
%  MAGENTAGRAD(M,startVal,stopVal)
%
%    M - Colormap length (M-by-3) [default: length of current colormap]
%    startVal - lowest intensity (0 to 1) of magenta in colormap  [default: 0.3]
%    stopVal  - highest intensity (0 to 1) of magenta in colormap [default: 1.0]
%
%  See Also: COLORMAP

% CVS ID and authorship of this code
% CVSId = '$Id: magentagrad.m,v 1.3 2005/02/03 16:58:34 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:34 $';
% CVSRCSFile = '$RCSfile: magentagrad.m,v $';

error(nargchk(0,3,nargin))

% Set defaults
if nargin<1, n=length(colormap); end
if nargin<2, startVal=0.3; end
if nargin<3, stopVal=1.0; end

% Check input arguments
if n < 1
  error('Colormap must have at least one element!'); 
end
if any([startVal stopVal] > 1) | any([startVal stopVal] < 0)
  error('startVal and stopVal must be between zero and one!');
end
if startVal >= stopVal
  error('startVal must be < stopVal!');
end

% Make the colormap
cmap=[[startVal:((stopVal-startVal)/(n-1)):stopVal]', zeros(n,1), [startVal:((stopVal-startVal)/(n-1)):stopVal]'];

% Modification History:
%
% $Log: magentagrad.m,v $
% Revision 1.3  2005/02/03 16:58:34  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:36  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/08/27 22:24:16  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2002/07/02. original