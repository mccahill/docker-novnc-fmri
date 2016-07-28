% ROIANALYSISSCRIPT_MRTEST Calculates statistics within several ROIs and time series
%
% Description:  
%  This is an example script for using the ROIANALYSIS_TIMECOURSE function
%  to calculate statistics within numerous ROIs spannning studies.  
%
%  This example is for data calculated using mrtest.  The prestimulus
%  baseline is calculated using the mean of preStimPts and prestimulus
%  baseline is subtracted when calculating the percent signal change.
%
%  Type "help roianalysis_timecourse" for more information
%

% MR Data Specifications
dataPath = '\\broca\data3\biac\MemLoad.fMRI.02\Analysis\';
dataFileSpec = 'sprintf(''%s\\Coronal_Bin%s_V*.img'',studies{study},bins{bin})';
params = {64,64,64,'float'};
zoom = [];    % [] will use full image size

% ROI Specifications
roiPath = '\\broca\data3\biac\MemLoad.fMRI.02\Data\Anat\ROI\';
roiFileSpec = 'sprintf(''%s\\%s%s_%s_sl%02d.roi'',studies{study},gyri{gyrus},sides{side},studies{study},slices{slice})';

% Subjects and Regions to Analyze
studies = {'021000_00502' '021000_00505'};
bins = {'01' '03'};
gyri = {'IFG' 'SFG' 'ACG' 'WHM'};
sides = {'R' 'L'};
slices = [19:26];

% Define time points and baseline
tPoints = [-12:3:45];
preStimPts = [1:5];

% Ranges to process (use {} if none)
ranges = {[-inf -5] [-5 -4] [-4 -3] [-3 -2] [-2 -1] [-1 0] [0 1] [1 2] [2 3] [3 4] [4 5] [5 inf]};
decDigits = 0;

% Output Excel filename
outputExcelFileName = 'ROIAnalysisOutput';

% Calculate the time course statistics
roianalysis_timecourse(dataPath,dataFileSpec,params,zoom,roiPath,roiFileSpec,...
  studies,bins,gyri,sides,slices,outputExcelFileName, ...
  preStimPts,tPoints,ranges,decDigits);

% Modification History:
% Charles Michelich 2002-11-27 Original example file.
% Charles Michelich 2002-12-31 Removed adding beta directory to path.
