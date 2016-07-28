function chan=chanNum(inFile,chanName)
%CHANNUM Return channel number given channel name and EEG file or structure.
%
%       chan=chanNum(inFile,chanName);
%
%       inFile is the name of an EEG file or an EEG data structure.
%       chanName is the channel name.
%
%       chan is the channel number.

% CVS ID and authorship of this code
% CVSId = '$Id: chanNum.m,v 1.4 2005/02/03 20:17:40 michelich Exp $';
% CVSRevision = '$Revision: 1.4 $';
% CVSDate = '$Date: 2005/02/03 20:17:40 $';
% CVSRCSFile = '$RCSfile: chanNum.m,v $';

% Check args
if nargin~=2
  error('Incorrect number of input arguments.');
end
if ~ischar(chanName)
  error('Second input argument must be a string.');
end

% Get EEG data
if ischar(inFile)
  eeg=EEGRead(inFile);
elseif isstruct(inFile)
  eeg=inFile;
  inFile='that EEG structure';
else
  error('First input argument must be a filename or EEG structure.');
end
for c=1:eeg.nChannels
  eeg.chanNames{c}=upper(eeg.chanNames{c});
end

% Find channel number
chan=find(strcmp(upper(spacejam(chanName)),spacejam(eeg.chanNames)));
if isempty(chan)
  disp(sprintf('Channel "%s" does not exist in %s!',chanName,inFile));
end

% Modification History:
%
% $Log: chanNum.m,v $
% Revision 1.4  2005/02/03 20:17:40  michelich
% M-Lint: Replace deprecated isstr with ischar.
%
% Revision 1.3  2005/02/03 16:58:20  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:34  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/10/08 23:46:46  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
%       Francis Favorini, 10/23/97.
%       Francis Favorini, 12/09/97.  Made case-insensitive.
