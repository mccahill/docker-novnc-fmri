function EEGTweak(action)
%EEGTWEAK Tweak properties of right-clicked on object.

% CVS ID and authorship of this code
% CVSId = '$Id: EEGTweak.m,v 1.4 2005/02/03 16:58:19 michelich Exp $';
% CVSRevision = '$Revision: 1.4 $';
% CVSDate = '$Date: 2005/02/03 16:58:19 $';
% CVSRCSFile = '$RCSfile: EEGTweak.m,v $';

if nargin==0
  set(gcf,'WindowButtonDownFcn','EEGTweak(''down'');');
elseif strcmp(action,'close')
  set(gcf,'WindowButtonDownFcn','');
elseif strcmp(action,'down')
  if strcmp(get(gcf,'SelectionType'),'alt')       % Right-click
    object=get(gcf,'CurrentObject');
    if ~isempty(object)
      tag=get(object,'Tag');
      if strcmp(tag,'binLegend')                  % Bin line in legend
        guiline(object,'BinLine',get(object,'UserData'));
      elseif strcmp(tag,'bin')                    % Bin line on plot
        guiline(object,'BinLine',get(object,'UserData'));
      elseif strcmp(tag,'binName')                % Bin name in legend
        guistrf('Enter new bin name:',get(object,'String'),15,...
                'BinName',num2str(get(object,'UserData')));
      end
    end
  end
end

% Modification History:
%
% $Log: EEGTweak.m,v $
% Revision 1.4  2005/02/03 16:58:19  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.3  2003/10/22 15:54:34  gadde
% Make some CVS info accessible through variables
%
% Revision 1.2  2003/09/15 16:44:00  michelich
% Changed guistrf() and guiline() to lowercase.
%
% Revision 1.1  2002/10/08 23:46:45  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Francis Favorini, 11/08/96.
% Francis Favorini, 12/09/96.  Changed params to GUILine.
% Francis Favorini, 01/30/97.  MATLAB 5 compliance.
