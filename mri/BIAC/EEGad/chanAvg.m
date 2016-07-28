function eeg=chanAvg(inFile,newTitle,newChannel)
%CHANAVG Read list of file/channel names and average channels within each bin.
%
%       eeg=chanAvg(inFile);
%       eeg=chanAvg(inFile,newTitle);
%       eeg=chanAvg(inFile,newTitle,newChannel);
%
%       inFile is the name of a .CSV file with a list of files and channels to average.
%         Each line should have: filename,channelname[,shift]
%         Leading and trailing spaces are trimmed.
%         shift is specified in ms and will be rounded to the nearest data point.
%         Positive shift will move the waveform to a later time.
%       newTitle is an experiment name for the new EEG file.
%       newChannel is a name for the new EEG channel.
%
%       eeg is an EEG data structure (see EEGRead.m).

% CVS ID and authorship of this code
% CVSId = '$Id: chanAvg.m,v 1.5 2005/02/03 20:17:40 michelich Exp $';
% CVSRevision = '$Revision: 1.5 $';
% CVSDate = '$Date: 2005/02/03 20:17:40 $';
% CVSRCSFile = '$RCSfile: chanAvg.m,v $';

% Check args
if nargin<1 | nargin>3
  error('Incorrect number of input arguments.');
end
if ~ischar(inFile)
  error('First input argument must be a filename.');
end

% Set defaults
if nargin<2, newTitle='Average of Multiple Channels'; end
if nargin<3, newChannel='Channel Average'; end
if ~ischar(newTitle)
  error('Second input argument must be a string.');
end
if ~ischar(newChannel)
  error('Third input argument must be a string.');
end

% Fill EEG structure
d=now;
eeg.expName=newTitle;
eeg.expDate=[datestr(d,'ddd') ' ' datestr(d,'mmm') ' ' datestr(d,'dd') ', ' datestr(d,'yyyy') ' ' datestr(d,'HH:MM')];
eeg.nBins=0;
eeg.nChannels=1;
eeg.nPoints=0;
eeg.sampling=0;
eeg.uvunits=0;
eeg.onset=0;
eeg.binNames={};
eeg.chanNames={newChannel};
eeg.coords=[];
eeg.data=[];
eeg.rawData=[];

% Get data files from list file
listFid=fopen(inFile,'rt');
if listFid==-1
  error(['Couldn''t open list file "' inFile '"'])
end
[lines,count]=getstrs(listFid);
fclose(listFid);

disp(sprintf('Processing %d channels...',count));
bad=0;
lastDataFile=[];
for n=1:count
  % Process line from list file
  s=upper(lines{n});
  comma=findstr(s,',');
  if isempty(comma)
    bad=bad+1;
    disp(sprintf('Error: No comma on line %d--excluded from average!',n));
  else
    dataFile=trim(s(1:comma(1)-1));
    shift=0;
    if length(comma)>1
      shift=str2num(s(comma(2)+1:end));
    else
      comma(2)=length(s)+1;
    end
    chanName=spacejam(trim(s(comma(1)+1:comma(2)-1)));
    if isempty(dataFile)
      badFile=1;
    else
      if dataFile(end)=='\', dataFile(end)=[]; end    % Trim trailing \
      newFile=~strcmp(dataFile,lastDataFile);
      badFile=exist(dataFile,'file')~=2;
    end
    if badFile
      bad=bad+1;
      disp(sprintf('Error: File "%s" does not exist--excluded from average!',dataFile));
    elseif isempty(shift)
      bad=bad+1;
      disp(sprintf('Error: Invalid shift specified on line %d--excluded from average!',n));
    else
      if newFile
        lastEEG=EEGRead(dataFile);
        lastEEG.origOnset=lastEEG.onset;
        lastEEG.origNPoints=lastEEG.nPoints;
        lastDataFile=dataFile;
        for c=1:lastEEG.nChannels
          lastEEG.chanNames{c}=upper(lastEEG.chanNames{c});
        end
      end
      % Find channel number
      chan=find(strcmp(chanName,spacejam(lastEEG.chanNames)));
      if isempty(chan)
        bad=bad+1;
        disp(sprintf('Error: Channel "%s" does not exist in file "%s"--excluded from average!',chanName,dataFile));
      elseif length(chan)>1
        bad=bad+1;
        disp(sprintf('Error: "%s" matches multiple channels in "%s"--excluded from average!',chanName,dataFile));
      else
        % Shift wave form if needed
        shift=round(shift/lastEEG.sampling)*lastEEG.sampling; % Convert to nearest multiple of sampling rate
        if newFile
          lastEEG.onset=lastEEG.onset-shift;
        end
        disp(sprintf('%26s,%8s: %4d ms onset, %3d points, %3d ms shift',dataFile,chanName,...
          lastEEG.origOnset,lastEEG.origNPoints,shift));
        if eeg.nBins==0
          % Initialize data/header info
          eeg.nBins=lastEEG.nBins;
          eeg.nPoints=lastEEG.nPoints;
          eeg.sampling=lastEEG.sampling;
          eeg.uvunits=lastEEG.uvunits;
          eeg.onset=lastEEG.onset;
          for b=1:eeg.nBins
            eeg.binNames{b}=lastEEG.binNames{b};
            eeg.data(b,1,:)=lastEEG.data(b,chan,:);
          end
        elseif eeg.nBins~=lastEEG.nBins | eeg.sampling~=lastEEG.sampling | eeg.uvunits~=lastEEG.uvunits
          % Make sure header info matches
          bad=bad+1;
          disp(sprintf(' Error: Header info does not match other files--excluded from average!'));
        elseif rem(lastEEG.onset,lastEEG.sampling)~=0
          % Make sure onset is a multiple of sampling
          bad=bad+1;
          disp(sprintf(' Error: Onset is not a multiple of sampling--excluded from average!'));
        else
          % Align time windows
          if eeg.nPoints~=lastEEG.nPoints | eeg.onset~=lastEEG.onset
            % Adjust start of time window
            extra=abs(lastEEG.onset-eeg.onset)/eeg.sampling;
            if eeg.onset<lastEEG.onset               % this chan starts too early
              lastEEG.data=lastEEG.data(:,:,extra+1:end);
              lastEEG.onset=eeg.onset;
              lastEEG.nPoints=lastEEG.nPoints-extra;
              disp(sprintf(' Warning: Trimmed %d ms pre-stimulus from this channel!',extra*eeg.sampling));
            elseif eeg.onset>lastEEG.onset           % this chan starts too late
              eeg.data=eeg.data(:,:,extra+1:end);
              eeg.onset=lastEEG.onset;
              eeg.nPoints=eeg.nPoints-extra;
              disp(sprintf(' Warning: Trimmed %d ms pre-stimulus from average!',extra*eeg.sampling));
            end
            % Adjust end of time window
            extra=abs(lastEEG.nPoints-eeg.nPoints);
            if eeg.nPoints<lastEEG.nPoints           % this chan ends too late
              lastEEG.data=lastEEG.data(:,:,1:end-extra);
              lastEEG.nPoints=eeg.nPoints;
              disp(sprintf(' Warning: Trimmed %d ms post-stimulus from this channel!',extra*eeg.sampling));
            elseif eeg.nPoints>lastEEG.nPoints       % this chan ends too early
              eeg.data=eeg.data(:,:,1:end-extra);
              eeg.nPoints=lastEEG.nPoints;
              disp(sprintf(' Warning: Trimmed %d ms post-stimulus from average!',extra*eeg.sampling));
            end
          end
          % Calculate running total
          for b=1:lastEEG.nBins
            if ~strcmp(eeg.binNames{b},lastEEG.binNames{b})
              disp(sprintf(' Warning: bin name mismatch ("%s" vs. "%s" in "%s")!',...
                   eeg.binNames{b},lastEEG.binNames{b},dataFile));
            end
            eeg.data(b,1,:)=eeg.data(b,1,:)+lastEEG.data(b,chan,:);
          end
        end % eeg.nBins==0
      end %isempty(chan)
    end % badfile
  end % isempty(comma)
end

if bad>0
  disp(sprintf('%d channels were excluded!\n',bad));
end

% Calculate average
count=count-bad;
if count==0
  eeg=[];
elseif count>2
  for b=1:lastEEG.nBins
    eeg.data(b,1,:)=eeg.data(b,1,:)/count;
  end
end
if isempty(eeg)
  disp('0 channels averaged.');
else
  disp(sprintf('%d channels were averaged over time window %d to %d ms.\n',...
               count,-eeg.onset,(eeg.nPoints-1)*eeg.sampling-eeg.onset));
end

% Modification History:
%
% $Log: chanAvg.m,v $
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
% Revision 1.1  2002/10/08 23:46:46  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
%       Francis Favorini, 10/22/97.
%       Francis Favorini, 11/14/97.  Allows for different time windows and only averages overlap.
%       Francis Favorini, 12/01/97.  Allows shift (in ms) of waveform before averaging.
%                                    Fixed bug: was trimming too many pre-stimulus points.
%       Francis Favorini, 12/22/97.  Made case-insensitive.
