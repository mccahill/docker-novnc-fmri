% ROICOUNTSCRIPT Calculates statistics within several ROIs and time series
%
% Description:  
%  This is an example script for using the ROIANALYSIS_COUNT function
%  to calculate information about the number of voxels within ROIs meeting
%  the specified criteria.
%
%  Type "help roianalysis_count" for more information
%

% MR Data Specifications
dataPath = '\\GALL\Data5\BIAC\Biomot.04\Analysis\';
dataFileSpec = 'sprintf(''%s\\Bin_%s.T'',studies{study},bins{bin})';
params = {64,64,20,'float'};
zoom = [];    % [] will use full image size

% ROI Specifications
roiPath = '\\GALL\Data5\BIAC\Biomot.04\Analysis\ROI\IndividualSlice\';
roiFileSpec = 'sprintf(''%s\\STS\\%s%s_%s_sl%s.roi'',studies{study},gyri{gyrus},sides{side},studies{study},slices{slice})';

% Subjects and Regions to Analyze
studies = {'010828_40507'};
bins = {'Allmovement'};
gyri = {'sts'};
sides = {'l' 'r'};
slices = [12:20];

% Other variables
writeMaskedROIs=1;
ranges = {[1.96 inf]};
decDigits = 2;
outputExcelFileName = 'ROICountTest';

% Do the analysis
roianalysis_count(dataPath,dataFileSpec,params,zoom,roiPath,roiFileSpec,...
  studies,bins,gyri,sides,slices,outputExcelFileName, ...
  writeMaskedROIs,ranges,decDigits);

% Modification History:
% Charles Michelich 2002-11-27 Original example file.
% Charles Michelich 2002-12-31 Removed adding beta directory to path.
