function outData=EEGBand(inData,lo,hi,beta)
%EEGBAND Apply bandpass Kaiser window filter to each channel of EEG data.
%
%       outData=EEGBAND(inData);
%       outData=EEGBAND(inData,lo,hi,beta);
%
%       inData is the EEG data in a [nBins nChannels nPoints] matrix.
%       outData is the filtered EEG data.

% CVS ID and authorship of this code
% CVSId = '$Id: EEGBand.m,v 1.3 2005/02/03 16:58:18 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:18 $';
% CVSRCSFile = '$RCSfile: EEGBand.m,v $';

order=50;
Fs=250;
if nargin<2
  lo=0.75;
else
  lo=varargin(2);
end
if nargin<3
  hi=20.5;
else
  hi=varargin(3);
end
if nargin<4
  beta=3.39532;
else
  beta=varargin(4);
end
a=1;
b=fir1(order,[lo hi]*2/Fs,kaiser(order+1,beta));
for bin=1:size(inData,1)
  for chan=1:size(inData,2)
    outData(bin,chan,:)=filtfilt(b,a,squeeze(inData(bin,chan,:)));
  end
end

% Modification History:
%
% $Log: EEGBand.m,v $
% Revision 1.3  2005/02/03 16:58:18  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:33  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/10/08 23:46:43  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Francis Favorini, 06/12/97.
% Francis Favorini, 07/24/97.  Operates on data instead of eeg structure.
% Francis Favorini, 08/19/97.  Spun off bandpass version from lowpass version.
