function eeg=EEGFilt(filt,varargin)
%EEGFilt Apply filter specified in filt to EEG data.
%	
%       eeg=EEGFilt(filt);
%       eeg=EEGFilt(filt,args...);
%
%       filt is a string containing the name of the filter function to apply to
%         each channel in data.  The filter must take a 3-D matrix and
%         return a filtered matrix of the same size.  It should operate on
%         the third dimension.  It may optionally take arguments following the
%         input matrix.
%       args are any arguments to be passed to the filter function.
%
%       eeg is a structure with the filtered EEG data.

% CVS ID and authorship of this code
% CVSId = '$Id: EEGFilt.m,v 1.3 2005/02/03 16:58:18 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:18 $';
% CVSRCSFile = '$RCSfile: EEGFilt.m,v $';

% Defaults
if nargin<2, args=[]; end

% Find EEG info
eeg=getfield(get(gcf,'UserData'),'eeg');

% Save raw data, if haven't already
if isempty(eeg.rawData)
  eeg.rawData=eeg.data;
end

% Filter data
eeg.data=feval(filt,eeg.data,varargin{:});
%for bin=1:eeg.nBins
%  for chan=1:eeg.nChannels
%    waveform=squeeze(eeg.data(bin,chan,:));
%    if isempty(args)
%      evalStr=[filt '(waveform)'];
%    else
%      evalStr=[filt '(waveform,' args ')'];
%    end
%    eeg.data(bin,chan,:)=eval(evalStr);
%  end
%end
set(gcf,'UserData',setfield(get(gcf,'UserData'),'eeg',eeg));

% Plot data
EEGPlot;

% Modification History:
%
% $Log: EEGFilt.m,v $
% Revision 1.3  2005/02/03 16:58:18  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:33  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/10/08 23:46:44  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Francis Favorini, 10/03/96.
% Francis Favorini, 10/23/96.  Modified to get EEG info using findobj.
% Francis Favorini, 07/02/97.  Changed to use eeg structure.
% Francis Favorini, 07/22/97.  Testing new vectorized version.
