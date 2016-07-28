% ROIANALYSISSCRIPT_TSTATPROFILE Calculates statistics within several ROIs and time series
%
% Description:  
%  This is an example script for using the ROIANALYSIS_TIMECOURSE function
%  to calculate statistics within numerous ROIs spannning studies. 
%
%  This example is for data calculated using tstatprofile.  The prestimulus 
%  baseline is calculated using baselineAvg.img files and the prestimulus
%  baseline is NOT subtracted when calculating the percent signal change
%  since tstatprofile already subtracts the baseline from the epoch
%  averaged data.
%
%  Type "help roianalysis_timecourse" for more information
%

% MR Data Specifications
dataPath = '\\GALL\Data5\BIAC\Biomot.04\Analysis\';
dataFileSpec = 'sprintf(''%s\\Avg_%s_V*.img'',studies{study},bins{bin})';
preStimMeanFileSpec = 'sprintf(''%s\\baselineAvg.img'',studies{study})';
params = {64,64,20,'float'};
zoom = [];    % [] will use full image size

roiPath = '\\GALL\Data5\BIAC\Biomot.04\Analysis\ROIs\IndividualSlice\';
roiFileSpec = 'sprintf(''%s\\PostSTS\\%s%d.roi'',studies{study},sides{side},slices{slice})';

studies = {'010828_40507' '010829_40508' '010905_40514' '010912_40528' '010919_40544' '010927_40561' '010928_40563' '011004_40579' '011005_40581' '011005_40583' '011009_40585' '011010_40588' '011205_40724' '011206_40729' '011207_40731'};
bins = {'Allmovement' 'Correct' 'Correct_1sec' 'Correct_3sec' 'Incorrect' 'Incorrect_1sec' 'Incorrect_3sec' 'Nomove'};
gyri = {'PostSTS'};
sides = {'r' 'l'};
slices = [5:11];

% Define time points 
tPoints = [-3.0:1.5:16.5];

% Ranges to process (use {} if none)
ranges = {};
decDigits = 0;

% Output Excel filename
outputExcelFileName = 'ROIAnalysisPostSTS_Base_Mean';

% Calculate the time course statistics
roianalysis_timecourse(dataPath,dataFileSpec,params,zoom,roiPath,roiFileSpec,...
  studies,bins,gyri,sides,slices,outputExcelFileName, ...
  preStimMeanFileSpec,tPoints,ranges,decDigits);

% Modification History:
% Charles Michelich 2002-11-27 Original example file.
% Charles Michelich 2002-12-31 Removed adding beta directory to path.
