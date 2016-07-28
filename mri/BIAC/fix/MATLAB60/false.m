function a=false(varargin)
%FALSE  False array.
%   FALSE is short-hand for logical(0).
%   FALSE(N) is an N-by-N matrix of logical zeros. 
%   FALSE(M,N) or FALSE([M,N]) is an M-by-N matrix of logical zeros.
%   FALSE(M,N,P,...) or FALSE([M N P ...]) is an M-by-N-by-P-by-...
%   array of logical zeros.
%   FALSE(SIZE(A)) is the same size as A and all logical zeros.
%
%   FALSE() is identical to LOGICAL(ZEROS()) for version of MATLAB prior to
%   MATLAB 6.5.  In MATLAB 6.5 and later, TRUE(N) is much faster and more
%   memory efficient than LOGICAL(ZEROS()).
%
%   Implements MATLAB R13 function for earlier versions of MATLAB.
%
%   See also TRUE, LOGICAL.

% Based on "help false" from MATLAB R13 SP1: 
%   Copyright 1984-2002 The MathWorks, Inc. 
%   Revision: 1.2   Date: 2002/04/08 20:21:05 
%   Built-in function.

% BIAC Revision: $Id: false.m,v 1.7 2004/07/27 03:52:02 michelich Exp $

if nargin==0, 
  a=logical(0);
else
  a=logical(zeros(varargin{:}));
end
