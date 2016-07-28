function outputData=roianalysis_count(dataPath,dataFileSpec,typeSpec,zoom,roiPath,roiFileSpec,...
  studies,bins,gyri,sides,slices,outputExcelFileName, ...
  writeMaskedROIs,ranges,decDigits)
%ROIANALYSIS_COUNT Calculates information about # of voxel within several ROIs meeting the specified criteria
%
%  This MATLAB function calculates statistics within numerous ROIs spannning
%  studies, bins, gyri, studies, and slices.  The script calculates the number
%  of voxels in an ROI whose values are within the specified range(s), the
%  total number of voxels in an ROI, and the percentage of voxels in an ROI 
%  whose values are within the specified range(s).  The output is formatted
%  for a pivot table with all appropriate labels included.  Each study is put
%  on a separate sheet, and the Excel file is saved in the dataPath with the
%  user-specified name.  Optionally, it will write out new ROI files that are
%  masked based on the specified bins and ranges.
%
%  out=roianalysis_count(dataPath,dataFileSpec,params,zoom,roiPath,roiFileSpec,...
%    studies,bins,gyri,sides,slices,outputExcelFileName, ...
%    writeMaskedROIs,ranges,decDigits);
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
%    writeMaskedROIs should be 1 if you want to write out the masked ROI files, otherwise 0.
%    ranges is a cell array of 2-element vectors specifying the [min,max] voxels to include in the count.
%      Each element of the cell array is evaluated allowing count in multiple regions.  The statFunc passed
%      to roiStats is length(find(voxels >= range(1) & voxels < range(2))) where range(1) and range(2)
%      are the ranges for each cell.  Note that -inf and +inf can be used to specify comparisons such
%      voxels >= 5 (i.e. [5 inf]) or voxels < 4 (i.e. [-inf 4])
%    decDigits is how many digits after the decimal point to show in the range labels.
%      The range labels are also used to generate the masked ROI file names.
%      Note: range values will be rounded if they have more than decDigits after the decimal point.
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
%  The following code is used to generate the file names
%
%    dataSpec = fullfile(dataPath,eval(dataFileSpec));
%    roiSpec = fullfile(roiPath,eval(roiFileSpec)); 
%
%  Please note that the following variables are available for use in
%    roiFileSpec and dataFileSpec:
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
%    % Using "Raw" format typeSpec:
%    dataPath = '\\Server\Share\Group\Experiment.01\Analysis\';
%    dataFileSpec = 'sprintf(''%s\\Bin_%s.T'',studies{study},bins{bin})';
%    typeSpec = {'Float',[64,64,20]};
%
%    % Using "BXH" format typeSpec:
%    dataPath = '\\Server\Share\Group\Experiment.01\Analysis\';
%    dataFileSpec = 'sprintf(''%s\\Bin_%s_T.bxh'',studies{study},bins{bin})';
%    typeSpec = 'BXH';
%
%    zoom = [];
%    roiPath = '\\Server\Share\Group\Experiment.01\Analysis\ROI\IndividualSlice\';
%    roiFileSpec = 'sprintf(''%s\\%s%s_%s_s%s.roi'',studies{study},gyri{gyrus},sides{side},studies{study},slices{slice})';
%    studies = {'20010101_11111' '20010102_11112' '20010103_11113' '20010104_11114'};
%    bins = {'Category1','Category2','Category3','Category4'};
%    gyri = {'ACG','STS',MFG'};
%    sides = {'r' 'l'};
%    slices = [12:20];
%    writeMaskedROIs=0;
%    ranges = {[1.96 inf]};
%    decDigits = 2;
%    outputExcelFileName = 'ROICountTest';
%    roianalysis_count(dataPath,dataFileSpec,params,zoom,roiPath,roiFileSpec,...
%      studies,bins,gyri,sides,slices,outputExcelFileName,writeMaskedROIs,ranges,decDigits);
%
%  See Also: roistats, roianalysis_peak, roianalysis_timecourse, roiunionexams

% CVS ID and authorship of this code
% CVSId = '$Id: roianalysis_count.m,v 1.14 2005/02/16 01:53:48 michelich Exp $';
% CVSRevision = '$Revision: 1.14 $';
% CVSDate = '$Date: 2005/02/16 01:53:48 $';
% CVSRCSFile = '$RCSfile: roianalysis_count.m,v $';

% Backwards compatibilty note:
% Also supports old-style "Volume" and "Float" formats for backward compatibility.
%   typeSpec = {xSz,ySz,zSz,'volume'} => {'Volume',[xSz,ySz,zSz]}
%   typeSpec = {xSz,ySz,zSz,'float'}  => {'Float' ,[xSz,ySz,zSz]}

lasterr('');  % Clear last error message
emsg='';      % Error message string
try           % Use try block to handle deleting the progress bars if an error occurs 
  % Check number of inputs
  error(nargchk(15,15,nargin))
  
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
  if ~(isnumeric(slices) | iscellstr(slices))
    emsg = 'slices must be a cell array of strings or a vector of numbers'; error(emsg);
  end
  if ~ischar(outputExcelFileName)
    emsg = 'outputExcelFileName must be a single string.'; error(emsg);
  end
  if writeMaskedROIs~=0 & writeMaskedROIs~=1
    emsg = 'writeMaskedROIs must be a 0 or 1.'; error(emsg);
  end
  if ~iscell(ranges)
    emsg = 'ranges must be a cell array.'; error(emsg);
  end
  if length(decDigits)~=1 | ~isint(decDigits)
    emsg = 'decDigits must be an integer.'; error(emsg);
  end
  if any(~cellfun('isclass',ranges,'double') | ~cellfun('isreal',ranges) | ...
      cellfun('prodofsize',ranges) ~= 2)
    emsg = 'Each element in ranges must be a 2-element numeric vector.'; error(emsg);
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
  nStudies = length(studies);
  nBins = length(bins)+1;   % Includes 1 extra for union of all bins
  nGyri = length(gyri);
  nSides = length(sides);
  nSlices = length(slices);
  nRanges = length(ranges);
  len = 1+nBins*nGyri*nSides*nSlices*nRanges;
  if len > 65536
    emsg='You are trying to analyze too many ROIs/ranges! Excel is limited to 65536 rows.'; error(emsg);
  end
  
  hXL=toexcel('Private');     % Private handle to Excel (invisible until we dump data into it)
  
  % Build list of colHeaders
  % Note: Code farther below assumes the following order based on the column anchors
  ROIHeaders = {'Study' 'Bin' 'Gyrus' 'Side' 'Slice'};
  rangeHeaders = {'Range' 'Voxels in Range' 'Voxels in ROI' '% Voxels in Range'};
  colHeaders = [ROIHeaders rangeHeaders];
  studyCol = strmatch('Study',colHeaders,'exact');  % Anchors ROI label info
  rangeCol = strmatch('Range',colHeaders,'exact');  % Anchors range calcs
  
  % Build list of range Labels, StatFuncs and MaskFuncs
  % Ranges labels are handled specially: they are put in rows under the "Range" column
  for n = 1:nRanges
    range = ranges{n};
    % Note: rangeLabels is used below to generate new .ROI file names by changing " to " into "_"
    rangeLabels{n} = sprintf('%.*f to %.*f',decDigits,range(1),decDigits,range(2));
    % Generate rangeStatFunc to get voxel count in range
    % ex: length(find(voxels >= range(1) & voxels < range(2)));
    rangeStatFuncs{n} = sprintf('length(find(voxels >= %f & voxels < %f))',range(1),range(2));
    % Generate rangeMaskFuncs to mask voxels for masked ROIs (must correspond to above rangeStatFuncs!)
    rangeMaskFuncs{n} = sprintf('find(voxels >= %f & voxels < %f)',range(1),range(2));
  end
  rangeStatFuncs{nRanges+1} = 'length(voxels)';      % Total number of voxels in the ROI
  
  % Build complete list of statFuncs (use voxels to mask ROIs below)
  statFuncs = [rangeStatFuncs {'voxels'}];
  
  % Initalize prototype output data array (All output for a single study)
  dataProto = cell(len,length(colHeaders));
  dataProto(1,:) = colHeaders;
  
  clear groupedRoi        % In case it exists in the current workspace
  clear newRoiNames       % In case it exists in the current workspace
  roibaseSize = [0 0 0];  % Set to a null value in case it exists in the current workspace
  data_i = 2;             % Index to output data array (points to current empty row)
  
  % Initialize progress bar for count number of tsv's to process
  nTsv = nStudies*nBins;
  tsv_i = 1;  
  p = progbar(sprintf('Loading ROIs for 0 of %d TSVs',nTsv),[-1 0.6 -1 -1]);
  
  % Check to make sure that all ROIs exist, their baseSizes are correct,
  % and generate all of the labels for a prototype output data array
  for study = 1:nStudies
    for bin = 1:nBins       % Last one is union of all bins
      % Update Progress bar for number of ROIs processed if it still exists
      if ~ishandle(p), emsg='User abort'; error(emsg); end
      progbar(p,tsv_i/nTsv,sprintf('Loading ROIs for %d of %d volumes',tsv_i,nTsv));
      
      groupedRoi_i = 1;     % Initialize counter for the current roi in a group
      tsv_i = tsv_i+1;      % Update TSV counter
         
      for gyrus = 1:nGyri
        for side = 1:nSides
          for slice = 1:nSlices
            roiSpec = fullfile(roiPath,evalRoiFileSpec(roiFileSpec, ...
              studies,study,bins,bin,gyri,gyrus,sides,side,slices,slice));  % Also used to build newRoiNames
            if bin<nBins
              % Load ROI
              if ~exist(roiSpec)
                emsg=['ROI file "' roiSpec '" does not exist!']; error(emsg);
              else
                clear roi
                try
                  load(roiSpec,'-mat');
                catch
                  emsg=sprintf('Error loading ROI file "%s":\n%s',roiSpec,lasterr); error(emsg);
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
              % Store roi grouping by bin and study
              groupedRoi(groupedRoi_i,bin,study) = roi;
            end
              
            if writeMaskedROIs
              % Generate new ROI file name for each range by adding suffix based on bin and rangeLabel
              % Results in something like this '_b01_5.0_Inf' inserted just before the .ROI extension
              for n = 1:nRanges
                [pth name ext]=fileparts(roiSpec);
                rangeStr=strrep(rangeLabels{n},' to ','_');    % Replace ' to ' with '_'
                if bin==nBins
                  % Union of all bins
                  sortedbins = sort(bins); 
                  binStr=['b' sprintf('%s',sortedbins{:})];
                else
                  binStr=sprintf('b%s',bins{bin});
                end
                newRoiNames(n,groupedRoi_i,bin,study)={fullfile(pth,[name '_' binStr '_' rangeStr ext])};
              end
            end
            
            groupedRoi_i = groupedRoi_i + 1;              % Update pointer to current roi in group
            
            % The prototype is only for one study so only generate it on the first study loop
            if study == 1
              % Generate vector of indicies in dataProto that the current roi corresponds to
              curr_i = data_i:data_i+nRanges-1;
              
              if bin==nBins
                % Union of all bins
                dataProto(curr_i,studyCol+1) = repmat({'All'},[nRanges 1]);             % Label 'All' Bin
              else
                dataProto(curr_i,studyCol+1) = repmat({bins{bin}},[nRanges 1]);         % Label Bin
              end
              dataProto(curr_i,studyCol+2) = repmat(gyri(gyrus),[nRanges 1]);           % Label Gyrus
              dataProto(curr_i,studyCol+3) = repmat(sides(side),[nRanges 1]);           % Label Side
              dataProto(curr_i,studyCol+4) = repmat(slices(slice),[nRanges 1]);       % Label Slice
              dataProto(curr_i,rangeCol) = rangeLabels;                                 % Label Ranges
              
              % Update pointer to open data row and current roi in group
              data_i = curr_i(end)+1;
            end
            
          end % for slice
        end % for side
      end % for gyrus
    end % for bin
  end % for study
  delete(p) % delete progress bar
  
  % Determine the number of ROI for each tsv
  nRoi = size(groupedRoi,1);
  % Initialize progress bar for count number of tsv's to process
  tsv_i = 1;
  p=progbar(sprintf('Processing %d ROIs for 0 of %d volumes',nRoi,nTsv),[-1 0.6 -1 -1]);

  % Initialize output array if requested.
  if nargout > 0,
    outputData=repmat(struct('sheetname',[],'data',[]),1,length(studies)); 
  end

  % Loop through each study
  for study = 1:nStudies
    % Make a copy of the prototype output data format
    data = dataProto;
    
    % Initialize index to output data array (points to current empty row)
    data_i = 2;
    
    % Loop through each bin (last one is union of all bins)
    for bin = 1:nBins
      % Update Progress bar for number of ROIs processed if it still exists
      if ~ishandle(p), emsg='User abort'; error(emsg); end
      progbar(p,tsv_i/nTsv,sprintf('Processing %d ROIs for %d of %d volumes',nRoi,tsv_i,nTsv));
      
      tsv_i = tsv_i+1;                                   % Update counter
      
      if bin==nBins
        totalVoxels=zeros(nRanges,nRoi);
        % Union of all bins for each ROI/range
        for r = 1:nRoi
          for n = 1:nRanges
            roi = [];
            for b = 1:length(bins)    % Not nBins!
              roi=roiunion(roi,maskedGroupedRoi(n,r,b));
            end
            % Total voxels in ROI union
            totalVoxels(n,r)=sum(cellfun('length',roi.index));
            if writeMaskedROIs	
              % Save the masked ROI union
              if str2double(strtok(strtok(version),'.')) >=7
                % Save ROIs for MATLAB 5 & 6 compatibility
                save(newRoiNames{n,r,bin,study},'roi','-V6');
              else
                save(newRoiNames{n,r,bin,study},'roi');
              end			    
            end
          end
        end
        % These values don't apply for union of all bins ROI
        rangeVoxelCounts = repmat(NaN,size(totalVoxels));
        percentVoxels = repmat(NaN,size(totalVoxels));
      else
        % Data file specifier for this study and bin
        dataSpec = fullfile(dataPath,evalDataFileSpec(dataFileSpec,studies,study,bins,bin));
        
        % Calculate statistics for all roi's for this study and bin
        currdata = roistats(dataSpec,typeSpec,zoom,groupedRoi(:,bin,study),statFuncs);
        
        % Check to make sure that there was only one volume image
        if size(currdata,1) ~= 1
          emsg = sprintf('%s specifies more than one volume! This is not currently supported.',dataSpec);
          error(emsg);
        end
        
        % currdata is a 3D array with dimensions (tPoints, statFunc, roi)
        % Shift 1st dimension to end, which removes it, since it is a singleton
        % Don't use squeeze, since that won't work if there are other singleton dimensions
        currdata = shiftdim(currdata,1);
        
        % Mask and save the ROIs for each range
        for r = 1:nRoi
          for n = 1:nRanges
            roi=groupedRoi(r,bin,study);
            % Last statFunc returns all the voxels in the ROI with each
            % slice's voxels concatenated in a column in same order as roi.slice
            roiVoxels=currdata{end,r};
            % Mask the ROI by applying our rangeMaskFuncs to the voxels
            sliceOffset=0;
            for s = 1:length(roi.slice)
              % Mask each slice
              sliceLen=length(roi.index{s});
              voxels=roiVoxels(sliceOffset+[1:sliceLen]);   % rangeMaskFuncs expects voxels in 'voxels'
              roi.index{s}=index(roi.index{s},eval(rangeMaskFuncs{n}));
              sliceOffset=sliceOffset+sliceLen;
            end
            % Remove empty slices (all voxels may have been masked out)
            empties=cellfun('isempty',roi.index);    % Cellfun('isempty') returns logical array
            roi.index(empties)=[];
            roi.slice(empties)=[];
            maskedGroupedRoi(n,r,bin)=roi;           % Save masked ROI for union operation
            if writeMaskedROIs
              % Save the masked ROI
              save(newRoiNames{n,r,bin,study},'roi');
            end
          end % for n
        end % for r
        % Get rid of the 'voxels' statFunc results and turn currdata back into a numeric array
        % so the code below doesn't have to change.
        currdata(end,:)=[];
        currdata=reshape([currdata{:}],size(currdata));
      
        % Extract the total voxel count for each roi (last statFunc)
        totalVoxels = currdata(end,:);
        totalVoxels = repmat(totalVoxels,[nRanges 1]);
        
        % Extract the voxel counts for each range
        rangeVoxelCounts = currdata(1:end-1,:);
        
        % Calculate the % of voxels in a regions that are above a threshold
        percentVoxels = rangeVoxelCounts./totalVoxels;
      end % if bin==nBins
      
      % Add current data to the end of the data
      % Note: Using : fills by column left to right, so the data matrix is filled by roi
      data(data_i:data_i+nRoi*nRanges-1,studyCol) = studies(study);                     % Label Study
      data(data_i:data_i+nRoi*nRanges-1,rangeCol+1) = num2cell(rangeVoxelCounts(:));    % Voxels in a range
      data(data_i:data_i+nRoi*nRanges-1,rangeCol+2) = num2cell(totalVoxels(:));         % Total voxels in ROI
      data(data_i:data_i+nRoi*nRanges-1,rangeCol+3) = num2cell(percentVoxels(:));       % Percent of total voxels
      
      % Update pointer to open data row
      data_i = data_i+nRoi*nRanges;
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

% Modification History:
%
% $Log: roianalysis_count.m,v $
% Revision 1.14  2005/02/16 01:53:48  michelich
% Save ROIs for MATLAB 5 & 6 compatibility when using MATLAB 7 and later.
%
% Revision 1.13  2005/02/03 16:58:42  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.12  2004/12/14 01:58:00  michelich
% Fixed capitalization of roiunion.
%
% Revision 1.11  2003/12/15 20:04:19  michelich
% Corrected capitalization of isroi.
% Remove val and color fields so that both ROI structure types can be stored
%   in the same array.
%
% Revision 1.10  2003/12/09 23:49:04  michelich
% Made local functions for dataFileSpec and roiFileSpec evaulation such that
% other variables do not influence eval results (e.g. using gyri{gyrus} in a
% dataFileSpec).  Also report better error messages and updated help.
%
% Revision 1.9  2003/10/22 15:54:38  gadde
% Make some CVS info accessible through variables
%
% Revision 1.8  2003/09/08 17:25:26  michelich
% Michael Wu's update for BXH compatibility:
% Updated help on typeSpec and examples for using BXH.
% Changed params to typeSpec.
% Added backward compatibility for the old params format.
%
% Revision 1.7  2003/02/03 19:50:09  michelich
% Actually changed toexcel to all lowercase this time.
%
% Revision 1.6  2003/02/03 19:04:21  michelich
% Added optional output argument containing excel data for easier testing.
% Changed toexcel to all lowercase.
%
% Revision 1.5  2002/12/03 21:01:26  michelich
% Optionally pass slices as a cell array of strings.
% Added ability to save excel file in a different path.
%
% Revision 1.4  2002/11/26 14:31:21  michelich
% Changed deprecated isstr to ischar
%
% Revision 1.3  2002/10/27 22:05:53  michelich
% Updated description
%
% Revision 1.2  2002/10/25 03:05:20  michelich
% Remove ; on function
%
% Revision 1.1  2002/10/25 01:51:26  michelich
% Original CVS import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2002/10/24. Converted into function from roicountscript_newfix.
% Charles Michelich, 2001/10/30. Bug Fix:  If writeMaskedROIs = 0, the script was failing because the ROI for the
%                                  union of all bins was not being created.  Changed to always generate maskedGroupedROI
%                                  Removed "if writeMaskedROI" checks on generation of rangeMaskFuncs, addition of
%                                  'voxels' statFunc, and generation of maskedGroupedROI. Added "if writeMaskedROI"
%                                  checks before roi saves.
% Charles Michelich, 2001/10/18. Changed to use iscellstr (instead of iscell) for checking studies,gyri,sides,bins
% Charles Michelich, 2001/06/20. Modified to use cell array of bins to support text bin labels
% Francis Favorini,  2000/05/12. Properly create ROI for union of all bins.
% Francis Favorini,  2000/05/11. Create ROI for union of all bins.
%                                In catch block, clear all variables except emsg.
% Francis Favorini,  2000/05/09. Use clear all at beginning and private toexcel with Cleanup at end.
% Francis Favorini,  2000/05/05. Make sure each ROI file contains a valid ROI.
%                                Fixed bug: was using bin instead of bins(bin) in masked ROI file name.
%                                Fixed bug: was using ~= instead of isequal to compare baseSizes.
%                                Fixed bug: wasn't cleaning up empty roi.index elements.
% Francis Favorini,  2000/05/04. Added masked ROI output option.
%                                Use %.*d to output ranges with decDigits digits of precision.
%                                Fixed bug: need to use shiftdim instead of squeeze on currdata.
%                                Fixed bug: need to use nRanges in calculation of len.
%                                Updated some error messages/checks.
%                                Changed the way the headers are done.
%                                Allow user to specify [] for zoom.
% Charles Michelich, 2000/02/22. Created roiCountScript.m (Modified from roiAnalysisScript.m)
%                                Changed to allow counting all of the voxels within a range in an roi
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
% Charles Michelich, 2000/01/11. original. Adapted from roiscript
%                                Implemented as script until good function form can be determined
