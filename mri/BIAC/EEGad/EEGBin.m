function EEGBin(bins,state)
%EEGBin Sets display state of specified bins on current EEG plot.
%
%       EEGBin(bins);
%       EEGBin(bins,state);
%
%       bins are the bin numbers
%       state is 'on' or 'off'

% CVS ID and authorship of this code
% CVSId = '$Id: EEGBin.m,v 1.3 2005/02/03 16:58:18 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:18 $';
% CVSRCSFile = '$RCSfile: EEGBin.m,v $';

set(gcf,'Pointer','watch'); drawnow;

if isempty(bins), return; end

% If state not specified, user selected a single bin from the Bins menu
if nargin<2
  if strcmp(get(findobj(gcf,'Tag','binMenuItem','UserData',bins(1)),'Checked'),'off')
    state='on';
  else
    state='off';
  end
end

% Build channels and bins
plots=findobj(gcf,'Tag','EEG')';
channels=[];
for c=plots
  channels=[channels get(c,'UserData')];
end
channels=chanSort(channels);
oldBins=[];
for b=findobj(plots(1),'Tag','bin')'
  oldBins=[oldBins; get(b,'UserData')];
end
oldBins=sort(oldBins)';

% Update bin menu
binMenuItems=get(findobj(gcf,'Tag','binMenu'),'UserData');
if strcmp(state,'on')
  EEGPlot(bins,channels,[],[],[],0);        % Don't update xHairs here
  set(binMenuItems(bins),'Checked','on');
elseif strcmp(state,'off')
  if ~isempty(oldBins)
    newBins=oldBins;
    for b=bins
      bi=find(newBins==b);
      if ~isempty(bi)
        delete(findobj(gcf,'Tag','bin','UserData',b)');
        newBins(bi)=[];
      end
    end
    EEGLegnd(newBins);
    set(binMenuItems(bins),'Checked','off');
  end
elseif strcmp(state,'invert')
  % Turn off any bins that are on
  for b=oldBins
    bi=find(bins==b);
    if ~isempty(bi)
      delete(findobj(gcf,'Tag','bin','UserData',b)');
      set(binMenuItems(bins(bi)),'Checked','off');
      bins(bi)=[];
    end
  end
  % Turn on bins that were off
  if isempty(bins)
    EEGLegnd(bins);       % Turn off legend
  else
    EEGPlot(bins,channels,[],[],[],0);        % Don't update xHairs here
    set(binMenuItems(bins),'Checked','on');
  end
end

% Update bin selector
binSelector=findobj(gcf,'Tag','binSelector');
if ~isempty(binSelector)
  % Update bin selector strings
  newBins=[];
  binNames=[];
  handles=findobj(findobj(gcf,'Tag','Legend'),'Tag','binName')';
  for h=handles
    newBins(end+1)=get(h,'UserData');
    binNames{end+1}=get(h,'String');
  end
  [newBins bi]=sort(newBins);
  binNames=binNames(bi);

  % Update bin selector value
  if isempty(oldBins)
    oldBin=0;
  else
    oldBin=oldBins(get(binSelector,'Value'));
  end
  if strcmp(state,'invert') | oldBin==0 | ~isempty(find(oldBin==bins))
    val=1;                        % Old bin (if any) is not on anymore
  else
    val=find(oldBin==newBins);    % Get new index into bin names
  end
  set(binSelector,'String',binNames,'Value',val);
  xHairs('up');

  % Update bin selector visibility
  if length(newBins)>1
    set(binSelector,'Visible','on');
  else
    set(binSelector,'Visible','off');
  end
end

set(gcf,'Pointer','arrow');
figure(gcf);

% Modification History:
%
% $Log: EEGBin.m,v $
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
% Francis Favorini, 10/11/96.
% Francis Favorini, 10/22/96.  Modified to use EEGPlot and chanSort.
% Francis Favorini, 10/28/96.  Modified to support multiple bins.
% Francis Favorini, 01/10/97.  Modified to prevent EEGPlot from updating xHairs.
% Francis Favorini, 01/29/97.  MATLAB 5 compliance.
% Francis Favorini, 02/05/97.  MATLAB 5 compliance.
% Francis Favorini, 07/03/97.  Added isempty check.  Changed binNames to cell array.
