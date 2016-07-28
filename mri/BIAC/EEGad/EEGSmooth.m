function outData=EEGSmooth(inData)
%EEGSMOOTH Apply smoothing function (lowpass filter) to each channel of EEG data.
%
%       outData=EEGSMOOTH(inData);
%
%       inData is the EEG data in a [nBins nChannels nPoints] matrix.
%       outData is the filtered EEG data.

% CVS ID and authorship of this code
% CVSId = '$Id: EEGSmooth.m,v 1.3 2005/02/03 16:58:19 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:19 $';
% CVSRCSFile = '$RCSfile: EEGSmooth.m,v $';

order=50;
Fs=250;
Wp=20;
Ws=21;
beta=7.85726;
a=1;
b=fir1(order,(Wp+(Ws-Wp)/2)*2/Fs,kaiser(order+1,beta));
for bin=1:size(inData,1)
  for chan=1:size(inData,2)
    outData(bin,chan,:)=filtfilt(b,a,squeeze(inData(bin,chan,:)));
  end
end

% Modification History:
%
% $Log: EEGSmooth.m,v $
% Revision 1.3  2005/02/03 16:58:19  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:33  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/10/08 23:46:45  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Francis Favorini, 06/12/97.
% Francis Favorini, 07/24/97.  Operates on data instead of eeg structure.
