function tf = isequalwithequalnans(varargin)
%ISEQUALWITHEQUALNANS True if arrays are numerically equal.
%   ISEQUALWITHEQUALNANS(A,B) is 1 if the two arrays are the same size
%   and contain the same values, and 0 otherwise.
%
%   ISEQUALWITHEQUALNANS(A,B,C,...) is 1 if all the input arguments are
%   numerically equal.
%
%   ISEQUALWITHEQUALNANS recursively compares the contents of cell
%   arrays and structures.  If all the elements of a cell array or
%   structure are numerically equal, ISEQUALWITHEQUALNANS will return 1.
%
%   NaNs are considered equal to each other.
%
%   Implements MATLAB R13 function for earlier versions of MATLAB.
%   DIFFERENCES: Follows pre-R13 MATLAB ISEQUAL convention of requiring
%                structure field order to be the same.
%
%   See also ISEQUAL, EQ.

% NOTE: The ISEQUAL requirement that structure field order be the same was
%   tested and confirmed in MATLAB R11 (5.3), R11.1 (5.3.1), R12 (6.0) and
%   R12.1 (6.1).  Earlier MATLAB 5 versions were not available for testing
%   but likely followed the same convention.  Structures were introduced in
%   MATLAB 5 so testing MATLAB 4 and earlier is not necessary.

% Based on "help isequalwithequalnans" from MATLAB R13
%   Copyright 1984-2002 The MathWorks, Inc.
%   Revision: 1.1   Date: 2002/04/01 21:49:12 
%   Built-in function.
% and "help isequal" from MATLAB R12.1
%   Copyright 1984-2001 The MathWorks, Inc. 
%   Revision: 1.12   Date: 2001/04/15 12:02:42 
%   Built-in function.

% BIAC Revision: $Id: isequalwithequalnans.m,v 1.5 2004/07/27 03:52:02 michelich Exp $

%TODO: Address recursion limit issues?
%TODO: Additional speed optimizations?  Specifically a better approach to
%      inner loop comparisons of multiple variables.

error(nargchk(2,Inf,nargin));

% Try using isequal first
tf = isequal(varargin{:});
if tf, return; end

% Get classes
currClasses = cell(1,nargin);
for c=1:nargin, currClasses{c} = class(varargin{c}); end

% Note: tf is false going into this block
if all(ismember(currClasses,{'double','sparse','single'}))
  % All variables are classes which can represent NaNs.
  % Check with equal NaNs.

  % Check that sizes are equal & get number of elements
  numElements = size(varargin{1});
  for arg=2:nargin,
    if ~isequal(numElements,size(varargin{arg})), return; end
  end
  numElements = prod(numElements);
  
  % Compare each input with first input
  if strcmp(currClasses{1},'single')
    % ISNAN does not support singles, so cast as double first.
    A_NotNan = ~isnan(double(varargin{1}));
  else
    A_NotNan = ~isnan(varargin{1});
  end
  for arg=2:nargin
    if strcmp(currClasses{arg},'single')
      % ISNAN does not support singles, so cast as double first.
      B_NotNan = ~isnan(double(varargin{arg}));
    else
      B_NotNan = ~isnan(varargin{arg});
    end
    tf = isequal(varargin{1}(A_NotNan),varargin{arg}(B_NotNan));
    if ~tf, return; end
    clear('B_NotNan');
  end
elseif all(strcmp(currClasses{1},currClasses(2:end)))
  % Otherwise all variables must be the same class
  % (we have already compared numeric classes with ISEQUAL)
    
  % Check that sizes are equal & get number of elements
  numElements = size(varargin{1});
  for arg=2:nargin,
    if ~isequal(numElements,size(varargin{arg})), return; end
  end
  numElements = prod(numElements);
  
  % Check other classes
  if strcmp(currClasses{1},'cell')
    % Check cell contents of each input against the first input
    for arg=2:nargin
      for e=1:numElements
        tf = isequalwithequalnans(varargin{1}{e},varargin{arg}{e});
        if ~tf, return; end
      end
    end
  elseif strcmp(currClasses{1},'struct')
    % Make sure structs have same fields (in same order)
    currFieldnames = fieldnames(varargin{1});
    for arg=2:nargin,
      if ~isequal(currFieldnames,fieldnames(varargin{arg})), return; end
    end
    
    % Check structure fields and elements of each input against the first input
    s = struct('type','.','subs','');  % Faster than GETFIELD
    for arg=2:nargin
      for f = 1:length(currFieldnames)
        s.subs = currFieldnames{f};
        for e = 1:numElements
          tf = isequalwithequalnans(subsref(varargin{1}(e),s),subsref(varargin{arg}(e),s));
          if ~tf, return; end
        end
      end
    end
  else
    % No other classes could contain NaNs, isequal false is correct
    tf = logical(0); % NOTE: This is redundant since tf is already false.
  end
else
  % Classes are different and cannot both represent NaNs, isequal false is correct.
  tf = logical(0);  % NOTE: This is redundant since tf is already false.
end
