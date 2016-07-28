function qastats2(expName,dataSubDir,study,typeSpec,zoom,stats,expPath)
%QASTATS2 Calculate quality assurance statistics on MR study's data.
%
%   qastats2(expName,dataSubDir,study,typeSpec,zoom,stats,expPath);
%	
%   expName is the name of the experiment.
%   dataSubDir is the data subdirecory containing the study's directory.
%   study is the full study number.
%   typeSpec is a string or cell array containing the READMR typeSpec
%     Default is 'BXH'.  Empty selects the default.
%   zoom specifies how to zoom in on the volume before calculating stats.
%     The format is [xo yo xs ys], where (xo,yo) is the new upper left corner,
%     and [xs ys] is the new dimensions of the zoomed volume.
%     Default is full size of volume.
%   stats is a string or cell array of strings specifying which statistics to calculate.
%     Default is {'Stdev','Mean','CMass'}.
%   expPath is the path to your experiment.  If you do not specify it here, the database
%     will be used determine the experiment path.
%
%   Note: If a BXH typeSpec is specified, the .bxh file in each run
%   directory is used to read the images.  For all othet typeSpecs, the
%   wildcard string 'V*.img' is used to select the input images.
%
%   Note: QASTATS2 also support the following typeSpec syntaxes for
%         backwards compatibility (deprecated syntax):
%           typeSpec = {xSz,ySz,zSz,'Volume'} or {xSz,ySz,zSz,'Float'}
%
%   Examples:
%   >>qastats2('visual.01','func\raw','20010101_12345'); % Use BXH headers
%   >>qastats2('visual.01','func\raw','20010101_12345',{'volume',[64,64,12]}); % Use 'Volume' format
%   >>qastats2('visual.01','func\filt.hipass','20010101_12345','bxh');
%   >>qastats2('visual.01','func\raw','20010101_12345','',[],{'Mean'});
%   >>qastats2('visual.01','func\raw','20010101_12345','',[],{'Mean'},'D:\');
%
%  See Also: READMR

% CVS ID and authorship of this code
% CVSId = '$Id: qastats2.m,v 1.16 2005/02/03 17:08:09 michelich Exp $';
% CVSRevision = '$Revision: 1.16 $';
% CVSDate = '$Date: 2005/02/03 17:08:09 $';
% CVSRCSFile = '$RCSfile: qastats2.m,v $';

% TODO: What about running on the same study in different dataSubDirs-->output conflict!
% TODO: Related to above: what to do when output files exist?  Aborts if .XLS does, overwrites .STD.

xlWBATWorksheet=1;
allStats={'Stdev','Mean','CMass'};
sheetNames={'Volume Mean','Volume CMass'};
dataDir='Data';
runDirSpec='run*';
analysisDir='Analysis';
QAdir='QA';
QAfile='QAStats.xls';

lasterr('');
emsg='';
mrinfostruct=[];
try
  
  % Check arguments
  fid=0; p1=[]; p2=[]; hXL=[];
  error(nargchk(3,7,nargin));
  if nargin<4 | isempty(typeSpec), typeSpec='BXH'; end
  if nargin<5, zoom=[]; end
  if nargin<6 | isempty(stats), stats=allStats; elseif ischar(stats), stats={stats}; end
  if nargin<7, expPath=''; end
  if any(~ismember(stats,allStats)), error('Unknown stat!  Choices are: Stdev, Mean, CMass'); end
  
  % Support old-style readmr parameters.  
  if iscell(typeSpec) & length(typeSpec)==4 & any(strcmpi(typeSpec{4},{'Volume','Float'})) & ...
      isnumeric(typeSpec{1}) & isnumeric(typeSpec{2}) & isnumeric(typeSpec{3})
    typeSpec={typeSpec{4},[typeSpec{1:3}]};
  end
  
  % Get location of experiment (if it was not specified)
  if isempty(expPath) | ~exist(expPath,'dir')
    % Get location of experiment
    [expPath,expName,emsg]=findexp(expName);
    if isempty(expPath), error(emsg); end
  else % If the expPath is provided, add on expName
    expPath=fullfile(expPath,expName);
  end
  
  if ~exist(expPath,'dir')
    emsg=sprintf('You do not have access to "%s".',expName); error(emsg);
  end
  
  % Make sure input and output directories exist
  % Input: \\Server\Share\Group\Exp\Data\dataSubDir\Study
  % Output: \\Server\Share\Group\Exp\Analysis\QA\study
  studyPath=fullfile(expPath,dataDir,dataSubDir,study);
  if ~exist(studyPath,'dir'), emsg=sprintf('Study directory "%s" does not exist!',studyPath); error(emsg); end
  outPath=fullfile(expPath,analysisDir,QAdir,study);
  [ok,emsg]=makedir(outPath);
  if ~ok, error(emsg); end
  XLName=fullfile(outPath,QAfile);
  if exist(XLName,'file')
    emsg=sprintf('"%s" already exists!',XLName); error(emsg);
  end
  
  % Get raw data run names
  while studyPath(end)==filesep, studyPath(end)=[]; end
  [studyPath,runsDir]=fileparts(studyPath);
  d=dir(fullfile(studyPath,runsDir,runDirSpec));      % Look in specified path
  d(~[d.isdir])=[];  % Remove non-directory matches
  if isempty(d)
    studyPath=fullfile(studyPath,runsDir);
    runsDir=defRunsDir;
    d=dir(fullfile(studyPath,runsDir,runDirSpec));    % Look in default runs dir
    if isempty(d)
      emsg=sprintf('No runs found in study "%s"!',studyPath); error(emsg);
    end
  end
  runNames=sort({d.name}');
  nRuns=length(runNames);
  
  % Construct runDataSpecs for each run
  if (iscell(typeSpec) & strcmpi(typeSpec{1},'BXH')) | (ischar(typeSpec) & strcmpi(typeSpec,'BXH'))
    % Get BXH filenames if the typeSpec in BXH
    runDataSpecs=cell(size(runNames));
    for r=1:length(runNames)
      currSpec=fullfile(studyPath,runsDir,runNames{r},'*.bxh');
      d=dir(currSpec);
      if isempty(d),
        emsg=sprintf('No BXH files found in %s',currSpec); error(emsg);
      end
      if length(d) > 1
        emsg=sprintf('More than one BXH file found in %s',currSpec); error(emsg);
      end
      runDataSpecs{r}=d.name;
    end
  else
    % Otherwise, look for V*.img in each run.
    runDataSpecs=repmat({'V*.img'},size(runNames));
  end
      
  % Create/open Excel file
  hXL=toexcel('private');
  hXL.interactive=0;
  % Create workbook and add worksheets in reverse order
  invoke(hXL.Workbooks,'Add',xlWBATWorksheet);    % Create workbook with one worksheet
  hSheet=hXL.ActiveSheet;
  hSheet.Name=sheetNames{end};                    % Name it
  release(hSheet);                                % Release ActiveX object
  for s=length(sheetNames)-1:-1:1                 % Setup the other worksheets
    hSheet=invoke(hXL.Worksheets,'Add');          % Create worksheet
    hSheet.name=sheetNames{s};                    % Name it
    release(hSheet);                              % Release ActiveX object
  end
  invoke(hXL.ActiveWorkbook,'SaveAs',XLName);     % Save as Excel file
  
  % Loop through runs
  p1=progbar(sprintf('Processing 0 of %d runs...',nRuns),[-1 .65 -1 -1]);
  for r=1:nRuns
    if ~ishandle(p1), emsg='User abort'; error(emsg); end
    progbar(p1,sprintf('Processing %d of %d runs...',r,nRuns));

    % Read the info for this time series of volumes (to use for reading as necessary)
    dataSpec=fullfile(studyPath,runsDir,runNames{r},runDataSpecs{r});
    mrinfostruct = readmr(dataSpec, typeSpec,'=>INFOONLY');
    
    % Check the data dimensions & order and get sizes
    if length(mrinfostruct.info.dimensions) ~= 4
      error(sprintf('Images are not 4D: %s',dataSpec));
    end
    if ~isequal({mrinfostruct.info.dimensions.type},{'x','y','z','t'})
      error(sprintf('Data is not in x,y,z,t order: %s',dataSpec));
    end
    dataSize=[mrinfostruct.info.dimensions.size];
    
    % Generate indicies for zoom
    if isempty(zoom) | all(zoom==[1 1 dataSize(1) dataSize(2)])
      xi=[]; yi=[]; % Keep all data
    else
      % Keep zoomed window.
      xi=zoom(1):zoom(1)+zoom(3)-1;
      yi=zoom(2):zoom(2)+zoom(4)-1;
      if xi(end) > dataSize(1) | yi(end) > dataSize(2), 
        error('Invalid Zoom!');
      end
      dataSize(1:2)=zoom(3:4);  % Update dataSize to size to be read
    end
    
    % Check if we have enough memory to read all of the data at once:
    singleRead=1;
    try
      tmp=zeros(dataSize);  % Full data array
      tmp2=zeros([dataSize(1:3),5]);  % Intermediate variables
    catch
      singleRead=0;
    end
    clear('tmp','tmp2');
    
    % Read all of the data if we can.
    if singleRead, tsv=readmr(mrinfostruct,{xi,yi,[],[]}); end
    
    p2=progbar(sprintf('Calculating statistics for %s...',dataSpec));
    statCnt=0;
    
    % Standard deviation for each voxel time series
    if any(strcmpi('Stdev',stats))
      % Process by slice for memory efficiency      
      stdVol=zeros(dataSize(1:3));
      for z=1:dataSize(3)
        if singleRead
          currSrs.data=tsv.data(:,:,z,:);
        else
          currSrs=readmr(mrinfostruct,{xi,yi,z,[]},'NOPROGRESSBAR');  % Read current slice time series
        end
        stdVol(:,:,z)=std(currSrs.data,1,4);
        if ~ishandle(p2), emsg='User abort'; error(emsg); end
        progbar(p2,(statCnt+z/dataSize(3))/length(stats));
      end

      % Write results
      % Construct output header based on input header.
      stdVol.data = stdVol;
      if singleRead, stdVol.info = tsv.info; else stdVol.info = mrinfostruct.info; end
      stdVol.info.dimensions(4)=[];   % Remove time dimension
      stdVol.info.outputelemtype='float32'; % Write as floating point
      
      % --- Add a history entry ---
      % If header is not already a BXH header, convert it so that we can
      % add a history entry.
      stdVol = convertmrstructtobxh(stdVol);
      
      % Determine how many history entries already exist (if any).
      numEntries = 0;
      if isfield(stdVol.info.hdr.bxh{1},'history')
        numEntries = length(stdVol.info.hdr.bxh{1}.history{1}.entry);
      end
      
      % Add the history entry
      stdVol.info.hdr.bxh{1}.history{1}.entry{numEntries+1}.date{1}.VALUE = datestr(now,31);
      stdVol.info.hdr.bxh{1}.history{1}.entry{numEntries+1}.description{1}.VALUE = ...
        'Calculated standard deviation along time for all time points in run using qastats2';
      
      % Write the std output data
      stdName=fullfile(outPath,[runNames{r} '_STD.bxh']);
      writemr(stdVol,stdName,'BXH');

      statCnt=statCnt+1;
    end
    if ~ishandle(p2), emsg='User abort'; error(emsg); end
    progbar(p2,statCnt/length(stats));
    
    % Check for byTimePtStats
    byTimePtStatsFlag=ismember({'Mean','CMass'},stats);
    numByTimePtStats=length(find(byTimePtStatsFlag));  % For use in progress bars
    
    if any(byTimePtStatsFlag)
      % Initialize outputs
      if byTimePtStatsFlag(1), % Volume means by time
        volMeans=zeros(dataSize(4),1);
      end
      if byTimePtStatsFlag(2), % Volume centers of mass by time
        cm=zeros(dataSize(4),3);
      end
      
      % Process each time point
      for t=1:dataSize(4)
        if singleRead
          vol.data=tsv.data(:,:,:,t);
        else
          vol=readmr(mrinfostruct,{xi,yi,[],t},'NOPROGRESSBAR');
        end
        if byTimePtStatsFlag(1), % Volume means by time     
          volMeans(t)=mean(vol.data(:));
        end
        if byTimePtStatsFlag(2), % Volume centers of mass by time
          cm(t,:)=cmass(vol.data);
        end
        
        if ~ishandle(p2), emsg='User abort'; error(emsg); end
        if ~mod(t,5), progbar(p2,(statCnt+numByTimePtStats*t/dataSize(4))/length(stats)); end
      end
        
      % Send results to Excel
      if byTimePtStatsFlag(1), % Volume means by time
        toexcel(hXL,runNames{r},1,r,'Volume Mean',0);      % Put header in worksheet
        toexcel(hXL,volMeans,2,r,'Volume Mean',0);         % Put data in worksheet
        invoke(hXL.ActiveWorkbook,'Save');                 % Save intermediate results
      end
      if byTimePtStatsFlag(2), % Volume centers of mass by time
        hdr=strcat(runNames{r},{' X',' Y',' Z'});
        toexcel(hXL,hdr,1,r*3-2,'Volume CMass',0);         % Put header in worksheet
        toexcel(hXL,cm,2,r*3-2,'Volume CMass',0);          % Put data in worksheet
        invoke(hXL.ActiveWorkbook,'Save');                 % Save intermediate results
      end
      % Move to first cell in worksheets
      toexcel(hXL,[],1,1,'Volume Mean',0);                
      toexcel(hXL,[],1,1,'Volume CMass',0);

      % Update statCnt
      statCnt=statCnt+numByTimePtStats;

      if ~ishandle(p2), emsg='User abort'; error(emsg); end
      progbar(p2,statCnt/length(stats));      
    end
    
    % Cleanup any temporary files associated with this mrinfostruct
    readmr(mrinfostruct, '=>CLEANUP');
    mrinfostruct=[];  % Set to empty for catch

    % Update progbars
    if ~ishandle(p2), emsg='User abort'; error(emsg); end
    delete(p2); p2=[];
    if ~ishandle(p1), emsg='User abort'; error(emsg); end
    progbar(p1,r/nRuns);
  end
  
  % Clean up
  delete(p1); p1=[];
  toexcel(hXL,[],1,1,sheetNames{1},0);                % Move to first cell in 1st worksheet
  invoke(hXL.ActiveWorkbook,'Save');                  % Save final results
  toexcel(hXL,'Done');
  hXL=[];
  
catch
  if isempty(emsg)
    if isempty(lasterr)
      emsg='An unidentified error occurred!';
    else
      emsg=lasterr;
    end
  end
  if fid>2, fclose(fid); end
  if ishandle(p1), delete(p1); end
  if ishandle(p2), delete(p2); end
  if ~isempty(hXL),
    hXL.DisplayAlerts=0;  % Don't ask whether to save
    toexcel(hXL,'Done');
  end
  if ~isempty(mrinfostruct)
    % Cleanup any temp files from open mrinfostruct
    readmr(mrinfostruct, '=>CLEANUP');
  end
  error(emsg);
end

% Modification History:
%
% $Log: qastats2.m,v $
% Revision 1.16  2005/02/03 17:08:09  michelich
% M-lint:  Remove unnecessary commas.
%
% Revision 1.15  2005/02/03 16:58:41  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.14  2004/10/26 21:25:47  michelich
% Bug Fix: std images were being written with same precision as the input
%  images instead of being written as float32's.  Precision of output images
%  was likely too low for them to be useful.
%
% Revision 1.13  2003/10/22 15:54:38  gadde
% Make some CVS info accessible through variables
%
% Revision 1.12  2003/09/10 17:51:33  michelich
% Simply adding BXH header (convertmrstructtobxh does all this now).
%
% Revision 1.11  2003/09/08 23:46:27  michelich
% Update for WRITEMR name change.
%
% Revision 1.10  2003/08/07 17:34:06  michelich
% Fixed typo in function prototype in help comments.
%
% Revision 1.9  2003/06/30 16:54:30  michelich
% Updated for readmr name change.
%
% Revision 1.8  2003/06/18 17:43:12  michelich
% Write STD volumes with BXH header using writemrtest.
%
% Revision 1.7  2003/04/24 13:37:18  michelich
% Remove non-directory run matches.
%
% Revision 1.6  2003/03/31 23:36:18  michelich
% Search for BXH files when BXH typespec specified.
%
% Revision 1.5  2003/03/31 04:43:25  michelich
% Use new readmrtest function to read data.
% Process by slice & time point if there is not enough memory available.
%
% Revision 1.4  2003/02/10 20:58:25  michelich
% Calculate std by slice for memory efficiency.
%
% Revision 1.3  2003/01/03 20:32:32  michelich
% Clear tsv before reading next tsv for better memory management.
% Change to only read V*.img (To exclude SPM preprocessed files).
%
% Revision 1.2  2002/09/25 22:02:00  michelich
% Use findexp to find experiment path.  Allows experiment database to be specified in one place (i.e. findexp).
%
% Revision 1.1  2002/08/27 22:24:23  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2001/09/14. Changed output filename case back to 'QAStats.xls' from 'qastats.xls'
% Charles Michelich, 2001/09/04. Added check for empty stats variable - use default for this case
% Charles Michelich, 2001/01/23. Changed function name to lowercase.
%                                Changed toexcel(), readtsv(), and readmr() to lowercase.
% Francis Favorini,  2000/03/31. Fixed bug requiring expPath as argument.		
% Charles Michelich, 1999/07/21. Added support for using if study is not in database
% Francis Favorini,  1999/07/14. Better help.
% Francis Favorini,  1999/05/03. Uses new directory structure.
%                                Uses expName, dataSubDir, study params instead of studyPath.
% Francis Favorini,  1998/12/03. Changed to look for *V*.img instead of V*.img.
% Francis Favorini,  1998/12/02. Added runsDir.
% Francis Favorini,  1998/11/24. Added stats argument.
%                                Added mean and center of mass statistics.
% Francis Favorini,  1998/11/23.
