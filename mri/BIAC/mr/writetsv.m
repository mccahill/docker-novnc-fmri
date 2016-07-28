function writetsv(srsSpec,tsv,zoom,cannedFormat)
%WRITETSV Write MR time series of volumes (TSV) to disk.
%
%   NOTE: This function is deprecated.  Use WRITEMR instead!
%
%   writetsv(srsSpec,tsv);
%   writetsv(srsSpec,tsv,zoom);
%   writetsv(srsSpec,tsv,zoom,cannedFormat);
%	
%   srsSpec is a file specifier indicating the nameseries of MR volumes to output.
%   tsv is the 4-D time series of volumes.
%   zoom specifies how to zoom in on the volume before writing it to disk.
%     This will reduce the size of the output files.
%     The format is [xo yo xs ys], where (xo,yo) is the new upper left corner,
%     and [xs ys] is the new dimensions of the zoomed volume.
%     Default is full size of volume.
%   cannedFormat is either 'volume' or 'float' to match the formats read by
%     READMR.  Default is 'volume'
%
%   Examples:
%   >>writetsv('\\broca\data2\study\analyzed\run01\V*.img',tsv);
%   >>writetsv('\\broca\data2\study\analyzed\run01\V*.img',tsv,[33 33 64 64]);
%   >>writetsv('\\broca\data2\study\analyzed\run01\V*.img',tsv,[33 33 64 64],'float');
%
% See Also: WRITEMR, READMR

% CVS ID and authorship of this code
% CVSId = '$Id: writetsv.m,v 1.4 2005/02/03 16:58:45 michelich Exp $';
% CVSRevision = '$Revision: 1.4 $';
% CVSDate = '$Date: 2005/02/03 16:58:45 $';
% CVSRCSFile = '$RCSfile: writetsv.m,v $';

lasterr('');
emsg='';
try
   
  p=[];
  
  % Check arguments
  emsg=nargchk(2,4,nargin); error(emsg);  
  if nargin<3 | isempty(zoom), zoom=[1 1 size(tsv,1) size(tsv,2)]; end	% Set zoom to default
  if nargin<4, cannedFormat='volume'; end			                          % Set cannedFormat to default
  
  % Check tsv is a numeric or logical array to prevent users from
  % accidentally passing new mrinfo structues 
  if ~(isnumeric(tsv) | islogical(tsv))
    emsg='tsv must be a numeric or logical array!'; error(emsg);
  end
  
  % Zoom parameters must be positive integers less than or equal to the image size
  if any(zoom < 0) | any(~isint(zoom)) | any(zoom(1:2)+zoom(3:4)-1 > [size(tsv,1) size(tsv,2)])
    emsg='Specified zoom parameters are invalid.'; error(emsg);
  end
  
  % Get volume file names
  nTimePts=size(tsv,4);
  fNames=cell(nTimePts,1);
  for t=1:nTimePts
    [path name ext]=fileparts(sprintf(strrep(strrep(srsSpec,'*','%04d'),'\','\\'),t));
    fNames{t}=[name ext];
  end
  
  % Zoom window
  xWin=zoom(1):zoom(1)+zoom(3)-1;
  yWin=zoom(2):zoom(2)+zoom(4)-1;
  
  % Write the MR volumes
  p=progbar(sprintf('Writing 0 of %d volumes of run %s...',nTimePts,path));
  for t=1:nTimePts
    if ~ishandle(p), emsg='User abort'; error(emsg); end
    progbar(p,sprintf('Writing %d of %d volumes of run %s...',t,nTimePts,path));
    writemr(fullfile(path,fNames{t}),tsv(xWin,yWin,:,t),cannedFormat);
    if ~ishandle(p), emsg='User abort'; error(emsg); end
    progbar(p,t/nTimePts);
  end
  delete(p);
  
catch
  if isempty(emsg)
    if isempty(lasterr)
      emsg='An unidentified error occurred!';
    else
      emsg=lasterr;
    end
  end
  if ishandle(p), delete(p); end
  error(emsg);
end

% Modification History:
%
% $Log: writetsv.m,v $
% Revision 1.4  2005/02/03 16:58:45  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.3  2003/10/22 15:54:40  gadde
% Make some CVS info accessible through variables
%
% Revision 1.2  2003/07/30 20:52:15  michelich
% Added deprecated note.
% Added additional class check on tsv to prevent accidental error.
%
% Revision 1.1  2002/08/27 22:24:26  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2001/01/25. Changed function name to lowercase.
%                                Changed readmr() and writemr() to lowercase.
% Francis Favorini,  2000/02/22. Empty zoom uses default.
% Charles Michelich, 1999/07/16. Added support for 'float' format and check for valid zoom parameters
% Francis Favorini,  1999/04/22.

