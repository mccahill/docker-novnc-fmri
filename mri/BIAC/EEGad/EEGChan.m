function EEGChan(chan,forceUpdate)
%EEGChan Sets first displayed channel on current EEG plot.
%
%       EEGChan(chan);
%
%       chan is a relative channel number.

% CVS ID and authorship of this code
% CVSId = '$Id: EEGChan.m,v 1.3 2005/02/03 16:58:18 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:18 $';
% CVSRCSFile = '$RCSfile: EEGChan.m,v $';

set(gcf,'Pointer','watch'); drawnow;

% Defaults
if nargin<1, chan=get(findobj(gcf,'Tag','showChannel'),'Value'); end
if nargin<2, forceUpdate=0; end

% Find EEG info
eeg=getfield(get(gcf,'UserData'),'eeg');
plots=getfield(get(gcf,'UserData'),'plots');
grid=getfield(get(gcf,'UserData'),'grid');
if length(plots)>eeg.nChannels, plots=plots(1:eeg.nChannels); end

% Build channels and bins
currChan=get(plots(1),'UserData');
chan=max(chan,1);
chan=min(chan,eeg.nChannels);
gLen=grid(1)*grid(2);
channels=[chan:chan+min(eeg.nChannels,gLen)-1];
tooFar=max(channels)-eeg.nChannels;
if tooFar>0
  channels=channels-tooFar;  % Don't display channels that don't exist
end
channels=chanMap(channels);
bins=[];
for b=findobj(plots(1),'Tag','bin')'
  bins=[bins; get(b,'UserData')];
end
bins=sort(bins)';

% Update channel data, if needed
if currChan~=channels(1) | forceUpdate
  EEGPlot(bins,channels);
elseif nargin==0
  % Reset channel popup menu
  rChan=find(channels(1)==chanMap(1:eeg.nChannels));            % Relative channel from actual
  set(findobj(gcf,'Tag','showChannel'),'Value',rChan);
end

set(gcf,'Pointer','arrow');
figure(gcf);

% Modification History:
%
% $Log: EEGChan.m,v $
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
% Francis Favorini, 10/15/96.
% Francis Favorini, 10/23/96.  Modified to use EEGPlot and chanMap.
% Francis Favorini, 10/25/96.  Bug fix when all nChannels<gLen.
%                              Only update data when actually change channel.
% Francis Favorini, 11/01/96.  Changed to use Channels menu.
% Francis Favorini, 11/08/96.  Changed back to popup, temporarily.
% Francis Favorini, 01/29/97.  MATLAB 5 compliance.
% Francis Favorini, 07/02/97.  Changed to use eeg structure.
