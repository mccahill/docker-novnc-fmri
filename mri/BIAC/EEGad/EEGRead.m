function EEG=EEGRead(file,nChannels,nPoints,sampling,uvunits,onset)
%EEGRead Read EEG data and header from data file.
%
%       The EEG data must be grouped as contiguous points (1 to nPoints),
%         then contiguous channels (1 to nChannels), then bins (1 to nBins).
%       Each point is a short (2-byte signed integer).
%
%       There are five variants of the calling sequence:
%
%         EEG=EEGRead(file);
%         EEG=EEGRead(file,nChannels,nPoints);
%         EEG=EEGRead(file,nChannels,nPoints,sampling);
%         EEG=EEGRead(file,nChannels,nPoints,sampling,uvunits);
%         EEG=EEGRead(file,nChannels,nPoints,sampling,uvunits,onset);
%
%       file is the name of the EEG data file.
%         If file is the only argument, there must be a header file (.HDR)
%         in the same directory as the EEG data file.
%       nChannels is the number of data channels (electrodes).
%         If nChannels is 0, only read the header.
%       nPoints is the number of data points collected per channel.
%       sampling is the sampling rate of the data points.  Defaults to 4 ms/point.
%       uvunits is the microvolt conversion factor.  Defaults to 10 units/microvolt.
%       onset is the stimulus onset from the first data point in ms.  Defaults to 100 ms.
%
%       EEG is a structure with the following fields:
%         expName is the experiment name
%         expDate is the experiment date string
%         nBins is the number of bins.
%         nChannels, nPoints, sampling, uvunits, onset are as above.
%         binNames is a cell array of bin names.
%         chanNames is a cell array of channel names.
%         coords is a matrix of electrode coordinates
%           with size [nChannels 2] or [nChannels 3].
%         data is the EEG data in a [nBins nChannels nPoints] matrix.
%         rawData is the raw EEG data in a [nBins nChannels nPoints] matrix when data has been filtered.

% CVS ID and authorship of this code
% CVSId = '$Id: EEGRead.m,v 1.5 2005/02/21 22:33:34 michelich Exp $';
% CVSRevision = '$Revision: 1.5 $';
% CVSDate = '$Date: 2005/02/21 22:33:34 $';
% CVSRCSFile = '$RCSfile: EEGRead.m,v $';

% Defaults
getHeader=0;
onlyHeader=0;
if nargin<2 | nChannels==0, getHeader=1; end
if nargin>1 & nChannels==0, onlyHeader=1; end

% Calculate data file size
EEGfid=fopen(file);
if EEGfid==-1
  error(['Couldn''t open data file "' file '"'])
end
fseek(EEGfid,0,'eof');
fsize=ftell(EEGfid);

% Read header file?
if ~getHeader
  if nargin<4, sampling=4; end
  if nargin<5, uvunits=10; end
  if nargin<6, onset=100; end
  EEG.expName='Experiment';
  EEG.expDate='Unknown Date';
  EEG.nBins=1;                    % Place holder
  EEG.nChannels=nChannels;
  EEG.nPoints=nPoints;
  EEG.sampling=sampling;
  EEG.uvunits=uvunits;
  EEG.onset=onset;
  EEG.nBins=fsize/(2*EEG.nPoints*EEG.nChannels);
  EEG.binNames=cell(EEG.nBins,1);
  for n=1:EEG.nBins, EEG.binNames{n}=sprintf('Bin %d',n); end
  EEG.chanNames=cell(EEG.nChannels,1);
  for n=1:EEG.nChannels, EEG.chanNames{n}=sprintf('Chan %d',n); end
  EEG.coords=[];
else
  dot=max(find(file=='.'));
  if isempty(dot), file=[file '.']; dot=length(file); end
  hdrfid=fopen([file(1:dot) 'hdr']);
  if hdrfid==-1
    fclose(EEGfid);
    error(['Couldn''t open header file "' file(1:dot) 'hdr"'])
  end

  % Read header info
  EEG.expName=fgetl(hdrfid);
  EEG.expDate=fgetl(hdrfid);
  EEG.nBins=1;                    % Place holder
  EEG.nChannels=str2num(fgetl(hdrfid));
  EEG.nPoints=str2num(fgetl(hdrfid));
  EEG.sampling=str2num(fgetl(hdrfid));
  EEG.uvunits=str2num(fgetl(hdrfid));
  EEG.onset=str2num(fgetl(hdrfid));

  % Check parameters
  if (isempty(EEG.nChannels) | EEG.nChannels<1 | round(EEG.nChannels)-EEG.nChannels~=0)
    fclose(EEGfid); fclose(hdrfid);
    error(['Invalid number of channels in "' file(1:dot) 'hdr"']);
  end
  if (isempty(EEG.nPoints) | EEG.nPoints<1 | round(EEG.nPoints)-EEG.nPoints~=0)
    fclose(EEGfid); fclose(hdrfid);
    error(['Invalid number of points in "' file(1:dot) 'hdr"']);
  end
  if (isempty(EEG.sampling) | EEG.sampling<=0)
    fclose(EEGfid); fclose(hdrfid);
    error(['Invalid sampling rate in "' file(1:dot) 'hdr"']);
  end
  if (isempty(EEG.uvunits) | EEG.uvunits<1)
    fclose(EEGfid); fclose(hdrfid);
    error(['Invalid microvolt conversion factor in "' file(1:dot) 'hdr"']);
  end
  if (isempty(EEG.onset) | EEG.onset<1 | mod(EEG.onset,EEG.sampling)~=0)
    fclose(EEGfid); fclose(hdrfid);
    error(['Invalid onset in "' file(1:dot) 'hdr"']);
  end

  % Calculate bins
  EEG.nBins=fsize/(2*EEG.nPoints*EEG.nChannels);
  if (EEG.nBins<1)
    fclose(EEGfid); fclose(hdrfid);
    error(['Invalid number of bins in "' file(1:dot) 'hdr"']);
  end

  % Read bin names
  [EEG.binNames count]=getstrs(hdrfid,EEG.nBins);
  if count~=EEG.nBins
    fclose(EEGfid); fclose(hdrfid);
    error(sprintf('Only %d of %d bin names present in "%shdr"',count,EEG.nBins,file(1:dot)));
  end
  EEG.binNames=deblank(EEG.binNames);

  % Read channel names
  [EEG.chanNames count]=getstrs(hdrfid,EEG.nChannels);
  if count~=EEG.nChannels
    fclose(EEGfid); fclose(hdrfid);
    error(sprintf('Only %d of %d channel names present in "%shdr"',count,EEG.nChannels,file(1:dot)));
  end
  EEG.chanNames=deblank(EEG.chanNames);

  % Read optional electrode coordinates
  EEG.coords=[];
  [coordStrs count]=getstrs(hdrfid,EEG.nChannels);
  if count>0
    if count~=EEG.nChannels
      fclose(EEGfid); fclose(hdrfid);
      error(sprintf('Only %d of %d electrode coordinates present in "%shdr"',count,EEG.nChannels,file(1:dot)));
    end
    [EEG.coords nDims]=sscanf(coordStrs{1},'%f',[1 inf]);
    line=7+EEG.nBins+EEG.nChannels+1;
    if nDims~=2 & nDims~=3
      fclose(EEGfid); fclose(hdrfid);
      error(sprintf('Line %d, %shdr: Found %d electrode coordinates (must be 2 or 3).',line,file(1:dot),nDims));
    end
    for c=2:EEG.nChannels
      [coord dim]=sscanf(coordStrs{c},'%f',[1 inf]);
      line=line+1;
      if dim~=nDims
        fclose(EEGfid); fclose(hdrfid);
        error(sprintf('Line %d, %shdr: Found %d electrode coordinates (expected %d).',line,file(1:dot),dim,nDims));
      end
      EEG.coords(c,:)=coord;
    end
  end

  fclose(hdrfid);
end

% Read EEG data, if requested
EEG.data=[];
EEG.rawData=[];
if ~onlyHeader
  fseek(EEGfid,0,'bof');
  EEG.data=fread(EEGfid,[EEG.nPoints EEG.nChannels*EEG.nBins],'short');
  EEG.data=reshape(EEG.data,EEG.nPoints,EEG.nChannels,EEG.nBins);
  EEG.data=permute(EEG.data,[3 2 1]);                        % Now data is a [nBins nChannels nPoints] array
end
fclose(EEGfid);

% Modification History:
%
% $Log: EEGRead.m,v $
% Revision 1.5  2005/02/21 22:33:34  michelich
% Fixed error message string.
%
% Revision 1.4  2005/02/03 16:58:18  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.3  2003/10/22 15:54:33  gadde
% Make some CVS info accessible through variables
%
% Revision 1.2  2003/09/15 16:44:36  michelich
% Changed getstrs() to lowercase
%
% Revision 1.1  2002/10/08 23:46:44  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Francis Favorini, 10/01/96.
% Francis Favorini, 02/19/97.  Added ability to read optional electrode
%                              coordinates from header file.
% Francis Favorini, 04/21/97.  Close file handles on errors.
%                              Allow floating point coords.
% Francis Favorini, 04/30/97.  Missed one close file handles on error.
% Francis Favorini, 06/12/97.  Now returns structure with 3-D array of data.
%                              Added more error checking of header file.
% Francis Favorini, 07/01/97.  Changed comments.
% Francis Favorini, 07/03/97.  Added rawData field.
% Francis Favorini, 12/08/97.  If nChannels is 0, only read header.
% Francis Favorini, 12/09/97.  Added file names to error messages.
