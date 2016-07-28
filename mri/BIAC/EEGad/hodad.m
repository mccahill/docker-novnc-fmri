function out=hodad(inFile,varargin)
%HODAD  Read EEG data files, measure the waveform peaks, and display or output to file.
%
%       out=hodad(inFile,outFile,priWin,filter);
%       out=hodad(inFile,chans,bins,x,y,priWin,filter);
%
%       inFile is either the name of a .TXT file with a list of data files
%         or the name of a data file
%         or an EEG data structure.
%       outFile is the name of an output file to put measurements in.
%       chans is a vector of channel numbers to show.  Default is all.
%       bins is a vector of bin numbers to show.  Default is all.
%       x and y define the grid of plots.  Default is 1 x 1.
%       priWin is the primary window's absolute latency range in ms.
%         Default is [90 350].
%       filter is one of the following:
%         'low' to apply a lowpass filter (EEGSmooth) before measuring,
%         'band' to apply a bandpass filter (EEGBand) before measuring,
%         'raw' to apply no filter before measuring.
%         Default is 'low'.
%
%       out is the EEG data structure of the (last) data file processed.

% CVS ID and authorship of this code
% CVSId = '$Id: hodad.m,v 1.4 2005/02/03 16:58:20 michelich Exp $';
% CVSRevision = '$Revision: 1.4 $';
% CVSDate = '$Date: 2005/02/03 16:58:20 $';
% CVSRCSFile = '$RCSfile: hodad.m,v $';

if nargin<1 | nargin>7
  error('Incorrect number of input arguments.  Type help hodad.');
end
if nargout>1
  error('Incorrect number of output arguments.  Type help hodad.');
end

% Define windows
baseWin=[-100 50];       % Baseline window absolute latency in ms
priWin=[90 350];         % Primary window absolute latency in ms
prefMargin=[-40 40];     % Preferred margin relative to primary trough in ms
secMargin=[-100 100];    % Secondary margin relative to primary trough in ms
peakMargin=[-50 50];     % Peak window margin relative to primary window in ms

% Process arguments
outFile=[];
chans=[];
bins=[];
x=1; y=1;
filter='low';
if ischar(inFile) & findstr(upper(inFile),'.TXT')
  % Get data files from list file
  listFid=fopen(inFile,'rt');
  if listFid==-1
    error(['Couldn''t open list file "' inFile '"'])
  end
  [lines,count]=getstrs(listFid);
  fclose(listFid);
else
  if ischar(inFile)  % inFile is a data file
    lines={inFile};
    count=1;
  else               % inFile is an eeg structure
    eeg=inFile;
    lines=[];
    count=1;
  end
end

if nargin>1 & ischar(varargin{1})
  % Create output file for measurements
  outFile=varargin{1};
  outFid=fopen(outFile,'r');
  if outFid~=-1
    fclose(outFid);
    error(['Output file "' outFile '" already exists!'])
  end
  outFid=fopen(outFile,'wt');
  if outFid==-1
    error(['Couldn''t create output file "' outFile '"'])
  end
  if nargin>2 & ~isempty(varargin{2}), priWin=varargin{2}; end
  if ~isnumeric(priWin) | length(priWin)~=2 | priWin(1)>=priWin(2)
    error(['Invalid primary window [' num2str(priWin) ']']);
  end
  if nargin>3 & ~isempty(varargin{3}), filter=lower(varargin{3}); end
  if ~ischar(filter) | isempty(strmatch(filter,{'low' 'band' 'raw'},'exact'))
    error(['Unrecognized filter type "' filter '"']);
  end
else
  % Create axes for displaying data
  if nargin>1 & ~isempty(varargin{1}), chans=varargin{1}; end
  if nargin>2 & ~isempty(varargin{2}), bins=varargin{2}; end
  if nargin>3 & ~isempty(varargin{3}), x=varargin{3}; end
  if nargin>4 & ~isempty(varargin{4}), y=varargin{4}; end
  if nargin>5 & ~isempty(varargin{5}), priWin=varargin{5}; end
  if ~isnumeric(priWin) | length(priWin)~=2 | priWin(1)>=priWin(2)
    error(['Invalid primary window [' num2str(priWin) ']']);
  end
  if nargin>6 & ~isempty(varargin{6}), filter=lower(varargin{6}); end
  if ~ischar(filter) | isempty(strmatch(filter,{'low' 'band' 'raw'},'exact'))
    error(['Unrecognized filter type "' filter '"']);
  end
  binColors=[1 0 0;0 1 0;1 0 1;0 1 1;1 0.5 0;0 0.25 1;0.5 0 0;0.5 0 1;0.5 0.5 0;1 1 1];
  clf
  axes('Position',[0 0 0.01 0.01],'Tag','plots','Visible','off');
  set(gcf,'UserData',[]);
  EEGSub(x,y);
  plots=getfield(get(gcf,'UserData'),'plots');
  set(plots,'vis','on');
end

% Define peak window within margin of primary window (don't go earlier than 75 ms)
peakWin=priWin+peakMargin;
if peakWin(1)<75, peakWin(1)=75; end

% Measure data files
disp(sprintf('Measuring %d files:',count));
disp(sprintf('Primary window: %d - %d ms',priWin(1),priWin(2)));
disp(sprintf('Filter type: %s',filter));
for n=1:count
  dataFile='EEG';
  newBins=[];
  if ~isempty(lines)
    % Process line from list file
    s=upper(lines{n});
    dataFile=sscanf(s,'%s',1);
    binMapFile=sscanf(s(length(dataFile)+1:end),'%s',1);
    
    % Check for bin-mapping file
    if isempty(binMapFile)
      disp(sprintf('%d: %s',n,dataFile));
    else
      % Process bin-mapping file
      binFid=fopen(binMapFile,'rt');
      if binFid==-1
        if ~isempty(outFile), fclose(outFid); end
        error(['Couldn''t open bin-mapping file "' binMapFile '"'])
      end
      newBins=getstrs(binFid);
      fclose(binFid);
      disp(sprintf('%d: %s (mapping bins with %s)',n,dataFile,binMapFile));
    end
    
    % Read data file
    eeg=eegread(dataFile);
    
    % If not displaying data, measure all bins and channels
    if ~isempty(outFile)
      chans=[];
      bins=[];
    end
  end

  % Subtract mean of data baseline
  time=([0:eeg.nPoints-1]*eeg.sampling)-eeg.onset;
  pt1=find(time>=baseWin(1) & time<=baseWin(2));
  pt2=pt1(end);
  pt1=pt1(1);
  m=mean(eeg.data(:,:,pt1:pt2),3);
  m=repmat(m,[1 1 eeg.nPoints]);
  eeg.data=eeg.data-m;
  
  % Apply filter
  out=eeg;
  if strcmp(filter,'low')
    out.data=EEGSmooth(eeg.data);    % Lowpass filter
  elseif strcmp(filter,'band')
    out.data=EEGBand(eeg.data);      % Bandpass filter
  else
    out.data=eeg.data;
  end
  
  % Process each waveform
  letterWarn=0;
  if isempty(chans), chans=1:out.nChannels; end
  if isempty(bins), bins=1:out.nBins; end
  if isempty(outFile), chans=chans(1:x*y); end
  for chan=chans
    if isempty(outFile)
      axes(plots(chan==chans));
      cla, hold on
      title(out.chanNames(chan));
    end

    % Find primary trough (most negative trough across all bins for this channel)
    priTrough=[];
    for bin=1:out.nBins
      amp=squeeze(out.data(bin,chan,:)/out.uvunits);
      troughs=findpeaks(-amp);
      troughs=troughs(time(troughs)>=priWin(1) & time(troughs)<=priWin(2));
      binTroughs{bin}=troughs;
      if ~isempty(troughs)
        minTrough=troughs(min(amp(troughs))==amp(troughs)); % Most negative trough
        minTrough=minTrough(1);                       % Take the first one, just in case
        if isempty(priTrough) | amp(minTrough)<priTrough.amp
          priTrough.bin=bin;
          priTrough.point=minTrough;
          priTrough.amp=amp(priTrough.point);
        end
      end
    end % bin
    if isempty(priTrough)                             % No troughs found in any bin
      priTrough.bin=1;                                % Arbitrary
      priTrough.point=min(find(time>=mean(priWin)));  % Mid-point of primary window
      priTrough.amp=amp(priTrough.point);
    end
    
    % Define preferred & secondary windows (within primary window & margin of primary trough)
    prefWin=[max([priWin(1) time(priTrough.point)+prefMargin(1)])...
             min([priWin(2) time(priTrough.point)+prefMargin(2)])];
    secWin=[max([priWin(1) time(priTrough.point)+secMargin(1)])...
            min([priWin(2) time(priTrough.point)+secMargin(2)])];

    % Identify secondary troughs and peaks
    for bin=bins
      % Limit peaks to peak window and troughs to secondary/preferred window
      amp=squeeze(out.data(bin,chan,:)/out.uvunits);
      peaks=findpeaks(amp);
      peaks=peaks(time(peaks)>=peakWin(1) & time(peaks)<=peakWin(2));
      troughs=binTroughs{bin};
      troughs=troughs(time(troughs)>=secWin(1) & time(troughs)<=secWin(2));
      if isempty(troughs)                             % No troughs found in this bin
        troughs=priTrough.point;                      % Use primary trough latency  
      else  
        % Check for troughs in preferred window
        prefTroughs=troughs(time(troughs)>=prefWin(1) & time(troughs)<=prefWin(2));
        if ~isempty(prefTroughs)
          troughs=prefTroughs;                        % Restrict to preferred window
        end
      end

      % Include points at each end of peak window, in case peaks are not found
      points=find(time>=peakWin(1) & time<=peakWin(2));
      if isempty(peaks) | points(1)<peaks(1)
        peaks=[points(1) peaks];                  % Add first point in peak window
      end
      if points(end)>peaks(end)
        peaks=[peaks points(end)];                % Add last point in peak window
      end
      p1=max(find(time(peaks)<time(troughs(1)))); % Peak immediately before first trough
      peaks=peaks(p1:p1+length(troughs));         % Remove extra peaks

      % Find deepest trough within secondary/preferred window
      if bin==priTrough.bin
        deepest=priTrough.point;                  % Just use primary trough
      else
        depths=amp(peaks(1:end-1))-amp(troughs);  % Depth from peak to trough
        deepest=troughs(max(depths)==depths);     % Deepest trough
        deepest=deepest(1);                       % Take the first one, just in case
      end

      % Find peaks surrounding deepest trough
      prePeak=peaks(troughs==deepest);            % Peak just before deepest trough
      postPeak=peaks(find(troughs==deepest)+1);   % Peak just after deepest trough

      % Display data or output to file
      if isempty(outFile)
        % Plot measurements
        plot(time,amp,'color',binColors(bin,:));
        plot(time(troughs),amp(troughs),'color',binColors(bin,:),'marker','+','linestyle','none');
        plot(time(peaks),amp(peaks),'color',binColors(bin,:),'marker','+','linestyle','none');
        if bin==priTrough.bin, style='yv'; else style='wo'; end
        plot(time(deepest),amp(deepest),style);
        plot(time([prePeak postPeak]),amp([prePeak postPeak]),'bs');

        % Plot windows
        plot([priWin(1) priWin(1)],get(gca,'YLim'),'y');
        plot([priWin(2) priWin(2)],get(gca,'YLim'),'y');
        plot([prefWin(1) prefWin(1)],get(gca,'YLim'),'y:');
        plot([prefWin(2) prefWin(2)],get(gca,'YLim'),'y:');
        plot([secWin(1) secWin(1)],get(gca,'YLim'),'w--');
        plot([secWin(2) secWin(2)],get(gca,'YLim'),'w--');
        plot([peakWin(1) peakWin(1)],get(gca,'YLim'),'b');
        plot([peakWin(2) peakWin(2)],get(gca,'YLim'),'b');
      else
        % Extract patient letter code from filename
        letterCode='???';
        bs=findstr(dataFile,'\');
        if length(bs)<2
          if ~letterWarn
            disp('  Warning: Couldn''t generate letter code.');
            letterWarn=1;
          end
        else
          letterCode=dataFile(bs(end-1)+1:bs(end)-1);    % Look between last two backslashes
        end
        
        % Remap to new bin names, if any
        if isempty(newBins)
          binName=out.binNames{bin};
        else
          binName=newBins{bin};
        end
        % Collapse n spaces to 1 in channel name
        chanName=out.chanNames{chan};
        while ~isempty(findstr(chanName,'  '))
          chanName=strrep(chanName,'  ',' ');
        end
        % Output file/bin/channel and measurements
        fprintf(outFid,'%s\t%s\t%d\t%s\t%d\t%s',letterCode,dataFile,bin,binName,chan,chanName);
        fprintf(outFid,'\t%d\t%.2f',time(deepest),amp(deepest));
        fprintf(outFid,'\t%d\t%.2f',time(prePeak),amp(prePeak));
        fprintf(outFid,'\t%d\t%.2f\n',time(postPeak),amp(postPeak));
      end
    end % bin
  end % chan
end % n

if ~isempty(outFile), fclose(outFid); end
if nargout<1, clear out; end

% Modification History:
%
% $Log: hodad.m,v $
% Revision 1.4  2005/02/03 16:58:20  michelich
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
% Francis Favorini, 06/13/97.
% Francis Favorini, 06/16/97.  Added ability to remap bin names.
% Francis Favorini, 06/17/97.  Widened window for negativities.
%                              Spun off new primary/secondary window version.
% Francis Favorini, 06/18/97.  Added preferred window and handle no trough cases.
%                              Combined viewer and measurer.
% Francis Favorini, 06/19/97.  Handle no peaks case.
%                              Measure all channels and bins when outputting to file.
% Francis Favorini, 06/26/97.  Output letter code.
%                              Collapse spaces in channel name.
% Francis Favorini, 07/03/97.  Use plots field of UserData.
% Francis Favorini, 07/24/97.  Changed to use EEGSmooth.
% Francis Favorini, 08/13/97.  Only warn once per file about letter code.
%                              Fixed bug with choosing the wrong mid-point of primary window
%                              for primary trough, when there aren't any troughs.
% Francis Favorini, 08/19/97.  Added filter parameter.
% Francis Favorini, 10/22/97.  Displays primary window.  Added priWin parameter.
% Francis Favorini, 02/04/98.  Bugfix: used wrong peakWin when priWin is a parameter.
%                              Bugfix: now handles passing EEG structure & output file.
