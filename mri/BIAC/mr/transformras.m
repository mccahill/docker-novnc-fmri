function [in2out,outFlipFlags]=transformras(inOrient,outOrient)
%TRANSFORMRAS - Calculate the permuation and flipdims necessary to transform between two RAS flags
%
%  Calculate the permuation and flipdims necessary to transform between two
%  RAS orientations.
%
%  [in2out,outFlipFlags]=transformras(inOrient,outOrient);
%
%  inOrient is the original RAS orientation
%  outOrient is the desired RAS orientation
%  in2out is a three element vector with the permuation from inOrient to outOrient.
%  outFlipFlags is a three element logical vector which is true for
%    dimensions of outOrient that should be flipped 
%    (i.e. swap R to L, S to I, A to P or vice-versa) 
%
%  inOrient and outOrient must be three character strings indicating
%    direction of increasing values in each of three dimensions.
%    e.g. lpi ->  X: R to L, Y: A to P, Z: S to I (Standard Axial S to I)
%
% See Also: READMR

%  % The following is true of the outputs:
%  newOrient = inOrient(in2out);
%  for n=1:length(outFlipFlags)
%    if outFlipFlags
%      if newOrient(n) = 'r', newOrient(n) = 'l';
%      elseif newOrient(n) = 'l', newOrient(n) = 'r';
%      elseif newOrient(n) = 'a', newOrient(n) = 'p';
%      elseif newOrient(n) = 'p', newOrient(n) = 'a';
%      elseif newOrient(n) = 's', newOrient(n) = 'i';
%      elseif newOrient(n) = 'i', newOrient(n) = 's';
%      end
%    end
%  end
%  newOrient == outOrient

% CVS ID and authorship of this code
% CVSId = '$Id: transformras.m,v 1.5 2005/02/03 16:58:45 michelich Exp $';
% CVSRevision = '$Revision: 1.5 $';
% CVSDate = '$Date: 2005/02/03 16:58:45 $';
% CVSRCSFile = '$RCSfile: transformras.m,v $';

% Check arguments
error(nargchk(2,2,nargin));
if ~ischar(inOrient) | ~ischar(outOrient) | ...
    ~isequal(size(inOrient),[1 3]) | ~isequal(size(outOrient),[1 3]);
  error('inOrient and outOrient must be 1 x 3 character arrays')
end

% Save original flags for calculating flipping
inOrientOrig=inOrient;
outOrientOrig=outOrient;

% Get rid of direction on orientations.
inOrient(find(inOrient=='l'))='r';
inOrient(find(inOrient=='p'))='a';
inOrient(find(inOrient=='i'))='s';
outOrient(find(outOrient=='l'))='r';
outOrient(find(outOrient=='p'))='a';
outOrient(find(outOrient=='i'))='s';

% Check that these are valid RAS flags
if ~strcmp(sort(inOrient),'ars'), error('inOrient is not a valid RAS flag!'); end
if ~strcmp(sort(outOrient),'ars'), error('inOrient is not a valid RAS flag!'); end

% Determine mapping of dimension order from input to output
for n=1:3
  % TODO: More efficient method to handle this???
  in2out(n) = find(outOrient(n)==inOrient);
end

if nargout > 1
  % Calculate flipping for output 
  outFlipFlags = outOrientOrig~=inOrientOrig(in2out);
end

% Modification History:
%
% $Log: transformras.m,v $
% Revision 1.5  2005/02/03 16:58:45  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.4  2004/01/08 17:40:16  michelich
% Added more error checking.
%
% Revision 1.3  2003/10/22 15:54:39  gadde
% Make some CVS info accessible through variables
%
% Revision 1.2  2003/09/25 20:28:37  michelich
% Fixed calculation of outFlipFlags
%
% Revision 1.1  2003/08/28 18:51:32  michelich
% Original version
%