function checkBins(inFile)
%CHECKBINS Read list of EEG files and find all bins.
%
%       checkBins(inFile);
%
%       inFile is the name of a .TXT file with a list of EEG files to check.

% CVS ID and authorship of this code
% CVSId = '$Id: checkBins.m,v 1.5 2005/02/03 20:17:40 michelich Exp $';
% CVSRevision = '$Revision: 1.5 $';
% CVSDate = '$Date: 2005/02/03 20:17:40 $';
% CVSRCSFile = '$RCSfile: checkBins.m,v $';

% Check args
if nargin~=1
  error('Incorrect number of input arguments.');
end
if ~ischar(inFile)
  error('Input argument must be a filename.');
end

if checkfiles(inFile)~=0
  return;
end

% Get data files from list file
listFid=fopen(inFile,'rt');
if listFid==-1
  error(['Couldn''t open list file "' inFile '"'])
end
[lines,count]=getstrs(listFid);
fclose(listFid);

bad=0;
bins=[];
for n=1:count
  % Process line from list file
  s=upper(lines{n});
  dataFile=sscanf(s,'%s',1);
  if dataFile(end)=='\', dataFile(end)=[]; end    % Trim trailing \
  ret=exist(dataFile);
  if ~any(ret==[2 3 4 6 7])
    bad=bad+1;
    if ~noDisplay, disp(sprintf('%s does not exist!',dataFile)); end
  else
    % Get bins
    eeg=EEGRead(dataFile);
    bins=strvcat(bins,[char(1:eeg.nBins)' char(eeg.binNames)]);
  end
end
% Show bins
bins=remduprows(double(bins));
disp(sprintf('Found %d bins:',size(bins,1)));
for b=1:size(bins,1)
  disp(sprintf('Bin %2d: %s',bins(b,1),bins(b,2:end)));
end

% Modification History:
%
% $Log: checkBins.m,v $
% Revision 1.5  2005/02/03 20:17:40  michelich
% M-Lint: Replace deprecated isstr with ischar.
%
% Revision 1.4  2005/02/03 16:58:20  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.3  2003/10/22 15:54:34  gadde
% Make some CVS info accessible through variables
%
% Revision 1.2  2003/09/15 16:45:05  michelich
% Changed getstrs() and checkfiles() to lowercase.
%
% Revision 1.1  2002/10/08 23:46:46  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
%       Francis Favorini, 12/10/97.
