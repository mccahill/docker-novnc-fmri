function varargout=tstatprofile2(varargin)
%TSTATPROFILE2 Calculate statistics on functional, TRAligned data, with the
% baseline subtracted.  Uses the new BIAC XML header data.  
%
%  USAGE
%   tstatprofile2;
%   tstatprofile2(controlfname);
%   out=tstatprofile2(controlfname);
%
%  INPUTS
%   controlfname is the optional string that represents the location of the Control File.
%   
%  OUTPUT
%   Output will be the parameters that were sent to TSP2.  
%
%  NOTE:  The optional variable in the control file, OutFlags, is an eleven element 
%   array that flags those files that should *NOT* be written out.  
%   The order of OutFlags is as follows:
%   [*.av *.sd *.avb *.sdb Avg*.img Var*.img StdDev*.img Zscore*.img *.N *.COR *.T]
%
%  See also:  MRTEST, TSTATPROFILE

% CVS ID and authorship of this code
% CVSId = '$Id: tstatprofile2.m,v 1.16 2005/02/11 17:27:19 michelich Exp $';
% CVSRevision = '$Revision: 1.16 $';
% CVSDate = '$Date: 2005/02/11 17:27:19 $';
% CVSRCSFile = '$RCSfile: tstatprofile2.m,v $';

tic;
lasterr('');

persistent SAVEHDRPATH

% Check input/output arguments
if length(varargin) > 2
  emsg='Too many input arguments.'; error(emsg);
end
if nargout > 1
  if length(varargout) > 1
    emsg='Too many output arguments.'; error(emsg);
  end
end

vout = [];
if nargin == 0 | isempty(varargin)
  if isempty(SAVEHDRPATH), SAVEHDRPATH=pwd; end
  [hdrFile,hdrPath]=uigetfile(fullfile(SAVEHDRPATH,'*.txt'),'Open Control File');
  if hdrFile ~= 0
    SAVEHDRPATH = hdrPath;
    vout = tstatprofile2(fullfile(hdrPath,hdrFile));
  else disp('No control file selected.'); end
elseif isstruct(varargin{1})
  vout = main(varargin{1});
elseif exist(varargin{1},'file')
  controlfile = varargin{1};
  SAVEHDRPATH = fileparts(controlfile);
  % Read header file
  reqKeys={'OutPath';'RunName';'Paradigm'};
  optKeys={'XPixels';'YPixels';'ZPixels';'TimePts';'SubjectNumber';'RunDataType';...
      'ParadigmColumn';'Bins';'BinsTest';'FilenameType';'Standard';'OutFlags';...
      'NOPROGRESSBAR';'USEBRAINONLY';'TRALIGNFLAG';'OUTPUT3D';'BrainThresh';...
      'FindBadPoints';'BadPointThresh';'FilterTR'};
  epochKeys={'PreEventPts';'PostEventPts';'Base1';'Base2';...
      'Threshhold';'CorrelationTemplate'};
  tsp2params=readkvf(controlfile,reqKeys,cat(1,optKeys,epochKeys));
  tsp2params.controlfile = controlfile;
  vout = main(tsp2params);
elseif nargin >= 2 & ischar(varargin{1}) & ischar(varargin{2})
  exam = varargin{1};
  exppath = varargin{2};
  if isempty(findstr(exppath,'\')) & isempty(findstr(exppath,'/'))
    exppath = findexp(exppath);
  end
  tsp2params = [];
  load(fullfile(exppath,'Control','tsp2params.mat'),'-mat');
  if isempty(tsp2params), error('Error loading tsp2params.'); end
  runNames = {};
  funcdir = fullfile(exppath,'Data','TRAlign',exam);
  rundir = dir(funcdir);
  if isempty(rundir)
    error(sprintf('Directory %s does not exist.',funcdir));
  end
  for i=3:length(rundir)
    if getfield(rundir,{i},'isdir')
      testdir = fullfile(funcdir,getfield(rundir,{i},'name'));
      fquery = dir(fullfile(testdir,'*.bxh'));
      if length(fquery) > 1
        error(sprintf('Invalid number of XML headers in folder %s',testdir)); 
      end
      if ~isempty(fquery)
        runNames = cat(2,runNames,{fullfile(testdir,getfield(fquery,{1},'name'))});
      end
    end
  end
  if isempty(runNames)
    error(sprintf('No XML headers found in subfolders of %s.',funcdir)); 
  end
  tsp2params.RunName = runNames;
  if ~isfield(tsp2params,'OutPath')
    tsp2params.OutPath = fullfile(exppath,'Analysis\',exam);
  end
  vout = main(tsp2params);
else
  error('Invalid input variable(s)');
end
if nargout == 1, 
  varargout{1} = vout; 
end

% --- MAIN PROCESSING FUNCTION ---
% This is the main processing function
function vout = main(tsp2params)

% CVS ID and authorship of this code
CVSRevision = '$Revision: 1.16 $';
CVSDate = '$Date: 2005/02/11 17:27:19 $';

p1=[]; LOGFID = []; emsg = '';  % Initialize for catch
try
  nTimePts = [];
  indatatype = [];
  out = [];
  runTimePts = {};
  
  runNames = tsp2params.RunName;
  if ~iscellstr(runNames), runNames = {runNames}; end
  paradigmfiles = tsp2params.Paradigm;
  if ~iscellstr(paradigmfiles), paradigmfiles={paradigmfiles}; end
  outpath = tsp2params.OutPath;
  if isfield(tsp2params,'XPixels'),xSize=str2num(tsp2params.XPixels);end
  if isfield(tsp2params,'YPixels'),ySize=str2num(tsp2params.YPixels);end
  if isfield(tsp2params,'ZPixels'),slices=str2num(tsp2params.ZPixels);end
  if isfield(tsp2params,'Bins'),bins=sscanf(tsp2params.Bins,'%d');
  else bins = []; end
  if isfield(tsp2params,'BinsTest')
    newbin = 0; currbin = []; bintests = [];
    for i=1:length(tsp2params.BinsTest)
      currchar = tsp2params.BinsTest(i);
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
  else bintests = []; end
  bins = union(bins,bintests);
  bintests = reshape(bintests,[2,length(bintests)/2])';
  if isfield(tsp2params,'CorrelationTemplate') 
    template = tsp2params.CorrelationTemplate; end
  if isfield(tsp2params,'ParadigmColumn')
    column = tsp2params.ParadigmColumn; 
    if ischar(column), column=str2num(column); end
  else column = []; end
  if isfield(tsp2params,'TimePts')
    if ~iscellstr(tsp2params.TimePts)
      %nTimePts=str2num(tsp2params.TimePts);
      tempval = str2num(tsp2params.TimePts);
      if length(tempval)==1, tempval=1:tempval; end
      runTimePts = {tempval};
    else
      %nTimePts=[];
      for c=1:length(tsp2params.TimePts)
        %nTimePts=[nTimePts str2num(tsp2params.TimePts{c})];
        tempval = str2num(tsp2params.TimePts{c});
        if length(tempval)==1, tempval=1:tempval; end
        runTimePts = {runTimePts{:},tempval};
      end
    end 
    clear tempval;
  end
  if isfield(tsp2params,'RunDataType'),indatatype=tsp2params.RunDataType; end
  if isfield(tsp2params,'PostEventPts'), last = tsp2params.PostEventPts; 
    if ischar(last), last = str2num(last); end
  end
  if isfield(tsp2params,'PreEventPts'), first = tsp2params.PreEventPts; 
    if ischar(first), first = str2num(first); end
    first = -first;
  end
  if isfield(tsp2params,'Base1'), base1 = tsp2params.Base1; 
    if ischar(base1), base1=str2num(base1); end
  end
  if isfield(tsp2params,'Base2'), base2 = tsp2params.Base2; 
    if ischar(base2), base2 = str2num(base2); end
  end
  if isfield(tsp2params,'Standard')
    if ~iscellstr(tsp2params.Standard), stdValue=str2num(tsp2params.Standard);
    else
      stdValue=[];
      for c=1:length(tsp2params.Standard)
        stdValue=[stdValue,str2num(tsp2params.Standard{c})];
      end
    end 
  else stdValue = zeros(1,length(paradigmfiles)); end
  if isfield(tsp2params,'BrainThresh'),threshhold=tsp2params.BrainThresh;
    if ischar(threshhold), threshhold=str2num(threshhold); end
  else threshhold = []; end
  if isfield(tsp2params,'Threshhold'),tmapthresh = tsp2params.Threshhold;
    if ischar(tmapthresh), tmapthresh = str2num(tmapthresh); end
  end
  if isfield(tsp2params,'OutFlags')
    if ischar(tsp2params.OutFlags),outFlags=sscanf(tsp2params.OutFlags,'%d'); 
    else outFlags=tsp2params.OutFlags; end
  else outFlags = zeros(1,11); end
  if isfield(tsp2params,'SubjectNumber'),subNo=tsp2params.SubjectNumber;
  else subNo = []; end
  if isfield(tsp2params,'NOPROGRESSBAR')
    NOPROGRESSBAR = str2num(tsp2params.NOPROGRESSBAR); 
  else NOPROGRESSBAR = 0; end
  if isfield(tsp2params,'USEBRAINONLY')
    USEBRAINONLY = str2num(tsp2params.USEBRAINONLY);
  else USEBRAINONLY = 0; end
  if isfield(tsp2params,'OUTPUT3D')
    OUTPUT3D = str2num(tsp2params.OUTPUT3D);
  else OUTPUT3D = 0; end
  if isfield(tsp2params,'FilenameType')
    if strncmp(tsp2params.FilenameType,'Unique',6), tsp2params.UNIQUEFLAG = 1;
    else tsp2params.UNIQUEFLAG = 0; end
  else
    if ~isfield(tsp2params,'UNIQUEFLAG'), tsp2params.UNIQUEFLAG = 0; end
  end
  UNIQUEFLAG = tsp2params.UNIQUEFLAG;
  if isfield(tsp2params,'TRALIGNFLAG')
    TRALIGNFLAG = str2num(tsp2params.TRALIGNFLAG);
  else TRALIGNFLAG = 1; end
  if isfield(tsp2params,'FindBadPoints')
    findbadpoints = str2num(tsp2params.FindBadPoints);
  else findbadpoints = 0; end
  if isfield(tsp2params,'BadPointThresh')
    stdThresh = str2num(tsp2params.BadPointThresh);
  else stdThresh = 3; end
  if isfield(tsp2params,'FilterTR'),
    filterTR{1} = []; filterTR{2} = '';
    idx = regexp(tsp2params.FilterTR,'[LlHhSsBb]','once');
    if isempty(idx)
      filterTR{1} = str2num(tsp2params.FilterTR);
      filterTR{2} = 'bandpass';
    else
      filterTR{1} = str2num(tsp2params.FilterTR(1:idx-1));
      if strcmp(tsp2params.FilterTR(idx),'L') | strcmp(tsp2params.FilterTR(idx),'l')
        filterTR{2} = 'low';
      elseif strcmp(tsp2params.FilterTR(idx),'S') | strcmp(tsp2params.FilterTR(idx),'s')
        filterTR{2} = 'stop';
      elseif strcmp(tsp2params.FilterTR(idx),'B') | strcmp(tsp2params.FilterTR(idx),'b')
        filterTR{2} = 'bandpass';
      else filterTR{2} = 'high'; end
    end
    if isempty(filterTR{1})
      error(['Invalid filter entry: ',tsp2params.FilterTR]); 
    end
    if min(filterTR{1})<3, error('Filter TR values must be greater than 2.'); end
  else filterTR = {}; end
  
  % Convert UNC paths to UNIX paths to allow control files to be used on
  % UNIX and Windows without modification.
  if isunix
    outpath = unc2unix(outpath);
    runNames = unc2unix(runNames);
    paradigmfiles = unc2unix(paradigmfiles);
    template = unc2unix(template);
  end
  
  if ~exist(outpath,'dir')
    warning(sprintf('Creating out path "%s".',outpath)); 
    [status,emsg] = makedir(outpath);
    if ~status, error(emsg); end
  end
  if isfield(tsp2params,'controlfile')
    logName = [tsp2params.controlfile(1:end-3),'log'];
  else
    logName = fullfile(outpath,'tstatlog2.txt');
  end
  
  % Create log file
  [LOGFID emsg]=fopen(logName,'wt');
  if LOGFID==-1
    emsg=sprintf('Error opening log file %s!\r\n%s',logName,emsg); 
    error(emsg); 
  end
  if isunix
    user = getenv('USER');
  else
    user = getenv('USERNAME');
  end
  if isempty(user), user = 'Unknown'; end
  fprintf(LOGFID,'----- TSTATPROFILE2 Log File -----\r\n\r\n');
  fprintf(LOGFID,'TSP2 %s %s\r\n',CVSRevision(2:end-1),CVSDate(8:end-2));
  fprintf(LOGFID,'Run by user: %s\r\n',user);
  fprintf(LOGFID,'Begin processing: %s\r\n',datestr(now));
  fprintf(LOGFID,'----------------------------------\r\n');
  
  % Initialize some variables
  allevents = {};
  allcols = {};
  allbins = {};
  allbinnames = {};
  listallbins = [];
  ISRAW = 0;
  format = autodetectmr(runNames{1});
  if ~isempty(format), tsvinfo = readmr(runNames{1},'=>INFOONLY');
  else
    if isempty(nTimePts), error('Number of time points not defined.'); end
    if isempty(indatatype), error('Data type not defined'); end
    if strncmp(indatatype,'volume',6), indatatype = 'int16'; 
    elseif strncmp(indatatype,'float',5), indatatype = 'float32'; 
    else error('Unknown run data type.'); end
    rawparams = {'Raw',[xSize,ySize,slices,nTimePts(1)],indatatype,'l',0};
    tsvinfo = readmr(runNames{1},rawparams,'=>INFOONLY');
    ISRAW = 1;
  end
  readmr(tsvinfo,'=>CLEANUP');
  xSize = getfield(tsvinfo.info.dimensions,{1},'size');
  ySize = getfield(tsvinfo.info.dimensions,{2},'size');
  slices = getfield(tsvinfo.info.dimensions,{3},'size');
  if isempty(runTimePts) & length(tsvinfo.info.dimensions)==4
    runTimePts = {1:getfield(tsvinfo.info.dimensions,{4},'size')};
  end
  if length(runTimePts) == 1
    tempval = {};
    for i=1:length(runNames)
      tempval = {tempval{:},runTimePts{1}};
    end
    runTimePts = tempval; clear tempval;
  end
  if length(runTimePts) ~= length(runNames)
    error('TimePts must be defined once or once for every run.');
  end
  for i=1:length(runTimePts)
    nTimePts(i) = length(runTimePts{i});
  end
  pts = last - first + 1;
  template=load(template,'-ascii');
  if pts ~= length(template)
    error('Rows of correlation template must match length of epoch.');
  end
  
  % Write variables to log file
  parm = tsp2params;
  if nargout == 1, vout = tsp2params; end
  clear tsp2params;
  fprintf(LOGFID,'\r\n--- Control file and other variables ---\r\n');
  fprintf(LOGFID,'XSize: %d\r\nYSize: %d\r\nZSize: %d\r\n',xSize,ySize,slices);
  if isfield(parm,'Bins'),fprintf(LOGFID,'Bins: %s\r\n',parm.Bins); end
  if isfield(parm,'BinsTest'),fprintf(LOGFID,'BinsTest:  %s\r\n',parm.BinsTest);end
  if isfield(parm,'ParadigmColumn'),
    fprintf(LOGFID,'ParadigmColumn: %s\r\n',parm.ParadigmColumn);end
  if isfield(parm,'PreEventPts'),
    fprintf(LOGFID,'PreEventPts: %s\r\n',parm.PreEventPts); end
  if isfield(parm,'PostEventPts'),
    fprintf(LOGFID,'PostEventPts: %s\r\n',parm.PostEventPts); end
  if isfield(parm,'Base1'),
    fprintf(LOGFID,'Base1: %s\r\nBase2: %s\r\n',parm.Base1,parm.Base2);end
  if isfield(parm,'FilenameType'),
    fprintf(LOGFID,'FilenameType: %s\r\n',parm.FilenameType); end
  % Write the outpath variable instead of parm.outPath to include any
  % changes by unc2unix.  No need to check if this variable was defined
  % code above requires it is present in tsp2params.
  fprintf(LOGFID,'OutPath: %s\r\n',outpath);
  clear parm
  
  % Replicate the template if requested
  if TRALIGNFLAG, template = repmat(template,1,slices); 
  else
    fprintf(LOGFID,'\r\n--- Using fitted-spline to template ---\r\n');
    t = 1:pts+1;
    template(pts+1) = mean(template(base1-first+1:base2-first+1));
    interval = zeros(1,slices);
    for i=1:slices, interval(i) = (i-1)/slices; end
    tt = zeros(1,pts*slices);
    for i=1:pts
      for j=1:slices, tt((i-1)*slices+j) = i + interval(j); end
    end
    template2 = spline(t,template,tt);
    template2 = reshape(template2,[slices,pts])';
    if mod(slices,2)==0, idx = [1:2:slices-1,2:2:slices];
    else idx = [1:2:slices,2:2:slices-1]; end
    %idx = 1:slices;
    idx
    template = zeros(size(template2));
    template = template2(:,idx);
    clear template2 t tt interval
  end
  
  % Read the paradigm files
  if ~NOPROGRESSBAR
    p1=progbar(sprintf('Reading paradigm file 1 of %d...',length(paradigmfiles)));
  end
  for n=1:length(paradigmfiles),
    if ~NOPROGRESSBAR
      progbar(p1,sprintf('Reading paradigm file %d of %d...',n,length(paradigmfiles)));
    end
    [event_i,colBin,eventBin,eventsPerBin,uniqueBin,binnames]=...
      findparadigmevents(paradigmfiles{n},column,stdValue(n));
    allevents = {allevents{:},event_i};
    allcols = {allcols{:},colBin};
    allbins = {allbins{:},eventBin};
    listallbins = [listallbins,unique(eventBin)'];
    %allUbins = {allUbins{:},uniqueBin};
    allbinnames = cat(1,allbinnames,binnames);
    if ~NOPROGRESSBAR, progbar(p1,n/length(paradigmfiles)); end
  end
  if ~isempty(p1) & ishandle(p1), delete(p1); end;
  listallbins = unique(listallbins);
  [dummy,idx] = unique([allbinnames{:,1}]);
  binnames = {allbinnames{idx,2}};
  binnames = cat(2,num2cell(dummy)',binnames');
  nbins = length(listallbins);
  fprintf(LOGFID,'\r\n--- List of all bins from all paradigm files ---\r\n');
  for i=1:nbins
    fprintf(LOGFID,'Bin number:  %d\t',listallbins(i));
    idx = find([binnames{:,1}]==listallbins(i));
    fprintf(LOGFID,'Bin unique code:  %s\t',binnames{idx,2});
    cnt = 0;
    for j=1:length(allbins)
      idx = find([allbins{j}]==listallbins(i));
      cnt = cnt + length(idx);
    end
    fprintf(LOGFID,'Bin count:  %d\r\n',cnt);
  end
  
  % If no bins specified, run epoch tests of all bins found in the
  % paradigm files
  if isempty(bins)
    bins = listallbins;
    fprintf(LOGFID,'\r\n--- No bins specified, using all bins found. ---\r\n');
  end
  
  % Find the bins that don't exist in the paradigm files and remove
  [dummy,idx] = setdiff(bins,listallbins);
  if ~isempty(idx)
    fprintf(LOGFID,'\r\n--- Removing bins from control file not ');
    fprintf(LOGFID,'found in paradigm files ---\r\n');
    tempbins = [];
    for i=1:size(bintests,1)
      if isempty(intersect(bintests(i,:),bins(idx)))
        tempbins = cat(1,tempbins,bintests(i,:));
      else
        fprintf(LOGFID,'Removing BinsTest [%d %d]\r\n',bintests(i,:));
      end
    end
    bintests = tempbins;
    tempbins = [];
    for i=1:length(bins)
      if isempty(find(idx==i))
        tempbins = cat(2,tempbins,bins(i));
      else
        fprintf(LOGFID,'Removing Bin %d\r\n',bins(i));
      end
    end
    bins = tempbins;
  end
  bins = unique(bins);
  nbins = length(bins);
  
  % Read the first run to get a pointer to "brain" only voxels
  readcmd = 'runNames{1}';
  if ISRAW, readcmd = sprintf('%s,rawparams',readcmd); end
  if NOPROGRESSBAR, readcmd = sprintf('%s,''NOPROGRESSBAR''',readcmd); end
  readcmd = sprintf('run = readmr(%s);',readcmd);
  eval(readcmd);
  runinfo = run.info;
  run = run.data;
  % Change the data to a 2D vector, voxels x timepts
  run = reshape(run,[xSize*ySize*slices,size(run,4)]);
  % If desired, extract brain voxels for analysis.  Otherwise, use all voxels
  if ~USEBRAINONLY
    fprintf(LOGFID,'\r\n--- Using all voxels for analysis ---\r\n');
    bgmean = 0; bgstd = 0;
    runptr = [1:xSize*ySize*slices]';
    fprintf(LOGFID,'%d total voxels per volume.\r\n',length(runptr));
  else
    fprintf(LOGFID,'\r\n--- Using "brain" voxels for analysis ---\r\n');
    [run,runptr,bgmean,bgstd] = findbrain(run,threshhold,{xSize,ySize,slices});
    fprintf(LOGFID,'Went from %d voxels to ',xSize*ySize*slices);
    fprintf(LOGFID,'%d voxels.\r\n',length(runptr));
    if length(runptr) < .15*xSize*ySize*slices
      question = {'Small number of "brain" voxels detected.',...
        sprintf('Went from %d voxels to %d voxels, (%.2f percent).',...
        xSize*ySize*slices,length(runptr),100*length(runptr)/(xSize*ySize*slices)),...
        'Consider using or lowering BrainThresh in control file.',...
        'Continue or Stop?'};
      if NOPROGRESSBAR, warning([question{1},' ',question{2},' ',question{3}]);
      else
        bn=questdlg(question, ...
          'TstatProfile2 Warning!', ...
          'Continue','Stop','Continue');
        if strcmp(bn,'Stop'),
          error('User quit: too few voxels in brain extraction.');
        end
      end
    end
  end
  
  % Allocate memory for processing
  sumVol = zeros(length(runptr),1);
  sumSqrVol = zeros(length(runptr),1);
  sumBase = zeros(length(runptr),1);
  sumSqrBase = zeros(length(runptr),1);
  nTPGrand = [];
  nTPBase = zeros(length(runNames),1);
  bincount = zeros(nbins,1);
  sumTrials = {};
  sumSqrTrials = {};
  average = {};
  for i=1:nbins
    sumTrials{i} = zeros(length(runptr),pts);
    sumSqrTrials{i} = zeros(length(runptr),pts);
    average{i} = zeros(length(runptr),pts);
  end
  
  % Read through the runs
  for n=1:length(runNames)
    fprintf(LOGFID,'\r\n--- Processing Run %d ---\r\n',n);
    if size(runNames{n},1)>1, 
      fprintf(LOGFID,'\r\nRun first image:  %s\r\n',runNames{n}{1});
    else
      fprintf(LOGFID,'\r\nRun header:  %s\r\n',runNames{n});
    end
    fprintf(LOGFID,'Paradigm file:  %s\r\n',paradigmfiles{n});
    if n~=1
      readcmd = 'runNames{n}';
      if ISRAW, readcmd = sprintf('%s,rawparams',readcmd); end
      if NOPROGRESSBAR, readcmd = sprintf('%s,''NOPROGRESSBAR''',readcmd); end
      readcmd = sprintf('run = readmr(%s);',readcmd);
      eval(readcmd);
      runinfo = run.info;
      run = run.data;
      fprintf(LOGFID,'Size of run:  %s\r\n',num2str(size(run)));
      % Change the data to a 2D vector, voxels x timepts
      run = reshape(run,[xSize*ySize*slices,size(run,4)]);
      % Sometimes the run = run(runptr,:) runs out of memory.  If that happens,
      % loop through the voxels assigning values.  
      try run = run(runptr,:);
      catch
        row = {}; disp('Using memory save.'); 
        for t = 1:size(run,2)
          row = cat(1,row,{run(runptr,t)});
        end
        clear run; run = cat(2,row{:}); clear row;
      end
    else fprintf(LOGFID,'Size of run:  ');
      fprintf(LOGFID,'%s\r\n',num2str([xSize,ySize,slices,size(run,2)]));
    end
    % Replace NaN with zeros
    for t=1:size(run,2)
      nanidx = [];
      nanidx = find(isnan(run(:,t))==1);
      if ~isempty(nanidx), run(nanidx,t) = 0;
        fprintf(LOGFID, '!Warning - Volume %d in run %d has ',t,n);
        fprintf(LOGFID,'%d NaN values converted to 0.\r\n',length(nanidx));
      end
    end
    % Temporally filter the data if requested
    if ~isempty(filterTR)
      fprintf(LOGFID,'Temporally filtering the data:  ');
      fprintf(LOGFID,'%s TR(s) %s filter.\r\n',num2str(filterTR{1}),filterTR{2});
      run = temporalfilter(run,filterTR,n,NOPROGRESSBAR); 
    end
    % Find the bad points spikes over the entire run. Algorithm by Chuck Michelich
    if findbadpoints
      volMean = mean(run,1);           % Find the TSV mean
      volMean = detrend(volMean);      % Detrend the data
      numiter = 1;
      isBad = false(size(volMean));
      lastNumBadPts = Inf;
      volMeanStd = std(volMean(~isBad));
      while lastNumBadPts ~= length(find(isBad)) & numiter < 100
        % How many points were bad last time
        lastNumBadPts = length(find(isBad));
        % What is bad this time
        isBad = abs(volMean - mean(volMean(~isBad))) > stdThresh*volMeanStd;
        % What is our new std
        volMeanStd = std(volMean(~isBad));
        numiter = numiter + 1;
      end
      badPoints = find(isBad);
    else badPoints = [];
    end
    [smV,smsqV] = sumRunVol(run,n,NOPROGRESSBAR,LOGFID);
    sumVol = sumVol + smV; clear smV; 
    sumSqrVol = sumSqrVol + smsqV; clear smsqV;
    nTPGrand = [nTPGrand,size(run,2)];
    if ~NOPROGRESSBAR
      p1=progbar(sprintf('Processing event 0 of %d for run %d...',...
        length(allevents{n}),n));
    end
    % Loop through the events
    fprintf(LOGFID,'Number of events:  %d\r\n\r\n',length(allevents{n}));
    for event = 1:length(allevents{n});
      if ~NOPROGRESSBAR
        progbar(p1,sprintf('Processing event %d of %d for run %d...',...
          event,length(allevents{n}),n));
      end
      eTim = allevents{n}(event);
      eBin = allbins{n}(event);
      eCol = allcols{n}(event);
      j = find(bins==eBin);
      if isempty(find(runTimePts{n}==eTim))
        fprintf(LOGFID,'Event: %d NOT IN DEFINED TIME POINTS. IGNORING.',eTim);
        if ~UNIQUEFLAG, eBin = num2str(eBin);
        else, eBin = binnames{find([binnames{:,1}]==bins(j)),2}; end
        fprintf(LOGFID,' Bin: %s Col: %d\r\n',eBin,eCol);
      elseif ((eTim+first < 1) | (eTim+last > nTPGrand(n)) | (eTim+base1 < 1)) & ~isempty(j)
        fprintf(LOGFID,'Event: %d REMOVED. EPOCH OUT OF TIME RANGE.',eTim); 
        if ~UNIQUEFLAG, eBin = num2str(eBin);
        else eBin = binnames{find([binnames{:,1}]==bins(j)),2}; end
        fprintf(LOGFID,' Bin: %s Col: %d\r\n',eBin,eCol);
      else
        if ~isempty(j)
          if ~isempty(intersect(badPoints,[eTim+first:eTim+last]))
            fprintf(LOGFID,'Event: %d REMOVED. "BAD" TIME POINT.\r\n',eTim);
          else
            base = mean(run(:,eTim+base1:eTim+base2),2);
            sumBase = sumBase + sum(run(:,eTim+base1:eTim+base2),2);
            sumSqrBase = sumSqrBase + sum(run(:,eTim+base1:eTim+base2).^2,2);
            nTPBase(n) = nTPBase(n) + length(eTim+base1:eTim+base2);
            for t=first:last
              trial(:,t-first+1) = run(:,eTim+t) - base;
            end
            sumTrials{j} = sumTrials{j} + trial;
            sumSqrTrials{j} = sumSqrTrials{j} + trial.^2;
            bincount(j) = bincount(j) + 1;
            if ~UNIQUEFLAG, eBin = num2str(eBin);
            else eBin = binnames{find([binnames{:,1}]==bins(j)),2}; end
            fprintf(LOGFID,'Event: %d Epoch: %d to %d ',eTim,eTim+first,eTim+last); 
            fprintf(LOGFID,'Baseline: %d to %d ',eTim+base1,eTim+base2);
            fprintf(LOGFID,'Bin: %s Col: %d\r\n',eBin,eCol);
          end
        else
          fprintf(LOGFID,'Event: %d Bin %d not ',eTim,eBin);
          fprintf(LOGFID,'requested in control file\r\n');
        end
      end
      if ~NOPROGRESSBAR, progbar(p1,event/length(allevents{n})); end
    end
    if ~NOPROGRESSBAR, delete(p1); end
    
    % Save some memory
    clear run base trial
  end
  
  % Calculate and write the grand average volume
  fprintf(LOGFID,'\r\n--- Calculating and Writing Cumulative Stats ---\r\n');
  if ~isempty(subNo),outbase = fullfile(outpath,sprintf('%s_av.bxh',subNo));
    outbase2 = fullfile(outpath,sprintf('%s.av',subNo));
  else outbase = fullfile(outpath,'grandAvg.bxh'); 
    outbase2 = [outbase(1:end-3),'img']; end
  if ~outFlags(1)
    fprintf(LOGFID,'Writing file:  %s\r\n',outbase);
    vol = sumVol/sum(nTPGrand);
    vol = mrrestore(vol,runptr,[bgmean,bgstd,xSize,ySize,slices]);
    idx = vol>=tmapthresh;
    vol = setupmrstruct(vol,tsvinfo,'float32',4);
    writecmd='writemr(vol,outbase,{''BXH'',''image'',[],outbase2},''OVERWRITE'');';
    try eval(writecmd);
    catch emsg=sprintf('Error writing output file %s!\r\n%s',outbase,lasterr);
      error(emsg); end
  else fprintf(LOGFID,'\r\nGrand average, %s, calculated but not written.\r\n',outbase); 
  end 
  
  % Calculate and write the grand standard deviation volume
  vol = [];
  if ~isempty(subNo), outbase = fullfile(outpath,sprintf('%s_sd.bxh', subNo));
    outbase2 = fullfile(outpath,sprintf('%s.sd',subNo));
  else outbase = fullfile(outpath,'grandSd.bxh'); 
    outbase2 = [outbase(1:end-3),'img']; end
  if ~outFlags(2)
    fprintf(LOGFID,'Writing file:  %s\r\n',outbase);
    vol = sqrt((sumSqrVol-((sumVol.^2)/sum(nTPGrand)))/(sum(nTPGrand)-1));
    vol = mrrestore(vol,runptr,[0,0,xSize,ySize,slices]);
    vol = setupmrstruct(vol,tsvinfo,'float32',4);
    writecmd='writemr(vol,outbase,{''BXH'',''image'',[],outbase2},''OVERWRITE'');';
    try eval(writecmd);
    catch emsg=sprintf('Error writing output file %s!\r\n%s',outbase,lasterr);
      error(emsg); end
  else fprintf(LOGFID,'Grand std dev, %s, calculated but not written.\r\n',outbase); 
  end 
  
  % Calculate and write the baseline average volume
  if ~isempty(subNo),outbase = fullfile(outpath,sprintf('%s_avb.bxh',subNo));
    outbase2 = fullfile(outpath,sprintf('%s.avb',subNo));
  else outbase = fullfile(outpath,'baselineAvg.bxh'); 
    outbase2 = [outbase(1:end-3),'img']; end
  if ~outFlags(3)
    fprintf(LOGFID,'Writing file:  %s\r\n',outbase);
    vol = sumBase/sum(nTPBase);
    vol = mrrestore(vol,runptr,[bgmean,bgstd,xSize,ySize,slices]);
    vol = setupmrstruct(vol,tsvinfo,'float32',4);
    writecmd='writemr(vol,outbase,{''BXH'',''image'',[],outbase2},''OVERWRITE'');';
    try eval(writecmd);
    catch emsg=sprintf('Error writing output file %s!\r\n%s',outbase,lasterr);
      error(emsg); end
  else fprintf(LOGFID,'Baseline average, %s, calculated but not written.\r\n',outbase); 
  end 
  
  % Calculate and write the baseline standard deviation volume
  vol = [];
  if ~isempty(subNo), outbase = fullfile(outpath,sprintf('%s_sdb.bxh', subNo));
    outbase2 = fullfile(outpath,sprintf('%s.sdb',subNo));
  else outbase = fullfile(outpath,'baselineSd.bxh'); 
    outbase2 = [outbase(1:end-3),'img']; end
  if ~outFlags(4)
    fprintf(LOGFID,'Writing file:  %s\r\n',outbase);
    vol = sqrt((sumSqrBase-((sumBase.^2)/sum(nTPBase)))/(sum(nTPBase)-1));
    vol = mrrestore(vol,runptr,[0,0,xSize,ySize,slices]);
    baseStd = vol;
    vol = setupmrstruct(vol,tsvinfo,'float32',4);
    writecmd='writemr(vol,outbase,{''BXH'',''image'',[],outbase2},''OVERWRITE'');';
    try eval(writecmd);
    catch emsg=sprintf('Error writing output file %s!\r\n%s',outbase,lasterr);
      error(emsg); end
  else fprintf(LOGFID,'Baseline std dev, %s, calculated but not written.\r\n',outbase); 
  end 
  clear vol
  
  % Loop through the bins calculating and writing tsv statistics
  for i = 1:nbins;
    if ~UNIQUEFLAG, ebin = num2str(bins(i));
    else ebin = binnames{find([binnames{:,1}]==bins(i)),2}; end
    fprintf(LOGFID,'\r\n--- Calculating and Writing Stats For Bin %s ---\r\n',ebin);
    % Calculate and write the average TSV
    if OUTPUT3D, outbase = fullfile(outpath,sprintf('Avg_%s_V*.img',ebin));
    else outbase = fullfile(outpath,sprintf('Avg_%s_V.bxh',ebin)); end
    if ~outFlags(5)
      fprintf(LOGFID,'Writing file:  %s\r\n',outbase);
      average{i} = sumTrials{i}./bincount(i);
      tsv = mrrestore(average{i},runptr,[0,0,xSize,ySize,slices]);
      tsv = setupmrstruct(tsv,tsvinfo,'float32',4);
      if OUTPUT3D, outspec = {'Float'};
      else outspec = {'BXH','image',[],[outbase(1:end-3),'img']}; end
      writecmd='writemr(tsv,outbase,outspec,''OVERWRITE'');';
      try eval(writecmd);
      catch emsg=sprintf('Error writing output file %s!\r\n%s',outbase,lasterr);
        error(emsg); end
    else fprintf(LOGFID,'\r\nAverage, %s, calculated but not written.\r\n',outbase); 
    end    
    % Calculate and write the zscore TSV
    if OUTPUT3D, outbase = fullfile(outpath,sprintf('Zscore_%s_V*.img',ebin));
    else outbase = fullfile(outpath,sprintf('Zscore_%s_V.bxh',ebin)); end
    if ~outFlags(8)
      fprintf(LOGFID,'Writing file:  %s\r\n',outbase);
      % Calculate using average "tsv" from above and baseline std from baseStd above
      for t=1:pts
        warning('off');tsv.data(:,:,:,t)=(tsv.data(:,:,:,t))./baseStd;warning('on');
      end
      if OUTPUT3D, outspec = {'Float'};
      else outspec = {'BXH','image',[],[outbase(1:end-3),'img']}; end
      writecmd='writemr(tsv,outbase,outspec,''OVERWRITE'');';
      try eval(writecmd);
      catch emsg=sprintf('Error writing output file %s!\r\n%s',outbase,lasterr);
        error(emsg); end
    else fprintf(LOGFID,'Variance, %s, calculated but not written.\r\n',outbase); 
    end
    % Calculate and write the variance TSV
    if OUTPUT3D, outbase = fullfile(outpath,sprintf('Var_%s_V*.img',ebin));
    else outbase = fullfile(outpath,sprintf('Var_%s_V.bxh',ebin)); end
    if ~outFlags(6)
      fprintf(LOGFID,'Writing file:  %s\r\n',outbase);
      tsv = sumSqrTrials{i}-((sumTrials{i}.^2)/bincount(i));
      tsv = tsv./(bincount(i)-1);
      tsv = mrrestore(tsv,runptr,[0,0,xSize,ySize,slices]);
      tsv = setupmrstruct(tsv,tsvinfo,'float32',4);
      if OUTPUT3D, outspec = {'Float'};
      else outspec = {'BXH','image',[],[outbase(1:end-3),'img']}; end
      writecmd='writemr(tsv,outbase,outspec,''OVERWRITE'');';
      try eval(writecmd);
      catch emsg=sprintf('Error writing output file %s!\r\n%s',outbase,lasterr);
        error(emsg); end
    else fprintf(LOGFID,'Variance, %s, calculated but not written.\r\n',outbase); 
    end
    % Calculate and write the standard deviation TSV
    if OUTPUT3D, outbase = fullfile(outpath,sprintf('StdDev_%s_V*.img',ebin));
    else outbase = fullfile(outpath,sprintf('StdDev_%s_V.bxh',ebin)); end
    if ~outFlags(7)
      fprintf(LOGFID,'Writing file:  %s\r\n',outbase);
      tsv.data = sqrt(tsv.data);
      if OUTPUT3D, outspec = {'Float'};
      else outspec = {'BXH','image',[],[outbase(1:end-3),'img']}; end
      writecmd='writemr(tsv,outbase,outspec,''OVERWRITE'');';
      try eval(writecmd);
      catch emsg=sprintf('Error writing output file %s!\r\n%s',outbase,lasterr);
        error(emsg); end
    else fprintf(LOGFID,'Variance, %s, calculated but not written.\r\n',outbase); 
    end
    % Calculate and write the number of bins volume
    outbase = fullfile(outpath,sprintf('N_%s.bxh',ebin));
    if ~outFlags(9)
      fprintf(LOGFID,'Writing file:  %s\r\n',outbase);
      vol = bincount(i)*ones(length(runptr),1);
      vol = mrrestore(vol,runptr,[0,0,xSize,ySize,slices]);
      vol = setupmrstruct(vol,tsvinfo,'int16',2);
      writecmd='writemr(vol,outbase,{''BXH'',''image'',[],[outbase(1:end-3),''img'']},''OVERWRITE'');';
      try eval(writecmd);
      catch emsg=sprintf('Error writing output file %s!\r\n%s',outbase,lasterr);
        error(emsg); end
    else fprintf(LOGFID,'Variance, %s, calculated but not written.\r\n',outbase); 
    end
    % Calculate and write the correlation volume
    outbase = fullfile(outpath,sprintf('COR_%s.bxh',ebin));
    if ~outFlags(10)
      fprintf(LOGFID,'Writing file:  %s\r\n',outbase);
      vol = mrrestore(average{i},runptr,[0,0,xSize,ySize,slices]);
      vol = volCorr(vol,template,idx);
      vol = setupmrstruct(vol,tsvinfo,'float32',4);
      writecmd='writemr(vol,outbase,{''BXH'',''image'',[],[outbase(1:end-3),''img'']},''OVERWRITE'');';
      try eval(writecmd);
      catch emsg=sprintf('Error writing output file %s!\r\n%s',outbase,lasterr);
        error(emsg); end
    else fprintf(LOGFID,'Variance, %s, calculated but not written.\r\n',outbase); 
    end
    % Calculate and write the Tmap volume
    outbase = fullfile(outpath,sprintf('T_%s.bxh',ebin));
    if ~outFlags(11)
      fprintf(LOGFID,'Writing file:  %s\r\n',outbase);
      warning('off');
      vol.data = ((vol.data).*sqrt(pts-2))./sqrt(1-(vol.data).^2);
      warning('on');
      writecmd='writemr(vol,outbase,{''BXH'',''image'',[],[outbase(1:end-3),''img'']},''OVERWRITE'');';
      try eval(writecmd);
      catch emsg=sprintf('Error writing output file %s!\r\n%s',outbase,lasterr);
        error(emsg); end
    else fprintf(LOGFID,'Variance, %s, calculated but not written.\r\n',outbase); 
    end
    
  end
  
  % Calculate and write the bin comparison tsvs
  if ~isempty(bintests)
    fprintf(LOGFID,'\r\n--- Calculating and Writing Bin Comparison Stats ---\r\n');
  end
  for i=1:size(bintests,1)
    eBin1 = bintests(i,1);
    eBin2 = bintests(i,2);
    j1 = find(bins==eBin1);
    j2 = find(bins==eBin2);
    if ~UNIQUEFLAG, eBin1 = num2str(bins(j1)); eBin2 = num2str(bins(j2)); 
    else eBin1 = binnames{find([binnames{:,1}]==bins(j1)),2}; 
      eBin2 = binnames{find([binnames{:,1}]==bins(j2)),2}; 
    end
    if OUTPUT3D, outbase = fullfile(outpath,sprintf('T_%s_%s_V*.img',eBin1,eBin2));
    else outbase = fullfile(outpath,sprintf('T_%s_%s_V.bxh',eBin1,eBin2)); end
    fprintf(LOGFID,'Writing file:  %s\r\n',outbase);
    warning('off');
    tsv = average{j1}-average{j2};
    tsv = tsv ./ sqrt(...
      ((sumSqrTrials{j1}-((sumTrials{j1}.^2)/bincount(j1)))./(bincount(j1).^2-bincount(j1)))+...
      ((sumSqrTrials{j2}-((sumTrials{j2}.^2)/bincount(j2)))./(bincount(j2).^2-bincount(j2))));
    warning('on');
    tsv = mrrestore(tsv,runptr,[0,0,xSize,ySize,slices]);
    tsv = setupmrstruct(tsv,tsvinfo,'float32',4);
    if OUTPUT3D, outspec = {'Float'};
    else outspec = {'BXH','image',[],[outbase(1:end-3),'img']}; end
    writecmd='writemr(tsv,outbase,outspec,''OVERWRITE'');';
    try eval(writecmd);
    catch emsg=sprintf('Error writing output file %s!\r\n%s',outbase,lasterr);
      error(emsg); end
  end
  
  % Print bin count summary 
  fprintf(LOGFID,'\r\n--- Bin Count Summary ---\r\n');
  for i=1:nbins
    if ~UNIQUEFLAG, binstr = num2str(bins(i));
    else binstr = binnames{find([binnames{:,1}]==bins(i)),2}; end
    cnt = 0;
    for j=1:length(allbins)
      idx = find([allbins{j}]==listallbins(i));
      cnt = cnt + length(idx);
    end
    fprintf(LOGFID,'Bin %s: \tAnalyzed %d of %d events.\r\n',binstr,bincount(i),cnt);
    fprintf(1,'Bin %s: \tAnalyzed %d of %d events.\n',binstr,bincount(i),cnt);
  end
  
  %Done processing, print out some time statistics
  fprintf(LOGFID,'\r\nEnd processing: %s\r\n',datestr(now));
  
  elapsed_time = toc;
  donemsg = sprintf('Processing took %.2f seconds.\n', elapsed_time);
  donemsg = [donemsg,sprintf('(%d min, %d sec)', floor(round(elapsed_time)/60), ...
      mod(round(elapsed_time),60))];
  disp(donemsg);
  fprintf(LOGFID,donemsg);
  
  if LOGFID>2, fclose(LOGFID); LOGFID=[]; end  
  
catch
  if isempty(emsg)
    if isempty(lasterr)
      emsg='An unidentified error occurred!';
    else
      emsg=lasterr;
    end
  end
  if ~isempty(p1) & ishandle(p1), delete(p1); end
  if ~isempty(LOGFID) & LOGFID>2
    fprintf(LOGFID,'\r\n*Error while processing: %s\r\n%s\r\n',datestr(now),emsg);
    fclose(LOGFID);
    LOGFID = [];
  end
  error(emsg);
end

% --- INLINE FUNCTION ---
% findbrain - Select only those voxels which are within the brain.
% This code is adapted from the "extract" function created by 
% Dr. Martin McKeown.  
function [newdata,ptr,bgmean,bgstd,cutoff] = findbrain(data,threshhold,params)
if size(data,1) == 1, mn = data; 
else mn = min(data,[],2); end
if ~isempty(threshhold)
  cutoff = threshhold;
else
  [n,x] = hist(mn,200);
  ii = find(x >50);
  xs = x(ii);
  ns = n(ii);
  warning('off');
  [p,S] = polyfit(xs,ns,5);
  warning('on');
  y = polyval(p,xs);
  for i = 1:(length(ns)-3)
    if(y(i) > y(i+1) & y(i+1) < y(i+2))
      select = i+1;
      break
    end
  end
  cutoff = xs(select);
end
numtp = length(mn);
ptr = find(mn > cutoff);
% Smooth the "brain" to account for interrun variance
vol = zeros([params{1},params{2},params{3}]);
vol(ptr) = 1; 
vol = smooth3(vol,'gaussian',[3,3,3],0.65);
ptr = find(vol>0);
newdata = data(ptr,:);
if isempty(newdata)
  error('Error finding brain; check threshhold and/or TSV histogram.'); 
end
% Find the background mean and standard deviation
backgroundp = setxor(ptr,1:numtp);
bgmean = mean(mn(backgroundp,:));
bgstd = std(mn(backgroundp,:));



% --- INLINE FUNCTION ---
% sumRunVol - Calculate the grand sum by looping through time points
% Slow, but does not give "Out of Memory" error as often.  
function [sumVol,sumsqrVol] = sumRunVol(run,runNo,NOPROGRESSBAR,LOGFID)

if nargout > 0, smV = zeros(size(run,1),1); end
if nargout > 1, smsqV = zeros(size(run,1),1); end
if ~NOPROGRESSBAR
  p1=progbar(sprintf...
    ('Calculating statistics for run %d: Processing time point 0 of %d...',...
    runNo,size(run,2)));
else p1 = []; end
for i=1:size(run,2)
  if ~NOPROGRESSBAR
    progbar(p1,sprintf...
      ('Calculating statistics for run %d: Processing time point %d of %d...',...
      runNo,i,size(run,2)));
  end
  nanRun = isnan(run(:,i));
  if any(any(any(nanRun)))
    fprintf(LOGFID, '!Warning - Volume %d in run %d has NaN values.\r\n',i,runNo);
  else
    smsqV = smsqV + run(:,i).^2; 
    smV = smV + run(:,i); 
  end
  if ~NOPROGRESSBAR
    progbar(p1,i/size(run,2));
  end
end
if ~isempty(p1) & ishandle(p1), delete(p1); end
clear nanRun; 
if nargout > 0, sumVol = smV; end
if nargout > 1, sumsqrVol = smsqV; end



% --- INLINE FUNCTION ---
% setupmrstruct - Create an MR structure for writing data. 
function outmr = setupmrstruct(inmr,ininfo,ftype,fsize)
inmr = createmrstruct(inmr);
%inmr.info.elemtype = ftype; 
inmr.info.outputelemtype = ftype;
inmr.info.elemsize = fsize;
inmr.info.hdr = ininfo.info.hdr; 
inmr.info.hdrtype = ininfo.info.hdrtype;
if ndims(inmr.data) == 3
  inmr.info.dimensions = ininfo.info.dimensions(1:3);
elseif ndims(inmr.data) == 4
  inmr.info.dimensions = ininfo.info.dimensions(1:4);
  inmr.info.dimensions(4).size = size(inmr.data,4);
else error('Invalid number of dimensions.'); end
if nargout==1, outmr = inmr; end



% --- INLINE FUNCTION ---
% mrrestore - Restore MR data from its compressed state. 
function newdata = mrrestore(data,ptr,params)
bgmean = params(1);
bgstd = params(2);
xdim = params(3);
ydim = params(4);
zdim = params(5);
% Create a matrix with random gaussian white noise
randn('state',sum(100*clock));
tempdata = bgmean + sqrt(bgstd)*randn([xdim*ydim*zdim,size(data,2)]);
for i=1:size(data,2)
  tempdata(ptr,i) = data(:,i);
end
newdata = tempdata;
clear tempdata;
newdata = squeeze(reshape(newdata,[xdim,ydim,zdim,size(data,2)]));



% % --- INLINE FUNCTION ---
% %volCorr - Calculate correlation of voxel time series with template
% %for each voxel in the volume time series
function vc=volCorr(volSrs,template,idx)
% Calculate correlation of voxel time series with template
% for each voxel in the volume time series
n=size(template,1);
sz=size(volSrs);
vc=zeros(sz(1:3));
% Loop through slice
for z=1:sz(3)
  tempStd=std(template(:,z),1,1);       % Std dev of template time series
  volStd=std(volSrs(:,:,z,:),1,4);      % Std dev of each voxel time series
  volMean=mean(volSrs(:,:,z,:),4);      % Mean of each voxel time series
  mm=volMean.*mean(template(:,z),1);    % Product of means
  % Loop through time
  for t=1:n
    volSrs(:,:,z,t)=volSrs(:,:,z,t).*template(t,z); % Product of values
  end
  volSum=sum(volSrs(:,:,z,:),4);        % Sum of product of values
  r=zeros(sz(1:2));
  % Correlation of time series
  r(idx(:,:,z))=(volSum(idx(:,:,z))./n - mm(idx(:,:,z)));
  r(idx(:,:,z)) = r(idx(:,:,z))./(volStd(idx(:,:,z)).*tempStd); 
  vc(:,:,z)=r;
end

% --- INLINE FUNCTION ---
% temporalfilter - Filter the functional MR data with a 5th order Butterworth filter.
function newdata = temporalfilter(data,TRval,runNo,NOPROGRESSBAR)

if length(TRval{1}) == 2
  TR = [2/TRval{1}(1),2/TRval{1}(2)];
  wn = [min(TR),max(TR)];
else
  wn = 2/TRval{1};
end

% Create the butterworth filter
[b,a] = butter(5,wn,TRval{2});

% Loop through the voxels filtering across time
if ~NOPROGRESSBAR
  p1=progbar(sprintf...
    ('Temporally filtering run %d: Voxel 0 of %d...',...
    runNo,size(data,1)));
  if size(data,1) > 256*4, modval = round(size(data,1)/256);
  else modval = size(data,1); end
else p1 = []; end
for i = 1:size(data,1)
  mn = mean(data(i,:));
  data(i,:) = filtfilt(b,a,data(i,:)) + mn;
  if ~NOPROGRESSBAR & mod(i,modval) == 0
    progbar(p1,sprintf...
      ('Temporally filtering run %d: Voxel %d of %d...',...
      runNo,i,size(data,1)));
    progbar(p1,i/size(data,1));
  end
end
if ~isempty(p1) & ishandle(p1), delete(p1); end
newdata = data;


% Modification History:
%
% $Log: tstatprofile2.m,v $
% Revision 1.16  2005/02/11 17:27:19  michelich
% Josh Bizzell: Fixed runTimePts bug introduced by previous fix.
%
% Revision 1.15  2005/02/10 19:02:32  michelich
% Josh Bizzell:  Fixed error when time points are to be excluded as requested
% by user.
%
% Revision 1.14  2005/02/03 20:17:47  michelich
% M-Lint: Replace deprecated isstr with ischar.
%
% Revision 1.13  2005/02/03 16:58:45  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.12  2005/01/24 22:02:39  michelich
% Added the ability to do temporal filtering; low-pass, high-pass, band-pass and stop band filters.
% Added the option to remove intensity spikes.
% Changed the output to return the parameters used to run the function in a struct.
% Added the option to use the struct of parameters as an input.
% Check to see if the automatic brain thresh hold detection returned too few voxels.
% Added a bin count summary to print at end of function and log file.
%
% Revision 1.11  2004/08/05 16:03:03  michelich
% Josh Bizzell: Creates output folder if it does not exist.
%
% Revision 1.10  2004/04/15 21:43:34  michelich
% Use isunix for MATLAB 5.3 compatibility.
%
% Revision 1.9  2004/02/12 19:41:45  michelich
% Josh Bizzell:  Fixed bug: Error when bin not requested in control file was
%   out of run time range.
%
% Revision 1.8  2004/01/12 21:48:00  michelich
% Changes by Josh Bizzell:
% - Uses autodetectmr to determine format of data.
% - Added BrainThresh variable for manual definition of the brain voxels
%   when USEBRAINONLY is set.
%
% Revision 1.7  2004/01/02 18:43:58  michelich
% Fixed argument checking.
% Look for user in USER environment variable on UNIX.
% Log outpath after unx2unix modifications.
%
% Revision 1.6  2004/01/02 17:11:52  michelich
% Convert UNC path to UNIX paths for control file portability.
%
% Revision 1.5  2003/11/03 19:58:17  michelich
% Updated indenting.
%
% Revision 1.4  2003/11/03 19:56:49  michelich
% Removed all global variables.
% Moved try-catch to the main() local function.
% - Allows making LOGFID a local varaible.
% - Fixes automatic closing of progress bars.
% Added NOPROGRESSBAR and LOGFID as arguments to sumRunVol() local function.
%
% Revision 1.3  2003/10/30 15:54:01  michelich
% Josh Bizzell: Added CVS version info to log file.
%
% Revision 1.2  2003/10/29 21:29:46  michelich
% Removed pack().  Let users to this only if necessary.
%
% Revision 1.1  2003/10/29 21:27:26  michelich
% Initial CVS import
%
%
% Pre CVS History Entries:
% Josh Bizzell  2003/10/29      Fixed NaN bug
% Josh Bizzell  2003/10/27      Added log file comments.
% Josh Bizzell  2003/10/2       Fixed bug with setting outputelemtype.
% Josh Bizzell  2003/10/1       Fixed indexing bug causing program to read
%                               incorrect run order.  
% Josh Bizzell, 2003/6/23       Original released version.
