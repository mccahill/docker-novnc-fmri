function dataOut=roistats(srsSpec,typeSpec,zoom,roi,statFunc,limits,inGUI)
%ROISTATS Calculate statistics within ROI for specified MR series.
%
%   data=roistats(srsSpec,typeSpec,zoom,roi);
%   data=roistats(srsSpec,typeSpec,zoom,roi,statFunc);
%   data=roistats(srsSpec,typeSpec,zoom,roi,statFunc,limits);
%
%   srsSpec is a file specifier indicating the series of MR volumes to process.
%   typeSpec is a string or cell array containing the READMR typespec
%   zoom specifies how to zoom in on the images before applying stats.
%     The format is [xo yo xs ys], where (xo,yo) is the new upper left corner,
%     and [xs ys] is the new dimensions of the zoomed images.
%     You may use [] to stand for the full image size.
%   roi is an ROI returned by ROIDEF.  An array of ROIs may be passed if
%     they were all drawn on the same sized images.
%   statFunc is the function to apply to the voxels within the ROI.
%     The empty string '' is equivalent to the default.  Default is 'mean'.
%     You may also pass valid MATLAB expression instead of just a function name.
%       The vector named "voxels" can be used to refer to the voxels.
%     You may also pass a cell array of functions/expressions, each of which will be
%       evaluated in turn.
%   limits is [min max] for pixel values within the ROI.  Values
%     outside the limits are ignored when calculating the stats.
%     Default is [], which means there are no limits.
%   data is an array of the results of each statFunc applied to each volume and ROI.
%     The dimensions of the array will be [#Volumes, #statFuncs, #ROIs].
%     Note: If your function or expression does not return a single scalar value,
%       data will be a cell array instead of numeric.
%
%   Examples:
%   >>data=roistats('D:\run01\run005_01.bxh','BXH',[],roi);
%   >>data=roistats('D:\run01\V*.img',{'Volume',[128,128,12]},[1 1 128 128],roi,'mean',[300 2000]);
%   >>data=roistats('D:\run01\V*.img',{'Volume',[128,128,12]},[],roi);
%   >>data=roistats('D:\run01\V*.img',{'Volume',[128,128,12]},[33 33 64 64],[roi roi2 roi3]);
%   >>data=roistats('D:\run01\V*.img',{'Volume',[128,128,12]},[],roi,{'mean' 'min' 'max'});
%   >>data=roistats('D:\run01\V*.img',{'Volume',[128,128,12]},[],[roi roi2],'length(find(voxels>5))');
%
%   See also ROIDEF, ROIGROW, ROICOORDS.

% CVS ID and authorship of this code
% CVSId = '$Id: roistats.m,v 1.11 2006/11/27 16:25:25 gadde Exp $';
% CVSRevision = '$Revision: 1.11 $';
% CVSDate = '$Date: 2006/11/27 16:25:25 $';
% CVSRCSFile = '$RCSfile: roistats.m,v $';

lasterr('');
emsg='';
if nargin<7, inGUI=1; end
try
  
  % Initialize for error catch
  p=[];
  dataOut=[];
  mrinfostruct=[];
  
  % Check input arguments
  emsg=nargchk(4,7,nargin); error(emsg);
  
  % Set defaults
  if nargin<5 | isempty(statFunc), statFunc={'mean'}; end
  if ischar(statFunc), statFunc={statFunc}; end
  if nargin<6, limits=[]; end
  
  % Check other arguments
  if ~ischar(srsSpec) & ~isstruct(srsSpec)
    emsg='srsSpec must be a string or a struct.'; error(emsg);
  end
  if ~isempty(zoom) & (~isnumeric(zoom) | length(zoom)~=4)
    emsg='zoom must be empty or a vector of four numbers.'; error(emsg);
  end
  if ~all(isroi(roi))
    emsg='Invalid ROIs!'; error(emsg);
  end
  if length(roi)>1 & ~isequal(roi.baseSize) 
    emsg='All ROIs must be defined on volumes with the same dimensions.'; error(emsg);
  end
  if ~iscellstr(statFunc)
    emsg='statFunc must be a string or cell array of strings.'; error(emsg);
  end
  if ~isnumeric(limits) | all(length(limits)~=[0 2])
    emsg='limits must be empty or a vector of two numbers.'; error(emsg);
  end
      
  % Support old-style readmr parameters.  
  if iscell(typeSpec) & length(typeSpec)==4 & any(strcmpi(typeSpec{4},{'Volume','Float'})) & ...
      isnumeric(typeSpec{1}) & isnumeric(typeSpec{2}) & isnumeric(typeSpec{3})
    typeSpec={typeSpec{4},[typeSpec{1:3}]};
  end
  
  % Read the info for this time series of volumes (to use for reading as necessary)
  if length(typeSpec) == 0
    mrinfostruct=readmr(srsSpec,'=>INFOONLY');
  else
    mrinfostruct=readmr(srsSpec,typeSpec,'=>INFOONLY');
  end

  if isstruct(srsSpec)
    srsSpec=srsSpec.info.displayname;
  end
  
  % Check the data dimensions & order and get sizes
  if ~any(length(mrinfostruct.info.dimensions) == [3 4])
    error(sprintf('Images are not 3D or 4D: %s',srsSpec));
  end
  if ~isequal({mrinfostruct.info.dimensions(1:3).type},{'x','y','z'})
    error(sprintf('Data is not in x,y,z order: %s',srsSpec));
  end
  dataSize=[mrinfostruct.info.dimensions.size];
  % If there are only three dimensions in the data, the 4th dimension is size 1
  if length(dataSize) == 3, dataSize(4) = 1; end

  % Generate indicies for zoom
  if isempty(zoom) | all(zoom==[1 1 dataSize(1) dataSize(2)])
    xi=[]; yi=[]; % Keep all data
  else
    % Keep zoomed window.
    xi=zoom(1):zoom(1)+zoom(3)-1;
    yi=zoom(2):zoom(2)+zoom(4)-1;
    if xi(end) > dataSize(1) | yi(end) > dataSize(2), 
      error('Invalid Zoom!');
    end
    dataSize(1:2)=zoom(3:4);  % Update dataSize to size to be read
  end
  
  % Initialize output data array
  data=zeros(dataSize(4),length(statFunc),length(roi));
  
  % Calculate interpolation scale factors
  scale=roi(1).baseSize./dataSize(1:3);
  if scale(1) ~= scale(2) 
    % Warn user if there are different scale factors in x & y to avoid inadvertant mistakes
    warning('Interpolation factor different in x & y dimensions!  Did you really mean to do this???');
  end
  if any(~isint(scale))
    emsg='Interpolation factor(s) are not integers!'; error(emsg);
  end
  
  % Process each file
  p=progbar(sprintf(' Processing %d of %d volumes in %s... ',0,dataSize(4),srsSpec));  % Extra spaces allow for extra digits
  for v=1:dataSize(4)
    if ~ishandle(p), emsg='User abort'; error(emsg); end
    progbar(p,sprintf('Processing %d of %d volumes in %s...',v,dataSize(4),srsSpec));
    % Read data (current zoomed time point)
    srs=readmr(mrinfostruct,{xi,yi,[],v},'NOPROGRESSBAR');  srs=srs.data;
    if isempty(srs)
      % Couldn't read a volume in this series, return NaNs for its stats
      % TODO: Is this necessary anymore?
      warning(sprintf('Unable to read time point %d from %s, skipping volume ...',v,srsSpec));
      data(v,:,:)=NaN;
    elseif any(size(srs) ~= dataSize(1:3))
      % Image volume read is not the expected size, return NaNs for its stats
      % TODO: Is this necessary anymore?
      warning(sprintf('Incorrect image size for time point %d from %s, skipping volume ...',v,srsSpec));
      data(v,:,:)=NaN;
    else
      % Interpolate if needed
      if any(scale~=1)
        srs=scale3(srs,scale(1),scale(2),scale(3));
      end
      
      % Loop through the each roi
      for r = 1:length(roi)
        % Loop through slices
        voxels=[];
        for s=1:length(roi(r).slice)
          % Important: Make sure all slices' pixels are put in a column
          % by iterating through roi.slice in order (this order is assumed in other code)
          sliceData=srs(:,:,roi(r).slice(s));
          voxels=[voxels; sliceData(roi(r).index{s})];    % Put all slices' pixels in a column
        end
        % Filter voxels
        if ~isempty(limits) & ~isempty(voxels)
          voxels=voxels(find(voxels>=limits(1) & voxels<=limits(2)));
        end
        % Calculate stats
        for s=1:length(statFunc)
          func=statFunc{s};
          if isempty(findstr('voxels',func))
            stat=feval(func,voxels);                                 % Evaluate function on voxels
          else
            stat=eval(func);                                         % Evaluate expression
          end
          if ~isnumeric(stat) | any(size(stat)~=1)                   % stat must be a scalar
            %warning(['"' func '" did not return a scalar.  Output ignored.']);
            %stat=NaN;
            if ~iscell(data), data=num2cell(data); end
          end
          if iscell(data), stat={stat}; end
          data(v,s,r)=stat;                                          % Put stats for this ROI into a row
        end
      end % for r (processing each ROI)
    end % if isempty
    if ~ishandle(p), emsg='User abort'; error(emsg); end
    progbar(p,v/dataSize(4));
  end % for v
  % Cleanup any temporary files associated with this mrinfostruct
  readmr(mrinfostruct,'=>CLEANUP');
  delete(p);
  if nargout>0, dataOut=data; end
  
catch
  if isempty(emsg)
    if isempty(lasterr)
      emsg='An unidentified error occurred!';
    else
      emsg=lasterr;
    end
  end
  % Cleanup any temporary files associated with this mrinfostruct
  if ~isempty(mrinfostruct), readmr(mrinfostruct,'=>CLEANUP'); end
  if ishandle(p), delete(p); end
  if inGUI
    disp(sprintf('GUI Error:\n%s',emsg));
    errorbox(emsg);
  else
    error(emsg);
  end
end

% Modification History:
%
% $Log: roistats.m,v $
% Revision 1.11  2006/11/27 16:25:25  gadde
% Allow input argument to be MR struct (as returned by readmr).
%
% Revision 1.10  2005/02/03 17:08:09  michelich
% M-lint:  Remove unnecessary commas.
%
% Revision 1.9  2005/02/03 16:58:43  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.8  2004/10/13 19:32:47  michelich
% Fix typo in error message.
%
% Revision 1.7  2003/10/22 15:54:39  gadde
% Make some CVS info accessible through variables
%
% Revision 1.6  2003/08/15 15:10:50  michelich
% Updated examples and removed untested warning.
%
% Revision 1.5  2003/08/15 14:29:43  michelich
% Changes based on Michael Wu's testing:
% Added BXH example.
% Support 3D input series.
% Corrected varaible name in error messages.
%
% Revision 1.4  2003/07/30 15:18:50  michelich
% Updated to use new READMR.  Use typeSpec instead of params.
% Added support for zooms.
%
% Revision 1.3  2003/07/03 18:15:12  michelich
% Removed inGUI argument from readmr call (new version does not support this).
%
% Revision 1.2  2002/11/26 19:50:46  michelich
% Bug fix: Zoom was not being applied.  If zoom is not full size, issue an error.
%   If the zoom becomes useful in the future, support for it can be added.
% Added support for interpolation in the slice direction.
% Use the actual scale factors in x & y instead of the min (warn if different).
% Only calculate the scale factors once.
% Check that each volume read is the expected size.
%
% Revision 1.1  2002/08/27 22:24:25  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2001/01/25. Changed function name to lowercase.
%                                Changed readmr() to lowercase and updated comments.
%                                Changed see also to uppercase
% Francis Favorini,  2000/05/05. Fixed bug: Don't try to apply limits when isempty(voxels).
% Francis Favorini,  2000/05/04. Fixed bug: after data was converted to a cell array, wasn't inserting new
%                                stats as cells.
% Francis Favorini,  2000/04/07. Allow non-scalar return value from statFunc.  In this case data is returned
%                                as a cell array of results.
% Charles Michelich, 2000/03/27. Removed check for square series in argument checking
% Charles Michelich, 2000/03/26. Removed restriction that roi must be defined on square series since overlay2 can 
%                                generate rois on non-square baseimages now.
%                                Removed line that padded series out to a squaresrs.
% Francis Favorini,  2000/02/22. Handle bug in MATLAB 5.3 dir.
% Francis Favorini,  2000/02/17. Added warnings when stats results are not valid and NaNs are substituted.
% Francis Favorini,  2000/02/16. Allow empty zoom for no zooming of data.
%                                Use eval to support more general statFuncs.
%                                Renamed pixData to voxels to help users with using above feature.
%                                Moved apostrophe to correct location in above-mentioned comment change. (slices' ;-)
%                                Improved argument checking.
%                                Force statFunc to be a cellstr to simplify later code.
%                                For unreadable volume, return NaNs only for that volume's stats.
%                                Made inGUI an undocumented argument.
% Charles Michelich, 2000/02/16. Moved roi's to the third dimension of the output & updated help
%                                Initialized data before processing roi's
% Charles Michelich, 2000/02/15. Allow empty statFunc and limits to specify default.
%                                Allow multiple ROIs to be passed.
%                                Changed comment on this line to note that all pixels are put in a single column
%                                instead of a separate column for each slice as previously noted. (no change in code)
%                                pixData=[pixData; sliceData(roi.index{s})];    % Put all slice's pixels in a column
% Francis Favorini,  1998/12/01. Added error catching.
% Francis Favorini,  1998/11/11. Handle user abort.
% Francis Favorini,  1998/10/29. Added progress bar.
% Francis Favorini,  1998/09/30. Added zoom argument.
%                                Handle bad MR parameters by skipping series and returning NaN's.
% Francis Favorini,  1998/09/22. Interpolate series if needed.
% Francis Favorini,  1998/09/01. Consolidates params passed to readmr.
% Francis Favorini,  1998/08/18.
