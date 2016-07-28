function neuro2eegad(expName,fileSpec,outName)
%NEURO2EEGAD Convert Neuroscan average (.AVG) files to EEGAD format.
%
%   eeg=neuro2eegad(expName,fileSpec);
%   eeg=neuro2eegad(expName,fileSpec,outName);
%
%   expName is the name of the experiment.
%   fileSpec specifies the files to convert.
%   outName is the file name for the converted output.
%
%   All files matching fileSpec will be combined into one EEGAD file,
%     with each input file corresponding to one bin in the output file.
%
%   Example:
%      neuro2eegad('Multi-modal negativity','D:\MMN\CP*.AVG','\\Broca\Data\ERPs\MMN\CP.AVG');

% CVS ID and authorship of this code
% CVSId = '$Id: neuro2eegad.m,v 1.3 2005/02/03 16:58:20 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:20 $';
% CVSRCSFile = '$RCSfile: neuro2eegad.m,v $';

error(nargchk(3,3,nargin));
lasterr('');
emsg='';
try
  
neurofid=[];
  
% Get files to convert
d=dir(fileSpec);
if isempty(d), emsg=sprintf('Unable to find any files that match %s!',runSpec); error(emsg); end
[fNames I]=sort({d.name}');
d=d(I);
if exist(fileSpec,'dir')
  inPath=fileSpec;
elseif exist(fileSpec,'file')==2
  [inPath name ext]=fileparts(fileSpec);
  fNames={[name ext]};
else
  inPath=fileparts(fileSpec);
end
% Remove . and .., if present
fNames(strcmp(fNames,'.'))=[];
fNames(strcmp(fNames,'..'))=[];

% Loop through files to convert
for f=1:length(fNames)
  fprintf('%s: ',fNames{f});
  neurofid=fopen(fullfile(inPath,fNames{f}),'r');
  fileSize=d(f).bytes;
  % Create EEGAD EEG header from Neuroscan SETUP header
  fseek(neurofid,20,'bof');
  type=fread(neurofid,1,'uchar');
  switch type
    case 2, dataSize=4; dataType='float32';
    case 3, dataSize=4; dataType='float32';
    otherwise, emsg=sprintf('Unhandled Neuroscan data type: %d',type); error(emsg);
  end
  fseek(neurofid,375,'bof');
  varIncl=fread(neurofid,1,'uchar');  % Variance data appended to regular data (see note below)
  if varIncl~=0 & varIncl~=1
    emsg=sprintf('Invalid value for variance included flag: %d',varIncl); error(emsg);
  end
  if f==1
    eeg.expName=expName;
    fseek(neurofid,225,'bof');
    date=trim(char(fread(neurofid,10,'char')'));
    time=trim(char(fread(neurofid,12,'char')'));
    eeg.expDate=[date ' ' time];
    eeg.nBins=length(fNames);
  end
  fseek(neurofid,368,'bof');
  nPoints=fread(neurofid,1,'int16');
  fprintf('%d pts',nPoints);
  if f==1
    eeg.nPoints=nPoints;
  elseif eeg.nPoints~=nPoints
    emsg=sprintf('Number of points is not the same for all files!'); error(emsg);
  end
  fseek(neurofid,370,'bof');
  nChannels=fread(neurofid,1,'int16');
  fprintf(', %d chans',nChannels);
  if f==1
    eeg.nChannels=nChannels;
  elseif eeg.nChannels~=nChannels
    emsg=sprintf('Number of channels is not the same for all files!'); error(emsg);
  end
  if eeg.nPoints~=((fileSize-900-eeg.nChannels*75)/eeg.nChannels-5)/dataSize/(varIncl+1)
    emsg=sprintf('Number of points/channels given in header is not consistent with file size!'); error(emsg);
  end
  fseek(neurofid,505,'bof');
  start=round(fread(neurofid,1,'float32')*1000);   % Convert from secs to ms
  stop=round(fread(neurofid,1,'float32')*1000);    % Convert from secs to ms
  duration=stop-start;                             % Duration in ms
  fprintf(', %d to %d ms',start,stop);
  if f==1
    eeg.sampling=duration/eeg.nPoints;             % Sampling rate in ms/pts
    eeg.uvunits=10;   % When we read the data, we will scale it to this factor
    eeg.onset=-start;
  else
    if eeg.sampling~=duration/eeg.nPoints
      emsg=sprintf('Sampling rate is not the same for all files!'); error(emsg);
    end
    if eeg.onset~=-start
      emsg=sprintf('Stimulus onset is not the same for all files!'); error(emsg);
    end
  end
  % Use file name for bin name
  [junk eeg.binNames{f}]=fileparts(fNames{f});
  % Get channel names
  lastSweeps=[];
  lastCalib=[];
  if f==1
    eeg.chanNames=cell(eeg.nChannels,1);
  end
  fseek(neurofid,900,'bof');
  for chan=1:eeg.nChannels
    chanName=trim(char(fread(neurofid,10,'char')'));
    if f==1
      eeg.chanNames{chan}=chanName;
    elseif ~strcmp(eeg.chanNames{chan},chanName)
      emsg=sprintf('Channel names are not the same for all files!'); error(emsg);
    end
    fseek(neurofid,5,'cof');
    sweeps=fread(neurofid,1,'int16');
    fseek(neurofid,54,'cof');
    calib=fread(neurofid,1,'float32');
    if ~isempty(lastSweeps) & lastSweeps~=sweeps
      emsg=sprintf('Number of sweeps is not the same for each channel!'); error(emsg);
    end
    if ~isempty(lastCalib) & lastCalib~=calib
      emsg=sprintf('Calibration coefficient is not the same for each channel!'); error(emsg);
    end
    fseek(neurofid,900+chan*75,'bof');             % Skip to next channel
  end
  fprintf(', %4d sweeps, %.1f calib. coeff.\n',sweeps,calib);
  % Get EEG data
  if f==1
    eeg.coords=[];
    eeg.data=zeros(eeg.nBins,eeg.nChannels,eeg.nPoints);
    eeg.rawData=[];
  end
  for chan=1:eeg.nChannels
    fseek(neurofid,5,'cof');                     % Skip obsolete header
    eeg.data(f,chan,:)=fread(neurofid,eeg.nPoints,dataType)*calib/sweeps*eeg.uvunits;
  end
  % Note: If variance data is included, it is appended here after the regular data,
  %       and it doesn't have the 5-byte obsolete header before each channel.
  % Clean up
  fclose(neurofid); neurofid=[];
end

% Write data
fprintf('Writing %s...',outName);
EEGWrite(eeg,outName);
fprintf('Done.\n');
if nargout>0, eegOut=eeg; end

catch
  if ~isempty(neurofid)
    fclose(neurofid);
  end
  if isempty(emsg)
    if isempty(lasterr)
      emsg='An unidentified error occurred!';
    else
      emsg=lasterr;
    end
  end
  fprintf('\n');
  error(emsg);
end

% Modification History:
%
% $Log: neuro2eegad.m,v $
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
% Francis Favorini, 01/07/99.