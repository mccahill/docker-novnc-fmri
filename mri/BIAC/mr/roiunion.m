function newroi=roiunion(varargin)
%ROIUNION Combine one or more ROIs into a single ROI.
%
%   newroi=roiunion(roi1,roi2,...);
%
%   roi1, roi2, ... are the ROIs to combine.
%     isroi or isempty must be true for each one.
%   newroi is the combined ROI.
%
%   Notes:
%     This operation is not commutative!
%     All ROIs must be based on the same size series.
%     Will expand short form ROIs into long form ROIs (see ISROI).
%     roiunion(roi,[]) does not necessarily leave roi unchanged,
%       since newroi is passed to ROISORT before being returned.
%
%   See also ISROI, ROIDEF, ROIGROW, ROICOORDS, ROISTATS.

% Note: Sorts newroi.slice/index in case it is required in the future.

% CVS ID and authorship of this code
% CVSId = '$Id: roiunion.m,v 1.3 2005/02/03 16:58:43 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:43 $';
% CVSRCSFile = '$RCSfile: roiunion.m,v $';

% Check arguments
ROIs=varargin;
empty=cellfun('isempty',ROIs);
if isempty(empty) | all(empty) 
  error('You must specify at least one ROI.');
end
[OK,err,form]=isroi(ROIs);
OK=OK|empty;
if ~all(OK)
  error(['The following argument numbers are not valid ROIs: ' numlist(find(~OK)) '.']);
end

% Check for mixed long and short form ROIs (no val or color fields)
form=form(:)';     % Make it a row vector
if length(unique(form(find(form))))~=1
  % Found mixed forms
  long1=index(find(form>1),1);
  short1s=find(form==1);
  % Lengthen the short ones by adding info from first long one
  for r=short1s
    ROIs{r}.val=ROIs{long1}.val;
    ROIs{r}.color=ROIs{long1}.color;
  end
end

% Convert to array of structures
ROIs=[ROIs{:}];
if length(ROIs)>1 & ~isequal(ROIs.baseSize)
  error('All ROI''s baseSizes must match!');
end

newroi=ROIs(1);
for r=2:length(ROIs)
  roi=ROIs(r);
  for s=1:length(roi.slice)
    if isempty(newroi.slice)
      dupSlice=[];
    else
      dupSlice=find(roi.slice(s)==newroi.slice);    % roi.slice(s) should match 0 or 1 newroi.slice
    end
    if isempty(dupSlice)
      % Stick new slice data on the end
      newroi.index=[newroi.index roi.index(s)];
      newroi.slice=[newroi.slice roi.slice(s)];
    elseif length(dupSlice)==1
      % Merge with existing slice data
      % Notes on union:
      %   Good: union sorts its output
      %   Bad:  If either arg is a scalar it returns a row vector, so make sure we save as a column vector
      newindex=union(newroi.index{dupSlice},roi.index{s});
      newroi.index{dupSlice}=newindex(:);
    else
      error('Consistency check failed: ROI has duplicate slices!');
    end
  end
end

% Sort slice/index in case it is required in the future
newroi=roisort(newroi);

% Modification History:
%
% $Log: roiunion.m,v $
% Revision 1.3  2005/02/03 16:58:43  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:39  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/08/27 22:24:25  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2001/01/25. Changed function name to lowercase.
%                                Changed isroi() and roisort() to lowercase.
%                                Updated see also to uppercase
% Francis Favorini,  2000/05/05.
