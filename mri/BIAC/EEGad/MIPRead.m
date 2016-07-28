function MIP=MIPRead(file)
%MIPRead Read EEG data and header from data file created by MIP for Windows.
%
%   MIP=MIPRead(file);
%
%   file is the name of the MIP EEG data file.
%
%   MIP is a structure with many fields including the following:
%     nChannels is the number of data channels (electrodes),
%       not including the digital channel.
%     nPoints is the number of data points collected per channel.
%     data is the EEG data in a [nChannels+1 nPoints] matrix.
%       The last row contains the digital channel.

% CVS ID and authorship of this code
% CVSId = '$Id: MIPRead.m,v 1.4 2005/02/21 23:32:46 michelich Exp $';
% CVSRevision = '$Revision: 1.4 $';
% CVSDate = '$Date: 2005/02/21 23:32:46 $';
% CVSRCSFile = '$RCSfile: MIPRead.m,v $';

%TODO: Fix header string decoding

% Defaults and consants
MIPhSz=8088;                   % Header size
MIPsig=10706671;               % Header signature
MIPver=11;                     % Header version
MIPdSig=1152444886;            % Design parameters signature
MIPcSig=1051667;               % Calibration parameters signature
MIPmaxChans=128;               % Max possible channels
MIPmaxBins=32;                 % Max possible bins (for montage info)

% Calculate data file size
EEGfid=fopen(file);
if EEGfid==-1
  error(['Couldn''t open data file "' file '"'])
end
fseek(EEGfid,0,'eof');
fsize=ftell(EEGfid);
fseek(EEGfid,0,'bof');

% Read header info (0:8087=8088 bytes)
MIP.sig=fread(EEGfid,1,'int32');                                        % 0
fread(EEGfid,4,'uchar');                                                % 4
if MIP.sig~=MIPsig
  error(['"' file '" is not a MIP EEG file!'])
end
MIP.ver=fread(EEGfid,1,'float64');                                      % 8
if MIP.ver~=MIPver
  error(['Unrecognized header version in "' file '"!'])
end
MIP.hdrLen=fread(EEGfid,1,'int32');                                     % 16
MIP.dataStart=fread(EEGfid,1,'int32');                                  % 20
MIP.dataFooter=fread(EEGfid,1,'uint32');                                % 24
fread(EEGfid,4,'uchar');                                                % 28
% MIP.DAPinfo (32:263=232 bytes)
MIP.DAPinfo.minChanSep=fread(EEGfid,1,'float64');                       % 32
MIP.DAPinfo.it=fread(EEGfid,1,'float64');                               % 40
MIP.DAPinfo.ot=fread(EEGfid,1,'float64');                               % 48
MIP.DAPinfo.incr=fread(EEGfid,1,'float64');                             % 56
MIP.DAPinfo.oma=fread(EEGfid,1,'float64');                              % 64
MIP.DAPinfo.sioa=fread(EEGfid,1,'float64');                             % 72
MIP.DAPinfo.DAPname=sprintf('%s',char(fread(EEGfid,[1 20],'uchar')));   % 80
MIP.DAPinfo.sysName=sprintf('%s',char(fread(EEGfid,[1 20],'uchar')));   % 100
MIP.DAPinfo.maxVolt=fread(EEGfid,1,'float64');                          % 120
MIP.DAPinfo.minVolt=fread(EEGfid,1,'float64');                          % 128
MIP.DAPinfo.voltGrads=fread(EEGfid,1,'int32');                          % 136
MIP.DAPinfo.DAPchannels=fread(EEGfid,1,'int32');                        % 140
MIP.DAPinfo.timeVal=fread(EEGfid,1,'float64');                          % 144
MIP.DAPinfo.digGrads=fread(EEGfid,1,'int32');                           % 152
MIP.DAPinfo.ic=fread(EEGfid,1,'int32');                                 % 156
MIP.DAPinfo.dc=fread(EEGfid,1,'int32');                                 % 160
MIP.DAPinfo.nc=fread(EEGfid,1,'int32');                                 % 164
MIP.DAPinfo.dtaddr=fread(EEGfid,1,'int32');                             % 168
MIP.DAPinfo.nataddr=fread(EEGfid,1,'int32');                            % 172
MIP.DAPinfo.clockNum=fread(EEGfid,1,'int32');                           % 176
MIP.DAPinfo.andMask=fread(EEGfid,1,'int32');                            % 180
MIP.DAPinfo.orMask=fread(EEGfid,1,'int32');                             % 184
MIP.DAPinfo.xorMask=fread(EEGfid,1,'int32');                            % 188
MIP.DAPinfo.aScale=fread(EEGfid,1,'float64');                           % 192
MIP.DAPinfo.dScale=fread(EEGfid,1,'float64');                           % 200
MIP.DAPinfo.digTxt=fread(EEGfid,1,'uchar');                             % 208
fread(EEGfid,7,'uchar');                                                % 209
MIP.DAPinfo.calUVolt=fread(EEGfid,1,'float64');                         % 216
MIP.DAPinfo.testFreq=fread(EEGfid,1,'float64');                         % 224
MIP.DAPinfo.calFreq=fread(EEGfid,1,'float64');                          % 232
MIP.DAPinfo.natType=sprintf('%s',char(fread(EEGfid,[1 10],'uchar')));   % 240
fread(EEGfid,2,'uchar');                                                % 250
MIP.DAPinfo.readCodes=fread(EEGfid,1,'int32');                          % 252
MIP.DAPinfo.compressCodes=fread(EEGfid,1,'int32');                      % 256
fread(EEGfid,4,'uchar');                                                % 260
% MIP.design (264:2951=2688 bytes)
MIP.design.sig=fread(EEGfid,1,'int32');                                 % 264
if MIP.design.sig~=MIPdSig
  error(['Unrecognized design header in "' file '"!'])
end
MIP.design.seconds=fread(EEGfid,1,'int32');                             % 268
MIP.design.expand=fread(EEGfid,1,'int16');                              % 272
fread(EEGfid,6,'uchar');                                                % 274
MIP.design.freq=fread(EEGfid,1,'float64');                              % 280
MIP.design.idleFreq=fread(EEGfid,1,'float64');                          % 288
MIP.design.oneFreq=fread(EEGfid,1,'float64');                           % 296
MIP.design.logName=sprintf('%s',char(fread(EEGfid,[1 9],'uchar')));     % 304
MIP.design.logExt=sprintf('%s',char(fread(EEGfid,[1 4],'uchar')));      % 313
fread(EEGfid,3,'uchar');                                                % 317
MIP.design.channels=fread(EEGfid,[1 MIPmaxChans],'int32');              % 320
MIP.design.prePts=fread(EEGfid,1,'int32');                              % 832
MIP.design.postPts=fread(EEGfid,1,'int32');                             % 836
MIP.design.binCodes=fread(EEGfid,[1 MIPmaxBins],'uint32');              % 840
MIP.design.binNums=fread(EEGfid,[1 MIPmaxBins],'uint32');               % 968
for n=1:MIPmaxChans                                                     % 1096
  MIP.design.montLabels{n}=sprintf('%s',char(fread(EEGfid,[1 10],'uchar')));
end
MIP.design.montLabels=char(MIP.design.montLabels);
MIP.design.montChans=fread(EEGfid,[1 MIPmaxChans],'int32');             % 2376
MIP.design.montName=sprintf('%s',char(fread(EEGfid,[1 61],'uchar')));   % 2888
MIP.design.avgMode=char(fread(EEGfid,1,'uchar'));                       % 2949
fread(EEGfid,2,'uchar');                                                % 2950
% MIP.runInfo (2952:3399=448 bytes)
MIP.runInfo.time=sprintf('%s',char(fread(EEGfid,[1 26],'uchar')));      % 2952
MIP.runInfo.op=sprintf('%s',char(fread(EEGfid,[1 60],'uchar')));        % 2978
MIP.runInfo.subject=sprintf('%s',char(fread(EEGfid,[1 60],'uchar')));   % 3038
MIP.runInfo.control=sprintf('%s',char(fread(EEGfid,[1 60],'uchar')));   % 3098
for n=1:4                                                               % 3158
  MIP.runInfo.comments{n}=sprintf('%s',char(fread(EEGfid,[1 60],'uchar')));
end
MIP.runInfo.comments=char(MIP.runInfo.comments);
fread(EEGfid,2,'uchar');                                                % 3398
% MIP.calInfo (3400:6039=2640 bytes)
MIP.calInfo.sig=fread(EEGfid,1,'int32');                                % 3400
if MIP.calInfo.sig~=MIPcSig
  error(['Unrecognized calibration header in "' file '"!'])
end
MIP.calInfo.time=sprintf('%s',char(fread(EEGfid,[1 26],'uchar')));      % 3404
fread(EEGfid,2,'uchar');                                                % 3430
MIP.calInfo.nChannels=fread(EEGfid,1,'int32');                          % 3432
MIP.calInfo.channels=fread(EEGfid,[1 MIPmaxChans],'int32');             % 3436
fread(EEGfid,4,'uchar');                                                % 3440
MIP.calInfo.base=fread(EEGfid,[1 MIPmaxChans],'float64');               % 3952
MIP.calInfo.pp=fread(EEGfid,[1 MIPmaxChans],'float64');                 % 4976
MIP.calInfo.uVolts=fread(EEGfid,1,'float64');                           % 6000
MIP.calInfo.voltGrads=fread(EEGfid,1,'int32');                          % 6008
fread(EEGfid,4,'uchar');                                                % 6012
MIP.calInfo.ppv=fread(EEGfid,1,'float64');                              % 6016
MIP.calInfo.freq=fread(EEGfid,1,'float64');                             % 6024
MIP.calInfo.avgVals=fread(EEGfid,1,'int32');                            % 6032
% No need to read final header padding
%fread(EEGfid,4,'uchar');                                                % 6036
% unused space (6040:8087=2048 bytes))
%fread(EEGfid,2048,'uchar');                                             % 6040

% Check parameters
if (isempty(MIP.hdrLen) | MIP.hdrLen~=MIPhSz)
  fclose(EEGfid);
  error(['Invalid header length in "' file '"']);
end
if (isempty(MIP.dataStart) | MIP.dataStart~=MIP.hdrLen)
  fclose(EEGfid);
  error(['Invalid pointer to data start in "' file '"']);
end
if (isempty(MIP.dataFooter) | MIP.dataFooter<MIP.hdrLen | MIP.dataFooter>fsize)
  fclose(EEGfid);
  error(['Invalid data length in "' file '"']);
end

% Calculate number of channels and points
MIP.nChannels=length(find(MIP.design.channels));
MIP.nPoints=(MIP.dataFooter-MIP.dataStart)./(MIP.nChannels+1)./2;

% Read EEG data
MIP.data=[];
fseek(EEGfid,MIP.dataStart,'bof');
MIP.data=fread(EEGfid,[MIP.nChannels+1 MIP.nPoints],'int16');
fclose(EEGfid);

% Modification History:
%
% $Log: MIPRead.m,v $
% Revision 1.4  2005/02/21 23:32:46  michelich
% Changes by Charles Michelich & Francis Favorini:
% Remove garbage after null terminated strings.
% Cast uchars to chars when using sprintf to address MATLAB 7 warning.
%
% Revision 1.3  2005/02/03 16:58:19  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:34  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/10/08 23:46:45  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Francis Favorini, 06/15/01.
