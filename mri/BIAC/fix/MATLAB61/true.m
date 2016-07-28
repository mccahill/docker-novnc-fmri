function a=true(varargin)
%TRUE   True array.
%   TRUE is short-hand for logical(1).
%   TRUE(N) is an N-by-N matrix of logical ones.
%   TRUE(M,N) or TRUE([M,N]) is an M-by-N matrix of logical ones.
%   TRUE(M,N,P,...) or TRUE([M N P ...]) is an M-by-N-by-P-by-...
%   array of logical ones.
%   TRUE(SIZE(A)) is the same size as A and all logical ones.
%
%   TRUE() is identical to LOGICAL(ONES()) for version of MATLAB prior to
%   MATLAB 6.5.  In MATLAB 6.5 and later, TRUE(N) is much faster and more
%   memory efficient than LOGICAL(ONES()).
%
%   Implements MATLAB R13 function for earlier versions of MATLAB.
%
%   See also FALSE, LOGICAL.

% Based on "help true" from MATLAB R13 SP1: 
%   Copyright 1984-2002 The MathWorks, Inc. 
%   Revision: 1.2   Date: 2002/04/08 20:21:11
%   Built-in function.

% BIAC Revision: $Id: true.m,v 1.8 2004/07/27 03:52:02 michelich Exp $

if nargin==0, 
  a=logical(1);
else
  a=logical(ones(varargin{:}));
end
