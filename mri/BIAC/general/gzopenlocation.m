function [fids,messages]=gzopenlocation(URIs,fopenargs,base)
%GZOPENLOCATION Return open (uncompressed, if needed) file identifiers corresponding to given URI(s)
%
%   [fids,messages] = gzopenlocation(URIs);
%   [fids,messages] = gzopenlocation(URIs,fopenargs);
%   [fids,messages] = gzopenlocation(URIs,fopenargs,base);
%
%   URIs is a single URI (Uniform Resource Identifier) or a cell array of URIs
%   fopenargs is a cell array of arguments to pass to fopen (default = {})
%   base is a string specifying the base URI for relative URIs 
%     (default = current directory)
%   fids is a vector of MATLAB file identifiers for each element in URIs
%     fid will be -1 if there was an error.
%   messages is error message or cell array of error messages for each URI. 
%     messages will be empty strings if there was not an error.
%
%   GZOPENLOCATION takes one or more URI (Uniform Resource Identifiers)
%     and, for each, returns an open file identifier pointing to a local
%     file that contains the same data pointed to by the URI.
%     If the file has the extension .gz, then it uncompresses the file into
%     a temporary location before returning the file identifier to the open
%     temporary file.
%
%   If the URI is local (e.g. starts with 'file:', or is relative and
%     the base URI starts with 'file:') this is equivalent to an FOPEN
%     on that file.
%
%   If the URI is remote, the data is stored in a temporary local file
%     and the result of an FOPEN on that file is returned.  Any temporary
%     file created will be deleted when the file is closed.
%
%   See Also: FOPEN, FOPENLOCATION, LOADLOCATION

% CVS ID and authorship of this code
% CVSId = '$Id: gzopenlocation.m,v 1.2 2006/07/19 12:10:51 gadde Exp $';
% CVSRevision = '$Revision: 1.2 $';
% CVSDate = '$Date: 2006/07/19 12:10:51 $';
% CVSRCSFile = '$RCSfile: gzopenlocation.m,v $';

% Handle input arguments
error(nargchk(1,3,nargin));

% Default arguments
if nargin < 2, fopenargs = {}; end
if nargin < 3, base = ''; end

% Check inputs
if ~ischar(URIs) & ~isa(URIs, 'url') & ~iscell(URIs), error('URIs must be a string, a url object, or a cell array of strings or url objects!'); end
if ~iscellstr(fopenargs), error('fopenargs must be a cell array of strings!'); end
if ~ischar(base) & ~isa(base, 'url'), error('base must be a string or url object!'); end

[fids,messages] = grablocation('gzopen', URIs, base, fopenargs);

% grablocation returns cell array, we return scalar array
fids = [ fids{:} ];
if length(messages)==1, messages=messages{1}; end

% Modification History:
%
% $Log: gzopenlocation.m,v $
% Revision 1.2  2006/07/19 12:10:51  gadde
% Remove old log.
%
% Revision 1.1  2006/06/27 20:42:28  gadde
% Updates to support reading of compressed files (if Java is enabled).
%
