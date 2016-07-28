function roiunionexams(roiPath,roiFileSpec,outRoiFileSpec,studies,bins,gyri,sides,slices)
%ROIUNIONEXAMS Generate rois that are the union across slices for specified exams
%
%  This MATLAB function generates new rois that are the union of the 
%  rois across all slices specifed.  The new rois are saved in the same 
%  location as the original rois.
%
%  roiunionexams(roiPath,roiFileSpec,outRoiFileSpec,studies,bins,gyri,sides,slices)
%
%  Inputs:
%    ------ ROI Specifications ------
%    roiPath is a string specifying the path to the ROI files
%    roiFileSpec is a string that is evaluated to generate the file name of the roi files to be processed
%    outRoiFileSpec is a string that is evaluated to generate the file name of the unioned roi
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
%  Outputs:
%    unioned rois are written to disk.
%
%  The following code is used to generate the file names
%
%    roiSpec = fullfile(roiPath,eval(roiFileSpec)); 
%
%  Please note that the following variables are available for use.
%    All variables are strings.  Please note the braces.
%
%    studies{study} => The current study from studies being analyzed
%    bins{bin}      => The current bin from bins being analyzed
%    gyri{gyrus}    => The current gyrus from gyri being analyzed
%    sides{side}    => The current side from sides being analyzed
%    slices{slice}  => The current slice from slices being analyzed
%
%  Example:
%    studies = {'021000_00502' '021000_00505'};
%    bins = {'01' '03'};
%    gyri = {'IFG' 'SFG' 'ACG' 'WHM'};
%    sides = {'R' 'L'};
%    slices = [19:25];
%    roiPath = '\\broca\data3\biac\MemLoad.fMRI.02\Data\Anat\ROI\';
%    roiFileSpec = 'sprintf(''%s\\%s%s_%s_sl%s.roi'',studies{study},gyri{gyrus},sides{side},studies{study},slices{slice})';
%    outRoiFileSpec = sprintf('%s%d-%d%s','sprintf(''%s\\%s%s_%s_sl',min(slices),max(slices), ...
%      '.roi'',studies{study},gyri{gyrus},sides{side},studies{study})');
%    roiunionexams(roiPath,roiFileSpec,outRoiFileSpec,studies,bins,gyri,sides,slices,inExcel_h);
%
%  See Also: roiunion, roianalysisexams, roicountexams, roipeakexams

% CVS ID and authorship of this code
% CVSId = '$Id: roiunionexams.m,v 1.7 2005/02/22 03:48:19 michelich Exp $';
% CVSRevision = '$Revision: 1.7 $';
% CVSDate = '$Date: 2005/02/22 03:48:19 $';
% CVSRCSFile = '$RCSfile: roiunionexams.m,v $';

lasterr('');  % Clear last error message
emsg='';      % Error message string
try           % Use try block to handle deleting the progress bars if an error occurs
  
  % Check number of inputs
  error(nargchk(8,8,nargin))
  
  % Check input variables
  if ~ischar(roiPath) 
    emsg = 'roiPath must be a single string.'; error(emsg);
  end
  if ~ischar(roiFileSpec)
    emsg = 'roiFileSpec must be a single string.'; error(emsg);
  end
  if ~ischar(outRoiFileSpec)
    emsg = 'outRoiFileSpec must be a single string.'; error(emsg);
  end
  if ~iscellstr(studies) | ~iscellstr(gyri) | ~iscellstr(sides) | ~iscellstr(bins)
    emsg = 'studies, gyri, bins, and sides must all be cell arrays of strings.'; error(emsg)
  end
  if ~(isnumeric(slices) | iscellstr(slices))
    emsg = 'slices must be a cell array of strings or a vector of numbers'; error(emsg);
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
  
  roibaseSize = [];  % Set to a null value in case it exists in the current workspace
  
  % Initialize progress bar for count number of volumes to process
  nTsv = length(studies)*length(bins);
  tsv_i = 1;
  p = progbar(sprintf('Loading ROIs for 0 of %d volumes',nTsv),[-1 0.6 -1 -1]);
  
  % Check to make sure that all ROIs exist, their baseSizes are correct,
  % and write output rois that are the union of the rois across slices
  for study = 1:length(studies)
    for bin = 1:length(bins)
      % Update Progress bar for number of ROIs processed if it still exists
      if ~ishandle(p), emsg='User abort'; error(emsg); end
      progbar(p,tsv_i/nTsv,sprintf('Loading ROIs for %d of %d volumes',tsv_i,nTsv));
      
      tsv_i = tsv_i+1;      % Update TSV counter
      
      for gyrus = 1:length(gyri)
        for side = 1:length(sides)
          % Initialize an array for the union of the roi's from all slices
          allslicesroi = [];
          
          for slice = 1:length(slices)
            % Load roi (and catch errors nicely)
            roiSpec = fullfile(roiPath,eval(roiFileSpec)); 
            if ~exist(roiSpec)
              emsg=['ROI file "' roiSpec '" does not exist!']; error(emsg);
            else
              % Clear previous roi
              clear roi              
              % Try to load roi
              try
                load(roiSpec,'-mat');
              catch
                emsg=sprintf('Error loading ROI file "%s":\n%s',roiSpec,lasterr); error(emsg);
              end       
              % Check that roi was loaded and is valid
              if ~exist('roi','var') | ~isROI(roi)
                emsg=['The ROI in "' roiSpec '" is invalid!']; error(emsg);
              end              
              % Check that the roibaseSizes are the same for all rois
              if isempty(roibaseSize)
                roibaseSize = roi.baseSize;
              elseif ~isequal(roi.baseSize,roibaseSize)
                emsg=['roibaseSize specified does not match the baseSize of ',roiSpec]; error(emsg);
              end
            end
            
            % Make a union of all slices
            allslicesroi = roiunion(allslicesroi,roi);
            
          end % for slice
          
          % Save the unioned by slice roi at the user specified path using their outRoiFileSpec
          roiName = fullfile(roiPath,eval(outRoiFileSpec));
          roi = allslicesroi;
          if str2double(strtok(strtok(version),'.')) >=7
            % Save ROIs for MATLAB 5 & 6 compatibility
            save(roiName,'roi','-V6');
          else
            save(roiName,'roi');
          end
          
        end % for side
      end % for gyrus
    end % for bin
  end % for study
  delete(p) % delete progress bar
  
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
  
  error(emsg);
end

% Modification History:
%
% $Log: roiunionexams.m,v $
% Revision 1.7  2005/02/22 03:48:19  michelich
% Fixed capitalization of roiunion.
%
% Revision 1.6  2005/02/16 01:53:49  michelich
% Save ROIs for MATLAB 5 & 6 compatibility when using MATLAB 7 and later.
%
% Revision 1.5  2005/02/03 20:17:47  michelich
% M-Lint: Replace deprecated isstr with ischar.
%
% Revision 1.4  2005/02/03 16:58:44  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.3  2003/10/22 15:54:39  gadde
% Make some CVS info accessible through variables
%
% Revision 1.2  2002/12/03 21:18:42  michelich
% Optionally pass slices as a cell array of strings.
%
% Revision 1.1  2002/10/25 01:51:44  michelich
% Original CVS import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2002/10/24. Converted into function from roiunionscript
% Charles Michelich, 2001/10/18. Changed to use iscellstr (instead of iscell) for checking studies,gyri,sides,bins
% Charles Michelich, 2001/06/20. Modified to use cell array of bins to support text bin labels
% Charles Michelich, 2000/05/09. original.  Modified from roiCountScript.
