function Tout=tstatprofile(controlfname,flags)
%TSTATPROFILE Calculate statistics on functional, TRAligned data, with the
% baseline subtracted.  
%
%  USAGE
%   tstatprofile;
%   out=tstatprofile(controlfname);
%   out=tstatprofile(flags);
%   out=tstatprofile(controlfname,flags);
%
%  INPUTS
%   controlfname is the optional string that represents the location of the Control File.
%   flags is the optional cell array of strings that will tell the function which files
%     should NOT be written out.  The flags and the files they supress are shown below:
%     {'-av' '-sd' '-avb' '-sdb' '-Avg'   '-Var'    '-Std'       '-Z'     '-N' '-Cor' '-T'}
%     {*.av  *.sd  *.avb  *.sdb Avg*.img Var*.img StdDev*.img Zscore*.img *.N  *.COR  *.T }
%     Also, the following flags, '-grand' and '-epoch', will suppress the saving of the 
%     first four elements (grand mean, etc...) of the second array above and the final 
%     seven elements of that same array (epoch average info) respectively.
%   
%  OUTPUT
%   Output argument is optional, and will return the "epoch average" TSV for each bin, 
%   (i.e. a 5 dimensional array, [x,y,z,time,bin])
%
%  NOTE:  The optional variable in the control file, OutFlags, is an eleven element 
%   array that flags those files that should *NOT* be written out.  
%   The order of OutFlags is as follows:
%   [*.av *.sd *.avb *.sdb Avg*.img Var*.img StdDev*.img Zscore*.img *.N *.COR *.T]
%
%  See also:  MRTEST

% CVS ID and authorship of this code
% CVSId = '$Id: tstatprofile.m,v 1.9 2005/02/03 20:17:47 michelich Exp $';
% CVSRevision = '$Revision: 1.9 $';
% CVSDate = '$Date: 2005/02/03 20:17:47 $';
% CVSRCSFile = '$RCSfile: tstatprofile.m,v $';

tic;
lasterr('');
emsg='';
inGUI=0;
try
  
  persistent SAVEHDRPATH SAVESRSPARAMS SAVEZOOM
  if nargout==1, Tout=[]; end
  hdrFile=[];
  logfid=1;
  p1=[];
  out_path=[];
  
  % Check args
  if nargin > 2
    emsg='Incorrect number of input arguments.'; error(emsg);
  end
  if nargout > 1
    emsg='Too many output arguments.'; error(emsg);
  end
  
  inGUI=1;
  hdrFile = '';
  outFlagsInput = {};
  % Get control file name
  if nargin==0
    % Do nothing
  elseif nargin==1
    if ischar(controlfname)
      if strncmp(controlfname,'-',1), outFlagsInput = {controlfname}; 
      else hdrFile=controlfname; end
    elseif iscellstr(controlfname), outFlagsInput = controlfname;
    else error('Input must be a string or a cell array of strings.'); end
  else
    if ~ischar(controlfname), error('Control file name must be a string.'); end
    if ~iscellstr(flags), error('Output flags must be a cell array of strings.'); end
    hdrFile=controlfname;
    outFlagsInput = flags;
  end
  if isempty(hdrFile)
    % Remember directory
    if isempty(SAVEHDRPATH), SAVEHDRPATH=pwd; end
    [hdrFile hdrPath]=uigetfile(fullfile(SAVEHDRPATH,'*.txt'),'Open Control File');
    if hdrFile==0, return; end
    hdrFile=fullfile(hdrPath,hdrFile);
    SAVEHDRPATH=hdrPath;
  end
  if ~exist(hdrFile,'file')
    emsg=sprintf('Control file %s does not exist!',hdrFile); error(emsg);
  end
  % Create log file
  [hdrPath hdrName]=fileparts(hdrFile);
  logName=fullfile(hdrPath,[hdrName '.log']);
  [logfid emsg]=fopen(logName,'wt');
  if logfid==-1, emsg=sprintf('Error opening log file %s!\n%s',logName,emsg); error(emsg); end
  fprintf(logfid,'MR Analysis Program Log File\n----------------------------\n\n');
  fprintf(logfid,'Control file: %s\n',hdrFile);
  d=dir(hdrFile);
  fprintf(logfid,'Control file date: %s\n',d.date);
  % Read header file
  reqKeys={'XPixels';'YPixels';'ZPixels';'ParadigmColumn';'OutPath';'RunName';'Paradigm';'TimePts'};
  optKeys={'SubjectNumber';'RunDataType';'Bins';'BinsTest';'Base1';'Base2';'FilenameType';'Standard';'OutFlags'};
  epochKeys={'PreEventPts';'PostEventPts';'Threshhold';'CorrelationTemplate'};
  hdrInfo=readkvf(hdrFile,reqKeys,cat(1,optKeys,epochKeys));
  % Save hdrInfo to logfile
  hdrNames=fieldnames(hdrInfo);
  fprintf(logfid,'Control file information:\n');
  for i=1:length(hdrNames)
    hdrField = getfield(hdrInfo,hdrNames{i});
    if ischar(hdrField)
      fprintf(logfid,'\t%s: %s\n',hdrNames{i},hdrField);
    end
  end
  % Set the optional fields to their default values.  
  in_data_type='volume';
  out_data_type='float';
  bintests=[];
  subNo = [];
  base1 = 0;
  base2 = 0;
  binType = 'Normal';
  stdValue = 0;
  tests=[];
  outFlags = zeros(1,11);
  % Get data from required fields
  xSize=str2num(hdrInfo.XPixels);
  ySize=str2num(hdrInfo.YPixels);
  slices=str2num(hdrInfo.ZPixels);
  runNames=hdrInfo.RunName;
  if ~iscellstr(hdrInfo.TimePts)
    %nTimePts=str2num(hdrInfo.TimePts);
    tempval = str2num(hdrInfo.TimePts);
    if length(tempval)==1, tempval=1:tempval; end
    runTimePts = {tempval};
  else
    %nTimePts=[];
    runTimePts = {};
    for c=1:length(hdrInfo.TimePts)
      %nTimePts=[nTimePts str2num(hdrInfo.TimePts{c})];
      tempval = str2num(hdrInfo.TimePts{c});
      if length(tempval)==1, tempval=1:tempval; end
      runTimePts = {runTimePts{:},tempval};
    end
  end 
  clear tempval;
  nTimePts = [];
  for i=1:length(runTimePts)
    nTimePts(i) = length(runTimePts{i});
  end
  paradigm_file=hdrInfo.Paradigm;
  column=str2num(hdrInfo.ParadigmColumn);
  out_path=hdrInfo.OutPath;
  % Check for optional fields
  if isfield(hdrInfo,'RunDataType')
    in_data_type=hdrInfo.RunDataType;
    %out_data_type=hdrInfo.RunDataType;
  end
  % Convert fields from control file from strings to correct format
  if isfield(hdrInfo, 'BinsTest')
    newbin = 0;
    currbin = [];
    for i=1:length(hdrInfo.BinsTest)
      currchar = hdrInfo.BinsTest(i);
      if ~isempty(str2num(currchar)) & newbin
        currbin = [currbin,currchar];
      end
      if ~isempty(str2num(currchar)) & ~newbin
        currbin = currchar;
        newbin = 1;
      end
      if isempty(str2num(currchar)) & newbin
        bintests = [bintests,str2num(currbin)];
        currbin = [];
        newbin = 0;
      end
    end 
    clear currbin newbin;
  end
  if isfield(hdrInfo,'SubjectNumber'), subNo = hdrInfo.SubjectNumber; end
  if isfield(hdrInfo,'Base1'), base1 = str2num(hdrInfo.Base1); end
  if isfield(hdrInfo,'Base2'), base2 = str2num(hdrInfo.Base2); end
  if isfield(hdrInfo,'FilenameType'), binType = hdrInfo.FilenameType; end
  if isfield(hdrInfo,'OutFlags'), outFlags = sscanf(hdrInfo.OutFlags,'%d'); end
  if isfield(hdrInfo,'Standard')
    if ~iscellstr(hdrInfo.Standard)
      stdValue=str2num(hdrInfo.Standard);
    else
      stdValue=[];
      for c=1:length(hdrInfo.Standard)
        stdValue=[stdValue str2num(hdrInfo.Standard{c})];
      end
    end 
  end   
  gotEpochKeys=ismember(epochKeys,fieldnames(hdrInfo));
  if any(gotEpochKeys)
    testType='Epoch Average';
    if ~all(gotEpochKeys)
      emsg=sprintf('Missing keywords from file %s:\n%s',hdrFile,strlist(epochKeys(~gotEpochKeys)));
      error(msg);
    end
    if isfield(hdrInfo,'Bins')
      if strncmp(hdrInfo.Bins,'None',4)
        tests='None';
      else
        tests=sscanf(hdrInfo.Bins,'%d');
      end  
    end
    first=-str2num(hdrInfo.PreEventPts);
    last=str2num(hdrInfo.PostEventPts);
    epoch=[-first last];
    pts = last - first + 1;
    threshhold=str2num(hdrInfo.Threshhold);
    template=hdrInfo.CorrelationTemplate;
  else
  end
  
  % Check parameters for validity
  if ~all(isint([xSize ySize slices]) & [xSize ySize slices]>0) | length(xSize)~=1 | length(ySize)~=1 | length(slices)~=1
    emsg='x,y,z pixel dimensions must be positive integers.'; error(emsg);
  end
  if ischar(runNames), runNames={runNames}; end
  for c=runNames
    c=c{1};
    if isempty(c) | ~ischar(c)
      emsg='run names must be a string or a cell array of strings.'; error(emsg);
    end
  end
  nRuns=length(runNames);
  if nRuns==0, emsg='No runs specified!'; error(emsg); end
  if ischar(in_data_type), in_data_type={in_data_type}; end
  for c=in_data_type
    c=c{1};
    if isempty(c) | ~ischar(c)
      emsg='in_data_type must be a string or a cell array of strings.'; error(emsg);
    end
  end
  if ~iscell(runTimePts) | size(runTimePts,1)~=1 | isempty(runTimePts)
    emsg='Each run time point vector must be positive integers.'; error(emsg);
  end
  if isempty(nTimePts) | size(nTimePts,1)~=1 | ~all(isint(nTimePts) & nTimePts>0)
    emsg='Time points must be positive integers.'; error(emsg);
  end
  if isempty(stdValue) | size(stdValue,1)~=1 | ~all(isint(stdValue)) %& stdValue>0)
    emsg='Standard values must be positive integers.'; error(emsg);
  end
  if ~all(isint(base1) & isint(base2))
    emsg='Baseline points must be integers.'; error(emsg);
  end
  if base1 > base2
    error('Base2 cannot be larger than Base1');
  end
  if base1 < first | base2 > last
    error('Baseline values outside of epoch. Check control file parameters.');
  end
  if isempty(paradigm_file), emsg='There are no paradigms specified.'; error(emsg); end
  if ~iscell(paradigm_file), paradigm_file={paradigm_file}; end
  for p=paradigm_file
    p=p{1};
    if isempty(p) | size(p,1)~=1 | (~ischar(p) & ~all(isint(p) & p>=0))
      emsg='Paradigm is not a filename or a vector of non-negative integers.'; error(emsg);
    end
  end
  %if length(column)~=1 | column<1 | ~isint(column), emsg='Paradigm column must be a positive integer.'; error(emsg); end
  if ~isequal(size(epoch),[1 2]) | ~all(isint(epoch) & epoch>=0)
    emsg='Epoch must be two non-negative integers.'; error(emsg);
  end
  epochLen=sum(epoch)+1;
  if ischar(tests) & isempty(bintests), error('No bins found in control file.  Nothing will be calculated.'); end
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
      template=repmat(template,1,slices);    % Replicate columns for each slice
    elseif size(template,2)~=slices
      emsg='Columns of correlation template must equal 1 or number of Z pixels.'; error(emsg);
    end
  else
    emsg='Template must be a filename or a matrix of real numbers.'; error(emsg);
  end
  outDir=fileparts(out_path);
  if ~exist(outDir,'dir')
    emsg=sprintf('Output directory %s does not exist!',outDir); error(emsg);
  end
  if ~strcmp(binType,'Normal') & ~strcmp(binType,'Unique')
    error('Incorrect filename type.  Must be "Unique" or "Normal".');
  end
  % Process out flags that were input into the function
  if ~iscellstr(outFlagsInput), error('Output flags must be a cell array of strings.'); end
  if ~isempty(outFlagsInput) & size(outFlagsInput,1)~=1 & size(outFlagsInput,2)~=1, error('Output flags must be a vector.'); end
  if ~isempty(outFlagsInput)
    flagKeys = {'-av','-sd','-avb','-sdb','-Avg','-Var','-Std','-Z','-N','-Cor','-T','-grand','-epoch'};
    keysIndx = {1,2,3,4,5,6,7,8,9,10,11,[1:4],[5:11]};
    for i=1:length(outFlagsInput)
      indx = find(strcmp(flagKeys,outFlagsInput{i}));
      if isempty(indx), emsg=sprintf('Output flag %s not found.',outFlagsInput{i}); error(emsg); end
      outFlags(keysIndx{indx}) = 1;
    end
  end
  if size(outFlags,1)~=1 & size(outFlags,2)~=1, error('Internal variable, outFlags, must be an integer vector.'); end
  if length(outFlags)~=11, error('Internal variable, outFlags, must be 11 elements long.'); end
  if any(outFlags>1) | any(outFlags<0), error('Internal variable, outFlags, must be zeros or ones.'); end
  
  % Expand args if needed
  try in_data_type(1:nRuns)=in_data_type; catch emsg='Incorrect number of data types specified.'; error(emsg); end
  try nTimePts(1:nRuns)=nTimePts; catch emsg='Incorrect number of time points specified.'; error(emsg); end
  try stdValue(1:nRuns)=stdValue; catch emsg='Incorrect number of standard values specified.'; error(emsg); end
  try paradigm_file(1:nRuns)=paradigm_file; catch emsg='Incorrect number of paradigms specified.'; error(emsg); end
  
  write_flag = 0;	% if write_flag > 0, each single trial will be written (this creates a huge dataset)	
  trial = zeros(xSize,ySize,slices,pts);
  
  if length(runNames) > length(paradigm_file)
    error('More runs specified than paradigm_files');
  end
  
  fprintf(logfid,'\nBegin Processing: %s\n', datestr(now));
  fprintf(logfid,'Processing %d runs\n', nRuns);
  fprintf(logfid,'Run Size: [%d %d %d]\n',xSize,ySize,slices);
  
  % First read through all paradigm files to identify number of unique bins
  p1=progbar(sprintf('Reading paradigm file 1 of %d...',length(paradigm_file)));
  [event_i,colBin,eventBin,eventsPerBin,uniqueBin,binnames] = findparadigmevents(paradigm_file{1},column,stdValue(1));
  all_events = event_i;
  all_bins = eventBin;
  all_Ubins = uniqueBin;
  all_binnames = binnames;
  progbar(p1,1/length(paradigm_file));
  
  if length(paradigm_file)>1
    for n=2:length(paradigm_file),
      %[event_i,eventBin,eventsPerBin]=readparadigm(strcat(paradigm_base,paradigm_file{n}),column);
      progbar(p1,sprintf('Reading paradigm file %d of %d...',n,length(paradigm_file)));
      [event_i,colBin,eventBin,eventsPerBin,uniqueBin,binnames]=findparadigmevents(paradigm_file{n},column,stdValue(n));
      all_events = cat(1,all_events,event_i);
      all_bins = cat(1,all_bins,eventBin);
      all_Ubins = { all_Ubins{:} uniqueBin{:} };
      all_binnames = cat(1,all_binnames,binnames);
      progbar(p1,n/length(paradigm_file));
    end
  end
  delete(p1);
  
  % Determine the number of bins and events within each bin 
  % Sort the bins
  switch binType
  case 'Normal'
    sortedBin = sort(all_bins);
  case 'Unique'
    sortedBin = sort(all_Ubins);
    % Sort the cell array of bin names
    bnCol1 = [all_binnames{:,1}];
    [bnCol1,idx] = sort(bnCol1);
    bnCol2 = {all_binnames{:,2}};
    all_binnames = {};
    for i=1:length(bnCol2)
      all_binnames = cat(1,all_binnames,{bnCol1(i), bnCol2{idx(i)}});
    end
  end
  
  % Initialize counting variables
  n = 1;    % index in sortedBin
  switch binType
  case 'Normal'
    bin = 1;  % bin number
    while n  <= length(sortedBin)
      % Find all events in current bin
      currBin = find(sortedBin == sortedBin(n));
      % Determine number of events in current bin
      eventsPerBin(bin,1) = length(currBin);
      % Label the bin number 
      eventsPerBin(bin,2) = sortedBin(n);
      % Move the sortedBin index to the next bin
      n = n + eventsPerBin(bin,1);
      % Increment the bin counter
      bin=bin+1;
    end
    if isempty(tests), tests=eventsPerBin(:,2); 
    elseif ischar(tests), tests=[]; end
    tests=unique(tests(:));
    testBins=[tests;bintests'];
    testBins=unique(testBins(:));
    if ~all(isint(testBins) & testBins>0), emsg='Bins must be positive integers.'; error(emsg); end
    if size(tests,2)~=1, emsg='Bins must be a column vector.'; error(emsg); end
    % Save the eventsPerBin matrix for all paradigms so that we know which events exist in ANY paradigm file
    ePBAPtemp=[];
    for i=1:length(testBins)
      indx = find(eventsPerBin(:,2)==testBins(i));
      ePBAPtemp=[ePBAPtemp;eventsPerBin(indx,:)];
    end
    eventsPerBinAllParadigms=ePBAPtemp;
    % Calculate number of unique bins
    nbins = size(eventsPerBinAllParadigms,1);
    
  case 'Unique'
    eventsPerBin = {};
    bin = sortedBin{1};
    bincnt = 0;
    while n  <= length(sortedBin)
      % Find all events in current bin
      if strcmp(sortedBin{n},bin)
        bincnt = bincnt + 1;
      else
        eventsPerBin = {eventsPerBin{:}, bincnt, sortedBin{n-1}};
        bin = sortedBin{n};
        bincnt = 1;
      end
      % Increment the bin counter
      n = n+1;
    end
    eventsPerBin = {eventsPerBin{:}, bincnt, sortedBin{n-1}};
    %eventsPerBinAllParadigms=eventsPerBin;
    %nbins = length(eventsPerBinAllParadigms)/2;
    % Create a list of all bin names for ALL paradigm files, and save into binnames
    n = 1;
    bin = 1;  % bin number
    binnames = {};
    while n  <= length([all_binnames{:,1}])
      % Find all events in current bin
      currBin = find([all_binnames{:,1}] == all_binnames{n,1});
      % Label the bin number 
      binnames = cat(1,binnames,{all_binnames{n,1}, all_binnames{n,2}});
      % Move the sortedBin index to the next bin
      n = n + length(currBin);
      % Increment the bin counter
      bin=bin+1;
    end
    if isempty(tests)
      for i=2:2:length(eventsPerBin)
        binStr = eventsPerBin{i};
        for j=1:length(binnames)
          if strcmp(binStr,binnames{j,2})
            tests = [tests, binnames{j,1}]; break;
          end
        end
      end
    elseif ischar(tests), tests=[]; end
    tests=unique(tests(:));
    testBins=[tests;bintests'];
    testBins=unique(testBins(:));
    if ~all(isint(testBins) & testBins>0), emsg='Bins must be positive integers.'; error(emsg); end
    nbins=length(testBins);
    if size(tests,2)~=1, emsg='Bins must be a column vector.'; error(emsg); end
    ePBAPtemp={};
    for i=1:length(testBins)
      binStr = '';
      for j=1:length(binnames)
        if binnames{j,1}==testBins(i)
          binStr = binnames{j,2}; break;
        end
      end
      if isempty(binStr), emsg=sprintf('Bin %d not found.',testBins(i)); error(emsg); end
      for j=2:2:length(eventsPerBin)
        if strcmp(eventsPerBin{j},binStr)
          ePBAPtemp={ePBAPtemp{:}, eventsPerBin{j-1}, eventsPerBin{j}}; break;
        end
      end
    end
    eventsPerBinAllParadigms=ePBAPtemp;
    nbins = length(eventsPerBinAllParadigms)/2;
  end
  
  %Print the bins and binnames to the log file if unique
  switch binType
  case 'Unique'
    fprintf(logfid, '\nAll Bins and All Unique Bin Names (Including Standards)\n');
    for i=1:length(binnames)
      fprintf(logfid,'Bin number:  %d, Unique bin name:  %s\n', binnames{i,1}, binnames{i,2});
    end
  end
  
  %Print paradigm counts to log file
  fprintf(logfid, '\nEvents for All Paradigm Files for Selected Bin(s) and Column(s)\n');
  uniqueBinAll = {};
  for i = 1:nbins
    switch binType
    case 'Normal'
      fprintf(logfid,'Bin: %d, Count: %d\n', eventsPerBinAllParadigms(i,2), eventsPerBinAllParadigms(i,1));
    case 'Unique'
      uniqueBinAll = {uniqueBinAll{:} eventsPerBinAllParadigms{2*i}};
      fprintf(logfid,'Bin: %s, Count: %d\n', eventsPerBinAllParadigms{2*i}, eventsPerBinAllParadigms{2*i-1});
    end
  end
  
  clear sortedBin currBin eventBin bin n event_i event_bin sortedUBin;
  bin_count = zeros(nbins,1);
  
  % Try to save some memory
  clear a* d* g* h* j* op* outD* outFlagsI* uniqueBin binS* binc* bn* ep* p logN* i id* nR* re* c colB* testT*
  
  % Preallocate memory for averaging bins
  average = zeros(xSize,ySize,slices,pts,nbins);
  sum_sqr = zeros(xSize,ySize,slices,pts,nbins);
  std_dev = zeros(xSize,ySize,slices,pts,nbins);
  var     = zeros(xSize,ySize,slices,pts,nbins);
  z_score = zeros(xSize,ySize,slices,pts,nbins);
  sum_trials  = zeros(xSize,ySize,slices,pts,nbins);
  corr = zeros(xSize,ySize,slices);
  t = zeros(xSize,ySize,slices,pts);
  sumVol = zeros(xSize,ySize,slices,length(runNames));
  sumSqrVol = zeros(xSize,ySize,slices,length(runNames));
  sumBase = zeros(xSize,ySize,slices,length(runNames));
  sumSqrBase = zeros(xSize,ySize,slices,length(runNames));
  nTimePtsGrand = zeros(1,length(runNames));
  nTimePtsBase = zeros(1,length(runNames));
  
  % Now start reading through the data
  for n=1:length(runNames),
    [event_i,colBin,eventBin,eventsPerBin,uniqueBin]=findparadigmevents(paradigm_file{n},column,stdValue(n));
    % Remove any events that occur before or after the epoch time frame
    extraStart = find(event_i+first<1);
    if ~isempty(extraStart), fprintf(logfid,'There was/were %d event(s) removed from the start of the epoch.\n',length(extraStart)); end
    %extraEnd = find(event_i+last>nTimePts(n));
    finaltp = runTimePts{n}(end);
    extraEnd = find(event_i+last>finaltp);
    if ~isempty(extraEnd), fprintf(logfid,'There was/were %d event(s) removed from the end of the epoch.\n', length(extraEnd)); end
    event_i = event_i((1+length(extraStart)):(length(event_i)-length(extraEnd)));
    colBin = colBin((1+length(extraStart)):(length(colBin)-length(extraEnd)));
    eventBin = eventBin((1+length(extraStart)):(length(eventBin)-length(extraEnd)));
    uniqueBin = uniqueBin((1+length(extraStart)):(length(uniqueBin)-length(extraEnd)));
    [event_i,idx] = intersect(event_i,runTimePts{n});
    colBin = colBin(idx); eventBin = eventBin(idx); uniqueBin = uniqueBin(idx);
    fprintf(logfid, '\nReading Run%d - Total Events: %d\n', n, length(event_i));
    run=readtsv([runNames{n}],{xSize,ySize,slices,in_data_type{n}});
    p1=progbar(sprintf('Calculating statistics for run %d: Processing time point 0 of %d...',n,size(run,4)));
    for i=1:size(run,4)
      progbar(p1,sprintf('Calculating statistics for run %d: Processing time point %d of %d...',n,i,size(run,4)));
      nanRun = isnan(run(:,:,:,i));
      % Convert NaNs to zeros
      if any(any(any(nanRun)))
        idx = find(nanRun==1);
        nanRun = run(:,:,:,i);
        nanRun(idx) = 0;
        run(:,:,:,i) = nanRun;
        fprintf(logfid, '!Warning - Volume %d in run %d has ',i,n);
        fprintf(logfid,'%d NaN values converted to 0.\n',length(idx));
      end
      sumVol(:,:,:,n) = sumVol(:,:,:,n) + run(:,:,:,i);
      sumSqrVol(:,:,:,n) = sumSqrVol(:,:,:,n) + run(:,:,:,i).^2;
      nTimePtsGrand(n) = nTimePtsGrand(n) + 1;
      progbar(p1,i/size(run,4));
    end
    delete(p1);
    
    % Now subtract the baseline prior to each stimulus event
    runNo = n;
    p1=progbar(sprintf('Processing event 0 of %d for run %d...',length(event_i),runNo));
    for n = 1:length(event_i);
      progbar(p1,sprintf('Processing event %d of %d for run %d...',n,length(event_i),runNo));
      eBinFound = 0;
      switch binType
      case 'Normal'
        eBin = eventBin(n);
        if ~isempty(find(testBins==eBin))
          eBinFound = 1;
        else
          fprintf(logfid,'Event: %d Bin %d not found in control file, skipping calculations.\n', event_i(n), eBin);
        end
      case 'Unique'
        eBin = uniqueBin{n};
        eBinNum = [];
        for j=1:length(binnames)
          if strcmp(eBin,binnames{j,2})
            eBinNum=binnames{j,1};
            break;
          end
        end
        if isempty(eBinNum), emsg=sprintf('Bin %s not found.',eBin); error(emsg); end
        if ~isempty(find(testBins==eBinNum))
          eBinFound=1;
        else
          fprintf(logfid,'Event: %d Bin %s (%d) not found in control file, skipping calculations.\n', event_i(n), eBin, eBinNum);
        end
      end
      
      if eBinFound
        eCol = colBin(n);
        i = event_i(n);
        % Each of the variables average, sum_sqr, std_dev, var, and sum_trials are
        % xSz x ySz x zSz x epochLength x number of bins
        % The corresponding bin number for each 5th Dimension index is from
        % eventsPerBinAllParadigm (i.e. all of the events from all of the paradigm files)
        % Find which 5th dimension index corresponds to the current bin.
        switch binType
        case 'Normal'
          j = find(eventsPerBinAllParadigms(:,2)==eBin); 
          if isempty(j), emsg=sprintf('Bin %d not found.',eBin); error(emsg); end
        case 'Unique'
          j = find(strcmp(uniqueBinAll,eBin));
          if isempty(j), emsg=sprintf('Bin %s not found.',eBin); error(emsg); end
        end 
        %if i+base1 < 1, emsg=sprintf('Baseline Error:\nTrying to access timepoint %d of epoch (1 to %d).',i+base1,nTimePts(runNo)); error(emsg); end
        %if i+base2 > nTimePts(runNo), emsg=sprintf('Baseline Error:\nTrying to access timepoint %d of epoch (1 to %d).',i+base2,nTimePts(runNo)); error(emsg); end
        if i+base1 < 1, emsg=sprintf('Baseline Error:\nTrying to access timepoint %d of epoch (1 to %d).',i+base1,size(run,4)); error(emsg); end
        if i+base2 > size(run,4), emsg=sprintf('Baseline Error:\nTrying to access timepoint %d of epoch (1 to %d).',i+base2,size(run,4)); error(emsg); end
        bin_count(j) = bin_count(j)+1;
        sumBase(:,:,:,runNo) = sumBase(:,:,:,runNo) + sum(run(:,:,:,i+base1:i+base2),4);
        sumSqrBase(:,:,:,runNo) = sumSqrBase(:,:,:,runNo) + sum(run(:,:,:,i+base1:i+base2).^2,4);
        nTimePtsBase(runNo) = nTimePtsBase(runNo) + length(i+base1:i+base2);
        base = repmat(mean(run(:,:,:,i+base1:i+base2),4),[1,1,1,pts]);
        trial(:,:,:,1:pts) = run(:,:,:,i+first:i+last) - base;
        sum_trials(:,:,:,:,j) = sum_trials(:,:,:,:,j) + trial;
        sum_sqr(:,:,:,:,j) = sum_sqr(:,:,:,:,j) + trial.^2;
        switch binType
        case 'Normal'
          fprintf(logfid,'Event: %i Epoch: %i to %i Baseline: %i to %i Bin: %i Col: %i\n',i, i+first, i+last, i+base1, i+base2, eBin, eCol);
        case 'Unique'
          fprintf(logfid,'Event: %i Epoch: %i to %i Baseline: %i to %i Bin: %s Col: %i\n',i, i+first, i+last, i+base1, i+base2, eBin, eCol);
        end
        if write_flag > 0
          outputfile = sprintf('%s%s%02d%s%04d%s',out_base,'ST_Bin',eBin,'_',bin_count(j),'.img');
          save(outputfile,'trial');
        end
      end   %if eBin is found
      progbar(p1,n/length(event_i));
    end   %for events
    delete(p1);
    % Save memory usage
    clear base eBin eBinFound eBinNum eCol nanRun run runNo;
  end   %for runs
  
  grandMean = zeros(xSize,ySize,slices);
  grandStdDev = zeros(xSize,ySize,slices);
  baseMean = zeros(xSize,ySize,slices);
  baseStdDev = zeros(xSize,ySize,slices);
  % Calculate the mean and standard deviation for volume over all runs and 
  %   for baseline
  for i=1:length(runNames)
    grandMean(:,:,:) = grandMean(:,:,:) + sumVol(:,:,:,i);
    baseMean(:,:,:) = baseMean(:,:,:) + sumBase(:,:,:,i);
    % Calculate a weighted standard deviation
    grandStdDev(:,:,:) = grandStdDev(:,:,:) + nTimePtsGrand(i)*sqrt((sumSqrVol(:,:,:,i)-((sumVol(:,:,:,i).^2)/nTimePtsGrand(i)))/(nTimePtsGrand(i)-1)); 
    baseStdDev(:,:,:) = baseStdDev(:,:,:) + nTimePtsBase(i)*sqrt((sumSqrBase(:,:,:,i)-((sumBase(:,:,:,i).^2)/nTimePtsBase(i)))/(nTimePtsBase(i)-1)); 
  end
  % Find all voxels with an intensity above the threshhold
  grandMean = grandMean./sum(nTimePtsGrand);
  idx = grandMean>=threshhold;
  baseMean = baseMean./sum(nTimePtsBase);
  % Calculate a grand standard deviation (3D)
  grandStdDev(:,:,:) = grandStdDev./sum(nTimePtsGrand);
  % Calculate a baseline standard deviation (3D)
  baseStdDev(:,:,:) = baseStdDev(:,:,:)./sum(nTimePtsBase);
  baseStdDev = repmat(baseStdDev,[1 1 1 pts]);
  % Write out grand mean and grand standard deviations
  if ~isempty(subNo), out_base = strcat(out_path,sprintf('%s.av', subNo));
  else out_base = strcat(out_path,'grandAvg.img'); end
  if ~outFlags(1)
    fprintf(logfid,'\nWriting file:  %s\n',out_base);
    try writemr(out_base,grandMean(:,:,:),'float');
    catch emsg=sprintf('Error writing output file %s!\n%s',out_base,lasterr);error(emsg);end
  else fprintf(logfid,'\nGrand average, %s, calculated but not written.\n',out_base); end 
  if ~isempty(subNo), out_base = strcat(out_path,sprintf('%s.sd', subNo));
  else out_base = strcat(out_path,'grandSd.img'); end
  if ~outFlags(2)
    fprintf(logfid,'Writing file:  %s\n',out_base);
    try writemr(out_base,grandStdDev(:,:,:),'float');
    catch emsg=sprintf('Error writing output file %s!\n%s',out_base,lasterr);error(emsg);end
  else fprintf(logfid,'Grand std dev, %s, calculated but not written.\n',out_base); end
  if ~isempty(subNo), out_base = strcat(out_path,sprintf('%s.avb', subNo));
  else out_base = strcat(out_path,'baselineAvg.img'); end
  if ~outFlags(3)
    fprintf(logfid,'Writing file:  %s\n',out_base);
    try writemr(out_base,baseMean(:,:,:),'float');
    catch emsg=sprintf('Error writing output file %s!\n%s',out_base,lasterr);error(emsg);end
  else fprintf(logfid,'Baseline average, %s, calculated but not written.\n',out_base); end
  if ~isempty(subNo), out_base = strcat(out_path,sprintf('%s.sdb', subNo));
  else out_base = strcat(out_path,'baselineSd.img'); end
  if ~outFlags(4)
    fprintf(logfid,'Writing file:  %s\n',out_base);
    try writemr(out_base,baseStdDev(:,:,:,1),'float');
    catch emsg=sprintf('Error writing output file %s!\n%s',out_base,lasterr);error(emsg);end
  else fprintf(logfid,'Baseline std dev, %s, calculated but not written.\n',out_base); end
  
  % Now compute the average, # tests, variance and standard deviation epochs for each bin and write out
  for i = 1:length(tests);
    n = [];
    switch binType
    case 'Normal'
      n = find(eventsPerBinAllParadigms(:,2)==tests(i));
      if ~isempty(n), binNo = eventsPerBinAllParadigms(n,2);
        out_avg = strcat(out_path,sprintf('Avg_%d_V*.img',binNo));  
        out_var = strcat(out_path,sprintf('Var_%d_V*.img',binNo)); 
        out_std = strcat(out_path,sprintf('StdDev_%d_V*.img',binNo));
        out_z = strcat(out_path,sprintf('Zscore_%d_V*.img',binNo)); 
        out_n = strcat(out_path,sprintf('Bin_%d.N',binNo));
        out_cor = strcat(out_path,sprintf('Bin_%d.COR',binNo));
        out_t = strcat(out_path,sprintf('Bin_%d.T',binNo)); end
    case 'Unique'
      binStr = '';
      for j=1:length(binnames)
        if tests(i)==binnames{j,1}
          binStr = binnames{j,2}; break;
        end
      end
      if isempty(binStr), emsg=sprintf('Bin %d not found.',tests(i)); error(emsg); end
      n = find(strcmp(uniqueBinAll,binStr));
      if ~isempty(n), binString = uniqueBinAll{n};
        out_avg = strcat(out_path,sprintf('Avg_%s_V*.img',binString)); 
        out_var = strcat(out_path,sprintf('Var_%s_V*.img',binString));
        out_std = strcat(out_path,sprintf('StdDev_%s_V*.img',binString)); 
        out_z = strcat(out_path,sprintf('Zscore_%s_V*.img',binString));
        out_n = strcat(out_path,sprintf('Bin_%s.N', binString));
        out_cor = strcat(out_path,sprintf('Bin_%s.COR', binString));
        out_t = strcat(out_path,sprintf('Bin_%s.T', binString)); end
    end
    if isempty(n), warnmsg=sprintf('Bin %d not found.  No epoch data saved for this bin.',tests(i)); 
      fprintf(logfid,strcat('\nWarning: ',warnmsg,'\n'));
      warning(warnmsg); 
    else
      % Do calculations and save TSV's and volumes
      average(:,:,:,:,n) = sum_trials(:,:,:,:,n)./bin_count(n);
      if ~outFlags(5)
        fprintf(logfid,'\nWriting files: %s\n',out_avg);
        try writetsv(out_avg,average(:,:,:,:,n),[1 1 xSize ySize],out_data_type);
        catch emsg=sprintf('Error writing output file %s!\n%s',out_avg,lasterr);error(emsg);end
      else fprintf(logfid,'\nBin avg, %s, calculated but not written.\n', out_avg); end
      var(:,:,:,:,n) = sum_sqr(:,:,:,:,n) - ( (sum_trials(:,:,:,:,n).^2) / bin_count(n));
      var(:,:,:,:,n) = var(:,:,:,:,n) / (bin_count(n)-1);
      if ~outFlags(6)
        fprintf(logfid,'Writing files: %s\n',out_var);
        try writetsv(out_var,var(:,:,:,:,n),[1 1 xSize ySize],out_data_type);
        catch emsg=sprintf('Error writing output file %s!\n%s',out_var,lasterr);error(emsg);end
      else fprintf(logfid,'Bin var, %s, calculated but not written.\n', out_var); end
      if ~outFlags(7) 
        std_dev(:,:,:,:,n) = sqrt(var(:,:,:,:,n));   
        fprintf(logfid,'Writing files: %s\n',out_std);
        try writetsv(out_std,std_dev(:,:,:,:,n),[1 1 xSize ySize],out_data_type);
        catch emsg=sprintf('Error writing output file %s!\n%s',out_std,lasterr);error(emsg);end
      else fprintf(logfid, 'Bin std dev, %s, not calculated or written.\n', out_std); end
      if ~outFlags(8) 
        warning('off');
        z_score(:,:,:,:,n) = average(:,:,:,:,n)./baseStdDev; 
        warning('on');
        fprintf(logfid,'Writing files: %s\n',out_z);
        try writetsv(out_z,z_score(:,:,:,:,n),[1 1 xSize ySize],out_data_type);
        catch emsg=sprintf('Error writing output file %s!\n%s',out_z,lasterr);error(emsg);end
      else fprintf(logfid,'Bin Z score, %s, not calculated or written.\n', out_z); end
      if ~outFlags(9) 
        fprintf(logfid,'Writing files: %s\n',out_n);
        try writemr(out_n,repmat(bin_count(n),[xSize ySize slices]),'float');
        catch emsg=sprintf('Error writing output file %s!\n%s',out_n,lasterr);error(emsg);end
      else fprintf(logfid,'Bin count (N), %s, not calculated or written.\n',out_n); end
      corr(:,:,:) = volCorr(average(:,:,:,:,n),template,idx);
      if ~outFlags(10) 
        fprintf(logfid,'Writing file:  %s\n',out_cor);
        try writemr(out_cor,corr(:,:,:),'float');
        catch emsg=sprintf('Error writing output file %s!\n%s',out_cor,lasterr);error(emsg);end
      else fprintf(logfid, 'Bin corr, %s, calculated but not written.\n', out_cor); end
      if ~outFlags(11)
        corr=(corr.*sqrt(pts-2))./sqrt(1-corr.^2);
        fprintf(logfid,'Writing file:  %s\n',out_t);
        try writemr(out_t,corr(:,:,:),'float');
        catch emsg=sprintf('Error writing output file %s!\n%s',out_t,lasterr); error(emsg); end
      else fprintf(logfid,'Bin T-map, %s, not calculated or written.\n', out_t); end
    end   % if bin not found
  end   % for tested bins
  
  if nargout==1, Tout = average; end
  
  % Compute and save T-Tests for dual bin comparisons
  for i=1:2:length(bintests)
    binA=bintests(i);
    binB=bintests(i+1);
    binAstr = '';
    binBstr = '';
    switch binType
    case 'Normal' 
      jA = find(eventsPerBinAllParadigms(:,2)==binA);
      jB = find(eventsPerBinAllParadigms(:,2)==binB);
    case 'Unique'
      if (isint(binA) & isint(binB)) & iscellstr(uniqueBinAll)
        for j=1:length(binnames)
          if binA == binnames{j,1}
            binAstr = binnames{j,2};
          end
          if binB == binnames{j,1}
            binBstr = binnames{j,2};
          end
        end
        jA = find(strcmp(uniqueBinAll,binAstr));
        jB = find(strcmp(uniqueBinAll,binBstr));           
      end
    end
    % Ignore the 'Divide by zero' warning
    if isempty(jA) | isempty(jB)
      warnmsg = sprintf('One or both bins (%d and/or %d) not found in paradigm files.\n         T-Test NOT calculated.',binA,binB);
      fprintf(logfid,strcat('\nWarning: ',warnmsg,'\n'));
      warning(warnmsg);
    else
      warning('off');
      t = (average(:,:,:,:,jA)-average(:,:,:,:,jB)) ./ sqrt(((var(:,:,:,:,jA)/bin_count(jA))+(var(:,:,:,:,jB)/bin_count(jB))));
      warning('on');
      if isempty(binAstr) & isempty(binBstr)
        out_base = strcat(out_path,sprintf('T_%d_%d_V*.img',binA,binB));
      else
        out_base = strcat(out_path,sprintf('T_%s_%s_V*.img',binAstr,binBstr));
      end
      fprintf(logfid,'\nWriting files: %s\n',out_base);
      writetsv(out_base,t,[1 1 xSize ySize],out_data_type);
    end
  end
  
  %Done
  fprintf(logfid,'\nEnd processing: %s\n',datestr(now));
  
  elapsed_time = toc;
  disp(sprintf('Processing took %.2f seconds.', elapsed_time));
  disp(sprintf('(%d min, %d sec)', floor(round(elapsed_time)/60), mod(round(elapsed_time),60)));
  fprintf(logfid,'Processing took %.2f seconds, ', elapsed_time);
  fprintf(logfid,'(%d min, %d sec)\n', floor(round(elapsed_time)/60), mod(round(elapsed_time),60));
  
  if logfid>2, fclose(logfid); logfid=[]; end
  
catch
  if isempty(emsg)
    if isempty(lasterr)
      emsg='An unidentified error occurred!';
    else
      emsg=lasterr;
    end
  end
  if ~isempty(p1) & ishandle(p1), delete(p1); end
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
%function vc=volCorr(volSrs,template,threshhold);
function vc=volCorr(volSrs,template,idx)

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
  %idx=volMean>=threshhold;                                   % Voxels with mean of times series >=threshhold
  r=zeros(sz(1:2));
  %r(idx)=(volSum(idx)./n - mm(idx))./(volStd(idx).*tempStd); % Correlation of time series
  r(idx(:,:,z))=(volSum(idx(:,:,z))./n - mm(idx(:,:,z)))./(volStd(idx(:,:,z)).*tempStd); % Correlation of time series
  vc(:,:,z)=r;
end


% Modification History:
%
% $Log: tstatprofile.m,v $
% Revision 1.9  2005/02/03 20:17:47  michelich
% M-Lint: Replace deprecated isstr with ischar.
%
% Revision 1.8  2005/02/03 16:58:45  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.7  2003/10/22 15:54:39  gadde
% Make some CVS info accessible through variables
%
% Revision 1.6  2003/07/22 14:34:47  michelich
% Changed case of readkvf. Thanks to Mary Beth Nebel for finding this problem.
%
% Revision 1.5  2003/07/01 19:25:01  michelich
% Changed case of readtsv, writetsv, writemr.
%
% Revision 1.4  2003/06/27 20:24:33  michelich
% Josh Bizzell: Changed handling of NaN values.  Now converts NaN values to
%   zero when calculating grand average and standard deviation volumes.
%   Updated indenting.
%
% Revision 1.2.2.1  2003/05/13 22:10:42  michelich
% Josh Bizzell: Fixed bug when reading multi-digit bin numbers in the BinsTest field of the control file.
%
% Revision 1.2  2003/01/14 01:03:47  michelich
% Changes by Josh Bizzell.  Added ability for user to enter time ranges in
% the control file to remove undesired time points from analysis.
%
% Revision 1.1  2002/11/06 18:33:49  michelich
% Initial CVS import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2002/11/06. Reformated comments for CVS.
%                                Changed function name to lowercase.
%                                Changed readparadigmCol to findparadigmevents.
% Josh Bizzell,      2002/10/24. Added more memory clearing before readtsv
% Josh Bizzell,      2002/08/13. FIXED BUG: Bins were incorrectly indexed when there were events that were
%                                removed at the beginning of runs because of epoch length restrictions.  
% Charles Michelich, 2002/07/11. Added clear run before readtsv for better memory management
% Josh Bizzell,      2002/02/11. Added abitlity to make subject number optional and changed its input
%                                to string only.  If user does not add field "SubjectNumber", the average
%                                and standard deviation grand and baseline volumes will be saved with the 
%                                following filenames: grandAvg.img, baselineAvg.img, grandSd.img
%                                and baselineSd.img
% Josh Bizzell,      2001/12/06. Fixed Bug - "Output flags must be a vector" OR empty.  
% Josh Bizzell,      2001/12/05. Added feature for user to enter an array of flags that will tell the 
%                                function which output files should NOT be created/saved. 
% Josh Bizzell,      2001/12/04. Fixed future whitespace, comma, semicolon error when reading bintests 
%                                from control file.  
% Josh Bizzell,      2001/12/03. Fixed freadparadigm so that warning would not print when trying to 
%                                compare an empty string to a scalar value for future versions of Matlab.
% Josh Bizzell,      2001/11/15. Cleaned function declaration and args handling.  Can pass either no input
%                                arguments or one, the control filename.  
% Charles Michelich, 2001/11/15. Fixed Bug - clear at beginning of function was clearing all passed variables (including header file name)
%                                Changed to only clear inputs other than x.
% Josh Bizzell,      2001/09/21. All output is now written out in 'float' format.  
% Josh Bizzell,      2001/09/18. Fixed Bug - Was calculating baseline standard deviation incorrectly.
% Josh Bizzell,      2001/09/14. Added some comments.  
% Josh Bizzell,      2001/09/04. Added the Output Flags option.  This allows the user to select which 
%                                statistics NOT to calculate/write out.  This is described more in 
%                                the information in the control file and above in the help comments.  
% Josh Bizzell,      2001/08/22. The function now does many things since its original version.  It
%                                calculates and saves the following statistics:  average, standard
%                                deviation, variance, and Z-score TSVs for each bin; grand mean, grand 
%                                standard deviation, baseline mean, and baseline standard deviation 
%                                volumes for the study; correlation map, T-map, and number of trial 
%                                volumes for each bin; 
% Josh Bizzell,      2001/06/14. Original Version.  
%                                Function TStatProfile based on tstatprofile
%                                script written by Gregory McCarthy 2000-08-02