function [positions,sortOrder,fname]=EEGCustm(gridFile)
%EEGCUSTM Read custom grid layout file and return positions and sortOrder.
%
%       [positions,sortOrder]=EEGCustm;
%       [positions,sortOrder]=EEGCustm(gridFile);
%
%       gridFile specifies the name of a grid file (.GRD) to read.
%         If empty, omitted or 'custom' get file from user.
%
%       The .GRD file has the following format:
%
%       Line   1: sortOrder
%       Line   2: positions(1)
%                 ...
%       Line n+1: positions(n)
%
%       where
%       sortOrder is 'numeric', 'alphabetic',
%         or a space-separated list of channel numbers in the desired order.
%       positions(n) is a space-separated list of four numbers:
%         left bottom width height 
%         which specify the location and size of the side of the axis box
%         in normalized units relative to the Figure window.
%         (0,0) is the lower-left corner and (1.0,1.0) is the upper-right.

% CVS ID and authorship of this code
% CVSId = '$Id: EEGCustm.m,v 1.3 2005/02/03 16:58:18 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:18 $';
% CVSRCSFile = '$RCSfile: EEGCustm.m,v $';

% Check args
if nargin < 1, gridFile=[]; end

% Get file name
if isempty(gridFile) | ~strcmp('custom',lower(gridFile))
  fname=gridFile;
else
  [name,path]=uigetfile('*.grd','Select grid layout file');
  if name==0                                                    % User hit Cancel button.
    set(gcf,'Pointer','arrow');
    figure(gcf);
    positions=[];
    sortOrder=[];
    return;
  end
  fname=[path name];
  cd(path);                                                     % Remember this directory
end

% Open file
fid=fopen(fname);
if fid==-1
  error(['Couldn''t open grid layout file "' fname '"']);
end

% Get sort order and axes positions
sortOrder=lower(fgetl(fid));
positions=fscanf(fid,'%f');
fclose(fid);
if ~(strcmp(sortOrder,'alphabetic') | strcmp(sortOrder,'numeric'))
  sortOrder=fix(sscanf(sortOrder,'%d')');
  if isempty(sortOrder) | any(sortOrder<1)
    error(['Improper sort order in grid layout file "' fname '"']);
  end
end
if rem(length(positions),4) | any(positions>1) | any(positions<0)
  error(['Improper axes positions in grid layout file "' fname '"']);
end
positions=reshape(positions,[4 length(positions)/4])';

% Modification History:
%
% $Log: EEGCustm.m,v $
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
% Francis Favorini, 11/01/96.
% Francis Favorini, 02/06/97.  Now returns empty args when user cancels.
% Francis Favorini, 07/08/97.  cd handles UNC names now.
%                              Added gridFile input and fname output arguments.
