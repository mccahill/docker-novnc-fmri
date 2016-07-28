% BIAC EEGAD Toolbox
% Version 3.1.0 2006-09-19
%
% Duke-UNC Brain Imaging and Analysis Center MATLAB Tools for working with
% Electroencephalogram data.
% - Requires BIAC General Toolbox
%
% Main Program
%   EEGAD       - Read in and display an EEG file.
%
% Functions
%   alphasort   - Sort string array or cell array alphabetically using
%   BinLine     - Set bin's line properties.
%   BinName     - Set bin's name.
%   charArea    - Measure area under EEG waveforms for list of file and
%                 channel names.
%   chanAvg     - Read list of file/channel names and average channels
%                 within each bin. 
%   chanLabel   - Return channel label based on name and/or number.
%   chanMap     - Sort and remap list of channels in chans based on names
%                 in strs. 
%   chanNum     - Return channel number given channel name and EEG file or
%                 structure. 
%   charSort    - Sort list of channels in chans based on names in strs.
%   checkBins   - Read list of EEG files and find all bins.
%   CheckHdrs   - Check all EEG .HDR files in directory for missing spaces
%                 in channel names.
%   EEGBand     - Apply bandpass Kaiser window filter to each channel of
%                 EEG data. 
%   EEGBin      - Sets display state of specified bins on current EEG plot.
%   EEGChan     - Sets first displayed channel on current EEG plot.
%   EEGCustm    - Read custom grid layout file and return positions and
%                 sortOrder. 
%   EEGFig      - Create new EEG figure.
%   EEGFilt     - Apply filter specified in filt to EEG data.
%   EEGFmt      - Change formatting of EEG display axes.
%   EEGGrid     - Sets grid dimensions of current EEG plot.
%   EEGLegnd    - Display legend for EEG data.
%   EEGPage     - Page up or down through channels on current EEG plot.
%   EEGPlot     - Plots the specified EEG channels and bins on current
%                 figure. 
%   EEGRaw      - Revert to raw EEG data.
%   EEGRead     - Read EEG data and header from data file.
%   EEGScale    - Sets X- and Y-axis scale on current EEG plot.
%   EEGShow     - Plot EEG data on multiple axes.
%   EEGSmooth   - Apply smoothing function (lowpass filter) to each channel
%                 of EEG data. 
%   EEGSort     - Sort EEG channels and update display.
%   EEGSub      - Subdivide the current figure into a matrix of EEG plots.
%   EEGTopo     - Generate topographical map of EEG data at specified
%                 latency. 
%   EEGTweak    - Tweak properties of right-clicked on object.
%   EEGWrite    - Write eeg data to file.
%   EEGZoom     - Select and hilight EEG plots with the mouse.  Then zoom
%                 grid to just those plots. 
%   findpeaks   - Find peaks in real vector.
%   hodad       - Read EEG data files, measure the waveform peaks, and
%                 display or output to file. 
%   MIPRead     - Read EEG data and header from data file created by MIP
%                 for Windows. 
%   neuro2eegad - Convert Neuroscan average (.AVG) files to EEGAD format.
%   xHairs      - Display crosshairs for reading (x,y) values from a set of
%                 EEG plots. 
%

%TODO: Organize the functions into logical groups.

% CVS ID and authorship of this code
% $Id: Contents.m,v 1.9 2006/09/19 19:44:26 gadde Exp $
