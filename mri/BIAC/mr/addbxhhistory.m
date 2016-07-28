function newmrstruct = addbxhhistory(mrstruct, historyMsg)
%ADDBXHHISTORY - Add BXH history entry to specified mrstruct
%
% newmrstruct = addbxhhistory(mrstruct, historyMsg);
%   mrstruct - input mrstruct
%   historyMsg - string to use as the history entry description
%   newmrstruct - input mrstruct with the specified history entry added.
%
% Example:
% >> imgOrig = readmr('V.bxh');
% >> % Do some processing to imgOrig to generate img
% >> img = addbxhhistory(img, 'Performed processing steps A, B, and C');
% >> writemr(img,'Vout.bxh');
%
% See also: READMR, CONVERTMRSTRUCTTOBXH

% TODO: Add revision information to history entry also.

% CVS ID and authorship of this code
% CVSId = '$Id: addbxhhistory.m,v 1.6 2005/03/18 22:24:43 michelich Exp $';
% CVSRevision = '$Revision: 1.6 $';
% CVSDate = '$Date: 2005/03/18 22:24:43 $';
% CVSRCSFile = '$RCSfile: addbxhhistory.m,v $';

% Check arguments and set defaults
error(nargchk(2,2,nargin))
if ~isstruct(mrstruct) | ~isfield(mrstruct, 'info')
  error('First argument is not a valid mrstruct!');
end
if ~ischar(historyMsg)
  error('historyMsg must be a string!');
end

% Determine the current user
if isunix
  user = getenv('USER');
else
  user = getenv('USERNAME');
end
if isempty(user)
  user = 'Unknown';
end

% Determine the current host (fully qualified, if possible)
if isunix
  % TODO: Find more robust method to get fully qualified host.
  host = getenv('HOST');
  if isempty(host)
    host = getenv('HOSTNAME');
  end
  if isempty(host)
    [status, host] = unix('hostname');
    if status, host = ''; end
  end 
else
  % TODO: Avoid using dos() command, if possible.
  host = local_getWinHost;
  if isempty(host)
    host = getenv('COMPUTERNAME');
  end
end
if isempty(host)
  host = 'Unknown';
end

% Add a empty BXH header if necessary (no changes made if already BXH)
newmrstruct = convertmrstructtobxh(mrstruct);

% Determine how many history entries already exist (if any).
numEntries = 0;
if isfield(newmrstruct.info.hdr.bxh{1},'history')
  numEntries = length(newmrstruct.info.hdr.bxh{1}.history{1}.entry);
end

% Add the history entry
newmrstruct.info.hdr.bxh{1}.history{1}.entry{numEntries+1}.date{1}.VALUE = datestr(now,31);
newmrstruct.info.hdr.bxh{1}.history{1}.entry{numEntries+1}.user{1}.VALUE = user;
newmrstruct.info.hdr.bxh{1}.history{1}.entry{numEntries+1}.host{1}.VALUE = host;
newmrstruct.info.hdr.bxh{1}.history{1}.entry{numEntries+1}.description{1}.VALUE = historyMsg;

%--------------------------------------------------------------------------
function host = local_getWinHost
% Determine fully qualified hostname for current Windows computer using
% ipconfig.  Return '' if unable to determine fully qualified hostname.

host = ''; % Initialize output

% Grab ipconfig output
status = 1;
try
  [status, stdout] = dos('ipconfig /all');
catch
  % DOS commands cannot be executed from a UNC path, try from WINDIR.
  wd = pwd;
  try
    cd(getenv('WINDIR'))
    [status, stdout] = dos('ipconfig /all');
  catch
    cd(wd)
    return;
  end
  cd(wd)
end
if status, return, end

% Find line breaks (CR-LF per Windows conventions)
lines = strfind(stdout, char([13 10]));

% Parse out the Host Name and Primary Dns Suffix from the output.
% TODO: Test on other Windows platforms (Only WinXP tested)
%        Host Name . . . . . . . . . . . . : machine
%        Primary Dns Suffix  . . . . . . . : domainname.com
hostNameProto = '        Host Name . . . . . . . . . . . . : ';
priDnsSxProto = '        Primary Dns Suffix  . . . . . . . : ';
hostName = '';
priDnsSx = '';
lastLine = 1;
for line = lines
  currLine = stdout(lastLine:line-1);
  if isempty(hostName) & length(currLine) > length(hostNameProto) & ...
      strncmp(currLine, hostNameProto, length(hostNameProto))
    hostName = currLine(length(hostNameProto)+1:end);
  elseif isempty(priDnsSx) & length(currLine) > length(priDnsSxProto) & ...
      strncmp(currLine, priDnsSxProto, length(priDnsSxProto))
    priDnsSx = currLine(length(priDnsSxProto)+1:end);
  end
  lastLine = line + 2;
  if ~isempty(hostName) & ~isempty(priDnsSx)
    break
  end
end

% Construct fully qualified hostname
if ~isempty(hostName) | ~isempty(priDnsSx)
  host = [hostName '.' priDnsSx] ;
end

% Modification History:
%
% $Log: addbxhhistory.m,v $
% Revision 1.6  2005/03/18 22:24:43  michelich
% Added missing semicolon.
%
% Revision 1.5  2005/03/14 18:33:40  michelich
% Added example to help comments.
% Remove unused code and added more error checking on local_getWinHost parsing.
%
% Revision 1.4  2005/02/25 19:21:49  michelich
% Correct function name in comments.
%
% Revision 1.3  2005/02/24 19:55:20  michelic
% Try UNIX hostname command if necessary.
%
% Revision 1.2  2005/02/24 19:51:10  michelich
% Added host to history entry.
%
% Revision 1.1  2005/02/21 16:46:07  michelich
% Initial version.  Based on local function in mrtest.m rev 1.16.
%
