function h=toexcel(varargin)
%TOEXCEL Export data variable to new Excel worksheet.
%
%   toexcel(data,row,col,sheet,visible);
%   toexcel('SaveAs',filename);
%   toexcel('Save');
%   toexcel('Cleanup');
%   toexcel('Quit');
%   toexcel('ForceQuit');
%   toexcel('Done');
%   toexcel('ForceDone');
%   h=toexcel('Handle');
%
%   hPrivate=toexcel('Private');
%   toexcel(hPrivate,...);
%
%   data is the data to export to Excel.
%     data can be a numeric, char or cell array.
%     Cells may only be scalars or strings.
%     If data is >2D, it is reshaped into 2D, putting higher
%     dimensions side-by-side to the right.
%     If data is empty, Excel is just brought to the foreground.
%     Default is empty.
%   row is the starting Excel row (default is 1).
%   col is the starting Excel column (default is 1).
%   sheet is the Excel worksheet to use (default is 1).
%     This may be the ordinal position of the worksheet
%     (which is not related to names like Sheet1, etc.),
%     or it may be the worksheet name.
%     If the sheet doesn't exist, a new one will be created.
%     Specifying Inf will always create a new sheet.
%   visible is 1 if Excel should be visible, otherwise 0
%     (default is 1).
%
%   Calling toexcel('SaveAs',filename) will save the current workbook
%     with the specified filename.  If no path is given, the file
%     is written into Excel's default file location.
%
%   Calling toexcel('Save') will save the current workbook.
%     If it hasn't been saved yet, you will be prompted for a filename.
%
%   Calling toexcel('Cleanup') will delete the ActiveX interface,
%     and free up its resources.  It will not quit Excel.  The next
%     call to toexcel will start a new instance of Excel.
%
%   Calling toexcel('Quit') will quit Excel.  It will not delete
%     the ActiveX interface, so subsequent calls to toexcel will
%     reuse it.  If there are unsaved files, you will be asked
%     to save them.
%
%   Calling toexcel('ForceQuit') will quit Excel.  It will not delete
%     the ActiveX interface, so subsequent calls to toexcel will
%     reuse it.  If there are unsaved files, you will NOT be asked
%     to save them.
%
%   Calling toexcel('Done') will quit, then cleanup.
%
%   Calling toexcel('ForceDone') will forcequit, then cleanup.
%
%   Calling h=toexcel('Handle'); will return the handle to the
%     ActiveX interface for the common instance of Excel.
%     If it is empty, there is no current common instance of Excel.
%     The first time toexcel is given a data argument, it will create
%     a new instance of Excel, which will then be used for subsequent
%     calls until that instance's ActiveX interface is deleted.
%   
%   Calling hPrivate=toexcel('Private'); will return a handle to
%     the ActiveX interface for a new private instance of Excel.
%     Passing hPrivate to toexcel as the first argument will then
%     use that private instance of Excel, instead of the common one.
%     This private instance will not initially be visible.
%
%   Notes:
%   When passing data to Excel, if there is no open workbook,
%     a new one is created, otherwise the current workbook is used.
%   Case doesn't matter when calling toexcel('quit'), etc.
%   Trailing arguments with defaults may be omitted.
%
%   Examples:
%   >>toexcel(data,1,1,'MATLAB Data')
%   >>toexcel(data)
%   >>toexcel('saveas','D:\scratch\MyExcelFile.xls')
%   >>h=toexcel('handle');
%   >>toexcel cleanup

% TODO: Handle >2D char matrix input?

% CVS ID and authorship of this code
% CVSId = '$Id: toexcel.m,v 1.7 2005/02/03 16:58:36 michelich Exp $';
% CVSRevision = '$Revision: 1.7 $';
% CVSDate = '$Date: 2005/02/03 16:58:36 $';
% CVSRCSFile = '$RCSfile: toexcel.m,v $';

persistent hXLCommon

% Defaults
badValue='#NUM!';         % Send #NUM! for NaN, Inf, -Inf.
action=''; data=[]; row=1; col=1; sheet=1; visible=1;
actions={'save' 'saveas' 'cleanup' 'quit' 'forcequit' 'done' 'forcedone' 'handle' 'private'};

% Handle args
error(nargchk(0,6,nargin));
if nargin>0 & (isa(varargin{1},'activex') | isa(varargin{1},'COM.excel.application')) | isa(varargin{1},'COM.Excel_Application')
  % If first argument is an Excel COM interface, use it if it is valid
  % Until MATLAB 6.1, the Excel COM interface isa 'activex'
  % In MATLAB 6.5 & 6.5.1, the Excel COM interface isa 'COM.excel.application'
  % In MATLAB 7.0 & 7.0.1, the Excel COM interface isa 'COM.Excel_Application'
  hXL=varargin{1};
  varargin(1)=[];
  if any(size(hXL) ~= [1 1])
    error('toexcel requires a single Microsoft Excel handle!');
  end
  if ~isExcelHandle(hXL)
    error('That is not a valid handle to an instance of Microsoft Excel.');
  end
  common=0;
else
  if ~isempty(hXLCommon) & ~isExcelHandle(hXLCommon)
    warning('Saved handle to Excel has been deleted externally--starting a new instance.');
    hXLCommon=[];
  end
  hXL=hXLCommon;
  common=1;
end
nArgs=length(varargin);
if nArgs>=1
  if ischar(varargin{1}) & size(varargin{1},1)==1 & any(strcmpi(varargin{1},actions))
    action=varargin{1};
  else
    data=varargin{1};
    if ~iscell(data) & ~isnumeric(data) & ~ischar(data)
      error('data must be a numeric, char or cell array.');
    end
  end
end
if isempty(hXL) & ~isempty(action) & ~any(strcmpi(action,{'handle' 'private'}))
  error('Specified instance of Excel does not exist.');
end
if isempty(action)
  if nArgs>=2, row=varargin{2}; end
  if nArgs>=3, col=varargin{3}; end
  if nArgs>=4, sheet=varargin{4}; end
  if nArgs>=5, visible=varargin{5}; end
end

if strcmpi(action,'save')
  % Save current Excel workbook
  hWorkbook=hXL.ActiveWorkbook;
  if isempty(hWorkbook.Path)
    filename=invoke(hXL,'GetSaveAsFilename','','Microsoft Excel Workbook (*.xls), *.xls');
    if ischar(filename)
      invoke(hWorkbook,'SaveAs',filename);
    end
  else
    invoke(hWorkbook,'Save');
  end
  release(hWorkbook);
elseif strcmpi(action,'saveas')
  % Save current Excel workbook
  if nArgs<2, error('You must specify a filename to save as.'); end
  filename=varargin{2};
  hWorkbook=hXL.ActiveWorkbook;
  invoke(hWorkbook,'SaveAs',filename);
  release(hWorkbook);
elseif strcmpi(action,'cleanup')
  % Clean up ActiveX interface
  delete(hXL);
  if common, hXLCommon=[]; end
elseif strcmpi(action,'quit')
  % Quit Excel
  if ~allSaved(hXL), error('There are unsaved workbooks in Excel!'); end
  invoke(hXL,'Quit');
  %warning off, while hXL.Path==-1, end, warning on   % Wait for user to save or cancel, if asked
elseif strcmpi(action,'forcequit')
  % Quit Excel, ignoring any warnings about unsaved files, etc.
  hXL.DisplayAlerts=0;
  invoke(hXL,'Quit');
  hXL.DisplayAlerts=1;
elseif strcmpi(action,'done')
  % Quit Excel and clean up ActiveX interface
  if ~allSaved(hXL), error('There are unsaved workbooks in Excel!'); end
  if common, toexcel('Quit'); else toexcel(hXL,'Quit'); end
  if ~hXL.UserControl                                % If user didn't cancel quitting, clean up
    if common, toexcel('CleanUp'); else toexcel(hXL,'CleanUp'); end
  end
elseif strcmpi(action,'forcedone')
  % Quit Excel without saving and clean up ActiveX interface
  if common, toexcel('ForceQuit'); else toexcel(hXL,'ForceQuit'); end
  if common, toexcel('CleanUp'); else toexcel(hXL,'CleanUp'); end
elseif strcmpi(action,'handle')
  % Return ActiveX object handle to common Excel instance
  h=hXL;
elseif strcmpi(action,'private')
  % Return ActiveX object handle to new private Excel instance
  h=actxserver('Excel.Application');
else
  % Open Excel, if we haven't already
  if common & isempty(hXLCommon)
    hXLCommon=actxserver('Excel.Application');
    hXL=hXLCommon;
  end
  
  % Hide or show our Excel instance
  hXL.ScreenUpdating=visible;
  hXL.visible=visible;
  
  % Create new workbook, if one doesn't exist
  if hXL.Workbooks.Count==0
    hXL.Workbooks.Add;
  end
  
  % Activate or create the specified worksheet and get its cells
  hWorksheets=hXL.Worksheets;
  hSheet=[];
  if isnumeric(sheet)
    % Find worksheet by number
    if sheet<=hWorksheets.Count
      hSheet=get(hWorksheets,'Item',sheet);
    end
  else
    % Find worksheet by name
    for s=1:double(hWorksheets.Count)
      hSheet=get(hWorksheets,'Item',s);
      if strcmpi(sheet,hSheet.name), break; else release(hSheet); hSheet=[]; end
    end
  end
  if isempty(hSheet)
    % Create new worksheet before other sheets
    hFirstSheet=get(hWorksheets,'Item',1);
    hSheet=invoke(hWorksheets,'Add',hFirstSheet);
    if ischar(sheet), hSheet.name=sheet; end
    sheet=hSheet.index;
    release(hFirstSheet);
  end
  hSheet.Activate;
  hCells=hSheet.Cells;
  release(hSheet);
  release(hWorksheets);
  
  if isempty(data)
    % Just select the specified cell (brings Excel to foreground)
    hCell=get(hCells,'Item',row,col);
    hCell.Select;
    release(hCell);
  else
    % Convert char to cellstr, since passing char array to Excel doesn't work right
    if ischar(data)
      data=cellstr(data);
    end
    
    % For >2D data reshape into 2D, putting higher dimensions side-by-side
    data=smush(data);
    szData=size(data);
    
    % Replace NaN, Inf, -Inf with Excel's invalid number value
    if ~iscell(data) & any(~isfinite(data))
      % Must turn into cell array, since badValue is a string
      data=num2cell(data);
    end
    if iscell(data)
      data(cellfun2('isnotfinite',data))={badValue};
      data(cellfun('isempty',data))={''};  % Put in empty strings for empty cells.
    end
    
    % Copy the data to Excel as a block
    hRange=setRange(hCells,row,col,row+szData(1)-1,col+szData(2)-1,data);
    
    % Select the cells and name range
    hRange.Select;
    hRange.Name='MATLABData';
    release(hRange);
  end % if isempty
  release(hCells);
  
  % Return ActiveX object handle to our Excel instance
  if nargout>0
    h=hXL;
  end
end % if strcmpi


% See if all Excel workbooks have been saved

function ret=allSaved(h)
ret=1;
hWorkbooks=get(h,'Workbooks');
if hWorkbooks.Count~=0
  for i=1:double(hWorkbooks.Count)
    hWorkbook=get(hWorkbooks,'Item',i);
    if ~hWorkbook.Saved
      release(hWorkbook);
      release(hWorkbooks);
      ret=0;
      return;
    end
    release(hWorkbook);
  end
end
release(hWorkbooks);


% Set a range of cells bounded by (r1,c1) and (r2,c2) to data
%   data should be the same size as the range
%   sheet can be a worksheet object or a range object
% Returns handle to range if requested.

function hRange=setRange(sheet,r1,c1,r2,c2,data)
hCell1=get(sheet.cells,'Item',r1,c1);
hCell2=get(sheet.cells,'Item',r2,c2);
hRange=get(sheet.cells,'Range',hCell1,hCell2);
set(hRange,'Value',data);
release(hCell1);
release(hCell2);
if nargout==0, release(hRange); end

% Smush ND array into 2D array, putting higher dimensions side-by-side to the right.

function data2D=smush(dataND)
sz=size(dataND);
if length(sz)>2
  data2D=reshape(dataND,sz(1),prod(sz(2:end)));
else
  data2D=dataND;
end

% Test for valid ActiveX handle to Excel

function TF=isExcelHandle(h)
TF=(isa(h,'activex') | isa(h,'COM.excel.application')) | isa(h,'COM.Excel_Application');
% Until MATLAB 6.1, the Excel COM interface isa 'activex'
% In MATLAB 6.5 & 6.5.1, the Excel COM interface isa 'COM.excel.application'
% In MATLAB 7.0 & 7.0.1, the Excel COM interface isa 'COM.Excel_Application'
try
  % Try calling the 'name' Method to see if excel is still alive
  % (and to check if the activex handle is Excel for MATLAB versions < 6.5)
  if TF, TF=strcmp(h.name,'Microsoft Excel'); end
catch
  TF=logical(0);
end

% Modification History:
%
% $Log: toexcel.m,v $
% Revision 1.7  2005/02/03 16:58:36  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.6  2004/10/26 00:59:10  michelich
% Add support for MATLAB 7 COM changes.
%
% Revision 1.5  2004/02/12 21:12:31  michelich
% Replace empty cells in data with empty strings (Prevents segmentation fault)
%
% Revision 1.4  2003/10/22 15:54:36  gadde
% Make some CVS info accessible through variables
%
% Revision 1.3  2002/09/25 22:42:59  michelich
% Handle identification of private excel handle properly for MATLAB 6.1
%
% Revision 1.2  2002/09/25 20:07:50  michelich
% Set 'Value' property instead of 'Cells' property of Excel Range.  'Cells'
%   property is read-only according to Excel documentation.
% Updated for MATLAB 6.5 COM support changes
% Added check for attempting to pass mulitple Excel COM handles
%
% Revision 1.1  2002/08/27 22:24:19  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2001/07/23. MATLAB 6 bug fix: Converted hWorkbooks.Count to a double since it returns type int32
% Charles Michelich, 2001/04/27. MATLAB 6 bug fix: Converted hWorksheets.Count to a double since it returns type int32
% Charles Michelich, 2001/01/23. Changed function name to lowercase.
% Francis Favorini,  2000/05/09. Added local function isExcelHandle.
%                                If hXLCommon becomes invalid, warn user and start a new instance of Excel.
% Francis Favorini,  2000/05/08. Don't allow arrays to be in cells; only scalars and strings.
%                                Massive speed up: set whole range in Excel at one time.
%                                Send #NUM! for NaN, Inf, -Inf.
% Francis Favorini,  1999/12/13. Check for unsaved workbooks when quitting Excel, and return error if there are any.
%                                This is due to a change in MATLAB 5.3 that made it hard to wait for Excel to ask the user.
% Francis Favorini,  1999/10/12. Fixed bug with Done and ForceDone ignoring private handle arg (due to last mod).
% Francis Favorini,  1999/10/07. Added Save, SaveAs, ForceQuit, and ForceDone actions.
%                                For Quit action, wait for user to dismiss save dialog, if any.
%                                For Done action, don't clean up interface if user cancels quitting.
% Francis Favorini,  1998/11/24. Added visible argument.
%                                Set hXL.ScreenUpdating.
%                                Added ability to quit Excel.
%                                If data is empty, just bring Excel to foreground.
%                                Added ability to specify sheet by name.
%                                Added ability to specify private instance of Excel.
% Francis Favorini,  1998/09/30. Handle cell arrays.
%                                Remember handle to Excel instance.
%                                Be smart about creating workbooks and sheets.
%                                Ignore non-numeric/non-string data.
%                                Substitute 'NaN' for NaN (which becomes 65535 in Excel).
%                                Substitute 'Inf' for +/-Inf (which becomes 65535 in Excel).
% Francis Favorini,  1998/09/22.
