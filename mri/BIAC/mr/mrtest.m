function Tout=mrtest(varargin)
%MRTEST  Run T-Test or Epoch Average on MR series.
%
% out=mrtest;
% out=mrtest(controlFileName);
%
% Tmaps=mrtest(runNames,typeSpecs,paradigms,pCol,tests);
% epochAvgs=mrtest(runNames,typeSpecs,paradigms,pCol,bins,epoch,threshhold,template);
% Tmaps=mrtest(runNames,typeSpecs,paradigms,pCol,tests,outPath);
% epochAvgs=mrtest(runNames,typeSpecs,paradigms,pCol,bins,epoch,threshhold,template,outPath);
%
% General arguments:
%   runNames is a string or cell array of strings specifying the full path
%     and filenames of the images to read for each run.
%     (see READMR filename argument)
%   typeSpecs is a READMR type specifier or column vector cell array of
%     READMR type specifiers to use when reading the data for each run.
%     (See READMR typespec argument).  Column vector cell arrays will be
%     interpreted as a list of type specifiers for each run.  Otherwise,
%     the same type specifier will be used for all runs.
%   paradigms is either a integer row vector, cell array of integer row
%     vectors, a filename or a cell array of filesnames indicating the
%     bin to assign to each image volume.  If a cell array is specified,
%     there must be one cell for each run, otherwise the specified
%     paradigms will be used for all runs.  If a filename or cell array of
%     filenames is specified, each will be loaded using the LOAD function.
%   pCol is the column of the paradigm file to use.  This variable is not
%     used if a numeric vector is specifed for paradigms.
%   outPath is an optional string that is prepended as is to the names of
%     the output files. This allows a custom string at the front of the
%     file name, but means you need a trailing \ if you don't want one.
%
% T-Test arguments:
%   tests is a n x 2 array of the bins of to compare with t-test.  Each
%     row is a separate t-test.
%
% Epoch Analysis arguments:
%   bins is a column vector of the bins to process.
%   epoch is a two element vector indicating the number of image volumes
%     prior to and after each event to include in each epoch.
%     (i.e. epoch = [PreEventPts, PostEventPts])
%   threshold is a single number.  Only voxels with a mean time series 
%     >= threshold are included in the correlation-maps and t-maps.
%   template is the correlation template which the epoch averaged data is
%     correlated to to generate the correlation and t-maps.  It can either
%     be a numeric array or a filename that will be loaded using the MATLAB
%     LOAD function.  The template must be either epochLength-by-1 or
%     epochLength-by-nSlices.  Each column will be used the respective
%     slice.  If only one column is specified, it will be used for all
%     slices.
%
% Output argument is optional.
% If outPath or a header file are specified, the outputs are written to file.
%
% Note: If you only have one run and your typeSpec is a 1x1 cell array, the data
%       will be read using "readmr(runNames{1},typeSpec{1})" such that you are
%       effectly specifying a typeSpec for "each run".
%
% -----------------------------------------------------------------------------
% MRTEST Control file format
%
% Instead of specifying the all of the MRTEST options as arguments to the
% function, a single text file can be used to specify the options.
%
% The file consists of a plain text file of keyword, value pairs in the 
% format keyword=value.  Blank lines and those that start with % are
% ignored.  See READKVF for more details on the format.
%
% General Keys:
%   RunName - Full path and filename of run to process (see READMR
%             filenames argument).  Include one RunName for each run.
%   RunTypeSpec - Type specifier for reading data.  This string will be
%             passed to the EVAL function to generate the typespec.
%             Example: {'Volume',[64 64 34 205]} or 'BXH'
%             (see READMR typespec argument)
%   OutPath - string is prepended as is to the names of the output files.
%             This allows a custom string at the front of the file name,
%             but means you need a trailing \ if you don't want one.
%   Paradigm - Full path and filename of paradigm file.  See paradigms
%              argument for futher information.
%   ParadigmColumn - Column of paradigm file to use.
%
%   RunTypeSpec and Paradigm may be specified once or for each run.
%
% T-Test Keys
%   Tests - A list of bin pairs to compare with a t-test.  The format is:
%             (a b) (b c) (a c)
%           where a,b,c are the bins to compare.
%
% Epoch Average Keys
%   Bins - List of the bins to process.
%   PreEventPts - Number of image volumes prior to each event to include in
%                 each epoch.
%   PostEventPts - Number of image volume after each event to include in
%                  each epoch. 
%   Threshhold - Only voxels with a mean time series >= Threshold are
%                included in the correlation-maps and t-maps.
%   CorrelationTemplate - Full path and filename of correlation template file.
%                See template argument for futher information.
% -----------------------------------------------------------------------------
%
% See Also: READMR, WRITEMR, TSTATPROFILE

% --- Historical compatibility support ---
%
% The following calling conventions are supported for historical compatibility:
%   Tmaps=mrtest(x,y,z,runNames,dataTypes,nTimePts,paradigms,pCol,tests);
%   epochAvgs=mrtest(x,y,z,runNames,dataTypes,nTimePts,paradigms,pCol,bins,epoch,threshhold,template);
%   Tmaps=mrtest(x,y,z,runNames,dataTypes,nTimePts,paradigms,pCol,tests,outPath);
%   epochAvgs=mrtest(x,y,z,runNames,dataTypes,nTimePts,paradigms,pCol,bins,epoch,threshhold,template,outPath);
%
% The control file also 
% The following control file format is supported for historical compatibility:
% -----------------------------------------------------------------------------
% MRTEST Control file format
%
% Instead of specifying the all of the MRTEST options as arguments to the
% function, a single text file can be used to specify the options.
%
% The file consists of a plain text file of keyword, value pairs in the 
% format keyword=value.  Blank lines and those that start with % are ignored. 
%
% General Keys:
%   XPixels - X size of data
%   YPixels - Y size of data
%   ZPixels - Z size of data
%   TimePts - Number of time points in each run
%   RunName - Same as current version
%   OutPath - Same as current version
%   Paradigm - Same as current version
%   ParadigmColumn - Same as current version
%
%   TimePts and Paradigm may be specified once or for each run.
%
% Optional Keys:
%   RunDataType - Specified the data type (volume or float) to use when
%     reading the data.  Default to volume if not specified.  You can
%     specify it once or for each run.
%
% T-Test and Epoch Averages Keys are the same as the current version.
% -----------------------------------------------------------------------------

% CVS ID and authorship of this code
% CVSId = '$Id: mrtest.m,v 1.21 2005/02/03 20:17:46 michelich Exp $';
CVSRevision = '$Revision: 1.21 $';
CVSDate = '$Date: 2005/02/03 20:17:46 $';
% CVSRCSFile = '$RCSfile: mrtest.m,v $';

%TODO: Merge and write .info fields of runs.

lasterr('');
emsg='';
inGUI=0;
try

persistent SAVEHDRPATH SAVESRSPARAMS SAVEZOOM
if nargout==1, Tout=[]; end
hdrFile=[];
logfid=1;
p1=[];
p2=[];
mrinfo=[];

% Check args
if ~any(nargin==[0 1 5 6 8 9 10 12 13])
  emsg='Incorrect number of input arguments.'; error(emsg);
end
if nargout>1
  emsg='Too many output arguments.'; error(emsg);
end

% Initialize history entry string for output file
historyEntry='';

% Process header file, unless passed params as function arguments
if ~any(nargin==[0 1])
  % Handle parameters passed through command line.
  % NOTE: Epoch Averaging "bins" argument is actually tests in all of the code.

  if nargin == 5
    % Tmaps=mrtest(runNames,typeSpecs,paradigms,pCol,tests);
    % T-test, don't write to file
    testType='T-Test';
    outPath=[];
    [runNames,typeSpecs,paradigms,pCol,tests] = deal(varargin{:});
  elseif nargin == 6
    % Tmaps=mrtest(runNames,typeSpecs,paradigms,pCol,tests,outPath);
    % T-test, write to file
    testType='T-Test';
    [runNames,typeSpecs,paradigms,pCol,tests,outPath] = deal(varargin{:});
  elseif nargin == 8
    % epochAvgs=mrtest(runNames,typeSpecs,paradigms,pCol,bins,epoch,threshhold,template);
    % Epoch Average, don't write to file
    testType='Epoch Average';
    outPath=[];
    [runNames,typeSpecs,paradigms,pCol,tests,epoch,threshhold,template] = deal(varargin{:});
  elseif nargin == 9 & ~isnumeric(varargin{1})
    % epochAvgs=mrtest(runNames,typeSpecs,paradigms,pCol,bins,epoch,threshhold,template,outPath);  
    % Epoch Average, write to file
    testType='Epoch Average';
    [runNames,typeSpecs,paradigms,pCol,tests,epoch,threshhold,template,outPath] = deal(varargin{:});
  else
    % Backwards compatibility support.
    %   Tmaps=mrtest(x,y,z,runNames,dataTypes,nTimePts,paradigms,pCol,tests);
    %   epochAvgs=mrtest(x,y,z,runNames,dataTypes,nTimePts,paradigms,pCol,bins,epoch,threshhold,template);
    %   Tmaps=mrtest(x,y,z,runNames,dataTypes,nTimePts,paradigms,pCol,tests,outPath);
    %   epochAvgs=mrtest(x,y,z,runNames,dataTypes,nTimePts,paradigms,pCol,bins,epoch,threshhold,template,outPath);
    warning(sprintf(['Running mrtest in compatibility mode!\n'...
        'Please use typeSpecs instead of x,y,z,nTimePts,dataTypes.']));
        
    % Extract common parameters
    [x,y,z,runNames,dataTypes,nTimePts,paradigms,pCol,tests] = deal(varargin{1:9});
    if ischar(runNames), runNames={runNames}; end % For uniform handling
    
    % Contruct typeSpecs from old inputs
    typeSpecs = local_MakeTypeSpecCompat(x,y,z,nTimePts,dataTypes,length(runNames));
    clear x y z nTimePts dataTypes

    % Parse remaining arguments
    if nargin==9
      % T-test, don't write to file
      testType='T-Test';
      outPath=[];
    elseif nargin==10
      % T-test, write to file
      testType='T-Test';
      outPath = varargin{10};
    elseif nargin==12
      % Epoch Average, don't write to file
      testType='Epoch Average';
      outPath=[];
      [epoch,threshhold,template] = deal(varargin{[10:12]});      
    elseif nargin==13
      % Epoch Average, write to file
      testType='Epoch Average';
      [epoch,threshhold,template,outPath] = deal(varargin{[10:13]});
    end
  end
    
  % Open log file.
  if ~isempty(outPath)
    % Create log file if we are writing to file
    % Name the log file with the current date & time 'mrtest_yyyymmdd_HHMMSS.log'
    % Create the log in the same directory as the output files (Note that
    % outPath may contain a path and a filename stub)
    logName=fullfile(fileparts(outPath),['mrtest_',strrep(datestr(now,30),'T','_'),'.log']);
    [logfid emsg]=fopen(logName,'wt');
    if logfid==-1, emsg=sprintf('Error opening log file %s!\n%s',logName,emsg); error(emsg); end
  else
    % If outPath not specified, write log to standard out.
    logfid=1;
  end

  % Write header to log
  historyEntry = logEntry(historyEntry,logfid,'MRTEST: MR Analysis Program Log File');
  historyEntry = logEntry(historyEntry,logfid,'(mrtest %s%s)\n',CVSRevision(2:end-1),CVSDate(8:end-2));
  historyEntry = logEntry(historyEntry,logfid,'Processing using specified parameters (rather than header file)\n');
else
  inGUI=1;
  % Get header file name
  if nargin==1
    hdrFile=varargin{1};
  else
    % Remember directory
    if isempty(SAVEHDRPATH), SAVEHDRPATH=pwd; end
    [hdrFile hdrPath]=uigetfile(fullfile(SAVEHDRPATH,'*.txt'),'Open Header File');
    if hdrFile==0, return; end
    hdrFile=fullfile(hdrPath,hdrFile);
    SAVEHDRPATH=hdrPath;
  end
  if ~exist(hdrFile,'file')
    emsg=sprintf('Header file %s does not exist!',hdrFile); error(emsg);
  end
  % Create log file
  [hdrPath hdrName]=fileparts(hdrFile);
  logName=fullfile(hdrPath,[hdrName '.log']);
  [logfid emsg]=fopen(logName,'wt');
  if logfid==-1, emsg=sprintf('Error opening log file %s!\n%s',logName,emsg); error(emsg); end
  historyEntry = logEntry(historyEntry,logfid,'MR Analysis Program Log File\n');
  historyEntry = logEntry(historyEntry,logfid,'Header file: %s\n',hdrFile);
  d=dir(hdrFile);
  historyEntry = logEntry(historyEntry,logfid,'Header file date: %s\n',d.date);
  % Read header file
  reqKeys={'ParadigmColumn';'OutPath';'RunName';'Paradigm';};
  newFormatKeys={'RunTypeSpec'};
  oldFormatReqKeys={'XPixels';'YPixels';'ZPixels';'TimePts'};
  oldFormatOptKeys={'RunDataType'};
  ttestKeys={'Tests'};
  epochKeys={'Bins';'PreEventPts';'PostEventPts';'Threshhold';'CorrelationTemplate'};
  hdrInfo=readkvf(hdrFile,reqKeys,cat(1,newFormatKeys,oldFormatReqKeys,oldFormatOptKeys,ttestKeys,epochKeys));
  % Get data from required fields
  runNames=hdrInfo.RunName;
  if ischar(runNames), runNames={runNames}; end % For uniform handling
  paradigms=hdrInfo.Paradigm;
  pCol=str2num(hdrInfo.ParadigmColumn);
  outPath=hdrInfo.OutPath;
  if any(ismember(cat(1,oldFormatReqKeys,oldFormatOptKeys),fieldnames(hdrInfo)))
    % Compatibility Mode
    warning(sprintf(['Running mrtest in compatibility mode!\n'...
        'Please use RunTypeSpec instead of XPixels, YPixels, ZPixels, TimePts and RunDataType.']));
        
    % Check for required fields
    tf=ismember(oldFormatReqKeys,fieldnames(hdrInfo));
    if ~all(tf)
      emsg=sprintf('Missing keywords from file %s:\n%s',hdrFile,strlist(oldFormatReqKeys(~tf)));
      error(msg);
    end
    
    % Check for optional fields
    if isfield(hdrInfo,'RunDataType')
      dataTypes=hdrInfo.RunDataType;
    else
      dataTypes='Volume';
    end
       
    % Get number of time points in each run
    if ~iscellstr(hdrInfo.TimePts)
      % Same for all runs
      nTimePts=str2num(hdrInfo.TimePts);
    else
      nTimePts=[];
      for c=1:length(hdrInfo.TimePts)
        nTimePts=[nTimePts str2num(hdrInfo.TimePts{c})];
      end
    end
    
    % Get image size [x,y,z]
    x = str2num(hdrInfo.XPixels);
    y = str2num(hdrInfo.YPixels);
    z = str2num(hdrInfo.ZPixels);

    % Contruct typeSpecs from old inputs
    typeSpecs = local_MakeTypeSpecCompat(x,y,z,nTimePts,dataTypes,length(runNames));
    clear x y z nTimePts dataTypes
    
  else
    % New readmrtest fields.
    
    % Check for required fields
    tf=ismember(newFormatKeys,fieldnames(hdrInfo));
    if ~all(tf)
      emsg=sprintf('Missing keywords from file %s:\n%s',hdrFile,strlist(newFormatKeys(~tf)));
      error(msg);
    end

    % Generate runTypeSpec (Evaluate string)
    if ~iscell(hdrInfo.RunTypeSpec)
      % Single typeSpec
      [typeSpecs,ok,emsg] = local_safeeval(hdrInfo.RunTypeSpec);
      if ~ok,emsg=sprintf('Unable to generate RunTypeSpec\n%s',emsg); error(emsg); end
    else
      % Multiple typeSpecs.  Put each in a column vector cell array
      typeSpecs=cell(length(hdrInfo.RunTypeSpec),1);
      for c=1:length(typeSpecs)
        [typeSpecs{c},ok,emsg] = local_safeeval(hdrInfo.RunTypeSpec{c});
        if ~ok,emsg=sprintf('Unable to generate RunTypeSpec #%d\n%s',c,emsg); error(emsg); end
      end
    end
  end
  
  % Handle T-Test and Epoch Average specific keys
  gotEpochKeys=ismember(epochKeys,fieldnames(hdrInfo));
  gotTtestKeys=ismember(ttestKeys,fieldnames(hdrInfo));
  if any(gotEpochKeys)
    testType='Epoch Average';
    if ~all(gotEpochKeys)
      emsg=sprintf('Missing keywords from file %s:\n%s',hdrFile,strlist(epochKeys(~gotEpochKeys)));
      error(msg);
    end
    tests=sscanf(hdrInfo.Bins,'%d');
    epoch=[str2num(hdrInfo.PreEventPts) str2num(hdrInfo.PostEventPts)];
    threshhold=str2num(hdrInfo.Threshhold);
    template=hdrInfo.CorrelationTemplate;
  else
    testType='T-Test';
    if ~all(gotTtestKeys)
      emsg=sprintf('Missing keywords from file %s:\n%s',hdrFile,strlist(ttestKeys(~gotTtestKeys)));
      error(msg);
    end
    tests=hdrInfo.Tests;
    tests(tests=='(' | tests==')')=' ';    % Ignore parentheses
    tests=sscanf(tests,'%d',[2 Inf])';
  end
end

% --- Check parameters for validity (and expand if necessary) ---
% Check runNames
if isempty(runNames), emsg='No runs specified!'; error(emsg); end
if ischar(runNames), runNames={runNames}; end % For uniform handling
if ~iscellstr(runNames) | any(cellfun('isempty',runNames))
  emsg='Run names must be a string or a cell array of strings.'; error(emsg);
end
nRuns=length(runNames);
% Check typeSpecs (expand if necessary)
% Examples:
% Multiple runs (nRuns > 1)
%  - 'BXH'             one element for all runs "style"
%  - {'BXH';'BXH'}     one element for each run "style"
%  - {'BXH'}           one element for all runs "style"
%  - {{'BXH'};{'BXH'}} one element for each run "style"
%  - {'Volume',[64 64 30]} one element for all runs "style"
%  - {{'Volume',[64 64 30]};{'Volume',[64 64 40]}} one element for each run "style"
%  - {'BXH';{'Volume',[64 64 40]}} one element for each run "style"
% Single run (nRuns == 1)
%  - 'BXH'             one element for all runs "style"
%  - {'BXH'}           one element for each run "style" - CAN'T TELL THESE APART!!!!  Assume it is this one.
%  - {'BXH'}           one element for all runs "style" - CAN'T TELL THESE APART!!!!
%  - {{'BXH'}}         one element for each run "style"
%  - {'Volume',[64 64 30]} one element for all runs "style"
%  - {{'Volume',[64 64 30]}} one element for each run "style"
if iscell(typeSpecs) & ndims(typeSpecs) == 2 & size(typeSpecs,2) == 1 ...
    & (nRuns == 1 | size(typeSpecs,1) ~= 1)
  % Column vector cell array.  Should be one element for each run.
  % If only one run, and user specified 1x1 cell array typeSpec, assume 
  % that user already wrapped this is a cell array in the "one element for each run" fashion
  if size(typeSpecs,1) ~= nRuns
    emsg='Incorrect number of typeSpecs specified.'; error(emsg);
  end
else
  % Use specified typeSpec for all runs.
  typeSpecs = repmat({typeSpecs},[nRuns,1]);
end
% Check paradigms (expand if necesssary)
if isempty(paradigms), emsg='There are no paradigms specified.'; error(emsg); end
if ~iscell(paradigms), paradigms={paradigms}; end
for p=paradigms
  p=p{1};
  if isempty(p) | size(p,1)~=1 | (~ischar(p) & ~all(isint(p) & p>=0))
    emsg='Paradigm is not a filename or a vector of non-negative integers.'; error(emsg);
  end
end
try paradigms(1:nRuns)=paradigms; catch emsg='Incorrect number of paradigms specified.'; error(emsg); end
% Check pCol
if length(pCol)~=1 | pCol<1 | ~isint(pCol), emsg='Paradigm column must be a positive integer.'; error(emsg); end
% Check tests
if isempty(tests) | ~all(isint(tests) & tests>0), emsg='Bins must be positive integers.'; error(emsg); end
testBins=unique(tests(:))';
nBins=length(testBins);
% Check that output directory exists, if needed
if ~isempty(outPath)
  outDir=fileparts(outPath);
  if ~exist(outDir,'dir')
    emsg=sprintf('Output directory %s does not exist!',outDir); error(emsg);
  end
end

% Check that the data is going somewhere
if nargout < 1 & isempty(outPath)
  error('No outputs (output argument or outPath) specified!'); 
end

historyEntry = logEntry(historyEntry,logfid,'Begin %s: %s\n',testType,datestr(now));
historyEntry = logEntry(historyEntry,logfid,'Processing %d runs\n',nRuns);

% Read info for first run to get data sizes
mrinfo = readmr(runNames{1},typeSpecs{1},'=>INFOONLY');
if length(mrinfo.info.dimensions) ~= 4
  emsg=sprintf('Input series %s must be 4D!',runNames{1}); error(emsg);
end
if ~isequal({mrinfo.info.dimensions(1:3).type},{'x','y','z'})
  emsg=sprintf('Input series %s must have x,y,z as the first three dimensions!',runNames{1}); error(emsg);
end
imageSz = [mrinfo.info.dimensions(1:3).size];
historyEntry = logEntry(historyEntry,logfid,'Run size: [%d %d %d]\n',imageSz(1),imageSz(2),imageSz(3));

% Check test specify arguments
switch testType
  case 'T-Test'
    if size(tests,2)~=2, emsg='Tests must be an 2-column array.'; error(emsg); end
  case 'Epoch Average'
    if size(tests,2)~=1, emsg='Bins must be a column vector.'; error(emsg); end
    if ~isequal(size(epoch),[1 2]) | ~all(isint(epoch) & epoch>=0)
      emsg='Epoch must be two non-negative integers.'; error(emsg);
    end
    epochLen=sum(epoch)+1;
    if length(threshhold)~=1 | ~isreal(threshhold)
      emsg='Threshhold must be a real number.'; error(emsg);
    end
    if ischar(template)
      if ~exist(template,'file')
        emsg='Correlation template file does not exist.'; error(emsg);
      end
      template=load(template,'-ascii');
    end
    if isreal(template)
      if size(template,1)~=epochLen
        emsg='Rows of correlation template must match length of epoch.'; error(emsg);
      end
      if size(template,2)==1
        template=repmat(template,1,imageSz(3));    % Replicate columns for each slice
      elseif size(template,2)~=imageSz(3)
        emsg='Columns of correlation template must equal 1 or number of Z pixels.'; error(emsg);
      end
    else
      emsg='Template must be a filename or a matrix of real numbers.'; error(emsg);
    end
end

% --- Create an info struct for the output ---
% TODO: Clean this up...  Save other information too.

% Create info struct for 3D volume (Save information in dimensions)
outTemplate = struct('data',[],'info',struct( ...
  'elemtype', 'double', ... % TODO: Is this appropriate ???
  'outputelemtype', 'float', ...
  'byteorder', mrinfo.info.byteorder, ...
  'dimensions', mrinfo.info.dimensions(1:3), ...
  'hdr', '', ...
  'hdrtype', '', ...
  'displayname',''));

% Keep 4th dimension info for checking against info from other runs
ref4thDInfo = mrinfo.info.dimensions(4);
ref4thDInfo.size = NaN;  % Size can vary across runs

% Create template for outputing the 4th dimension
if strcmp(testType,'Epoch Average')
  outTemplate4thD = mrinfo.info.dimensions(4);
  outTemplate4thD.size = epochLen;
  if length(outTemplate4thD.datapoints) ~=1 | ~isnan(outTemplate4thD.datapoints{1});
    % Timing specified with datapoints.  TODO: Handle this???
    warning(['Time dimension specified using datapoints!  ',...
        'Don''t know how to handle this, so datapoints, origin,',...
        'gap, spacing not specifed in output']);
    outTemplate4thD.datapoints = {NaN};
    outTemplate4thD.origin = NaN;
    outTemplate4thD.gap = NaN;
    outTemplate4thD.spacing = NaN;
  else
    % Timing specified with origin, gap, and spacing.
    outTemplate4thD.origin = -epoch(1)*outTemplate4thD.spacing;
  end
end

% Initialize arrays
binCnt=zeros(1,nBins);
nTests=size(tests,1);
switch testType
  case 'T-Test'
    volumeSum=zeros([imageSz,nBins]);
    volumeStats=zeros([imageSz,nBins]);
    Tmap=zeros([imageSz,nTests]);
    historyEntry = logEntry(historyEntry,logfid,'Tests: %s\n',sprintf('(%d %d)',tests'));
  case 'Epoch Average'
    epochCnt=zeros(1,nBins);
    volumeSum=zeros([imageSz,epochLen,nBins]);
    volumeCorr=zeros(imageSz);
    historyEntry = logEntry(historyEntry,logfid,'Bins: %s\n',numlist(testBins,' '));
    historyEntry = logEntry(historyEntry,logfid,'Epoch: %d pre-event, %d post-event points\n',epoch);
end

% Loop through runs
p1=progbar([-1 .6 -1 .1]);
for r=1:nRuns
  if ~ishandle(p1), emsg='User abort'; error(emsg); end
  progbar(p1,sprintf('Processing %d of %d runs...',r,nRuns));
  
  % Grab current runSpec for convenience
  runSpec=runNames{r};
  
  if r ~= 1 % Already read info for first series
    mrinfo = readmr(runSpec,typeSpecs{r},'=>INFOONLY');
    if length(mrinfo.info.dimensions) ~= 4
      emsg=sprintf('Input series %s must be 4D!',runSpec); error(emsg);
    end
    if ~isequal({mrinfo.info.dimensions(1:3).type},{'x','y','z'})
      emsg=sprintf('Input series %s must have x,y,z as the first three dimensions!',runSpec); error(emsg);
    end
    if ~isequal(imageSz,[mrinfo.info.dimensions(1:3).size])
      emsg=sprintf('Input series %s does not have the same x,y,z dimensions as 1st input series %s', ...
        runSpec,runNames{1}); error(emsg);
    end
    % TODO: Check other fields???
    if ~isequalwithequalnans(mrinfo.info.dimensions(1:3),outTemplate.info.dimensions)
      emsg=sprintf('Input series %s does not have the same info.dimensions(1:3) as 1st input series %s', ...
        runSpec,runNames{1}); error(emsg);
    end
    % Check 4th dimension.
    curr4thDInfo = mrinfo.info.dimensions(4);
    curr4thDInfo.size = NaN;  % Size can vary across runs
    if ~isequalwithequalnans(curr4thDInfo,ref4thDInfo)
      emsg=sprintf('Input series %s does not have the same info.dimensions(4) as 1st input series %s', ...
        runSpec,runNames{1}); error(emsg);
    end
  end
  nPts = mrinfo.info.dimensions(4).size;
  
  % TODO: Should this be implemented for backward compatiblity???
  %   runSpec=name2spec(runNames{r});
  %   runPath=fileparts(runSpec);
  %   d=dir(runSpec);
  %   if isempty(d), emsg=sprintf('Unable to find any files that match %s!',runSpec); error(emsg); end
  %   fNames=sort({d.name}');
  % 
  % Make sure we have all the time points
  %   nPts=nTimePts(r);
  %   runPts=sscanf(strcat(fNames{:}),strrep(name2spec(fNames{1}),'*','%d'))';  % Time points in run
  %   missingPts=setdiff(1:nPts,runPts);                                        % Time points specified but not in run
  %   if ~isempty(missingPts)
  %     if length(missingPts)<=20
  %       ptList=sprintf(' (#%s)',numlist(missingPts));
  %     else
  %       ptList='';
  %     end
  %     emsg=sprintf('Missing time points%s from run %s.',ptList,runSpec);
  %     error(emsg);
  %   end
  
  % Make log entry
  historyEntry = logEntry(historyEntry,logfid,'\nRun name: %s\n',runSpec);
  historyEntry = logEntry(historyEntry,logfid,'Data typespec: %s\n',typespec2str(typeSpecs{r}));
  historyEntry = logEntry(historyEntry,logfid,'Time points in run: %d\n',nPts);
  
  % Get paradigm
  if ~ischar(paradigms{r})
    paradigm=paradigms{r};
    historyEntry = logEntry(historyEntry,logfid,'Paradigm file: [%s]\n',numlist(paradigm,' '));
    historyEntry = logEntry(historyEntry,logfid,'Paradigm file date: N/A\n');
  else
    % Read paradigm file
    historyEntry = logEntry(historyEntry,logfid,'Paradigm file: %s\n',paradigms{r});
    d=dir(paradigms{r});
    if isempty(d)
      emsg=sprintf('Paradigm file %s does not exist!',paradigms{r}); error(emsg);
    end
    historyEntry = logEntry(historyEntry,logfid,'Paradigm file date: %s\n',d.date);
    paradigm=load(paradigms{r});
    % Make sure we got valid bins
    if isempty(paradigm) | ~all(isint(paradigm) & paradigm>=0)
      emsg=sprintf('Invalid bin found in paradigm %s.',paradigms{r}); error(emsg);
    end
    if size(paradigm,2)<pCol
      emsg=sprintf('Column %d does not exist in paradigm %s.',pCol,paradigms{r}); error(emsg);
    end
    paradigm=paradigm(:,pCol);
  end
  if length(paradigm)<nPts, emsg=sprintf('Not enough time points in paradigm %s.',paradigms{r}); error(emsg); end
  paradigm=reshape(paradigm(1:nPts),1,nPts);   % Make sure we have row vector & remove extra points
  
  % Determine time points to read
  switch testType
    case 'T-Test'
      timePts=1:nPts;
    case 'Epoch Average'
      ep=inEpoch(testBins,epoch,paradigm);     % Only complete epochs are returned
      timePts=find(any(ep));
      historyEntry = logEntry(historyEntry,logfid,'Time points used: %d\n',length(timePts));
      % Check for incomplete epochs that were omitted from ep
      bad=length(find(ismember(paradigm,testBins)))-length(find(ep(1,:)));
      if bad~=0
        warn=sprintf('Warning: Ignoring %d epoch%s that extend%s outside of paradigm\n',...
          bad,index('s',bad>1),index('s',bad==1));
        historyEntry = logEntry(historyEntry,logfid,['*' warn]);
        disp(sprintf('%s in run %s.',warn,runSpec));
      end
      if isempty(timePts)
        warn=sprintf('Warning: No complete epochs found for any specified bins\n');
        historyEntry = logEntry(historyEntry,logfid,['*' warn]);
        disp(sprintf('%s in run %s.',warn,runSpec));
      end
  end
  
  % Loop through time points
  if isempty(timePts)
    if ~ishandle(p1), emsg='User abort'; error(emsg); end
    progbar(p1,r/nRuns);
  else
    p2=progbar([-1 .4 -1 .1]);
    for t=1:nPts
      if ~ishandle(p2), emsg='User abort'; error(emsg); end
      progbar(p2,sprintf('Processing %d of %d time points in run %d...',t,nPts,r));
      bin=paradigm(t);
      bind=find(bin==testBins);                              % bind is index into testBins
      binCnt(bind)=binCnt(bind)+1;                           % Bin count
      if any(timePts==t)                                     % Do we need to look at this time point?
        % Read individual data volume
        try
          srs=readmr(mrinfo,{'','','',t},'NOPROGRESSBAR');
        catch
          emsg=sprintf('Error reading time point %d of %s\n%s',t,runSpec,lasterr); error(emsg);
        end
        % TODO: Carry the header data through...
        srs=srs.data;
        % Calculate stats using this volume
        switch testType
          case 'T-Test'
            if any(bin==testBins)
              volumeSum(:,:,:,bind)=volumeSum(:,:,:,bind)+srs;         % Sums
              volumeStats(:,:,:,bind)=volumeStats(:,:,:,bind)+srs.^2;  % Sums of squares
            end
          case 'Epoch Average'
            for bind=1:nBins                                           % bind is index into testBins
              for et=find(ep(1:epochLen,t)==testBins(bind))'
                % Time point t is part of this bin's epoch at epoch time et
                volumeSum(:,:,:,et,bind)=volumeSum(:,:,:,et,bind)+srs; % Sums
              end
              if ep(1,t)==testBins(bind)                               % t is start of epoch for this bin
                epochCnt(bind)=epochCnt(bind)+1;                       % Increment epochCnt for this bin
              end
            end
        end % switch
      end % any(timePts==t)
      if ~ishandle(p2), emsg='User abort'; error(emsg); end
      progbar(p2,t/nPts);
      if ~ishandle(p1), emsg='User abort'; error(emsg); end
      progbar(p1,(r-1+t/nPts)/nRuns);
    end % for t
    delete(p2); p2=[];
    readmr(mrinfo,'=>CLEANUP');  % Remove any temporary files.
  end % isempty(timePts)
end % for r
delete(p1); p1=[];

% Finish calculations and write data
switch testType
  case 'T-Test'
    historyEntry = logEntry(historyEntry,logfid,'\nNumber of volumes in each bin:%s\n',sprintf(' %d=%d',[testBins; binCnt]));
    % Done creating historyEntry... Add to outTemplate & clear historyEntry so we don't use it again
    outTemplate = addHistoryEntry(outTemplate,historyEntry); clear('historyEntry');
    
    p1=progbar(sprintf('Writing 0 of %d files...',nTests));
    % TODO: Error if binCnt<2 for any testBins?
    % Calculate variance by bin (bind is index into testBins)
    for bind=1:nBins
      if binCnt(bind)>1
        volumeStats(:,:,:,bind)=(volumeStats(:,:,:,bind)-(volumeSum(:,:,:,bind).^2)./binCnt(bind))./(binCnt(bind)-1);
      end
    end
    % Calculate Tmap by test
    for test=1:nTests
      if ~ishandle(p1), emsg='User abort'; error(emsg); end
      progbar(p1,sprintf('Writing %d of %d files...',test,nTests));
      grp1=find(tests(test,1)==testBins);    % index into testBins
      grp2=find(tests(test,2)==testBins);    % index into testBins
      if binCnt(grp1)>1 & binCnt(grp2)>1
        % Calculate pooled SD by test
        Tmap(:,:,:,test)=((volumeStats(:,:,:,grp1).*(binCnt(grp1)-1))+(volumeStats(:,:,:,grp2).*(binCnt(grp2)-1)))./ ...
          (binCnt(grp1)+binCnt(grp2)-2);
        % Calculate Tmap by test
        warning('off');      % Ignore divide by zero error
        Tmap(:,:,:,test)=(volumeSum(:,:,:,grp1)./binCnt(grp1)-volumeSum(:,:,:,grp2)./binCnt(grp2))./ ...
          sqrt(Tmap(:,:,:,test).*(binCnt(grp1)+binCnt(grp2))./(binCnt(grp1)*binCnt(grp2)));
        warning('on');
        Tmap(isnan(Tmap))=0; % Replace NaN's with 0
      end
      % Write output file, if needed
      if ~isempty(outPath)
        outName=sprintf('%sMap_%d-%d_T.img',outPath,testBins(grp1),testBins(grp2));
        fprintf(logfid,'Writing file: %s\n',outName);
        % Create output structure
        outStruct = outTemplate;
        outStruct.data = Tmap(:,:,:,test);
        try writemr(outStruct,outName,'Float');
        catch emsg=sprintf('Error writing output file %s!\n%s',outName,lasterr); error(emsg); end
      end
      if ~ishandle(p1), emsg='User abort'; error(emsg); end
      progbar(p1,test/nTests);
    end
    delete(p1); p1=[];
    if nargout==1, Tout=Tmap; end
    
  case 'Epoch Average'
    historyEntry = logEntry(historyEntry,logfid,'\nNumber of event volumes in each bin:%s\n',sprintf(' %d=%d',[testBins; binCnt]));
    historyEntry = logEntry(historyEntry,logfid,'Number of complete epochs in each bin:%s\n',sprintf(' %d=%d',[testBins; epochCnt]));
    % Calculate and ouput epoch volumes
    p1=progbar(sprintf('Writing 0 of %d epoch timecourses...',nBins));
    % Check for and log empty bins (do this before writing any bins out so that it is recorded in the historyEntry for all bins.
    isBinEmpty = (epochCnt(1:nBins) == 0);
    for bind=find(isBinEmpty)
      warn=sprintf('Warning: No complete epochs found for bin %d; skipping output!',testBins(bind));
      historyEntry = logEntry(historyEntry,logfid,sprintf('*%s\n',warn));
      disp(warn);
    end
    % Done creating historyEntry... Add to outTemplate & clear historyEntry so we don't use it again
    outTemplate = addHistoryEntry(outTemplate,historyEntry); clear('historyEntry');

    % Loop through all bins  %TODO: Change progbar to only display bins being saved???
    for bind=find(~isBinEmpty)
      if ~ishandle(p1), emsg='User abort'; error(emsg); end
      progbar(p1,sprintf('Writing %d of %d epoch timecourses...',bind,nBins));
      % Calculate average (could do this is a single step but would require more memory)
      for et=1:epochLen
        volumeSum(:,:,:,et,bind)=volumeSum(:,:,:,et,bind)./epochCnt(bind);
      end
      % Write output file, if needed
      if ~isempty(outPath)
        outName=sprintf('%sBin%02d_V*.img',outPath,testBins(bind));
        % Create output structure
        outStruct = outTemplate;
        outStruct.info.dimensions(4) = outTemplate4thD; % Add 4th dimension information.
        outStruct.data = volumeSum(:,:,:,:,bind);
        fprintf(logfid,'Writing file: %s\n',outName);
        try writemr(outStruct,outName,'Float');
        catch emsg=sprintf('Error writing output file %s!\n%s',outName,lasterr); error(emsg); end
      end
      if ~ishandle(p1), emsg='User abort'; error(emsg); end
      progbar(p1,bind/nBins);
    end
    delete(p1); p1=[];
    % Calculate and ouput correlation and T-map volumes
    f=0;
    ftotal=2*nBins;
    p1=progbar(sprintf('Writing 0 of %d statistical volumes...',ftotal));
    % Loop through all bins
    for bind=1:nBins
      f=f+1;
      if ~ishandle(p1), emsg='User abort'; error(emsg); end
      progbar(p1,sprintf('Writing %d of %d statistical volumes...',f,ftotal));
      % Calculate correlation
      volumeCorr(:,:,:)=volCorr(volumeSum(:,:,:,:,bind),template,threshhold);
      % Write output file, if needed
      if ~isempty(outPath)
        outName=sprintf('%sBin%02d_cor.img',outPath,testBins(bind));
        % Create output structure
        outStruct = outTemplate;
        outStruct.data = volumeCorr;
        fprintf(logfid,'Writing file: %s\n',outName);
        try writemr(outStruct,outName,'Float');
        catch emsg=sprintf('Error writing output file %s!\n%s',outName,lasterr); error(emsg); end
      end
      if ~ishandle(p1), emsg='User abort'; error(emsg); end
      progbar(p1,f/ftotal);
      f=f+1;
      if ~ishandle(p1), emsg='User abort'; error(emsg); end
      progbar(p1,sprintf('Writing %d of %d statistical volumes...',f,ftotal));
      % Calculate T-map
      volumeCorr=(volumeCorr.*sqrt(epochLen-2))./sqrt(1-volumeCorr.^2);
      % Write output file, if needed
      if ~isempty(outPath)
        outName=sprintf('%sBin%02d_T.img',outPath,testBins(bind));
        % Create output structure
        outStruct = outTemplate;
        outStruct.data = volumeCorr;
        fprintf(logfid,'Writing file: %s\n',outName);
        try writemr(outStruct,outName,'Float');
        catch emsg=sprintf('Error writing output file %s!\n%s',outName,lasterr); error(emsg); end
      end
      if ~ishandle(p1), emsg='User abort'; error(emsg); end
      progbar(p1,f/ftotal);
    end
    delete(p1); p1=[];
    if nargout==1, Tout=volumeSum; end
end

% We're done
fprintf(logfid,'End processing: %s\n',datestr(now));
if logfid>2, fclose(logfid); logfid=[]; end

catch
  if isempty(emsg)
    if isempty(lasterr)
      emsg='An unidentified error occurred!';
    else
      emsg=lasterr;
    end
  end
  if ~isempty(mrinfo), readmr(mrinfo,'=>CLEANUP'); end
  if ~isempty(p1) & ishandle(p1), delete(p1); end
  if ~isempty(p2) & ishandle(p2), delete(p2); end
  if ~isempty(logfid) & logfid>2
      fprintf(logfid,'\n*Error while processing: %s\n%s\n',datestr(now),emsg);
      fclose(logfid);
  end
  if inGUI
    disp(sprintf('GUI Error:\n%s',emsg));
    errorbox(emsg);
  else
    error(emsg);
  end
end

%--------------------------------------------------
function ep=inEpoch(bins,epoch,paradigm)

% Return matrix ep of size [sum(epoch)+1 length(paradigm)]
% ep(et,t) is equal bin if time point t in paradigm is in epoch
% position et for the specified bin.
% Return [] if any epochs point out of paradigm.

pLen=length(paradigm);
eLen=sum(epoch)+1;
ep=zeros(eLen,pLen);
events=find(ismember(paradigm,bins))';
if ~isempty(events)
  epochs=[events-epoch(1) events+epoch(2)];
  if any(epochs(:,1)<1) | any(epochs(:,2)>pLen)
    bad=find(epochs(:,1)<1 | epochs(:,2)>pLen);
    epochs(bad,:)=[];
  end
  for e=epochs(:,1)'
    ep(1:eLen,e:e+eLen-1)=ep(1:eLen,e:e+eLen-1)+(paradigm(e+epoch(1)).*eye(eLen));
  end
end

%--------------------------------------------------
function vc=volCorr(volSrs,template,threshhold)

% Calculate correlation of voxel time series with template
% for each voxel in the volume time series
n=size(template,1);
sz=size(volSrs);
vc=zeros(sz(1:3));
% Loop through slice
for z=1:sz(3)
  tempStd=std(template(:,z),1,1);                            % Std dev of template time series
  volStd=std(volSrs(:,:,z,:),1,4);                           % Std dev of each voxel time series
  volMean=mean(volSrs(:,:,z,:),4);                           % Mean of each voxel time series
  mm=volMean.*mean(template(:,z),1);                         % Product of means
  % Loop through time
  for t=1:n
    volSrs(:,:,z,t)=volSrs(:,:,z,t).*template(t,z);          % Product of values
  end
  volSum=sum(volSrs(:,:,z,:),4);                             % Sum of product of values
  idx=volMean>=threshhold;                                   % Voxels with mean of times series >=threshhold
  r=zeros(sz(1:2));
  r(idx)=(volSum(idx)./n - mm(idx))./(volStd(idx).*tempStd); % Correlation of time series
  vc(:,:,z)=r;
end

%--------------------------------------------------
function [MRTEST_VaR,ok,emsg] = local_safeeval(MRTEST_StR)
%LOCAL_SAFEEVAL
% 
%  Simple function to evaluate a string with a single output out of scope
%  from the rest of the code.  If the eval fails, return [] and ok=0 and
%  any errors are put in emsg.  Based on similar local function in
%  Mathworks STR2NUM function.
try
  MRTEST_VaR = eval(MRTEST_StR);
  ok = logical(1);
  emsg = '';
catch
  MRTEST_VaR = [];
  ok = logical(0);
  emsg = lasterr;
end

%--------------------------------------------------
function typeSpecs = local_MakeTypeSpecCompat(x,y,z,nTimePts,dataTypes,nRuns)
%local_MakeTypeSpecCompat
%
% Function to convert compatibility mode inputs (x,y,z,nTimePts,dataTypes)
% into new typeSpecs. 
%
% typeSpecs = local_MakeTypeSpecCompat(x,y,z,nTimePts,dataTypes,nRuns)
%   x - Number of pixels in 1st dimension
%   y - Number of pixels in 2nd dimension
%   z - Number of pixels in 3rd dimension
%   nTimePts - Number of time point in each run (scalar or [1 x nRuns] vector)
%   dataTypes - Format of data ('Volume' or 'Float')
%               string (same for all runs) 
%               OR cell array of strings (format specified for each run)
%   nRuns - the number of runs being processed.  Used for expanding
%           nTimePts and dataTypes

error(nargchk(6,6,nargin));

% --- Check that x, y, and z are valid values. ---
if length(x)~=1 | length(y)~=1 | length(z)~=1 | ...
    ~isnumeric(x) | ~isnumeric(y) | ~isnumeric(z) | ...
    ~all(isint([x y z]) & [x y z]>0)
  emsg='x,y,z pixel dimensions must be positive integers.'; error(emsg);
end

% --- Process nTimePts ---
if ~isnumeric(nTimePts) | ndims(nTimePts) > 2 | size(nTimePts,1) ~= 1
  emsg='Time points must be a numeric scalar or [1 x nRuns] vector!'; error(emsg);
end
if ~all(isint(nTimePts) & nTimePts>0)
  emsg='Time points must be positive integers.'; error(emsg);
end
if length(nTimePts) == 1
  % If only one nTimePts specified, use it for all runs.
  nTimePts(1:nRuns) = nTimePts;
end
if length(nTimePts) ~= nRuns 
  emsg='Incorrect number of time points specified.'; error(emsg);
end

% --- Process dataTypes ---
if ischar(dataTypes), dataTypes={dataTypes}; end % For uniform handling
if ~iscellstr(dataTypes) | min(size(dataTypes)) ~= 1
  emsg='dataTypes must be a string or vector cell array of strings!';
end
if any(~ismember(lower(dataTypes),{'volume','float'}))
  emsg='Only Volume and Float data types are supported in compatibility mode!'; error(emsg);
end
% Convert to standard case of format name.
dataTypes(strcmpi(dataTypes,'volume')) = {'Volume'};
dataTypes(strcmpi(dataTypes,'float')) = {'Float'};
if length(dataTypes) == 1
  % If only one dataTypes specified, use it for all runs.
  dataTypes = repmat(dataTypes,1,nRuns);
end
if length(dataTypes) ~= nRuns
  emsg='Incorrect number of data types specified.'; error(emsg);
end

% Construct typeSpecs from {dataTypes,[x y z t]}
typeSpecs = cell(nRuns,1);  % Must be a column vector!
for r = 1:length(typeSpecs)
  typeSpecs{r} = {dataTypes{r},[x,y,z,nTimePts(r)]};
end

%--------------------------------------------------
function historyEntry = logEntry(historyEntry,logfid,varargin)
%LOGENTRY - Make log entry in file and add to historyEntry
%
% historyEntryOut = logEntry(historyEntryIn,logfid,logString, ...);
%
%   historyEntryIn - Previous history entry
%   historyEntryOut - New history entry (concatenated to historyEntryIn)
%   logfid - fid of log file
%   logString - sprintf/fprintf string to add to log.
%               Additional arguments are passed to sprintf/fprintf.

error(nargchk(3,inf,nargin));
fprintf(logfid,varargin{:});
historyEntry = [historyEntry,sprintf(varargin{:})];

%--------------------------------------------------
function newmrstruct = addHistoryEntry(mrstruct,historyEntry)
%ADDHISTORYENTRY - Add BXH history entry to mrstruct
%
% newmrstruct = addHistoryEntry(mrstruct,historyEntry);
%

% Add a empty BXH header if necessary (no changes made if already BXH)
newmrstruct = convertmrstructtobxh(mrstruct);

% Determine how many history entries already exist (if any).
numEntries = 0;
if isfield(newmrstruct.info.hdr.bxh{1},'history')
  numEntries = length(newmrstruct.info.hdr.bxh{1}.history{1}.entry);
end

% Add the history entry
newmrstruct.info.hdr.bxh{1}.history{1}.entry{numEntries+1}.date{1}.VALUE = datestr(now,31);
newmrstruct.info.hdr.bxh{1}.history{1}.entry{numEntries+1}.description{1}.VALUE = historyEntry;


% Modification History:
%
% $Log: mrtest.m,v $
% Revision 1.21  2005/02/03 20:17:46  michelich
% M-Lint: Replace deprecated isstr with ischar.
%
% Revision 1.20  2005/02/03 17:08:09  michelich
% M-lint:  Remove unnecessary commas.
%
% Revision 1.19  2005/02/03 16:58:40  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.18  2004/11/04 02:22:50  michelich
% Fix typo in error message.
%
% Revision 1.17  2004/10/13 19:10:27  michelich
% Fixed typo in catch statement of local_safeeval().
%
% Revision 1.16  2004/02/12 15:38:23  michelich
% Removed untested warnings.
%
% Revision 1.15  2004/01/21 23:13:37  michelich
% Use the dimensions portion of the info struct in the output.
% Check that all runs have the same dimensions structure.
% Create BXH history entry similar to logfile.
% Check for empty bins before calculating any epoch averages to create full
%   BXH history entry for all bins written.
%
% Revision 1.14  2003/10/27 21:30:26  michelich
% Include revision information in log file.
%
% Revision 1.13  2003/10/22 15:54:37  gadde
% Make some CVS info accessible through variables
%
% Revision 1.12  2003/09/10 15:25:00  michelich
% Use .img file extensions for all outputs.
%
% Revision 1.11  2003/08/27 16:37:16  michelich
% Make mrstructs from data before writing.
%
% Revision 1.10  2003/08/27 16:28:15  michelich
% Use new writemr to write the data with BXH headers.
% Write each epoch time course with a single writemr call (instead of writing
%   each volume one-by-one.)
% Use lower case .img and .cor file extensions.
%
% Revision 1.9  2003/08/26 15:53:55  michelich
% Changes based on Michael Wu's testing:
% Fixed argument handling in mrtest command line backwards compatibility mode.
%
% Revision 1.8  2003/08/23 01:51:09  michelich
% Finished writing help section.
%
% Revision 1.7  2003/08/22 16:52:15  michelich
% Changed based on Michael Wu's testing:
% Put string runNames in a cell before calling local_MakeTypeSpecCompat()
% Don't call name2spec for each runName (assume user included any desired *s)
% Handle typeSpecs for single run data consistently
% Call Epoch Averaging "bins" argument "tests" since it is treated as such in
%   other sections of the code.
%
% Revision 1.6  2003/07/30 16:03:22  michelich
% Updated to use new READMR.
% - Use typeSpecs instead of x,y,z,dataTypes,nTimePts in command line version.
% - Use RunTypeSpec instead of XPixels, YPixels, ZPixels, TimePts, RunDataType
%   in control files.
% - Implemented backwards compatiblity layer.
% - Started writing help section with detailed description of input arguments
%   and control file format.
%
% Revision 1.5  2003/02/04 01:55:57  michelich
% Only check is outPath exists if one was specified.
% Require some form of output (outPath or output argument).
%
% Revision 1.4  2003/02/03 20:32:07  michelich
% Handle outPath with filename stub correctly.
%
% Revision 1.3  2002/12/06 20:37:39  michelich
% Added ability to specify an output directory (and write results) using
%   command line version.
%
% Revision 1.2  2002/10/08 17:25:33  michelich
% Changed inEpoch to return a double array instead of a logical array.  The values returned were not logical (they indicate the bin number) therefore the function did not work in MATLAB 6.5.
%
% Revision 1.1  2002/08/27 22:24:21  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Francis Favorini,  2001/09/26. Changed numlist() to lowercase.
% Charles Michelich, 2001/01/23. Changed readkvf(), readmr(), writemr() to lowercase.
% Francis Favorini,  1999/05/10. More comments.
% Francis Favorini,  1998/11/23. Made name2spec an external function.
% Francis Favorini,  1998/11/16. Fixed bug with using bin index instead of bin number when writing T-maps.
% Francis Favorini,  1998/11/11. Handle user abort.
% Francis Favorini,  1998/11/10. Fixed bug with checking for paradigm length.
% Francis Favorini,  1998/11/06. Added correlation and T-map calculation for epochs.
%                                Use load to read paradigms and template.
% Francis Favorini,  1998/11/04. Added epoch averaging.
% Francis Favorini,  1998/10/30. Eliminated option to be prompted for files.
%                                Moved check for missing/extra fields to readkvf.
% Francis Favorini,  1998/10/27. More verbose error messages.
% Francis Favorini,  1998/10/26. Handle missing time points.
% Francis Favorini,  1998/10/20. Read header file.
% Francis Favorini,  1998/10/16. Handle multiple runs.
% Francis Favorini,  1998/10/02.
