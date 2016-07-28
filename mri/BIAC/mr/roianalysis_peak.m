function outputData=roianalysis_peak(dataPath,dataFileSpec,typeSpec,zoom,roiPath,roiFileSpec,...
  studies,bins,gyri,sides,slices,outputExcelFileName,preStimMeanSpecifier,tPoints, ...
  splineTR,tRanges,statFunc,limits,subBaselineForPerChange)
%ROIANALYSIS_PEAK Calculates peak value and time within several spline interpolated ROI time series
%
%  This MATLAB function calculates peak value and time within numerous ROI
%  spannning studies, gyri, stides, slices, and bins.  The script calculates
%  the peak value and time at peak value of the percent signal change spline
%  interpolated time series for each roi.  The output is formated for a pivot
%  table with all appropriate labels included.  Each study is put on a
%  separate sheet in an Excel file saved at the specified location.
%
%  out=roianalysis_peak(dataPath,dataFileSpec,typeSpec,zoom,roiPath,roiFileSpec,...
%    studies,bins,gyri,sides,slices,outputExcelFileName,preStimMeanSpecifier,tPoints, ...
%    splineTR,tRanges,statFunc,limits,subBaselineForPerChange)
%
%  Inputs:
%    ------ MR Image Data Specificiations ------
%    dataPath is the path to the data to analyze without the series specifier
%    dataFileSpec is a string that is evaluated to generate the file name of the image files to be processed
%    typeSpec is a string or cell array containing the READMR typespec
%    zoom specifies how to zoom in on the images before applying stats.
%      The format is [xo yo xs ys], where (xo,yo) is the new upper left corner,
%      and [xs ys] is the new dimensions of the zoomed images.
%      You may use [] to specify the full image size.
%
%    ------ ROI Specifications ------
%    roiPath is a string specifying the path to the ROI files
%    roiFileSpec is a string that is evaluated to generate the file name of the roi files to be processed
%
%    ------ Subjects and Regions to Analyze ------
%    studies is a cell array of the full study numbers (Study date and exam number)
%    bins is a cell array of bins to analyze.  Just put {'1'} if you don't use 'bin' in the dataFileSpec
%      Note that you must include any leading zeros because this is a string.
%    gyri is a cell array of the names of the gyri to analyze.
%    sides is a cell array of the sides to analyze.
%    slices is a cell array or numeric array of the slices to analyze.
%      If a numeric array is specified, it is automatically converted to a
%      two digit padded integer (i.e. %02d) string.
%
%    ------ Other Variables ------
%    outputExcelFileName is the file name for the output excel file.
%      Saved in dataPath if outputExcelFileName does not include a path.
%    preStimMeanSpecifier determines how the prestimulus baseline is calculated.
%      If preStimMeanSpecifier is a string, (i.e. tstatprofie analysis results)
%        This string is evaluated to generate the file name of the image
%        file containing the baseline values.  The baseline is then calculate
%        calculated as the ROI average within the specified image.  There
%        can be but does not have to be, a different file for each bin and
%        study. 
%      If preStimMeanSpecifier is a vector of indicies, (i.e. mrtest analysis results)
%        The ROI average of across the prestimulus time points
%        tPoints(preStimMeanSpecifier) are used as the prestimulus
%        baseline.  A new baseline is calculated for each ROI, bin, and study.   
%    subBaselineForPerChange determines if baseline is subtracted from data
%      when calculating percent signal change. (==0 don't subtract, ~=0 subtract)
%        Default = 1 if preStimMeanSpecifier is numbers. (i.e. mrtest analysis results)
%        Default = 0 if preStimMeanSpecifier is a string. (i.e. tstatprofie analysis results)
%      NOTE: The data MUST already have the baseline removed for the percent
%        signal change output to be correct if you use subBaselineForPerChange==0
%    tPoints is a vector of labels for each time point (seconds). Time points must be uniformly spaced.
%    splineTR is a scalar indicating the spacing between interpolated time points. (seconds)
%    tRanges is a cell array of two element vectors specifying the [startTime, stopTime] to search for 
%      the peak in.  The peak value and time is found with the search region specified in each element
%      of the cell array.   All time values use tPoints as the time reference.  If interpolated data does
%      not exist at the start and stop times requested, the nearest time point that falls within the range
%      is used instead.  All times should be in seconds.
%
%    ------ Statistical function and limits to pass to ROIStats
%    statFunc is the function to apply to the pixels within the ROI.
%      Default is 'mean'.  Enter [] to use the default.
%    limits is [min max] for pixel values within the ROI.  Values
%      outside the limits are ignored when calculating the stats.
%      Default is [] which means there are no limits.
%
%  Outputs:
%    Excel spreadsheet saved within the outputExcelFileName 
%      (in dataPath if outputExcelFileName does not include a path)
%
%    out is an array of structures containing the data sent to the Excel
%      spreadsheet.  The argument is optional and redundant with the output
%      Excel spreadsheet.  The fields are: 
%        out.sheetname: name of sheet data sent to in Excel
%        out.data: cell array of data sent to Excel
%
%  The following code is used to generate the file names:
%  (Note that preStimMeanDataSpec is only calculated if the
%   preStimMeanSpecifier is a string)
%
%    dataSpec = fullfile(dataPath,eval(dataFileSpec));
%    roiSpec = fullfile(roiPath,eval(roiFileSpec));
%    preStimMeanDataSpec = fullfile(dataPath,eval(preStimMeanSpecifier));
%
%  Please note that the following variables are available for use in
%    roiFileSpec, dataFileSpec, and preStimMeanSpecifier:
%    (all variables are cell arrays of strings)
%
%    studies{study} => The current study from studies being analyzed
%    bins{bin}      => The current bin from bins being analyzed
%
%  The following additional variables are avaialable only for use in
%    roiFileSpec:   (all variables are cell arrays of strings)
%
%    gyri{gyrus}    => The current gyrus from gyri being analyzed
%    sides{side}    => The current side from sides being analyzed
%    slices{slice}  => The current slice from slices being analyzed
%
%  Example:
%    % Using "Raw" format typeSpec:
%    dataPath = '\\Server\Share\Group\Experiment.01\Analysis\';
%    dataFileSpec = 'sprintf(''%s\\Avg_%s_V*.img'',studies{study},bins{bin})';
%    typeSpec = {'Float',[64,64,20]};
%
%    % Using "BXH" format typeSpec:
%    dataPath = '\\Server\Share\Group\Experiment.01\Analysis\';
%    dataFileSpec = 'sprintf(''%s\\Avg_%s_V.bxh'',studies{study},bins{bin})';
%    typeSpec = 'BXH';
%
%    zoom = [];
%    roiPath = '\\Server\Share\Group\Experiment.01\Analysis\ROIs\IndividualSlice\';
%    roiFileSpec = 'sprintf(''%s\\%s%s_%s_s%s.roi'',studies{study},gyri{gyrus},sides{side},studies{study},slices{slice})';
%    studies = {'20010101_11111' '20010102_11112' '20010103_11113' '20010104_11114'};
%    bins = {'Category1','Category2','Category3','Category4'};
%    gyri = {'ACG','STS',MFG'};
%    sides = {'r' 'l'};
%    slices = [5:11];
%    tPoints = [-15 -12 -9 -6 -3 0 3 6 9 12 15 18 21 24 27 30];
%    outputExcelFileName = 'roiPeakOutput';
%    splineTR = 1;
%    tRanges = {[0,18],[18,30]};
%
%    % For tstatprofile analysis results:
%    preStimMeanSpecifier = 'sprintf(''%s\\baselineAvg.img'',studies{study})'; % "Raw" format
%    preStimMeanSpecifier = 'sprintf(''%s\\baselineAvg.bxh'',studies{study})'; % "BXH" format
%    OR 
%    % For mrtest analysis results:
%    preStimMeanSpecifier = [5:6];
%
%    roianalysis_peak(dataPath,dataFileSpec,typeSpec,zoom,roiPath,roiFileSpec,...
%      studies,bins,gyri,sides,slices,outputExcelFileName,preStimMeanSpecifier,tPoints, ...
%      splineTR,tRanges);
%
%   Note:  ONLY works for a single statFunc at a time currently
%          ONLY works if time series are the same length for all studies
%          Interpolation is a cubic spline with not-a-knot end conditions
%          
%  See Also: ROISTATS, ROIANALYSIS_TIMECOURSE, ROIANALYSIS_COUNT, ROIUNIONEXAMS

% Backwards compatibilty note:
% Also supports old-style "Volume" and "Float" formats for backward compatibility.
%   typeSpec = {xSz,ySz,zSz,'volume'} => {'Volume',[xSz,ySz,zSz]}
%   typeSpec = {xSz,ySz,zSz,'float'}  => {'Float' ,[xSz,ySz,zSz]}

% CVS ID and authorship of this code
% CVSId = '$Id: roianalysis_peak.m,v 1.16 2005/02/03 16:58:42 michelich Exp $';
% CVSRevision = '$Revision: 1.16 $';
% CVSDate = '$Date: 2005/02/03 16:58:42 $';
% CVSRCSFile = '$RCSfile: roianalysis_peak.m,v $';

lasterr('');  % Clear last error message
emsg='';      % Error message string
try           % Use try block to handle deleting the progress bars if an error occurs
  % Check number of inputs
  error(nargchk(16,19,nargin))
  
  % Set defaults
  if nargin < 17, statFuncs = []; end
  if nargin < 18, limits = []; end
  if nargin < 19 | isempty(subBaselineForPerChange)
    if isnumeric(preStimMeanSpecifier) 
      % Default to subtract baseline, if using vector of time points to
      % calculate prestimulus baseline.
      subBaselineForPerChange=1;
    elseif ischar(preStimMeanSpecifier)
      % Default to NOT subtract baseline, if using a separate file to
      % calculate prestimulus baseline.
      subBaselineForPerChange=0;
    else
      emsg = 'preStimMeanSpecifier must be a single string or a vector of indicies!'; error(emsg);
    end
  end
  
  % Check input variables
  if ~ischar(dataPath)
    emsg = 'dataPath must be a single string.'; error(emsg);
  end
  if ~ischar(dataFileSpec)
    emsg = 'dataFileSpec must be a single string.'; error(emsg);
  end
  % Support old-style readmr parameters.
  if iscell(typeSpec) & length(typeSpec)==4 & any(strcmpi(typeSpec{4},{'Volume','Float'})) & ...
      isnumeric(typeSpec{1}) & isnumeric(typeSpec{2}) & isnumeric(typeSpec{3})
    typeSpec={typeSpec{4},[typeSpec{1:3}]};
  end
  if ~isempty(zoom) & (length(zoom)~=4 | any(~isnumeric(zoom)))
    emsg = 'Invalid zoom parameters.'; error(emsg);
  end
  if ~ischar(roiPath) 
    emsg = 'roiPath must be a single string.'; error(emsg);
  end
  if ~ischar(roiFileSpec)
    emsg = 'roiFileSpec must be a single string.'; error(emsg);
  end
  if ~iscellstr(studies) | ~iscellstr(gyri) | ~iscellstr(sides) | ~iscellstr(bins)
    emsg = 'studies, gyri, bins, and sides must all be cell arrays of strings.'; error(emsg)
  end
  if any(~isnumeric(tPoints))
    emsg = 'tPoints must be a numeric array.'; error(emsg)
  end
  if ~(isnumeric(slices) | iscellstr(slices))
    emsg = 'slices must be a cell array of strings or a vector of numbers.'; error(emsg);
  end  
  if ~ischar(outputExcelFileName)
    emsg = 'outputExcelFileName must be a single string.'; error(emsg);
  end
  if ~(ischar(preStimMeanSpecifier) | isnumeric(preStimMeanSpecifier))
    emsg = 'preStimMeanSpecifier must be a single string or a vector of indicies!'; error(emsg);
  end
  if ~isnumeric(subBaselineForPerChange) | (length(subBaselineForPerChange)~=1)
    emsg = 'subBaselineForPerChange must be a single number!'; error(emsg);
  end
  if any(diff(tPoints) ~= tPoints(2)-tPoints(1))
    emsg = 'tPoints must be uniformly spaced.'; error(emsg);
  end
  if ~isnumeric(splineTR) | length(splineTR) ~= 1 | splineTR <= 0
    emsg = 'splineTR must be a positive numeric scalar.'; error(emsg);
  end
  % Check to make sure that each element in tRanges is a real numeric vector of size 1x2 or 2x1
  if any(cellfun('length',tRanges) ~=2 | cellfun('length',tRanges)./cellfun('prodofsize',tRanges) ~= 1 | ...
      ~cellfun('isclass',tRanges,'double') | ~cellfun('isreal',tRanges))
    emsg = 'Each element in tRanges must be a 2 element numeric vector.'; error(emsg);
  end
  % Check that there is only one 1 x n string for the statFunc (or empty)
  if ~isempty(statFunc) & ~(ischar(statFunc) & ndims(statFunc) == 2 & size(statFunc,1) == 1)
    emsg = ['This roi analysis script only supports one statistic at a time currently.   ', ...
        'Please specify statFunc as a single 1 x n string'] ; error(emsg);
  end
  % Check to make sure user is aware of the results of changing statFunc and limits variables
  if ~isempty(statFunc) & ~strcmp('mean',statFunc)
    warning('You are not using the mean statistic!  The percent signal change column will be incorrect!')
  end
  
  % Convert slices to a cell array (Padding using %02d)
  if isnumeric(slices)
    slicesOrig=slices;
    slices=cell(size(slicesOrig));
    for n=1:length(slicesOrig)
      slices{n}=sprintf('%02d',slicesOrig(n));
    end
    clear('slicesOrig'); 
  end
  
  % Determine output data array size and check to see if it is too long for Excel
  len=length(bins)*length(gyri)*length(sides)*length(slices)*length(tRanges)+1;
  if len > 65536
    emsg='You are trying to analyze too many ROIs (more than 65536 rows in Excel)'; error(emsg);
  end
  
  % Initialize roibasesize to a null value just in case it exists in the current workspace.
  roibaseSize = [0 0 0];
  
  % Generate a label for each tRange
  for n = 1:length(tRanges)
    % Extract vector for each range
    range = tRanges{n};
    
    % Generate label for spreadsheet
    tRangeLabel{n} = sprintf('%d to %d',range(1),range(2));
  end
  
  % Initalize prototype output data array (All output for a single study)
  dataProto = cell(len,8);
  
  % Initialize prototype output data array headings
  dataProto(1,:) = {'Study' 'Bin' 'Gyrus' 'Side' 'Slice' 'Time Range' 'Peak Value (% Sig Change)' 'Peak Time (sec)'};
  
  % Initialize index to output data array (points to current empty row)
  data_i = 2;
  
  tSz = length(tPoints);	% Length of each time series
  
  % Determine the number of tsv's and initialize counter for the number of tsv's processed
  nTsv = length(studies)*length(bins);
  
  % Initialize progress bar for count number of tsv's to process
  p=progbar(sprintf('Loading ROI''s for 0 of %d tsv''s',nTsv),[-1 0.6 -1 -1]);
  % Initialize counter for tsv progress bar
  tsv_i = 1;
  
  % Check to make sure that all ROIs Exist and that the baseSizes are correct
  % and generate all of the labels for a prototype output data array
  for study = 1:length(studies)
    for bin = 1:length(bins)
      % Initialize counter for the current roi in a group
      groupedRoi_i = 1;
      
      % Update Progress bar for number of ROIs processed if it still exists
      if ~ishandle(p), emsg='User abort'; error(emsg); end
      progbar(p,tsv_i/nTsv,sprintf('Loading ROI''s for %d of %d tsv''s',tsv_i,nTsv));
      tsv_i = tsv_i+1;	% Update counter
      
      for gyrus = 1:length(gyri)
        for side = 1:length(sides)
          for slice = 1:length(slices)
            roiSpec = fullfile(roiPath,evalRoiFileSpec(roiFileSpec, ...
              studies,study,bins,bin,gyri,gyrus,sides,side,slices,slice));
            if ~exist(roiSpec)
              emsg=['This ROI file ',roiSpec,' does not exist!']; error(emsg);
            else
              clear roi
              try
                load(roiSpec,'-mat');
              catch
                emsg=sprintf('Error loading ROI file %s:\n%s',roiSpec,lasterr);
                error(emsg);
              end
              if ~exist('roi','var') | ~isroi(roi)
                emsg=['The ROI in "' roiSpec '" is invalid!']; error(emsg);
              end
              % Remove .val and .color fields so that all ROIs have the same structure.
              [tmp1,tmp2,form]=isroi(roi); clear tmp1 tmp2
              if form == 2, roi = rmfield(roi,{'val','color'}); end, clear form
              if data_i == 2
                roibaseSize = roi.baseSize;
              elseif ~isequal(roi.baseSize,roibaseSize)
                emsg=['roibaseSize specified does not match the baseSize of ',roiSpec]; error(emsg);
              end
              
            end
            
            % Store roi sorting by patient and study
            groupedRoi(groupedRoi_i,bin,study) = roi;
            
            % Update pointer to current roi in group
            groupedRoi_i = groupedRoi_i + 1;
            
            % The prototype is only for one study so only generate it on the first study loop
            if study == 1
              % Generate vector of indicies in dataProto that the current roi corresponds to
              curr_i = data_i:data_i + length(tRanges)-1;
              
              dataProto(curr_i,2) = repmat(bins(bin),[length(tRanges) 1]);				% Label Bin
              dataProto(curr_i,3) = repmat(gyri(gyrus),[length(tRanges) 1]);			% Label Gyrus
              dataProto(curr_i,4) = repmat(sides(side),[length(tRanges) 1]);			% Label Side
              dataProto(curr_i,5) = repmat(slices(slice),[length(tRanges) 1]);		% Label Slice
              dataProto(curr_i,6) = tRangeLabel;													% Label time ranges
              
              % Update pointer to open data row and current roi in group
              data_i = data_i+length(tRanges);
              
            end                   
          end % for slice
        end % for side
      end % for gyrus        
    end % for bin
  end % for study
  delete(p) % Delete Progress bar
  
  % Determine the number of ROIs for each tsv
  nRoi = size(groupedRoi,1);
  % Initialize progress bar for count number of tsv's to process
  p=progbar(sprintf('Processing %d ROI''s for 0 of %d tsv''s',nRoi,nTsv),[-1 0.6 -1 -1]);
  % Initialize counter for tsv progress bar
  tsv_i = 1;
  
  % Initialize output array if requested.
  if nargout > 0,
    outputData=repmat(struct('sheetname',[],'data',[]),1,length(studies)); 
  end
  
  hXL=toexcel('Private');     % Private handle to Excel (invisible until we dump data into it)
  
  % Loop through each study
  for study = 1:length(studies)
    % Make a copy of the prototype output data format
    data = dataProto;
    
    % Initialize index to output data array (points to current empty row)
    data_i = 2;
    
    % Loop through each bin
    for bin = 1:length(bins)
      % Update Progress bar for number of ROIs processed if it still exists
      if ~ishandle(p), emsg='User abort'; error(emsg); end
      progbar(p,tsv_i/nTsv,sprintf('Processing %d ROI''s for %d of %d tsv''s',nRoi,tsv_i,nTsv));
      
      tsv_i = tsv_i+1;  % Update counter
      
      % Determine the file specifier for the data for the study and bin
      dataSpec = fullfile(dataPath,evalDataFileSpec(dataFileSpec,studies,study,bins,bin));
      
      % Calculate statistics for all roi's for this study and bin
      % meandata is a 3D array with dimensions (tPoints, statFunc, roi)
      meandata = roistats(dataSpec,typeSpec,zoom,groupedRoi(:,bin,study),statFunc,limits);
            
      % Check to make sure that the output statistics has the number of time points expected
      if size(meandata,1) ~= tSz
        emsg=['Study ', dataSpec , ' does not contain ' , num2str(tSz) , ' time points!']; error(emsg);
      end   

      % Remove 2nd dimension since there is only one statFunc calculated)         
      % Move middle singleton dimension to end so we get a 2D matrix
      % Now there is one roi per column of meandata
      meandata = permute(meandata(:,1,:),[1 3 2]);
      
      % --- Calculate prestimulus baseline ---
      if ischar(preStimMeanSpecifier)
        % preStimMeanSpecifier is a string, use it to generate the filename
        % of the image file containing the baseline values.
        
        % Calculate the prestim mean from the volume passed
        % prestimmeanData is a 3D array with dimensions (1, 1, roi)
        % Calculate ONLY the mean (use NaN if there are no voxels)
        preStimMeanDataSpec = fullfile(dataPath, ...
          evalPreStimMeanSpecifier(preStimMeanSpecifier,studies,study,bins,bin));

        prestimmean = roistats(preStimMeanDataSpec,typeSpec,zoom,groupedRoi(:,bin,study), ...
          {'evalif(''isempty(voxels)'',''NaN'',''mean(voxels)'')'});
        
        % Check to make sure that the prestimmean output only has one time point
        if size(prestimmean,1) ~= 1
          emsg=['Study ', preStimMeanDataSpec , ' contains more than one time point!']; error(emsg);
        end
        
        % Check to make sure that there is ONLY one statistical function output (mean)
        if size(prestimmean,2) ~= 1
          emsg=['Study ', preStimMeanDataSpec , ' contains more than one statistical function!']; error(emsg);
        end
      
        % Mean is the first statFunc
        % Move middle singleton dimension to end so we get a 2D matrix
        % Now there is one roi per column of meandata
        prestimmean = permute(prestimmean(:,1,:),[1 3 2]);
      else
        % If preStimMeanSpecifier is a vector of numbers, use it as
        % indicies of baseline time points.

        prestimmean = mean(meandata(preStimMeanSpecifier,:),1);
      end
      % Replicate to the number of time points.
      prestimmean = repmat(prestimmean,[tSz 1]);
      
      % --- Calculate the percent signal change for each roi ---
      if subBaselineForPerChange
        % Substract prestimulus baseline
        % NOTE: This method of calculating percent signal change assumes
        %   that the baseline HAS NOT already been removed from the data!
        percentSigChange = meandata./prestimmean - 1;
      else
        % Don't subtract prestimulus baseline
        % NOTE: This method of calculating percent signal change assumes
        %   that the baseline HAS already been removed from the data!     
        percentSigChange = meandata./prestimmean;
      end
      
      % Calculate spline percent signal change time courses to new splineTR
      
      % Determine points to interpolate at.
      splinedtPoints = tPoints(1):splineTR:tPoints(end);
      
      % Interpolate using cubic spline interpolation with not-a-knot end conditions
      splinedPercentSigChange = interp1(tPoints',percentSigChange,splinedtPoints','spline');
      
      % Find peak value and peak time in each of the specified ranges
      for peakN = 1:length(tRanges)
        
        % Extract limits of current search
        currtRange = tRanges{peakN};
        
        % Find indicies to splined time vector nearest to desired current start and stop times
        start_i = find(splinedtPoints >= currtRange(1));
        start_i = start_i(1);
        stop_i = find(splinedtPoints <= currtRange(2));
        stop_i = stop_i(end);
        
        % Check to make sure that start and stop aren't the same point
        if start_i == stop_i
          emsg=('Range specified only contains one point!'); error(emsg);
        else                  
          % Find peak in range
          [currpeakVal peak_i] = max(splinedPercentSigChange(start_i:stop_i,:));
          
          % Generate a matrix of times
          currtRangeSearched = splinedtPoints(start_i:stop_i);
          
          % Find time of each peak
          currpeakTime = currtRangeSearched(peak_i);
          
          % Save peak time and value
          % The nth row contains the peak for the nth range
          peakVal(peakN,:) = currpeakVal;
          peakTime(peakN,:) = currpeakTime;
        end
        
      end
      
      % Add current data to the end of the data
      % Note: Using : fills by column left to right, so the data matrix is filled by roi
      data(data_i:data_i+size(groupedRoi,1)*length(tRanges)-1,1) = {studies{study}};		% Label Study
      data(data_i:data_i+size(groupedRoi,1)*length(tRanges)-1,7) = num2cell(peakVal(:));	% Peak Value
      data(data_i:data_i+size(groupedRoi,1)*length(tRanges)-1,8) = num2cell(peakTime(:));	% Peak Time
      
      % Update pointer to open data row
      data_i = data_i+size(groupedRoi,1)*length(tRanges);
    end % for bin
    
    % Send the current subject's data to a new sheet in excel Name Patient Date & Exam #
    toexcel(hXL,data,1,1,studies{study})
    if nargout > 0
      % Save output in matrix
      outputData(study).sheetname=studies{study};
      outputData(study).data=data;
    end
    clear data
  end % for study
  delete(p)	% Delete the progress bar
  
  % Save the workbook and clean up when done analyzing
  if isempty(fileparts(outputExcelFileName))
    % Save in dataPath if outputExcelFileName does not include a path
    outputExcelFileName=fullfile(dataPath,outputExcelFileName);
  end
  toexcel(hXL,'SaveAs',outputExcelFileName);
  toexcel(hXL,'Cleanup');
  
catch                   % Display captured errors and delete progress bar(s) if they exists
  if isempty(emsg)
    if isempty(lasterr)
      emsg='An unidentified error occurred!';
    else
      emsg=lasterr;
    end
  end
  
  if exist('p'), 
    if ishandle(p), delete(p); end
  end
  
  if exist('hXL') & isa(hXL,'activex')
    toexcel(hXL,'ForceDone');
  end
  
  error(emsg);
end

% --- Local functions ---
function dataFileSpecCurr = evalDataFileSpec(dataFileSpec,studies,study,bins,bin)
%evalDataFileSpec - Generate data specifier in a "controlled" environment
%
%  Generate data specifier limiting user to using the variables:
%    studies, study, bins, bin.
try
  dataFileSpecCurr = eval(dataFileSpec);
catch
  error(sprintf(...
    ['Unable to evaluate dataFileSpec!\n', ...
      'Check that it only uses the variables studies{study} and bins{bin}\n', ...
      'Error Message was: %s'],lasterr));
end

function roiFileSpecCurr = evalRoiFileSpec(roiFileSpec,studies,study,bins,bin,gyri,gyrus,sides,side,slices,slice)
%evalRoiFileSpec - Generate ROI specifier in a "controlled" environment
%
%  Generate ROI specifier limiting user to using the variables:
%    studies, study, bins, bin, gyri, gyrus, sides, side, slices, slice
try
  roiFileSpecCurr = eval(roiFileSpec);
catch
  error(sprintf(...
    ['Unable to evaluate roiFileSpec!\n', ...
      'Check that it only uses the variables studies{study}, bins{bin}, gyrus{gyri}, sides{side}, and slices{slice}\n', ...
      'Error Message was: %s'],lasterr));
end

function preStimMeanSpecifierCurr = evalPreStimMeanSpecifier(preStimMeanSpecifier,studies,study,bins,bin)
%evalPreStimMeanSpecifier - Generate data specifier in a "controlled" environment
%
%  Generate data specifier limiting user to using the variables:
%    studies, study, bins, bin.
try
  preStimMeanSpecifierCurr = eval(preStimMeanSpecifier);
catch
  error(sprintf(...
    ['Unable to evaluate preStimMeanSpecifier!\n', ...
      'Check that it only uses the variables studies{study} and bins{bin}\n', ...
      'Error Message was: %s'],lasterr));
end

% Modification History:
%
% $Log: roianalysis_peak.m,v $
% Revision 1.16  2005/02/03 16:58:42  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.15  2003/12/15 20:04:19  michelich
% Corrected capitalization of isroi.
% Remove val and color fields so that both ROI structure types can be stored
%   in the same array.
%
% Revision 1.14  2003/12/15 20:01:54  michelich
% Check that ROI loaded properly and is the correct format.
%
% Revision 1.13  2003/12/09 23:43:42  michelich
% Made local functions for dataFileSpec, roiFileSpec, and preStimMeanSpecifier
% evaulation such that other variables do not influence eval results (e.g.
% using gyri{gyrus} in a dataFileSpec).  Also report better error messages.
%
% Revision 1.12  2003/11/11 18:55:36  michelich
% Fixed error checking of statFunc... Handle empty statFunc correctly.
%
% Revision 1.11  2003/10/22 15:54:39  gadde
% Make some CVS info accessible through variables
%
% Revision 1.10  2003/09/08 19:29:30  michelich
% Fixed error checking of statFunc.
%
% Revision 1.9  2003/09/08 17:09:42  michelich
% Michael Wu's update for BXH compatibility:
% Updated help on typeSpec and examples for using BXH.
% Changed params to typeSpec.
% Added backward compatibility for the old params format.
%
% Revision 1.8  2003/07/31 04:05:06  michelich
% Updated help and examples.
% Don't open Excel until it is needed.
% Corrected capitalization of preStimMeanDataSpec and roistats.
% Reordered code in main processing loop to match other roianalysis functions.
%
% Revision 1.7  2003/02/03 20:12:32  michelich
% Added optional output argument containing excel data for easier testing.
% Changed toexcel to all lowercase.
% Added punctuation to argument checking error messages.
% Small whitespace and grammar changes.
% Handle empty zoom in error checking.
% Removed reference to unused variable preStimPts.
% Changed variable currdata to meandata to match other roianalysis_* functions.
% Refer to preStimMeanSpecifier instead of preStimMeanFileSpec.
%
% Revision 1.6  2002/12/31 22:20:53  michelich
% Added tstatprofile example.
%
% Revision 1.5  2002/12/03 21:01:26  michelich
% Optionally pass slices as a cell array of strings.
% Added ability to save excel file in a different path.
%
% Revision 1.4  2002/11/26 14:32:30  michelich
% Changed deprecated isstr to ischar
%
% Revision 1.3  2002/10/27 22:07:42  michelich
% Add defaults for statFuncs and limits arguments.
%
% Revision 1.2  2002/10/25 03:07:25  michelich
% Added ability to calculate prestimmean using either a
%   vector of time points or a filename specifier.
% Added ability to chose whether or not to subtract
%   prestimulus baseline when calculating percent signal change.
%
% Revision 1.1  2002/10/25 01:51:26  michelich
% Original CVS import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2002/10/24. Converted into function from roipeakscript.
% Charles Michelich, 2001/10/18. Changed to use iscellstr (instead of iscell) for checking studies,gyri,sides,bins
% Charles Michelich, 2001/06/20. Modified to use cell array of bins to support text bin labels
% Charles Michelich, 2001/05/01. Fixed bug for orientation of interp1 results for a single ROI of data.
% Francis Favorini,  2000/05/09. Use clear all at beginning and private toexcel with Cleanup at end.
% Charles Michelich, 2000/05/09. Fixed bug: was using ~= instead of isequal to compare baseSizes.
%                                Fixed bug: was using squeeze to remove singleton dimensions of currdata
% Charles Michelich, 2000/04/22. Created roiPeakScript.m (Modified from roiAnalysisScript.m)
%                                Changed to allow determination of the peak value and time of a spline
%                                interpolated time series.
% Francis Favorini,  2000/02/28. Added try,catch around load of ROI in case file is corrupt/empty.
% Charles Michelich, 2000/02/22. Changed order of columns to put mean at right side with other data
% Charles Michelich, 2000/02/18. Took out studies{study} from constuction of names for more flexibility
% Charles Michelich, 2000/02/16. Eliminated roibaseSize input argument (automatically read now)
%                                Changed string in progress bar to a more clear description
%                                Added check on input parameters
%                                Added progress bar for loading of ROIs and generation of dataProto
%                                Added squeeze(currdata) for new output format of ROIStats
% Charles Michelich, 2000/02/15. Changed name to roiAnalysisScript.m from roiAnalysisScript_roistats2.m
%                                Changed to use roiStats (with multiple passed rois)
%                                Changed study, gyrus, side, bin, slice to counters
% Charles Michelich, 2000/02/15. Changed name to roiAnalysisScript_roistats2.m from roiScriptNewInterp2.m
%                                Updated descriptions for submission into BIAC example scripts
%                                Added progress bar to interpolation and each total roi's processed
%                                Moved check for correct number of time points before interpolation
%                                Corrected length of output array (I had included length(bins) twice)
% Charles Michelich, 2000/01/14. Added Check for all ROI files before processing
%                                Added output of baseline mean and percent signal change
% Charles Michelich, 2000/01/11. original.  Adapted from roiscript
%                                Implemented as script until good function form can be determined
