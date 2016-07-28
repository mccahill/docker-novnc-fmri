function qastats(studyPath,params,zoom,stats)
%QASTATS Calculate quality assurance statistics on MR study's data.
%
%   qastats(studyPath,params,zoom,stats);
%	
%   studyPath is the path to the study's MR data files.
%     This path may include the subdirectory which contains the runs.
%     If it doesn't, the 'raw' subdirectory is assumed.
%   params is a cell array of the READMR parameters (except fName).
%   zoom specifies how to zoom in on the volume before calculating stats.
%     The format is [xo yo xs ys], where (xo,yo) is the new upper left corner,
%     and [xs ys] is the new dimensions of the zoomed volume.
%     Default is full size of volume.
%   stats is a string or cell array of strings specifying which statistics to calculate.
%     Default is {'Stdev','Mean','CMass'}.
%
%   Examples:
%   >>qastats('\\broca\data2\study',{128,128,12,'volume'});
%   >>qastats('\\broca\data2\study\air',{128,128,12,'volume'},[33 33 64 64]);
%   >>qastats('\\broca\data2\study\raw',{128,128,12,'volume'},[1 1 128 128],{'Mean'});

% CVS ID and authorship of this code
% CVSId = '$Id: qastats.m,v 1.3 2005/02/03 16:58:41 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:41 $';
% CVSRCSFile = '$RCSfile: qastats.m,v $';

xlWBATWorksheet=1;
allStats={'Stdev','Mean','CMass'};
sheetNames={'Volume Mean','Volume CMass'};
runsDir='raw';

lasterr('');
emsg='';
try

% Check arguments
p1=[]; p2=[]; hXL=[];
error(nargchk(2,4,nargin));
if nargin<3 | isempty(zoom), zoom=[1 1 params{1:2}]; end
if nargin<4, stats=allStats; elseif ischar(stats), stats={stats}; end
if ~exist(studyPath,'dir'), emsg=sprintf('Study directory "%s" does not exist!',studyPath); error(emsg); end

% Check for runs dir in study path
while studyPath(end)==filesep, studyPath(end)=[]; end
[path,name]=fileparts(studyPath);
if any(isletter(name)), runsDir=name; studyPath=path; end

% Get raw data run names
d=dir(fullfile(studyPath,runsDir,'run*'));
if isempty(d)
  emsg=sprintf('No runs found in study "%s"!',studyPath); error(emsg);
end
runNames=sort({d.name}');
nRuns=length(runNames);

% Make sure output directory exists
outPath=fullfile(studyPath,'Analysis');
if ~mkdir(studyPath,'Analysis'), emsg=sprintf('Unable to create output directory "%s"!',outPath); error(emsg); end
if ~mkdir(outPath,'QA'), emsg=sprintf('Unable to create output directory "%s"!',fullfile(outPath,'QA')); error(emsg); end
outPath=fullfile(outPath,'QA');

% Create/open Excel file
XLName=fullfile(outPath,'QAStats.xls');
hXL=toexcel('private');
hXL.interactive=0;
if exist(XLName,'file')
  invoke(hXL.Workbooks,'Open',XLName);            % Open existing Excel file
  toexcel(hXL,[],1,1,'Volume Mean',0);            % Go to worksheet
  % TODO: Clear all WS in sheetNames
  invoke(hXL.ActiveSheet.Cells,'Clear');          % Clear worksheet cells
else  
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
end

% Loop through runs
p1=progbar(sprintf('Processing 0 of %d runs...',nRuns),[-1 .65 -1 -1]);
for r=1:nRuns
  % Read in the time series of volumes
  if ~ishandle(p1), emsg='User abort'; error(emsg); end
  progbar(p1,sprintf('Processing %d of %d runs...',r,nRuns));
  runPath=fullfile(studyPath,runsDir,runNames{r});
  tsv=readtsv(fullfile(runPath,'*V*.img'),params,zoom);
  p2=progbar(sprintf('Calculating statistics for %s...',runPath));
  statCnt=0;
  
  % Standard deviation for each voxel time series
  if any(strcmpi('Stdev',stats))
    stdVol=std(tsv,1,4);
    stdName=fullfile(outPath,[runNames{r} '.STD']);
    writemr(stdName,stdVol,'float');
    statCnt=statCnt+1;
  end
  if ~ishandle(p2), emsg='User abort'; error(emsg); end
  progbar(p2,statCnt/length(stats));
  
  % Volume means by time
  if any(strcmpi('Mean',stats))
    volMeans=zeros(size(tsv,4),1);
    for t=1:size(tsv,4)
      vol=tsv(:,:,:,t);
      volMeans(t)=mean(vol(:));
    end
    toexcel(hXL,runNames{r},1,r,'Volume Mean',0);      % Put header in worksheet
    toexcel(hXL,volMeans,2,r,'Volume Mean',0);         % Put data in worksheet
    invoke(hXL.ActiveWorkbook,'Save');                 % Save intermediate results
    statCnt=statCnt+1;
  end
  if ~ishandle(p2), emsg='User abort'; error(emsg); end
  progbar(p2,statCnt/length(stats));
  
  % Volume centers of mass by time
  if any(strcmpi('CMass',stats))
    cm=zeros(size(tsv,4),3);
    for t=1:size(tsv,4)
      cm(t,:)=cmass(tsv(:,:,:,t));
    end
    hdr=strcat(runNames{r},{' X',' Y',' Z'});
    toexcel(hXL,hdr,1,r*3-2,'Volume CMass',0);         % Put header in worksheet
    toexcel(hXL,cm,2,r*3-2,'Volume CMass',0);          % Put data in worksheet
    invoke(hXL.ActiveWorkbook,'Save');                 % Save intermediate results
    statCnt=statCnt+1;
  end
  if ~ishandle(p2), emsg='User abort'; error(emsg); end
  progbar(p2,statCnt/length(stats));
  
  % Update progbars
  if ~ishandle(p2), emsg='User abort'; error(emsg); end
  delete(p2); p2=[];
  if ~ishandle(p1), emsg='User abort'; error(emsg); end
  progbar(p1,r/nRuns);
end

% Clean up
delete(p1); p1=[];
% TODO: Move for each WS
toexcel(hXL,[],1,1,'Volume Mean',0);                % Move to first cell in worksheet
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
  if ishandle(p1), delete(p1); end
  if ishandle(p2), delete(p2); end
  if ~isempty(hXL),
    hXL.DisplayAlerts=0;  % Don't ask whether to save
    toexcel(hXL,'Done');
  end
  error(emsg);
end

% Modification History:
%
% $Log: qastats.m,v $
% Revision 1.3  2005/02/03 16:58:41  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:38  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/08/27 22:24:23  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2001/09/14. Changed output filename case back to 'QAStats.xls' from 'qastats.xls'
% Charles Michelich, 2001/01/23. Changed function name to lowercase.
%                                Changed toexcel(), readtsv(), and readmr() to lowercase.
% Francis Favorini,  1998/12/03. Changed to look for *V*.img instead of V*.img.
% Francis Favorini,  1998/12/02. Added runsDir.
% Francis Favorini,  1998/11/24. Added stats argument.
%                                Added mean and center of mass statistics.
% Francis Favorini,  1998/11/23.
