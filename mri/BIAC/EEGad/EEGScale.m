function EEGScale(scale)
%EEGScale Sets X- and Y-axis scale on current EEG plot.
%       scale is the vector [xMin xMax yMin yMax]

% CVS ID and authorship of this code
% CVSId = '$Id: EEGScale.m,v 1.4 2005/02/03 20:17:40 michelich Exp $';
% CVSRevision = '$Revision: 1.4 $';
% CVSDate = '$Date: 2005/02/03 20:17:40 $';
% CVSRCSFile = '$RCSfile: EEGScale.m,v $';

set(gcf,'Pointer','watch'); drawnow;

% Defaults
if nargin<1
  scale=[str2num(get(findobj(gcf,'Tag','XMin'),'String')),...
         str2num(get(findobj(gcf,'Tag','XMax'),'String')),...
         str2num(get(findobj(gcf,'Tag','YMin'),'String')),...
         str2num(get(findobj(gcf,'Tag','YMax'),'String'))];
end

% Build channels
plots=findobj(gcf,'Tag','EEG')';
channels=[];
for c=plots
  channels=[channels get(c,'UserData')];
end
channels=chanSort(channels);

if ~ischar(scale)
  EEGPlot([],channels,scale(1:2),scale(3:4));
elseif strcmp(scale,'full')
  EEGPlot([],channels,scale);
elseif strcmp(scale,'auto')
  EEGPlot([],channels,[],scale);
end

set(gcf,'Pointer','arrow');
figure(gcf);

% Modification History:
%
% $Log: EEGScale.m,v $
% Revision 1.4  2005/02/03 20:17:40  michelich
% M-Lint: Replace deprecated isstr with ischar.
%
% Revision 1.3  2005/02/03 16:58:19  michelich
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
% Francis Favorini, 10/11/96.
% Francis Favorini, 10/23/96.  Modified to use EEGPlot and chanSort.
% Francis Favorini, 01/29/97.  MATLAB 5 compliance.
