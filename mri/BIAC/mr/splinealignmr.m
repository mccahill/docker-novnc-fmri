function splinealignmr(outPath,studyPath,runs,typeSpec,cmdlineTR,order,outFormat,outFilenames)
%splinealignmr Temporally align slices within a TR using spline interpolation
%
%   splinealignmr(outPath,studyPath,runs,typeSpec,TR)
%   splinealignmr(outPath,studyPath,runs,typeSpec,TR,order)
%   splinealignmr(outPath,studyPath,runs,typeSpec,TR,order,outFormat)
%
%   outPath is the path to use for output.
%       Directories for each run will be created in the outPath.
%   studyPath is the path to the study.
%   runs is a cell array of runs names to process.
%       Leave empty to process all runs in study (studyPath\run*).  Default is {}.
%   typeSpec is a string or cell array containing the READMR typeSpec
%       Default is 'BXH'.  Empty selects the default.
%   TR is the TR in seconds with which the data in study was acquired.
%       Default is to read from the header.
%   order specifies the acquisition order of slices as a vector of
%      slice numbers in chronological order.  [] uses default.
%      The default is all odds first, then evens, each in ascending order.
%   outFormat specifies the output format (see WRITEMR outputtype).
%      The default format is 'RawVolumes' with the same pixel type as the input.
%   outFilenames is a string or cell arry containing the output filename
%      for each run.  If a string is specified, it is used for all runs.
%      Default is 'V*.img'
%
%   Examples
%     cd(findexp('MyExperiment.01'))
%     splinealignmr('analysis\TRalign','data\func\000101_00001')
%     splinealignmr('analysis\TRalign','data\func\000101_00001',{},'BXH')
%     splinealignmr('analysis\TRalign','data\func\000101_00001',{},{'Float',[64 64 34]})
%     splinealignmr('analysis\TRalign','data\func\000101_00001',{'run01' 'run02'},{'Volume',[64,64,34]},3)
%     splinealignmr('analysis\TRalign','data\func\000101_00001',{},{'Volume',[64,64,34]},1.5,[1:size(tsv,3)])
%     splinealignmr('analysis\TRalign','data\func\000101_00001',{},{'Volume',[64,64,34]},1.5,[1:size(tsv,3)],'Float')
%     splinealignmr('analysis\TRalign','data\func\000101_00001',{},{'Volume',[64,64,34]},1.5,[1:size(tsv,3)],'BXH','header.bxh')
%
%   See also SPLINEALIGNTSV and SPLINEALIGNMR

% CVS ID and authorship of this code
% CVSId = '$Id: splinealignmr.m,v 1.13 2011/02/15 15:47:35 petty Exp $';
CVSRevision = '$Revision: 1.13 $';
CVSDate = '$Date: 2011/02/15 15:47:35 $';
% CVSRCSFile = '$RCSfile: splinealignmr.m,v $';

%____________________________________________________________________________
% Check arguments and set defaults
error(nargchk(2,8,nargin));
if ~ischar(outPath), error('outPath must be a string.'); end
if ~ischar(studyPath), error('studyPath must be a string.'); end
if ~isdir(studyPath)
  error(sprintf('the studyPath directory "%s" does not exist under current directory "%s"',...
    studyPath,pwd));
end
if nargin<3, runs = {}; end
if ~iscellstr(runs), error('runs must be a cell array of strings.'); end
if nargin<4 | isempty(typeSpec), typeSpec='BXH'; end % set BXH as default
if nargin<5, cmdlineTR=[]; end % Read TR from the header.
if ~isempty(cmdlineTR) & (~isnumeric(cmdlineTR) | length(cmdlineTR) > 1 | cmdlineTR <= 0)
  error('TR must be a single positive scalar number or [] to read it from the header!');
end  
if nargin<6, order=[]; end
if nargin<7, outFormat='RawVolumes'; end
if nargin<8, outFilenames='V*.img'; end
if ~ischar(outFilenames) & ~iscellstr(outFilenames)
  error('outFilenames must be a string or cell array of strings!');
end

%____________________________________________________________________________
% Support old-style readmr parameters.
if iscell(typeSpec) & length(typeSpec)==4 & any(strcmpi(typeSpec{4},{'Volume','Float'})) & ...
    isnumeric(typeSpec{1}) & isnumeric(typeSpec{2}) & isnumeric(typeSpec{3})
  typeSpec={typeSpec{4},[typeSpec{1:3}]};
end

%____________________________________________________________________________
% Retrieve all runs folder if runs is not specified.
if isempty(runs)
  % Get all runs in study
  d=dir(fullfile(studyPath,'run*'));
  if isempty(d) | ~any([d.isdir]) % if no runs directory present in the studyPath
    emsg=sprintf('No runs found in study "%s"!',studyPath); error(emsg);
  end
  d(~[d.isdir])=[]; % Remove non-directory matches
  runs={d.name};
  clear d
end

nRuns=length(runs);

% If outFilenames is a string, use it for all runs.
if ischar(outFilenames)
  outFilenames = repmat({outFilenames},[1,nRuns]);
end

% Check the size of outFilenames
if ndims(outFilenames) > 2 | any(size(outFilenames) ~= [1 nRuns])
  error('outFilenames must be a string or a 1 x nRuns cell array of strings!');
end

%____________________________________________________________________________
% Look for .bxh header and Construct runDataSpecs for each run
if (iscell(typeSpec) & strcmpi(typeSpec{1},'BXH')) | (ischar(typeSpec) & strcmpi(typeSpec,'BXH'))
  % Get BXH filenames if the typeSpec is BXH
  runDataSpecs=cell(size(runs));
  for r=1:length(runs)
    currSpec=fullfile(studyPath,runs{r},'*.bxh');
    d=dir(currSpec);
    if isempty(d),
      emsg=sprintf('No BXH files found in %s',currSpec); error(emsg);
    end
    if length(d) > 1
      emsg=sprintf('More than one BXH file found in %s',currSpec); error(emsg);
    end
    [pathstr, name, ext] = fileparts(d.name);
    runDataSpecs{r}=[name ext];
    clear d;
  end
else
  % Otherwise, look for V*.img in each run.
  runDataSpecs=repmat({'V*.img'},size(runs));
end

%____________________________________________________________________________
% Initialize for error catch
p=[]; lasterr(''); emsg='';

%____________________________________________________________________________
% start main loop
try
  p=progbar(sprintf(' Processing 0 of %d runs... ',nRuns),[-1 0.6 -1 -1]);
  for n=1:nRuns
    
    %------------------------------------------------------------------------
    % progress bar messages
    if ~ishandle(p), emsg='User abort'; error(emsg); end
    progbar(p,sprintf('Processing %d of %d runs...',n,nRuns));
    
    %------------------------------------------------------------------------
    % Read current time series
    currInputFile = fullfile(studyPath,runs{n},runDataSpecs{n});
    mrstruct=readmr(currInputFile,typeSpec);

    %------------------------------------------------------------------------
    % Check the data dimensions & order
    if length(mrstruct.info.dimensions) ~= 4
      error(sprintf('Images are not 4D: %s',dataSpec));
    end
    if ~isequal({mrstruct.info.dimensions.type},{'x','y','z','t'})
      error(sprintf('Data is not in x,y,z,t order: %s',dataSpec));
    end
    
    %------------------------------------------------------------------------
    % Grab TR from the header if this is a BXH file.
    TR = cmdlineTR;  % Default to TR specifed on command line
    if strcmpi(mrstruct.info.hdrtype,'bxh')
      [readTR, code] = xpathquery(mrstruct.info.hdr, '/bxh/acquisitiondata/tr');
      if code > 1 % More than one TR in header
        if isempty(cmdlineTR)
          error('More than one TR specifed in header.  Please specify TR manually!')
        else
          warning(sprintf('More than one TR specifed in header.  Using TR from command line (%g)!',cmdlineTR));
        end
      elseif code == 1 % Once TR element found
        if ~isnumeric(readTR) | length(readTR) > 1 | readTR <= 0 % Check that it is valid
          if isempty(cmdlineTR)
            error('Invalid TR specified in header.  Please specify TR manually!')
          else
            warning(sprintf('Invalid TR specified in header.  Using TR from command line (%g)!',cmdlineTR));
          end
        else
          readTR = readTR/1000; % Convert to sec (from msec)
          % Check if it matches what user specified.
          if ~isempty(cmdlineTR) & readTR ~= cmdlineTR
            warning(sprintf(...
              'TR in header (%g) does not match specified TR (%g) in run %s. Using specified TR (%g)'...
              ,readTR,cmdlineTR,runs{n},cmdlineTR));
          else
            % Use value from header.
            TR = readTR;
          end
        end
      end
      clear readTR code
    end
    
    %------------------------------------------------------------------------
    % Check that TR is valid.
    if isempty(TR) | ~isnumeric(TR) | length(TR) > 1 | TR <= 0
      error('Invalid TR!'); 
    end

    %------------------------------------------------------------------------
    % Update the out.info: Start with the original information
    % NOTE: Keep the same pixel type as the input (outelemtype is the same
    %       as the input by default.)
    out.info = mrstruct.info;
    % Make a generic BXH header if the input was not BXH.
    out = convertmrstructtobxh(out);
    
    %------------------------------------------------------------------------    
    % Update the out.info: update the history entry
    numEntries = length(out.info.hdr.bxh{1}.history{1}.entry);
    out.info.hdr.bxh{1}.history{1}.entry{numEntries+1}.date{1}.VALUE = datestr(now,31);
    
    history_outPath = sprintf('outPath = %s',outPath);
    history_studyPath = sprintf('studyPath = %s',studyPath);
    history_runs = sprintf('%s, ',runs{:});
    history_runs = sprintf('runs = %s ',history_runs(1:end-2));
    history_typeSpec = sprintf('typeSpec used = %s',typespec2str(typeSpec));
    history_TR = sprintf('TR = %g sec',TR);
    if isempty(order),
      history_order = 'order = default';
    else
      history_order = ['order = [',sprintf('%d ',order(1:end-1)),sprintf('%d]',order(end))];
    end
    history_outFormat = sprintf('outFormat = %s',typespec2str(outFormat));
    history_outFilenames = sprintf('%s, ',outFilenames{:});
    history_outFilenames = sprintf('outFilenames = %s',history_outFilenames(1:end-2));
    history_currentInputFile = sprintf('Current input filename specifier = %s',currInputFile);
    out.info.hdr.bxh{1}.history{1}.entry{numEntries+1}.description{1}.VALUE = ...
      sprintf('Data processed by splinealignmr (%s%s)\nParameters Used:\n %s \n %s \n %s \n %s \n %s \n %s \n %s \n %s \n %s', ...
      CVSRevision(2:end-1), CVSDate(8:end-2), ...
      history_outPath, history_studyPath, history_runs, ...
      history_typeSpec, history_TR, history_order, ...
      history_outFormat, history_outFilenames, history_currentInputFile);

    %------------------------------------------------------------------------
    % Do the time slice realignment.
    out.data = splinealigntsv(mrstruct.data,TR,order);

    %------------------------------------------------------------------------    
    % write splinealigned result to file(s)
    [status,emsg]=makedir(fullfile(outPath,runs{n})); if ~status, error(emsg); end
    writemr(out,fullfile(outPath,runs{n},outFilenames{n}),outFormat);
    
    %------------------------------------------------------------------------    
    % clear variables to save memory for the next run.
    clear out mrstruct

    %------------------------------------------------------------------------
    % Update progress bar
    if ~ishandle(p), emsg='User abort'; error(emsg); end
    progbar(p,n/nRuns);
    
  end % <end the for loop: for n=1:nRuns>
  delete(p);

catch
  if isempty(emsg)
    if isempty(lasterr)
      emsg='An unidentified error occurred!';
    else
      emsg=lasterr;
    end
  end
  if ishandle(p), delete(p); end
  error(emsg);
end

%____________________________________________________________________________
% Modification History:
%
% $Log: splinealignmr.m,v $
% Revision 1.13  2011/02/15 15:47:35  petty
% *** empty log message ***
%
% Revision 1.12  2005/02/03 16:58:44  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.11  2003/11/06 21:05:45  michelich
% Per Michael Wu's testing, Check cmdlineTR for errors to avoid overwriting
%   invalid cmdlineTR with value from header.  Add more TR error checking.
%
% Revision 1.10  2003/10/30 19:13:44  michelich
% Fixed and enhanced handling of auto TR detection.
%
% Revision 1.9  2003/10/30 17:29:49  michelich
% Added more detail to history entry.
%
% Revision 1.8  2003/10/30 14:52:02  michelich
% Added splinealignmr revision information to history entry.
%
% Revision 1.7  2003/10/24 17:47:59  michelich
% Bug Fix (found by Michael Wu):  Fixed replication of outFilenames.
%
% Revision 1.6  2003/10/22 17:59:23  michelich
% Updated for name change.
%
% Revision 1.5  2003/10/22 17:20:27  michelich
% Move splinealignmrtest to splinealignmr.
%
% Revision 1.13  2003/10/22 17:16:29  michelich
% Always use writemr for writing output.
% Changed default outputType to 'RawVolumes'
% Use input pixel type as default output pixel type.
% Added outFilenames to specify output filenames.
% Make sure that there is at least one directory match when constructing runs.
% Removed unnecessary semicolons after ends.
% Fixed format strings to use %g for TR since it is not always an integer.
% Make a empty BXH header using convertmrstructtobxh (otherwise writing fails!);
% Create out.info before calculations.
% Update progress bar after writing results.
%
% Revision 1.12  2003/10/22 15:54:39  gadde
% Make some CVS info accessible through variables
%
% Revision 1.11  2003/09/26 20:35:57  michelich
% Use default if runs not specified.
%
% Revision 1.10  2003/09/03 20:50:44  michelic
% Fix bug in handling using default order when creating history string.
%
% Revision 1.9  2003/08/21 18:57:39  michelich
% Use different date string format in history entry
%
% Revision 1.8  2003/08/21 17:20:22  michelich
% Use typespec2str for generating history entry.
% Vectorize history_order string generation.
%
% Revision 1.7  2003/08/04 18:14:26  michelich
% Incorporates the following changes from Michael Wu:
% - Changed writemrtest to writemr
%
% Revision 1.6  2003/07/17 17:39:06  michelich
% Incorporates the following changes from Michael:
% - Added comments lines to divide the code.
% - Use case-insensitive check for format.
% - Clear input & output structs after each run to avoid out of memory errors.
%
%
% Revision 1.5  2003/07/09 18:31:02  gadde
% Incorporates changes from Michael, as listed below.
% - fixed syntax error on line 49: a ')' missing in the previous version
% - added a checking to see if the StudyPath does not exist
% - changed line 113 in the previous version: added "| strcmp(mrstruct.info.hdrtype,'BXH')"
%
% Revision 1.4  2003/07/08 18:56:15  michelich
% Comment and example updates.
% Check for valid output format.
%
% Revision 1.3  2003/07/08 18:46:26  michelich
% Changed handling of I/O for SPLINEALIGNTSV to address memory problems.
% Check the data dimensions & order.
% Use outputelemtype to specify precision.
% Set precision for BXH output format.
% Moved try-catch to where it is needed & always use normal error message.
% Require TR if not in BXH header.
% Convert units of TR read from header to sec (from msec)
% Check TR from header against user specified value.
%
% Revision 1.2  2003/07/08 18:10:37  michelich
% Removed unnecessary CRs.
%
% Revision 1.1  2003/07/08 17:57:27  gadde
% Initial import of BXH-reading splinealignmr.
% Modified Michael's code to:
% - read TR from BXH header
% - use input file name for the output BXH file
% - address cases where typeSpec may not be fully populated.
% - UNIX fix, d.name includes whatever path you send to dir()
%   (but not on Windows), so strip the path first.
%
% 2003/06/10 16:40:30   Michael Wu
% Changed params to typeSpec
% Changed readmr to readmrtest
% Added Remove non-directory matches feature
% Added backward compatibility if params is input instead typeSpec
% Added update the mrstruct.info feature for updating elemtype
%   and COMMENTS about the data modification
%
% Revision 1.2  2002/11/15 20:47:40  michelich
% Added optional output format field.
%
% Revision 1.1  2002/08/27 22:24:26  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2002/08/26. Changed example to use findexp instead of getexppath
% Charles Michelich, 2001/01/23. Changed function name to lowercase.
%                                Changed makedir(), readtsv(), readmr(), writetsv() to lowercase
%                                Changed splinealigntsv() and getexppath() to lowercase
% Francis Favorini,  2000/04/25. Fixed comments.
% Francis Favorini,  2000/02/22.   
