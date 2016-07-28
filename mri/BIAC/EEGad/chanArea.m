function data=chanArea(inFile,latencyRange)
%CHANAREA Measure area under EEG waveforms for list of file and channel names.
%
%       data=chanArea(inFile,latencyRange);
%
%       inFile is the name of a .CSV file with a list of files and channels to average.
%         Each line should have: filename,channelname
%         Leading and trailing spaces are trimmed.
%       latencyRange is an array specifying the min and max latency range for the area.
%
%       data is an array of structures with the following fields:
%         fileName
%         chanName
%         binName
%         area
%         latencyRange

% CVS ID and authorship of this code
% CVSId = '$Id: chanArea.m,v 1.5 2005/02/03 20:17:40 michelich Exp $';
% CVSRevision = '$Revision: 1.5 $';
% CVSDate = '$Date: 2005/02/03 20:17:40 $';
% CVSRCSFile = '$RCSfile: chanArea.m,v $';

% Check args
if nargin~=2
  error('Incorrect number of input arguments.');
end
if ~ischar(inFile)
  error('First input argument must be a filename.');
end
if ~isnumeric(latencyRange) | isempty(latencyRange) | length(latencyRange)~=2
  error('Second input argument must be an array specifying the min and max latency range for the area.');
end

% Get data files from list file
listFid=fopen(inFile,'rt');
if listFid==-1
  error(['Couldn''t open list file "' inFile '"'])
end
[lines,count]=getstrs(listFid);
fclose(listFid);

disp(sprintf('Processing %d channels...',count));
data=[];
bad=0;
d=0;
lastDataFile=[];
for n=1:count
  % Process line from list file
  s=upper(lines{n});
  comma=findstr(s,',');
  if isempty(comma)
    bad=bad+1;
    disp(sprintf('No comma on line %d!',n));
  else
    dataFile=trim(s(1:comma-1));
    chanName=spacejam(trim(s(comma+1:end)));
    if isempty(dataFile)
      badFile=1;
    else
      if dataFile(end)=='\', dataFile(end)=[]; end    % Trim trailing \
      newFile=~strcmp(dataFile,lastDataFile);
      badFile=exist(dataFile,'file')~=2;
    end
    if badFile
      bad=bad+1;
      disp(sprintf('File "%s" does not exist!',dataFile));
    else
      if newFile
        lastEEG=EEGRead(dataFile);
        lastDataFile=dataFile;
        time=([0:lastEEG.nPoints-1]*lastEEG.sampling)-lastEEG.onset;
        pointRange=find(time>=latencyRange(1) & time<=latencyRange(2));
        for c=1:lastEEG.nChannels
          lastEEG.chanNames{c}=upper(lastEEG.chanNames{c});
        end
      end
      % Find channel number
      chan=find(strcmp(chanName,spacejam(lastEEG.chanNames)));
      if isempty(chan)
        bad=bad+1;
        disp(sprintf('Channel "%s" does not exist in file "%s"!',chanName,dataFile));
      elseif length(chan)>1
        bad=bad+1;
        disp(sprintf('"%s" matches multiple channels in "%s"!',chanName,dataFile));
      else
        % Calculate area under curve
        for b=1:lastEEG.nBins
          d=d+1;
          data(d).fileName=dataFile;
          data(d).chanName=chanName;
          data(d).binName=lastEEG.binNames{b};
          data(d).area=sum(lastEEG.data(b,chan,pointRange)/lastEEG.uvunits);
          data(d).latencyRange=latencyRange;
          disp(sprintf('%s\t%s\t%s\t%.2f',data(d).fileName,data(d).chanName,...
                                          data(d).binName,data(d).area));
        end
      end %isempty(chan)
    end % badfile
  end % isempty(comma)
end

if bad>0
  disp(sprintf('%d channels were skipped!\n',bad));
end
count=count-bad;
disp(sprintf('%d channels were measured.\n',count));

% Modification History:
%
% $Log: chanArea.m,v $
% Revision 1.5  2005/02/03 20:17:40  michelich
% M-Lint: Replace deprecated isstr with ischar.
%
% Revision 1.4  2005/02/03 16:58:19  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.3  2003/10/22 15:54:34  gadde
% Make some CVS info accessible through variables
%
% Revision 1.2  2003/09/15 16:44:36  michelich
% Changed getstrs() to lowercase
%
% Revision 1.1  2002/10/08 23:46:45  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
%       Francis Favorini, 10/22/97.
%       Francis Favorini, 12/22/97.  Made case-insensitive.
