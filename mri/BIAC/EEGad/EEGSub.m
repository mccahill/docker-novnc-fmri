function EEGSub(nRows,nCols)
%EEGSub Subdivide the current figure into a matrix of EEG plots.
%
%  	  EEGSub(m,n) subdivides the current figure into an m-by-n matrix of EEG plots.
%  	  EEGSub(positions), where positions is m x 4, subdivides the current figure
%         into m EEG plots with custom axes positions [left bottom width height]
%         in normalized units.

% CVS ID and authorship of this code
% CVSId = '$Id: EEGSub.m,v 1.3 2005/02/03 16:58:19 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:19 $';
% CVSRCSFile = '$RCSfile: EEGSub.m,v $';

% Remove old plots from current figure
userData=get(gcf,'UserData');
if isstruct(userData)
  delete(getfield(userData,'plots'));
end
set(gcf,'NextPlot','Add');

if nargin<2
  % Create custom sub-axes
  positions=nRows;
  len=size(positions,1);
  plots=zeros(1,len);
  for p=1:len
    % Create the sub-axes
  	ax=axes('Units','Normal','Position',positions(p,:),'DrawMode','Fast','Visible','Off');
    set(ax,'Units',get(gcf,'DefaultAxesUnits'));

    % Save vector of plots in order
    plots(p)=ax;
  end
else
  % This is the percent offset from the subplot grid of the plotbox.
  PERC_OFFSET_L=0.04;
  PERC_OFFSET_R=0.01;
  PERC_OFFSET_B=0.04;
  PERC_OFFSET_T=0.03;
  if nRows>2
  	PERC_OFFSET_T=0.9*PERC_OFFSET_T;
  	PERC_OFFSET_B=0.9*PERC_OFFSET_B;
  end
  if nCols>2
  	PERC_OFFSET_L=0.9*PERC_OFFSET_L;
  	PERC_OFFSET_R=0.9*PERC_OFFSET_R;
  end
  def_pos=[0.17 0.08 0.8 0.84];
  totalwidth=def_pos(3);
  totalheight=def_pos(4);

  % Create sub-axes
  p=0;
  plots=zeros(1,nRows*nCols);
  for col=0:nCols-1
    for row=nRows-1:-1:0
  		width=(totalwidth-(nCols-1)*(PERC_OFFSET_L+PERC_OFFSET_R))/nCols;
  		height=(totalheight-(nRows-1)*(PERC_OFFSET_T+PERC_OFFSET_B))/nRows;
  		position=[def_pos(1)+col*(width+PERC_OFFSET_L+PERC_OFFSET_R) ...
         		    def_pos(2)+row*(height+PERC_OFFSET_T+PERC_OFFSET_B) ...
  			        width height];
  		if width<0.75*totalwidth/nCols
  			position(3)=0.75*(totalwidth/nCols);
        margin=PERC_OFFSET_L+PERC_OFFSET_R-(position(3)-width);
        position(1)=def_pos(1)+col*(position(3)+margin);
  		end
  		if height<0.55*totalheight/nRows
  			position(4)=0.55*(totalheight/nRows);
        margin=PERC_OFFSET_T+PERC_OFFSET_B-(position(4)-height);
        position(2)=def_pos(2)+row*(position(4)+margin);
  		end

      % Create the sub-axes
    	ax=axes('Units','Normal','Position',position,'DrawMode','Fast','Visible','Off');
      set(ax,'Units',get(gcf,'DefaultAxesUnits'));

      % Save vector of plots in order (row-wise)
      p=p+1;
      plots(p)=ax;
  	end
  end
end

set(gcf,'UserData',setfield(get(gcf,'UserData'),'plots',plots));

% Modification History:
%
% $Log: EEGSub.m,v $
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
% Francis Favorini, 10/24/96.
% Francis Favorini, 10/31/96.  Added custom grid layout.
% Francis Favorini, 01/29/97.  Minor mods.
% Francis Favorini, 07/02/97.  Changed to use eeg structure.
% Francis Favorini, 08/19/97.  Don't choke if UserData doesn't exist yet.
