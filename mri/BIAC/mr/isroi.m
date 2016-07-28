function [TF,err,form]=isroi(ROIs)
%ISROI  Returns true for each valid ROI in ROIs.
%
%   [TF,err,form]=isroi(ROIs);
%
%   ROIs is an array or cell array of ROIs.
%   TF is a logical array the same shape as ROIs with
%     true for each valid ROI in ROIs.
%   err is an array the same shape as ROIs with
%     a numeric entry from the following list indicating
%     the problem for each invalid ROI and 0 otherwise.
%   form is an array the same shape as ROIs with
%     1  for each valid ROI with fieldnames shown in a. below,
%     2  for each valid ROI with fieldnames shown in b. below,
%     0  otherwise.
%
%   A valid ROI has the following properties:
%   1.  ROI is a structure
%   2.  ROI has one of two possible sets of fieldnames:
%       a. {'baseSize','index','slice'}
%       b. {'baseSize','index','slice','val','color'}
%   3.  baseSize is a row vector of 3 positive integers
%   4.  slice must be a row vector (may be empty) of positive integers
%       with none exceeding the number of slices (i.e., baseSize(3))
%       Note: slice does not have to be sorted (currently).
%   5.  slice has no duplicates
%   6.  index is a row vector (may be empty) of cells
%   7.  index is the same size as slice
%       Note: The elements in index should correspond to those in slice
%   8.  Each element of index is a column vector of positive integers (indices)
%       with none exceeding 2D image size (i.e., prod(baseSize(1:2)))
%   9.  Each vector of indices in index is sorted ascending
%   10. Each vector of indices in index has no duplicates
%   11. If present, val must be an integer in the range [ROIValMin ROIValMax]
%       (as defined by overlay2)
%   12. If present, color must be 1x3 vector of finite doubles in the range [0 1]
%
%   See also ISEMPTYROI, ROIDEF, ROIGROW, ROICOORDS, ROISTATS

% CVS ID and authorship of this code
% CVSId = '$Id: isroi.m,v 1.4 2005/02/03 16:58:39 michelich Exp $';
% CVSRevision = '$Revision: 1.4 $';
% CVSDate = '$Date: 2005/02/03 16:58:39 $';
% CVSRCSFile = '$RCSfile: isroi.m,v $';

% TODO: Pass ROIValMin/Max as params? Or create sep function roicolors that returns all relevant info?

% Check input args
error(nargchk(1,1,nargin));
if isempty(ROIs)
  TF=logical(0);
  err=1;
  form=0;
  return;
end

% Output args
TF=logical(zeros(size(ROIs)));
err=zeros(size(ROIs));
form=zeros(size(ROIs));

celery=iscell(ROIs);
ROIValMax=256;            % Must agree with ROIVals in overlay2!
ROIValMin=ROIValMax-32+1; % Must agree with ROIVals in overlay2!
% Two possible sets of fieldnames
flds1={'baseSize','index','slice'};
flds2={'baseSize','index','slice','val','color'};

for r=1:prod(size(ROIs))
  if celery
    roi=ROIs{r};
  else
    roi=ROIs(r);
  end
  if ~isstruct(roi)
    % Must be a structure
    err(r)=1;
  elseif length(roi)>1
    % We have a structure array in this cell, so run recursively isroi on it
    [subTF,subErr,subForm]=isroi(roi);
    if ~all(subTF)
      % At least one element was bad, so return first error
      err(r)=index(find(subErr),1);
    else
      % It's an array of valid ROIs, hence they must all be the same form
      form(r)=subForm(1);
    end
  else
    % Figure out which form it's in
    flds=fieldnames(roi);
    if isempty(setxor(flds,flds1))
      form(r)=1;
    elseif isempty(setxor(flds,flds2))
      form(r)=2;
    end
    if form(r)==0
      % Fields must exactly match one of two possibilities
      err(r)=2;
    elseif ~isequal(size(roi.baseSize),[1 3]) | any(~isint(roi.baseSize)) | any(roi.baseSize<1)
      % baseSize must be a row vector of 3 positive integers
      err(r)=3;
    elseif ~(isempty(roi.slice) & isnumeric(roi.slice)) & ...
        (size(roi.slice,1)~=1 | any(~isint(roi.slice)) | any(roi.slice<1) | any(roi.slice>roi.baseSize(3)))
      % slice must be a row vector (may be empty) of positive integers not exceeding number of slices
      err(r)=4;
    elseif length(roi.slice)~=length(unique(roi.slice))
      % slice must have no duplicates
      err(r)=5;
    elseif ~iscell(roi.index) | (~isempty(roi.index) & size(roi.index,1)~=1)
      % index must be a row vector (may be empty) of cells
      err(r)=6;
    elseif ~isequal(size(roi.index),size(roi.slice))
      % index must be the same size as slice
      err(r)=7;
    else
      % If optional fields present
      if isempty(setxor(flds,flds2))
        if length(roi.val)~=1 | ~isint(roi.val) | roi.val<ROIValMin | roi.val>ROIValMax
          % val must be an integer in the range [ROIValMin ROIValMax]
          err(r)=11;
        elseif ~isequal(size(roi.color),[1 3]) | any(~isfinite(roi.color)) | any(roi.color<0) | any(roi.color>1)
          % color must be 1x3 vector of finite doubles in the range [0 1]
          err(r)=12;
        end
      end
      % Check each vector in roi.index
      for i=1:length(roi.index)
        ind=roi.index{i};
        if size(ind,2)~=1 | any(~isint(ind)) | any(ind<1) | any(ind>prod(roi.baseSize(1:2)))
          % Each element of roi.index must be a column vector of positive integers not exceeding 2D image size
          err(r)=8; break;
        else
          diff=ind-[0; ind(1:end-1)];    % Subtract each element from its predecessor
          if any(diff<0)
            % Each column vector must be sorted in ascending order
            err(r)=9; break;
          elseif any(diff==0)
            % Each column vector must have no duplicates
            err(r)=10; break;
          end
        end
      end % for i
    end % if fieldnames are OK
  end % if isstruct
end
TF=(err==0);
    
%       baseSize: [256 256 64]
%       index: {[435x1 double]}
%       slice: 19
%         val: 255
%       color: [0 1 0]

% Modification History:
%
% $Log: isroi.m,v $
% Revision 1.4  2005/02/03 16:58:39  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.3  2004/04/01 20:20:32  michelich
% Bug Fix: form output not assigned for empty input roi.
%
% Revision 1.2  2003/10/22 15:54:37  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/08/27 22:24:21  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2001/01/23. Changed function name to lowercase.   Updated comments
%                                Updated help "see also" to uppercase.
%                                Changed overlay2 to lowercase (in comments and help)
% Francis Favorini,  2000/05/05. Also support cell array of ROIs as input.
%                                Added comments.
%                                Added second output arg indicating the problem with each element.
%                                Check for slice and index duplicates.
%                                Fixed bug: returned false for all subsequent elements after first non-ROI.
%                                Allow empty index and slice fields.
%                                Return true for ROI arrays that are elements of cell array argument form.
%                                Added form output arg.
% Francis Favorini,  2000/04/26.
