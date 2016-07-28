% ROIPEAKSCRIPT_TSTATPROFILE Calculates peak value and time within several spline interpolated ROI time series
%
% Description:  
%  This is an example script for using the ROIANALYSIS_PEAK function
%  to calculate the peak value and time within numerous ROI spannning studies, 
%  gyri, stides, slices, and bins.
%
%  This example is for data calculated using tstatprofile.  The prestimulus  
%  baseline is calculated using baselineAvg.img files and the prestimulus
%  baseline is NOT subtracted when calculating the percent signal change
%  since tstatprofile already subtracts the baseline from the epoch
%  averaged data.
%
%  Type "help roianalysis_peak" for more information.
%

% MR Data Specifications
dataPath = '\\broca\data3\biac\MemLoad.fMRI.01\Analysis\';
dataFileSpec = 'sprintf(''%saligned\\Coronal_Bin%s_V*.img'',studies{study},bins{bin})';
preStimMeanFileSpec = 'sprintf(''%s\\baselineAvg.img'',studies{study})';
params = {64,64,64,'float'};
zoom = [1 1 64 64];

% ROI Specifications
roiPath = '\\broca\data3\biac\MemLoad.fMRI.01\Data\Anat\ROI\';
roiFileSpec = 'sprintf(''%s\\%s%s_%s_sl%s.roi'',studies{study},gyri{gyrus},sides{side},studies{study},slices{slice})';

% Regions and Patients to Analyze
studies = {'092199_00189' '092499_00208' '092799_00217' '092999_00221' '100799_00261' '101199_00264' '101299_00268' '101399_00271' '101499_00272' '101599_00277'};
gyri = {'FFG' 'IPS'};
sides = {'R','L'};
bins = {'11' '12' '21' '22' '31' '32'};
slices = [42:48];

% Other variables
tPoints = [-15 -12 -9 -6 -3 0 3 6 9 12 15 18 21 24 27 30];
outputExcelFileName = 'roiPeakOutput';
splineTR = 1;
tRanges = {[0,18],[18,30]};

% statistical functions and limits to pass to ROIStats (using [] for defaults)
statFunc = [];
limits = [];

% Do the analysis
roianalysis_peak(dataPath,dataFileSpec,params,zoom,roiPath,roiFileSpec,...
  studies,bins,gyri,sides,slices,outputExcelFileName,...
  preStimMeanFileSpec,tPoints,splineTR,tRanges,statFunc,limits);

% Modification History:
% Charles Michelich 2002-11-27 Original example file.
% Charles Michelich 2002-12-31 Removed adding beta directory to path.
