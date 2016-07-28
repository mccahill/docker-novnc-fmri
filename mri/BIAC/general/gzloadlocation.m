function [filenames,messages]=gzloadlocation(URIs,base)
%GZLOADLOCATION Return local filename corresponding to given URI(s)
%
%   [filenames,messages]=gzloadlocation(URIs);
%   [filenames,messages]=gzloadlocation(URIs,base);
%
%   URIs is a single URI (Uniform Resource Identifier) or a cell array of URIs
%   base is a string specifying the base URI for relative URIs
%     (default = current directory)
%     base may also be relative to current directory
%   filenames is a filename or cell array of filenames for each element in URIs
%     If there was an error loading a URIs that filename will be ''
%   messages is error message or cell array of error messages for each URI. 
%     messages will be empty strings if there was not an error.
%
%   GZLOADLOCATION takes one or more URIs (Uniform Resource Identifiers)
%     for compressed files, and, for each, returns the name of a (newly
%     created) local file that contains the uncompressed version of the
%     data pointed to by the URI.
%
%   If the URI is local (e.g. starts with 'file:'), the file is copied
%     to a new file, and the name of the new file is returned.
%
%   If the URI is remote, the data is stored in a temporary local file
%     and the name of that file is returned.
%
%   It is the caller's responsibility to delete the temporary file.
%
%   See Also: LOADLOCATION, FOPENLOCATION

% CVS ID and authorship of this code
% CVSId = '$Id: gzloadlocation.m,v 1.1 2006/11/27 16:18:02 gadde Exp $';
% CVSRevision = '$Revision: 1.1 $';
% CVSDate = '$Date: 2006/11/27 16:18:02 $';
% CVSRCSFile = '$RCSfile: gzloadlocation.m,v $';

% Handle input arguments
error(nargchk(1,2,nargin));

% Default arguments
if nargin < 2, base = ''; end

% Check inputs
if ~ischar(URIs) & ~isa(URIs, 'url') & ~iscell(URIs), error('URIs must be a string or a cell array of strings or url objects!'); end
if ~ischar(base) & ~isa(base, 'url'), error('base must be a string or url object!'); end

[filenames,messages] = grablocation('gzload', URIs, base);

% Pull single value out of returned cell array
if length(filenames) == 1, filenames=filenames{1}; end
if length(messages)==1, messages=messages{1}; end

% Modification History:
%
% $Log: gzloadlocation.m,v $
% Revision 1.1  2006/11/27 16:18:02  gadde
% First import.
%
%
