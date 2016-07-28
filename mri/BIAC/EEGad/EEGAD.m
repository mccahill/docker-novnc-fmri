function EEGAD(varargin)
%EEGAD  Read in and display an EEG file.
%
%       EEGAD;
%       EEGAD(fname);
%       EEGAD(eeg);
%       EEGAD(grid);
%       EEGAD(fname,grid);
%       EEGAD(eeg,grid);
%
%       fname is the name of an EEG data file.
%       eeg is an EEG data structure (see EEGRead).
%         If you don't supply fname or eeg, you are prompted for a filename.
%       grid is [rows cols].  If grid is omitted, all channels are displayed.

% CVS ID and authorship of this code
% CVSId = '$Id: EEGAD.m,v 1.4 2005/02/03 20:17:40 michelich Exp $';
% CVSRevision = '$Revision: 1.4 $';
% CVSDate = '$Date: 2005/02/03 20:17:40 $';
% CVSRCSFile = '$RCSfile: EEGAD.m,v $';

% Defaults
fname='';
eeg=[];
grid=[];
if nargin==1
  if ischar(varargin{1})
    fname=varargin{1};
  elseif isstruct(varargin{1})
    eeg=varargin{1};
  else
    grid=varargin{1};
  end
elseif nargin==2
  if ischar(varargin{1})
    fname=varargin{1};
  else isstruct(varargin{1})
    eeg=varargin{1};
  end
  grid=varargin{2};
end

% Get file, if not specified
if isempty(fname) & isempty(eeg)
  [name,path]=uigetfile('*.avg; *.gav','Select EEG data file');
  if name==0, return, end                  % User hit Cancel button
  fname=[path name];
  cd(path);                                % Remember this directory
end

% Load EEG data, if not passed directly
if isempty(eeg)
  disp('Loading EEG data...');
  eeg=EEGRead(fname);
end

% Size grid to show all channels, if grid not specified
if isempty(grid)
  rows=ceil(sqrt(eeg.nChannels));
  cols=ceil(eeg.nChannels/rows);
  grid=[rows cols];
end

% Show EEG data
EEGFig;
text(0.5,0.5,'Plotting EEG data...','HorizontalAlignment','Center');
axis('off');
ax=gca;
drawnow;
bins=[1:eeg.nBins];
channels=[1:min(eeg.nChannels,grid(1)*grid(2))];
tic
EEGShow(eeg,bins,channels,grid,[],[],'numeric');
toc
delete(ax);

% Modification History:
%
% $Log: EEGAD.m,v $
% Revision 1.4  2005/02/03 20:17:40  michelich
% M-Lint: Replace deprecated isstr with ischar.
%
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
% Francis Favorini, 10/11/96.
% Francis Favorini, 10/23/96.  Minor mods.
% Francis Favorini, 01/24/97.  Shows all bins at start.
% Francis Favorini, 02/20/97.  Handles electrode coords in header file.
% Francis Favorini, 02/26/97.  cd handles UNC names now.
% Francis Favorini, 07/03/97.  Changed to use eeg structure.
% Francis Favorini, 07/08/97.  Changed to use EEGFig.
% Francis Favorini, 07/22/97.  Added ability to pass EEG structure.
