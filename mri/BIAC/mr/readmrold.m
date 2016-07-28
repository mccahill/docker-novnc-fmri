function varargout=readmrold(fName,xSz,ySz,zSz,hdrSz,pixelType,byteOrder,allInOne,startExt,inGUI)
%READMROLD Read MR images from fName.  Each of the zSz images is xSz by ySz pixels.
%
%   [srs,name,params]=readmrold(fName,xSz,ySz,zSz,cannedFormat);
%   [srs,name,params]=readmrold(fName,xSz,ySz,zSz,hdrSz,pixelType,byteOrder,allInOne,startExt);
%   [name,params]=readmrold('Params',...);
%   [name,params]=readmrold('Params;<dir>',...);
%   readmrold help
%   [params]=readmrold('help',cannedFormat);
%
%   If the format has a readable header, any values passed in xSz,ySz,zSz 
%     will be confirmed using the information in the header.  You can also 
%     use the following forms to read xSz,ySz,zSz from the header: 
%   [srs,name,params]=readmrold(fName,[],[],[],cannedFormat);
%   [srs,name,params]=readmrold(fName,cannedFormat);            
%
%   fName is the full path and name of the file with the MR data.
%     If fName is empty, a directory, 'Params' or a directory with
%     'Params;' prepended to it, a GUI is displayed to load the series,
%     and any other arguments are defaults for the GUI.
%   xSz is the x-size of the images. (default=64)
%   ySz is the y-size of the images. (default=64)
%   zSz is the number of images. (default=1)
%   cannedFormat is one of 'float','volume','signa5',etc. (default='float')
%   hdrSz is the number of header bytes to skip.
%   pixelType specifies how the pixels are stored in the file:
%     'int16', 'uint16', 'float32', 'uchar', etc.
%     It is passed to FREAD as the precision argument.
%   byteOrder is 'l' for little-endian, 'b' for big-endian,
%     or 'd' for VAX D floating point.
%     It is passed to FOPEN as the MACHINEFORMAT argument.
%   allInOne is 1 if all the images are in one file, else 0.
%     If 0, fName must not include extension.  See next argument.
%   startExt is the numeric file extension to start with.
%     Extension is zero-padded to 3 characters.
%
%   srs is an xSz by ySz by zSz array of the MR data.
%   name is the name of the file which was read.
%   params is a cell array of the parameters used to read the MR data.
%
%   [name,params]=readmrold('Params',...);
%     won't actually read the data, but will return the series 
%     name and a cell array of all the other parameters.
%
%   readmrold help
%     will print out a list of canned formats.
%
%   [params]=readmrold('help',cannedFormat);
%     will return default params for cannedFormat
%
%   Note: Assumes image pixels are stored such that the x coord increases
%     fastest, then y, then z.  Storing the upper left corner first is customary.
%     Returns [] if an error occurs.
%
%   Examples:
%   >>srs=readmrold('\\broca\data\study\mr.avg',64,64,36,'volume');
%   >>srs=readmrold('\\broca\data\study\mr.avg',64,64,36,0,'int16','l',1,1);
%   >>srs=readmrold('\\broca\data\study2\');
%   >>[name,params]=readmrold('Params;\\broca\data\study3');

% CVS ID and authorship of this code
% CVSId = '$Id: readmrold.m,v 1.7 2005/02/03 16:58:42 michelich Exp $';
% CVSRevision = '$Revision: 1.7 $';
% CVSDate = '$Date: 2005/02/03 16:58:42 $';
% CVSRCSFile = '$RCSfile: readmrold.m,v $';

%TODO: Make Enter and Esc the same as clicking OK and Cancel.
%TODO: Make local_fullName an external function?
%TODO: Give user feedback when the calculated file size does not match the actual file size.
%TODO: Detect number of slices for non allInOne file formats.
%TODO: Decide if readmrold('Params') form should return the format name for canned formats that read headers
%TODO: Decide if other parameters from header file should be returned.
%TODO: Implement and integrate an automatic header detection routine.
%TODO: Allow the user to select the header file or the image file.

lasterr('');
emsg='';
if ~exist('inGUI','var'), inGUI = 0; end
try
  
  % Maintain list of recent files/directories across all instances of readmrold
  persistent FileList FileListMaxFiles FileListMaxDirs
  if isempty(FileList), FileList={''}; end
  if isempty(FileListMaxFiles), FileListMaxFiles=5; end
  if isempty(FileListMaxDirs), FileListMaxDirs=5; end
  
  fid=[];
  
  % Define MR formats   
  % Note: Empty xSz|ySz|zSz means don't change size when selecting format
  % Note: hdr=1 will cause the program to attempt to read a header for this file format.
  %       Still need to include default values for MR formats with headers
  %       (for display before header is read or if header cannot be read).
  % Note: extReader=1 indicates that the image file(s) are read using another function (and none of the filled in fields are respected)
  f=1; fmts.name='Float'; fmts(f).xSz=[]; fmts(f).ySz=[]; fmts(f).zSz=[]; fmts.hdrSz=0; fmts.pixelType='float32'; fmts.byteOrder='l'; fmts.allInOne=1; fmts.startExt=1; fmts(f).hdr=0; fmts(f).extReader=0;
  f=f+1; fmts(f).name='Volume'; fmts(f).xSz=[64]; fmts(f).ySz=[64]; fmts(f).zSz=[]; fmts(f).hdrSz=0; fmts(f).pixelType='int16'; fmts(f).byteOrder='l'; fmts(f).allInOne=1; fmts(f).startExt=1; fmts(f).hdr=0; fmts(f).extReader=0;
  f=f+1; fmts(f).name='Signa5'; fmts(f).xSz=[]; fmts(f).ySz=[]; fmts(f).zSz=[]; fmts(f).hdrSz=7904; fmts(f).pixelType='int16'; fmts(f).byteOrder='b'; fmts(f).allInOne=0; fmts(f).startExt=1; fmts(f).hdr=1; fmts(f).extReader=0;
  f=f+1; fmts(f).name='ScreenSave'; fmts(f).xSz=512; fmts(f).ySz=512; fmts(f).zSz=1; fmts(f).hdrSz=7904; fmts(f).pixelType='int16'; fmts(f).byteOrder='b'; fmts(f).allInOne=1; fmts(f).startExt=1; fmts(f).hdr=0; fmts(f).extReader=0;
  f=f+1; fmts(f).name='Analyze7.5_SPM'; fmts(f).xSz=[79]; fmts(f).ySz=[95]; fmts(f).zSz=[68]; fmts(f).hdrSz=0; fmts(f).pixelType='int16'; fmts(f).byteOrder='l'; fmts(f).allInOne=1; fmts(f).startExt=1; fmts(f).hdr=1; fmts(f).extReader=0;
  f=f+1; fmts(f).name='DICOM_Slice'; fmts(f).xSz=[]; fmts(f).ySz=[]; fmts(f).zSz=[]; fmts(f).hdrSz=[]; fmts(f).pixelType=[]; fmts(f).byteOrder=[]; fmts(f).allInOne=[]; fmts(f).startExt=[]; fmts(f).hdr=1; fmts(f).extReader=1;
  f=f+1; fmts(f).name='DICOM_Volume'; fmts(f).xSz=[]; fmts(f).ySz=[]; fmts(f).zSz=[]; fmts(f).hdrSz=[]; fmts(f).pixelType=[]; fmts(f).byteOrder=[]; fmts(f).allInOne=[]; fmts(f).startExt=[]; fmts(f).hdr=1; fmts(f).extReader=1;
  f=f+1; fmts(f).name='DICOM_AVW_VolumeFile'; fmts(f).xSz=[]; fmts(f).ySz=[]; fmts(f).zSz=[]; fmts(f).hdrSz=[]; fmts(f).pixelType=[]; fmts(f).byteOrder=[]; fmts(f).allInOne=[]; fmts(f).startExt=[]; fmts(f).hdr=1; fmts(f).extReader=1;
  % Legacy formats from old MR program
  f=f+1; fmts(f).name='ANMR'; fmts(f).xSz=[]; fmts(f).ySz=[]; fmts(f).zSz=[]; fmts(f).hdrSz=80; fmts(f).pixelType='int16'; fmts(f).byteOrder='b'; fmts(f).allInOne=0; fmts(f).startExt=1; fmts(f).hdr=0; fmts(f).extReader=0;
  f=f+1; fmts(f).name='EP'; fmts(f).xSz=[]; fmts(f).ySz=[]; fmts(f).zSz=[]; fmts(f).hdrSz=0; fmts(f).pixelType='float32'; fmts(f).byteOrder='d'; fmts(f).allInOne=1; fmts(f).startExt=1; fmts(f).hdr=0; fmts(f).extReader=0;
  f=f+1; fmts(f).name='Signa4'; fmts(f).xSz=[]; fmts(f).ySz=[]; fmts(f).zSz=[]; fmts(f).hdrSz=14336; fmts(f).pixelType='int16'; fmts(f).byteOrder='b'; fmts(f).allInOne=0; fmts(f).startExt=1; fmts(f).hdr=0; fmts(f).extReader=0;
  f=f+1; fmts(f).name='CORITechs'; fmts(f).xSz=[]; fmts(f).ySz=[]; fmts(f).zSz=[]; fmts(f).hdrSz=0; fmts(f).pixelType='uint8'; fmts(f).byteOrder='l'; fmts(f).allInOne=0; fmts(f).startExt=0; fmts(f).hdr=0; fmts(f).extReader=0;
  % Custom format (Must be last entry)
  f=f+1; fmts(f).name='Custom'; fmts(f).xSz=[]; fmts(f).ySz=[]; fmts(f).zSz=[]; fmts(f).hdrSz=[]; fmts(f).pixelType=''; fmts(f).byteOrder=''; fmts(f).allInOne=[]; fmts(f).startExt=[]; fmts(f).hdr=[];
  
  % Check args and setup defaults
  if nargin~=9 & nargin~=10, emsg=nargchk(0,6,nargin); error(emsg); end
  if nargout>3, error('Too many output arguments specified.'); end
  if nargin<1, fName=''; end
  if nargin<2, xSz=64; end
  if nargin<3, ySz=64; end
  if nargin<4, zSz=1; end
  
  % Does the user only want the params?
  paramsOnly=0;
  if strcmp(fName,'Params')
    fName='';
    paramsOnly=1;
  elseif strncmp(fName,'Params;',7);
    % Strip off 'Params;'
    fName(1:7)=[];
    paramsOnly=1;
  end
  
  % Set inGUI
  if nargin==6                           % Short arg form with inGUI
    inGUI=pixelType;
  elseif nargin==3                       % Read from header short form with inGUI
    inGUI=ySz;
  elseif nargin<6 | nargin==9            % inGUI not an arg
    inGUI=isempty(fName) | paramsOnly | (nargin==1 & strncmp(fName,'GUI',3));
  else                                   % Otherwise, treat as not in a GUI
    inGUI=0;									
  end
  
  % If this isn't a callback or GUI form, handle the different formats passed
  if ~((strncmp(fName,'GUI',3) & nargin==1) | (strcmpi(fName,'help') & (nargin==1 | nargin==2)));
    
    % Determine format
    if nargin<5 & nargin~=2 & nargin~=3;
      cannedFormat=fmts(1).name;    % Default to first format
    elseif ischar(xSz)
      cannedFormat=xSz;             % Specified canned MR format with params from header
    elseif ~ischar(hdrSz)
      cannedFormat='Custom';        % Specified custom format
    else
      cannedFormat=hdrSz;           % Specified canned MR format
    end  
    f=find(strcmpi(cannedFormat,{fmts.name}));
    if isempty(f), emsg=sprintf('Unknown canned format "%s"!',cannedFormat); error(emsg); end
    
    % Determine parameters
    if strcmp('Custom',fmts(f).name)
      % If the user passed a custom header, use those values
      params={xSz,ySz,zSz,hdrSz,pixelType,byteOrder,allInOne,startExt};
      
    elseif fmts(f).hdr
      % If the format has a header
      if paramsOnly
        % Do NOT attempt to read the header if the user only requested
        % params.  Since the user only specifed default directory in fName,
        % attempting to read the header will fail.  Just get the default
        % values for this format from the fmts array to use as the default
        % GUI values.  Note that there is no need to specify params here
        % since this is constructed by the GUI in the paramOnly mode.
        hdrSz=fmts(f).hdrSz; pixelType=fmts(f).pixelType; byteOrder=fmts(f).byteOrder;
        allInOne=fmts(f).allInOne; startExt=fmts(f).startExt;
      else
        % Attempt to read the header
        [hdrParams emsg]=readmrhdr(fName,fmts(f).name);
        
        % If the header was not read sucessfully, display the error
        if isempty(hdrParams), error(emsg); end
        
        % If the person passed sizes, confirm that they match the header
        if ~(ischar(xSz) | all(isempty([xSz, ySz, zSz])))
          % If they don't match, issue an error
          if any([xSz,ySz,zSz]~=hdrParams.matSz)
            emsg = sprintf('Image dimensions passed to readmrold do not match information in header for %s',fName);
            error(emsg);
          end
        end
        
        % If the header was read sucessfully, set the values
        xSz=hdrParams.matSz(1);
        ySz=hdrParams.matSz(2);
        zSz=hdrParams.matSz(3);
        if fmts(f).extReader
          % Only xSz,ySz,zSz are relevant for fields with an external reader
          params={xSz,ySz,zSz,fmts(f).name};
          % Initialize to dummy values
          hdrSz=[];
          pixelType=[];
          byteOrder=[];
          allInOne=[];
          startExt=[];
        else
          % These fields are not used when there is an external reader
          hdrSz=hdrParams.hdrSz;
          pixelType=hdrParams.pixelType;
          byteOrder=hdrParams.byteOrder;
          allInOne=hdrParams.allInOne;
          startExt=fmts(f).startExt;
          % Also include the hdrSz, pixelType, etc. in the params cell array so that these
          % variables read from the header are returned in the readmrold('Params') form
          params={xSz,ySz,zSz,hdrSz,pixelType,byteOrder,allInOne,startExt};
        end
      end
    else
      % It is a canned format without a header, read the information from fmts
      hdrSz=fmts(f).hdrSz; pixelType=fmts(f).pixelType; byteOrder=fmts(f).byteOrder;
      allInOne=fmts(f).allInOne; startExt=fmts(f).startExt;
      params={xSz,ySz,zSz,fmts(f).name};
    end
  end
  
  if isempty(fName) | exist(fName,'dir') | paramsOnly
    % If no args or fName is empty or a directory or we only want params, initialize GUI
    if nargin<4, zSz=[]; end
    fig=local_initializegui;
    
    % Initialize popupmenus for FileList and FileType
    set(findobj(fig,'Tag','FileList'),'String',FileList);
    set(findobj(fig,'Tag','FileType'),'String',{fmts.name});
    
    % Verify and remember default path
    if exist(fName,'dir')
      defPath=fName;
    else
      defPath=cd;
    end
    set(findobj(fig,'Tag','FileName'),'UserData',defPath);
    
    % Update GUI fields
    local_updateFields(fmts(f).name,xSz,ySz,zSz,pixelType,hdrSz,byteOrder,allInOne,startExt);

    % Wait for user to hit OK or Cancel
    uiwait(fig);
    if ~ishandle(fig)
      % User closed window
      if nargout==1, varargout={[]}; end
      if nargout==2, varargout={[] ''}; end
      if nargout==3, varargout={[] '' {}}; end
      return;
    elseif get(fig,'UserData')==0
      % User hit Cancel
      delete(fig);
      if nargout==1, varargout={[]}; end
      if nargout==2, varargout={[] ''}; end
      if nargout==3, varargout={[] '' {}}; end
      return;
    else
      % User hit OK
      f=get(findobj(fig,'Tag','FileType'),'Value');
      fName=get(findobj(fig,'Tag','FileName'),'String');
      FileList=local_updateFileList(fName,FileList,FileListMaxFiles,FileListMaxDirs);
      xSz=str2num(get(findobj(fig,'Tag','XSize'),'String'));
      ySz=str2num(get(findobj(fig,'Tag','YSize'),'String'));
      zSz=str2num(get(findobj(fig,'Tag','ZSize'),'String'));
      if fmts(f).extReader
        % Only xSz,ySz,zSz are relevant for fields with an external reader
        % Initialize to dummy values
        hdrSz=[];
        pixelType=[];
        byteOrder=[];
        allInOne=[];
        startExt=[];
      else
        % Only xSz,ySz,zSz are relevant for fields with an external reader
        hdrSz=str2num(get(findobj(fig,'Tag','HdrSize'),'String'));
        pixelType=get(findobj(fig,'Tag','PixelType'),'String');
        pixelType=lower(char(pixelType(get(findobj(fig,'Tag','PixelType'),'Value'))));
        byteOrder=get(findobj(fig,'Tag','ByteOrder'),'String');
        byteOrder=char(byteOrder(get(findobj(fig,'Tag','ByteOrder'),'Value')));
        byteOrder=lower(byteOrder(1));
        allInOne=get(findobj(fig,'Tag','AllInOne'),'Value');
        startExt=str2num(get(findobj(fig,'Tag','StartExt'),'String'));
      end
      set(fig,'Pointer','watch');
      drawnow;
      delete(fig);
    end
    % Include the full format specfication for Custom and header read canned formats
    %    (but not for formats with an external reader)
    if (~strcmp(fmts(f).name,'Custom') & ~fmts(f).hdr) | (fmts(f).extReader)
      params={xSz,ySz,zSz,fmts(f).name};
    else
      params={xSz,ySz,zSz,hdrSz,pixelType,byteOrder,allInOne,startExt};
    end
    if paramsOnly
      varargout={fName params};
      return;
    end
    % Fall through to actually get data
  elseif nargin==1 & strcmp(fName,'GUIFileName')
    % User entered file name (also called indirectly when user selects file name via Browse or FileList)
    hFileName=findobj(gcf,'Tag','FileName');
    fName=get(hFileName,'String');
    set(hFileName,'TooltipString',fName);                    % Update Tooltip
    
    % Check to see if the user has a file type with a header selected
    fTypeVal=get(findobj(gcf,'Tag','FileType'),'Value');     % Get current file type
    if fmts(fTypeVal).hdr
      % If the format has a readable header, read parameters from header
      [hdrParams,msg]=readmrhdr(fName,fmts(fTypeVal).name);
      
      % Update visual feedback to user with results
      local_headerReadFeedback(~isempty(hdrParams),msg);
    else
      % If a header read was not attempted, update visual feedback to user
      hdrParams=[];
      local_headerReadFeedback(2);
    end
    
    % If the header was successfully read, update the fields in the GUI
    if ~isempty(hdrParams)
      % Update fields in GUI
      local_updateFields(hdrParams.format,hdrParams.matSz(1),hdrParams.matSz(2),hdrParams.matSz(3), ...
        hdrParams.pixelType,hdrParams.hdrSz,hdrParams.byteOrder, hdrParams.allInOne, []);
    else
      % Otherwise, just try to calculate the zSize
      local_calcZSize;
    end
    return;
  elseif nargin==1 & strcmp(fName,'GUIFileList')
    % User selected file or directory from FileList
    fName=cindex(get(gcbo,'String'),get(gcbo,'Value'));
    if ~isempty(fName)
      set(findobj(gcf,'Tag','FileName'),'String',fName);
      readmrold('GUIFileName');    % Load header, update fields
    end
    return;
  elseif nargin==1 & strcmp(fName,'GUIBrowse')
    % User hit Browse button
    % If there is a file/directory name in the text box, use it as a base for browsing
    fileName=get(findobj(gcf,'Tag','FileName'),'String');
    if exist(fileName,'dir')
      fPath=fileName;
    else
      fPath=fileparts(fileName);
    end
    % If we don't find a real path, use the default path
    if isempty(fPath)
      fPath=get(findobj(gcf,'Tag','FileName'),'UserData');
    end
    [fName,pathname]=uigetfile(fullfile(fPath,'*.*'),'Select MR Data File');
    
    % If we get a file name, attempt to read it
    if fName~=0
      fName=fullfile(pathname,fName);
      set(findobj(gcf,'Tag','FileName'),'String',fName);
      readmrold('GUIFileName');    % Load header, update fields
    end
    return;
  elseif nargin==1 & strcmp(fName,'GUIFileType')
    % User changed File Type
    
    % Get new FileType
    fType=get(findobj(gcf,'Tag','FileType'),'String');
    fTypeVal=get(findobj(gcf,'Tag','FileType'),'Value');
    fType=fType(fTypeVal);
    fName=get(findobj(gcf,'Tag','FileName'),'String');
    
    % Check to see if the user has a file type with a header and already selected a file 
    if fmts(fTypeVal).hdr & ~isempty(fName)
      % Attempt to read parameters from the header
      [hdrParams,msg]=readmrhdr(fName,fmts(fTypeVal).name);
      
      % Update visual feedback to user with results
      local_headerReadFeedback(~isempty(hdrParams),msg);
    else
      % If a header read was not attempted, update visual feedback to user
      hdrParams=[];
      local_headerReadFeedback(2);
    end
    
    % Update the GUI
    if ~isempty(hdrParams) 
      % If the header was successfully read, update the fields in the GUI
      local_updateFields(hdrParams.format,hdrParams.matSz(1),hdrParams.matSz(2),hdrParams.matSz(3), ...
        hdrParams.pixelType,hdrParams.hdrSz,hdrParams.byteOrder, hdrParams.allInOne, []);
    else
      % If the header was not successfuly read, set the fields in the GUI accorging to fmts.
      local_updateFields([],fmts(fTypeVal).xSz,fmts(fTypeVal).ySz,fmts(fTypeVal).zSz, ...
        fmts(fTypeVal).pixelType,fmts(fTypeVal).hdrSz, fmts(fTypeVal).byteOrder, ...
        fmts(fTypeVal).allInOne,fmts(fTypeVal).startExt);
      % Try to calculate the zSize
      local_calcZSize;
    end
    
    % If the file is read by an external reader, disable & hide all of the user entered fields
    if fmts(fTypeVal).extReader
      set(findobj(gcf,'Tag','XSize'),'Enable','off');
      set(findobj(gcf,'Tag','YSize'),'Enable','off');
      set(findobj(gcf,'Tag','ZSize'),'Enable','off');
      set(findobj(gcf,'Tag','HdrSize'),'Enable','off','Visible','off');
      set(findobj(gcf,'Tag','StartExt'),'Enable','off','Visible','off');
      set(findobj(gcf,'Tag','ByteOrder'),'Enable','off','Visible','off');
      set(findobj(gcf,'Tag','PixelType'),'Enable','off','Visible','off');
      set(findobj(gcf,'Tag','AllInOne'),'Enable','off','Visible','off');    
      % These are the labels for the user entered fields
      set(findobj(gcf,'Tag','StaticText1'),'Visible','off');    
      set(findobj(gcf,'Tag','StaticText2'),'Visible','off');    
      set(findobj(gcf,'Tag','StaticText6'),'Visible','off');    
      set(findobj(gcf,'Tag','StaticText7'),'Visible','off');    
    else
      % Otherwise enable all of the fields
      set(findobj(gcf,'Tag','XSize'),'Enable','on');
      set(findobj(gcf,'Tag','YSize'),'Enable','on');
      set(findobj(gcf,'Tag','ZSize'),'Enable','on');
      set(findobj(gcf,'Tag','HdrSize'),'Enable','on','Visible','on');
      set(findobj(gcf,'Tag','StartExt'),'Enable','on','Visible','on');
      set(findobj(gcf,'Tag','ByteOrder'),'Enable','on','Visible','on');
      set(findobj(gcf,'Tag','PixelType'),'Enable','on','Visible','on');
      set(findobj(gcf,'Tag','AllInOne'),'Enable','on','Visible','on');    
      % These are the labels for the user entered fields
      set(findobj(gcf,'Tag','StaticText1'),'Visible','on');    
      set(findobj(gcf,'Tag','StaticText2'),'Visible','on');    
      set(findobj(gcf,'Tag','StaticText6'),'Visible','on');    
      set(findobj(gcf,'Tag','StaticText7'),'Visible','on');    
    end
    
    return;
  elseif nargin==1 & strcmp(fName,'GUIXSize')
    % User changed XSize.  If YSize is unmodified, copy from XSize.
    h=findobj(gcf,'Tag','YSize');
    if isempty(get(h,'UserData'))
      set(h,'String',get(findobj(gcf,'Tag','XSize'),'String'),'UserData',1);
    end
    % Attempt to calculate and update the Z size
    local_calcZSize;
    return;
  elseif nargin==1 & strcmp(fName,'GUIYSize')
    % User changed YSize. Attempt to calculate ZSize
    local_calcZSize;
    return;
  elseif nargin==1 & strcmp(fName,'GUIZSize')
    % User changed ZSize
    hZSize=findobj(gcf,'Tag','ZSize');
    if ~isempty(get(hZSize,'String'))
      % User entered ZSize, so prevent local_calcZSize from trying to update it anymore.
      set(hZSize,'UserData',1);
    else
      % User cleared ZSize, so allow local_calcZSize to update it.
      set(hZSize,'UserData',[]);
      local_calcZSize;
    end
    return;
  elseif nargin==1 & strcmp(fName,'GUIParam')
    % User changed one of the parameters
    customVal=find(strcmpi('Custom',{fmts.name}));      
    set(findobj(gcf,'Tag','FileType'),'Value',customVal);	% File type->Custom
    local_calcZSize	% Try to calculate zSize
    local_headerReadFeedback(2)	% Reset read header feedback indicators (No header for 'Custom')
    return;
  elseif nargin==1 & strcmp(fName,'GUICancel')
    % User hit Cancel button
    set(gcf,'UserData',0);
    uiresume;
    return;
  elseif nargin==1 & strcmp(fName,'GUIOK')
    % User hit OK button
    % Validate parameters
    hFileName=findobj(gcf,'Tag','FileName');
    fName=get(hFileName,'String');
    defPath=get(hFileName,'UserData');
    xSz=str2num(get(findobj(gcf,'Tag','XSize'),'String'));
    ySz=str2num(get(findobj(gcf,'Tag','YSize'),'String'));
    zSz=str2num(get(findobj(gcf,'Tag','ZSize'),'String'));
    
    if isempty(fName), errorbox('Please specify a file name.'); return; end
    if fName(1)~='='
      fName=local_fullName(fName,defPath);
      % Update file name text box, since that's where fName is finally read from
      set(hFileName,'String',fName);
      if exist(fName,'file')~=2, errorbox(sprintf('The file "%s" does not exist!',fName)); return; end
      if ~all(size(xSz)==1) | ~isint(xSz) | xSz<1, errorbox('Please specify a positive integer for X.'); return; end
      if ~all(size(ySz)==1) | ~isint(ySz) | ySz<1, errorbox('Please specify a positive integer for Y.'); return; end
      if ~all(size(zSz)==1) | ~isint(zSz) | zSz<1, errorbox('Please specify a positive integer for Z.'); return; end
      if ~fmts(f).extReader
        % Only xSz,ySz,zSz are relevant for fields with an external reader (so don't check hdrSz & startExt for these formats)
        hdrSz=str2num(get(findobj(gcf,'Tag','HdrSize'),'String'));
        if ~all(size(hdrSz)==1) | ~isint(hdrSz) | hdrSz<0
          errorbox('Please specify a non-negative integer for header size.'); return;
        end
        startExt=str2num(get(findobj(gcf,'Tag','StartExt'),'String'));
        if ~all(size(startExt)==1) | ~isint(startExt) | startExt<0
          errorbox('Please specify a non-negative for extension start.'); return;
        end
      end
    end
    set(gcf,'UserData',1);
    uiresume;
    return;
  elseif (nargin==1 | nargin==2) & strcmpi(fName,'help')
    % If first arg is help, show or return format(s)
    if nargin==1
      cannedFormat='*';
    else
      cannedFormat=xSz;
    end
    if nargout==1
      if cannedFormat=='*'
        varargout={fmts(1:end-1)};
      else
        f=find(strcmpi(cannedFormat,{fmts.name}));
        varargout={fmts(f)};
      end
    else
      disp('MR formats recognized by readmrold');
      for f=1:length(fmts)-1
        if fmts(f).extReader
          disp(sprintf('%20s: Information read from header.',fmts(f).name));
        else  
          if fmts(f).allInOne, inOne='Y'; else inOne='N'; end
          switch fmts(f).byteOrder
          case 'b', byteOrd='Big';
          case 'l', byteOrd='Little';
          case 'd', byteOrd='Vax D';
          end
          if cannedFormat=='*' | strcmpi(cannedFormat,fmts(f).name)
            disp(sprintf('%20s: Header: %5d, Pixel: %7s, Byte Order: %6s, AllInOne: %s, Extension: %03d',...
              fmts(f).name,fmts(f).hdrSz,fmts(f).pixelType,byteOrd,inOne,fmts(f).startExt));
          end
        end
      end
    end
    return;
  end
  
  if fName(1)=='='
    % If fName starts with '=' the rest names a variable in the base workspace that holds the data
    srs=evalin('base',fName(2:end));
    if nargout==1, varargout={srs}; end
    if nargout==2, varargout={srs fName}; end
    if nargout==3, varargout={srs fName params}; end
    return;
  end
  
  % Check all of the parameters passed
  if exist(fName,'file')~=2, emsg=sprintf('The file "%s" does not exist!',fName); error(emsg); end
  if ~all(size(xSz)==1) | ~isint(xSz) | xSz<1, emsg='xSz must be a positive integer.'; error(emsg); end
  if ~all(size(ySz)==1) | ~isint(ySz) | ySz<1, emsg='ySz must be a positive integer.'; error(emsg); end
  if ~all(size(zSz)==1) | ~isint(zSz) | zSz<1, emsg='zSz must be a positive integer.'; error(emsg); end
  if ~fmts(f).extReader
    % Only xSz,ySz,zSz are relevant for fields with an external reader
    if ~all(size(hdrSz)==1) | ~isint(hdrSz) | hdrSz<0, emsg='Header size must be a non-negative integer.'; error(emsg); end
    % pixelType and byteOrder error checking will be handled by fread and fopen
    if ~all(size(allInOne)==1) | ~isnumeric(allInOne), emsg='allInOne must be a single number'; error(emsg); end 
    if ~all(size(startExt)==1) | ~isint(startExt) | startExt<0
      emsg='Extension start must be a non-negative integer'; error(emsg);
    end
  end
  
  % Handle each format
  %
  % Note on how formats are handled:
  %   Formats which are handled specially use or enforce (i.e. Issue errors if data does not match specified parameters)
  %      the following parameters: xSz,ySz,zSz.
  %      The parameters: hdrSz, pixelType, byteOrder, allInOne, startExt are ignored 
  %                      (should be set to [] by the time this code is reached)
  %      Returned params must be = {xSz,ySz,zSz,formatName}
  %   Other formats use all the parameters (i.e. xSz,ySz,zSz,hdrSz, pixelType, byteOrder, allInOne, startExt)
  %      when reading the data.
  %
  if strcmp(fmts(f).name,'DICOM_Slice')
    % Single slice DICOM format
    %  ONLY supports, 2D, single-frame, grayscale images, which are entirely opaque and contain no overlays.
    %   (These conditions are checked for after read).

    % Enforce that the image is only a single slice
    if zSz ~= 1
      emsg=sprintf('readmrold() currently only support single slice DICOM files.  See DICOM_Volume format!');
      error(emsg);
    end
    
    % Read the DICOM image (Checking for the above conditions)
    srs=dicomread_slicewithcheck(fName);
        
    % Check to make sure that the correct amount of data was read
    if any(size(srs)~=[xSz ySz])
      emsg='Data does not match parameters specified!'; error(emsg);
    end
    
    % Fill output parameters array
    params = {size(srs,1),size(srs,2),size(srs,3),'DICOM_Slice'};
    
  elseif strcmp(fmts(f).name,'DICOM_Volume');
    % Read in a volume of DICOM slices where each slice is in a separate file.
    %  - Each slice must be of the single slice DICOM format with the conditions listed in local_readdicomslice()
    %  - The file names to be read are generated as follows:
    %        - Use name2spec to get a wildcard.
    %        - Get the list of files that match the wildcard
    %        - Sort the directory listing and read in that order.
        
    % Preallocate arrays
    rawSlice=zeros(xSz,ySz);
    srs=zeros(xSz,ySz,zSz);
    
    % Get the series specifier from the name
    srsSpec=name2spec(fName);
    
    % Find the number of slices
    currPath=fileparts(srsSpec);
    d=dir(srsSpec);
    fNames=sort({d.name}');
    if isempty(fNames) | isequal(fNames,{''})
      emsg=sprintf('No files found matching %s!',srsSpec); error(emsg);
    end
    if zSz ~= length(fNames)
      emsg = sprintf('# of slices requested (%d) does not match # of files available (%d)!',zSz,length(fNames)); error(emsg); 
    end
    
    % Loop through each file
    for z=1:zSz
      
      % Construct the filename
      fName = fullfile(currPath,fNames{z});
      
      % Read the DICOM image (Checking for the above conditions)
      rawSlice=dicomread_slicewithcheck(fName);
      
      % Check to make sure that the correct amount of data was read
      if any(size(rawSlice)~=[xSz ySz])
        emsg='Data does not match parameters specified!'; error(emsg);
      end
      
      % Place the slice in the output array
      srs(:,:,z)=rawSlice;
    end % Slice loop
    params = {size(srs,1),size(srs,2),size(srs,3),'DICOM_Volume'};
    
  elseif strcmp(fmts(f).name,'DICOM_AVW_VolumeFile')
    % Read the Analyze AVW_VolumeFile
    srs = dicomread_analyzevolumefile(fName);
    
    % Check that the sizes requestd match the sizes returned.
    if any(size(srs)~=[xSz ySz zSz])
      emsg='Data does not match parameters specified!'; error(emsg);
    end
    params = {size(srs,1),size(srs,2),size(srs,3),'DICOM_AVW_VolumeFile'};
  else
    % For all other formats, use the user specified values
    
    % OK, now actually read the data
    if allInOne
      % Data all in one file
      
      % Check if the file exists
      if exist(fName,'file')~=2, emsg=sprintf('The file "%s" does not exist!',fName); error(emsg); end
      
      % Open the file for reading and check that the file opened properly
      [fid emsg]=fopen(fName,'r',byteOrder);
      if fid==-1, error(emsg); end
      
      % Skip to the data and check to see that the end of the file was not reached
      status=fseek(fid,hdrSz,'bof');
      if status==-1, emsg='Incorrect header size!'; error(emsg); end
      
      % Read all slices
      [srs,count]=fread(fid,xSz.*ySz.*zSz,pixelType);
      
      % Check to make sure that the correct amount of data was read
      if count~=xSz.*ySz.*zSz, emsg='Data does not match parameters specified!'; error(emsg); end
      
      % Check to see if the entire file was read
      [junk,count]=fread(fid,Inf,pixelType);
      if count > 0,
        emsg=sprintf('More data remaining in file %s!  Check parameters!',fName); error(emsg);
      end
      
      % Reshape the data into its proper size
      srs=reshape(srs,[xSz,ySz,zSz]);
      
      % Close the file
      fclose(fid);
      fid=[];
    else
      % Data in multiple files.  Read each slice separately
      
      % Preallocate arrays
      rawSlice=zeros(xSz,ySz);
      srs=zeros(xSz,ySz,zSz);
      
      % Loop through each file
      for z=1:zSz
        
        % Construct filename
        [pth,nm,ext]=fileparts(fName);                 % Strip extension
        fName=sprintf('%s.%03d',fullfile(pth,nm),z-1+startExt);
        
        % Check if the file exists
        if exist(fName,'file')~=2, emsg=sprintf('The file "%s" does not exist!',fName); error(emsg); end
        
        % Open the file for reading and check that the file opened properly
        [fid emsg]=fopen(fName,'r',byteOrder);
        if fid==-1, error(emsg); end
        
        % Skip to the data and check to see that the end of the file was not reached
        status=fseek(fid,hdrSz,'bof');
        if status==-1, emsg='Incorrect header size!'; error(emsg); end
        
        % Read one slice
        rawSlice=fread(fid,[xSz ySz],pixelType);
        
        % Check to make sure that the correct amount of data was read
        if any(size(rawSlice)~=[xSz ySz])
          emsg='Data does not match parameters specified!'; error(emsg);
        end
        
        % Check to see if the entire file was read
        [junk,count]=fread(fid,Inf,pixelType);
        if count > 0,
          msg=sprintf('More data remaining in file %s!  Check parameters!',fName); warning(msg);
        end
        
        % Place the slice in the output array
        srs(:,:,z)=rawSlice;
        
        % Close the file
        fclose(fid);
        fid=[];
      end % Slice loop
    end % Read if statement
  end % End format if statement
  % Return the output args
  if nargout==1, varargout={srs}; end
  if nargout==2, varargout={srs fName}; end
  if nargout==3, varargout={srs fName params}; end
  
catch
  if nargout==1, varargout={[]}; end
  if nargout==2, varargout={[] ''}; end
  if nargout==3, varargout={[] '' {}}; end
  if isempty(emsg)
    if isempty(lasterr)
      emsg='An unidentified error occurred!';
    else
      emsg=lasterr;
    end
  end
  if ~isempty(fid) & fid>2, fclose(fid); end
  if inGUI
    disp(['GUI Error: "' emsg '"']);
    errorbox(emsg);
  else
    error(emsg);
  end
end

%----------------------------------------------------------------------------------
% ------------ Local function to update the fields in the GUI --------------------
%----------------------------------------------------------------------------------
function local_updateFields(fileType,xSz,ySz,zSz,pixelType,hdrSz,byteOrder,allInOne,startExt)
%
% LOCAL_UPDATEFIELDS(fileType,xSz,ySz,zSz,pixelType,hdrSz,byteOrder,allInOne,startExt)
%
% Update any of the listed fields in the GUI
% Pass an empty array to leave a field unchanged
%

% Charles Michelich	2000/03/26	original (adapted from GUIFileType callback)

% Check input arguments
emsg=nargchk(9,9,nargin); error(emsg)

% Update Checkbox
if ~isempty(allInOne), set(findobj(gcf,'Tag','AllInOne'),'Value',allInOne); end

% Update Numeric fields
if ~isempty(xSz), set(findobj(gcf,'Tag','XSize'),'String',num2str(xSz)); end
if ~isempty(ySz), set(findobj(gcf,'Tag','YSize'),'String',num2str(ySz)); end
if ~isempty(zSz), set(findobj(gcf,'Tag','ZSize'),'String',num2str(zSz)); end
if ~isempty(hdrSz), set(findobj(gcf,'Tag','HdrSize'),'String',num2str(hdrSz)); end
if ~isempty(startExt), set(findobj(gcf,'Tag','StartExt'),'String',num2str(startExt)); end

% Update popupmenus
if ~isempty(fileType)
  v=find(strcmpi(fileType,get(findobj(gcf,'Tag','FileType'),'String')));
  if length(v)~=1, emsg='Invalid file type choices.'; error(emsg); end
  set(findobj(gcf,'Tag','FileType'),'Value',v);
end
if ~isempty(pixelType)
  v=find(strcmpi(pixelType,get(findobj(gcf,'Tag','PixelType'),'String')));
  if length(v)~=1, emsg='Invalid pixel type choices.'; error(emsg); end
  set(findobj(gcf,'Tag','PixelType'),'Value',v);
end
if ~isempty(byteOrder)
  v=find(strncmpi(byteOrder,get(findobj(gcf,'Tag','ByteOrder'),'String'),1));
  if length(v)~=1, emsg='Invalid byte order choices.'; error(emsg); end
  set(findobj(gcf,'Tag','ByteOrder'),'Value',v);
end   

%----------------------------------------------------------------------------------
% ------------ Local function to give the user feedback on the header read -------
%----------------------------------------------------------------------------------
function local_headerReadFeedback(result,msg)
%
% LOCAL_HEADERREADFEEDBACK(RESULT,MSG) - Provide feedback to the user about the
%                                    success of failure of the header read.
%
%              result  => 0 failed attempt to read header
%                      => 1 read header successfully
%                      => 2 no header read
%              msg => Optional string is added as a new line under the standard messgage
%
% The background of the 'OK' button changes to gray when when no header was read,
% to green when a header was read successfully, and to yellow when a header read
% failed.  The tooltip strings are updated to appropriate explanations.

% Charles Michelich	2000/03/26	original

% Check input arguments
emsg=nargchk(1,2,nargin); error(emsg)
if ~any(result==[0 1 2])
  emsg('results variable must be 0,1,or 2'); error(emsg)
end
% If there is a message to be added, add a new line and put it in parenthesis
if nargin<2 | isempty(msg)
  msg='';
else
  msg=sprintf('\n(%s)',msg);
end

% Define colors
normalCol=[0.752941176470588 0.752941176470588 0.752941176470588];
successCol=[0 1 0];
failureCol=[1 1 0];

% Get current color
h=findobj(gcf,'Tag','OKButton');
currCol=get(h,'BackgroundColor');

% Update color & tooltip strings
if result==2
  % Set background to normal color (if it isn't already)
  set(h,'BackgroundColor',normalCol);
  set(h,'TooltipString',sprintf('Note: No header for this format%s',msg));
elseif result==1
  % Set background to success color (if it isn't already)
  set(h,'BackgroundColor',successCol);
  set(h,'TooltipString',sprintf('Header read successfully%s',msg));
elseif result==0
  % Set background to failed attempt to read header color (if it isn't already)   
  set(h,'BackgroundColor',failureCol);
  set(h,'TooltipString',sprintf('Caution: Header was not read successfully!%s',msg));
end

%----------------------------------------------------------------------------------
% ------------ Local function calculate and update the number of slices ----------
%----------------------------------------------------------------------------------
function local_calcZSize
%
% LOCAL_CALCZSIZE - If the filename is present, zSz has not been modified by
%                   the user, and the file format is all in one, calculate the
%                   zSize from the format, xSize, and ySize and update the field
%                   in the GUI
%
%                   If the above conditions aren't true, the filename is invalid
%                   or zSize if not a positive integer, then the function
%                   doesn't change any fields and returns
%
%                   NOTE: The ZSize edit box UserData is set to 1 when the user
%                         types in a new value (See: readmrold('GUIZSize'))

% Charles Michelich	2000/03/26	original

% Check input arguments
emsg=nargchk(0,0,nargin); error(emsg)

% Check if the filename is present, zSz is empty, and the file format is all in one
fName=get(findobj(gcf,'Tag','FileName'),'String');
if ~isempty(fName) & isempty(get(findobj(gcf,'Tag','ZSize'),'UserData')) ...
    & get(findobj(gcf,'Tag','AllInOne'),'Value')
  
  % Get the current parameters
  xSz=str2num(get(findobj(gcf,'Tag','XSize'),'String'));
  ySz=str2num(get(findobj(gcf,'Tag','YSize'),'String'));
  hdrSz=str2num(get(findobj(gcf,'Tag','HdrSize'),'String'));
  pixelType=get(findobj(gcf,'Tag','PixelType'),'String');
  pixelType=pixelType(get(findobj(gcf,'Tag','PixelType'),'Value'));
  
  % Calculate pixel size in bytes
  if any(strcmpi(pixelType,{'uint8','int8'}))                  % If 8 bits
    pixelSz=1;
  elseif any(strcmpi(pixelType,{'int16','uint16'}))            % If 16 bits
    pixelSz=2;
  elseif any(strcmpi(pixelType,{'int32','uint32','float32'}))  % If 32 bits
    pixelSz=4;
  elseif any(strcmpi(pixelType,{'float64'}))                   % If 64 bits
    pixelSz=8;
  else % If not listed, ask user to tell programers to add support for the type and return
    warning(sprintf('Please ask programmers to add support to readmrold(''GUICalcZSize'') for %s!',pixelType));
    return;
  end
  
  % Find size of file
  d=dir(fName);
  
  % If the filename isn't valid or specifies more than one file, do nothing & return 
  if (length(d)~=1), return; end
  
  % Calculate zSz
  zSz=(d.bytes - hdrSz)./(xSz.*ySz.*pixelSz); 
  
  % Update zSz field
  if isint(zSz) & zSz > 0
    % If zSz is a positive integer, put it in the zSize field
    set(findobj(gcf,'Tag','ZSize'),'String',num2str(zSz));
  else
    % Otherwise, zSz is not valid so set it to empty
    set(findobj(gcf,'Tag','ZSize'),'String','');
  end
end

%----------------------------------------------------------------------------------
% -------- Local function to update recently opened file and directory list ------
%----------------------------------------------------------------------------------
function newFileList=local_updateFileList(fileName,fileList,maxFiles,maxDirs)

% Francis Favorini,	04/14/00.

% Note: an empty string separates the files from the directories in the list
% If list is full, delete oldest entries

[fPath,fName,fExt]=fileparts(fileName);
fName=[fName fExt];
sep=find(strcmp('',fileList));
dList=fileList(sep+1:end);
fList=fileList(1:sep-1);
if ~isempty(fName)
  fName=fullfile(fPath,fName);
  if ~any(strcmpi(fName,fList))
    fList=[{fName}; fList];
    fList(maxFiles+1:end)=[];
  end
end
if ~isempty(fPath)
  if fPath(end)~=filesep
    fPath=[fPath filesep];
  end
  if ~any(strcmpi(fPath,dList))
    dList=[{fPath}; dList];
    dList(maxDirs+1:end)=[];
  end
end
newFileList=[fList; {''}; dList];


%----------------------------------------------------------------------------------
% -------- Local function to expand relative file name to fully qualified --------
%----------------------------------------------------------------------------------
function fName=local_fullName(relName,defPath)

% Francis Favorini,	04/14/00.

fName=relName;
% Fully qualify relative path
switch isrelpath(fName)
case 1
  % Simple relative name, just add defPath
  fName=fullfile(defPath,fName);
case 2
  % PC relative name starting with '\', but no drive, as in '\whatever'
  % Need to add root of our defPath
  fName=fullfile(fileroot(defPath),fName);
case 3
  % PC relative name starting with drive letter, as in 'C:whatever'
  % Need to add that drive's current directory
  if strncmp(defPath,fName,2)
    % It's on the same drive as our defPath
    fName=fullfile(defPath,fName(3:end));
  elseif strncmp(cd,fName,2)
    % It's on the same drive as MATLAB's current directory
    fName=fullfile(cd,fName(3:end));
  else
    % It's on a different drive, so we use the root of that drive,
    % since MATLAB only keeps track of one current directory.
    fName=[fName(1:2) '\' fName(3:end)];
  end
end

%--------------------------------------------------------------------------
% -------- Local function to initialize GUI -------------------------------
%--------------------------------------------------------------------------
function fig = local_initializegui
% Create GUI for specifying and reading data.

h0 = figure('Units','points', ...
	'Color',[0.752941176470588 0.752941176470588 0.752941176470588], ...
	'MenuBar','none', ...
	'Name','Open MR Data File', ...
	'NumberTitle','off', ...
	'PaperPosition',[18 180 576 432], ...
	'PaperUnits','points', ...
	'Position',[228.75 188.25 309.75 189.75], ...
	'Tag','Fig1', ...
	'ToolBar','none');
h1 = uicontrol('Parent',h0, ...
	'Units','points', ...
	'BackgroundColor',[1 1 1], ...
	'Callback','readmrold(''GUIFileList'');', ...
	'FontName','Arial', ...
	'ListboxTop',0, ...
	'Position',[15 154 280 14], ...
	'String',{''}, ...
	'Style','popupmenu', ...
	'Tag','FileList', ...
	'Value',1);
h1 = uicontrol('Parent',h0, ...
	'Units','points', ...
	'BackgroundColor',[1 1 1], ...
	'Callback','readmrold(''GUIFileName'');', ...
	'FontName','Arial', ...
	'HorizontalAlignment','left', ...
	'ListboxTop',0, ...
	'Position',[15 152.5 267 15], ...
	'String','', ...
	'Style','edit', ...
	'Tag','FileName');
h1 = uicontrol('Parent',h0, ...
	'Units','points', ...
	'Callback','readmrold(''GUIBrowse'');', ...
	'ListboxTop',0, ...
	'Position',[15 130 37.5 15], ...
	'String','Browse', ...
	'Tag','BrowseButton');
h1 = uicontrol('Parent',h0, ...
	'Units','points', ...
	'BackgroundColor',[1 1 1], ...
	'Callback','readmrold(''GUIXSize'');', ...
	'HorizontalAlignment','right', ...
	'ListboxTop',0, ...
	'Position',[104 130 22.5 15], ...
	'Style','edit', ...
	'Tag','XSize');
h1 = uicontrol('Parent',h0, ...
	'Units','points', ...
	'BackgroundColor',[1 1 1], ...
	'Callback','readmrold(''GUIYSize'');', ...
	'HorizontalAlignment','right', ...
	'ListboxTop',0, ...
	'Position',[149 130 22.5 15], ...
	'Style','edit', ...
	'Tag','YSize');
h1 = uicontrol('Parent',h0, ...
	'Units','points', ...
	'BackgroundColor',[1 1 1], ...
	'Callback','readmrold(''GUIZSize'');', ...
	'HorizontalAlignment','right', ...
	'ListboxTop',0, ...
	'Position',[194 130 22.5 15], ...
	'Style','edit', ...
	'Tag','ZSize');
h1 = uicontrol('Parent',h0, ...
	'Units','points', ...
	'BackgroundColor',[0.752941176470588 0.752941176470588 0.752941176470588], ...
	'ListboxTop',0, ...
	'Position',[15 45 280 75], ...
	'Style','frame', ...
	'Tag','Frame1');
h1 = uicontrol('Parent',h0, ...
	'Units','points', ...
	'BackgroundColor',[1 1 1], ...
	'Callback','readmrold(''GUIFileType'');', ...
	'ListboxTop',0, ...
	'Position',[77.5 97.5 115 15], ...
	'String',' ', ...
	'Style','popupmenu', ...
	'Tag','FileType', ...
	'Value',1);
h1 = uicontrol('Parent',h0, ...
	'Units','points', ...
	'BackgroundColor',[1 1 1], ...
	'Callback','readmrold(''GUIParam'');', ...
	'HorizontalAlignment','right', ...
	'ListboxTop',0, ...
	'Position',[243 97.5 33.75 15], ...
	'Style','edit', ...
	'Tag','HdrSize');
h1 = uicontrol('Parent',h0, ...
	'Units','points', ...
	'BackgroundColor',[1 1 1], ...
	'Callback','readmrold(''GUIParam'');', ...
	'ListboxTop',0, ...
	'Position',[77.5 75 67.5 15], ...
	'String',{'Big-Endian';'Little-Endian';'D Float (Vax)'}, ...
	'Style','popupmenu', ...
	'Tag','ByteOrder', ...
	'Value',1);
h1 = uicontrol('Parent',h0, ...
	'Units','points', ...
	'BackgroundColor',[1 1 1], ...
	'Callback','readmrold(''GUIParam'');', ...
	'ListboxTop',0, ...
	'Position',[232.5 75 45 15], ...
	'String',{'int8';'int16';'int32';'uint8';'uint16';'uint32';'Float32';'Float64'}, ...
	'Style','popupmenu', ...
	'Tag','PixelType', ...
	'Value',1);
h1 = uicontrol('Parent',h0, ...
	'Units','points', ...
	'BackgroundColor',[0.752941176470588 0.752941176470588 0.752941176470588], ...
	'Callback','readmrold(''GUIParam'');', ...
	'ListboxTop',0, ...
	'Position',[77.5 52.5 67.5 15], ...
	'String','All in One File', ...
	'Style','checkbox', ...
	'Tag','AllInOne');
h1 = uicontrol('Parent',h0, ...
	'Units','points', ...
	'BackgroundColor',[1 1 1], ...
	'Callback','readmrold(''GUIParam'');', ...
	'HorizontalAlignment','right', ...
	'ListboxTop',0, ...
	'Position',[255 52.5 22.5 15], ...
	'Style','edit', ...
	'Tag','StartExt');
h1 = uicontrol('Parent',h0, ...
	'Units','points', ...
	'Callback','readmrold(''GUIOK'');', ...
	'ListboxTop',0, ...
	'Position',[95 15 45 15], ...
	'String','OK', ...
	'Tag','OKButton');
h1 = uicontrol('Parent',h0, ...
	'Units','points', ...
	'Callback','readmrold(''GUICancel'');', ...
	'ListboxTop',0, ...
	'Position',[170 15 45 15], ...
	'String','Cancel', ...
	'Tag','CancelButton');
h1 = uicontrol('Parent',h0, ...
	'Units','points', ...
	'BackgroundColor',[0.752941176470588 0.752941176470588 0.752941176470588], ...
	'HorizontalAlignment','right', ...
	'ListboxTop',0, ...
	'Position',[188.25 52.5 60 15], ...
	'String','Extension Start:', ...
	'Style','text', ...
	'Tag','StaticText2');
h1 = uicontrol('Parent',h0, ...
	'Units','points', ...
	'BackgroundColor',[0.752941176470588 0.752941176470588 0.752941176470588], ...
	'HorizontalAlignment','right', ...
	'ListboxTop',0, ...
	'Position',[181.5 75 45 15], ...
	'String','Pixel Type:', ...
	'Style','text', ...
	'Tag','StaticText6');
h1 = uicontrol('Parent',h0, ...
	'Units','points', ...
	'BackgroundColor',[0.752941176470588 0.752941176470588 0.752941176470588], ...
	'HorizontalAlignment','right', ...
	'ListboxTop',0, ...
	'Position',[28 75 42 15], ...
	'String','Byte Order:', ...
	'Style','text', ...
	'Tag','StaticText7');
h1 = uicontrol('Parent',h0, ...
	'Units','points', ...
	'BackgroundColor',[0.752941176470588 0.752941176470588 0.752941176470588], ...
	'HorizontalAlignment','right', ...
	'ListboxTop',0, ...
	'Position',[207.75 97.5 30 15], ...
	'String','Header:', ...
	'Style','text', ...
	'Tag','StaticText1');
h1 = uicontrol('Parent',h0, ...
	'Units','points', ...
	'BackgroundColor',[0.752941176470588 0.752941176470588 0.752941176470588], ...
	'HorizontalAlignment','right', ...
	'ListboxTop',0, ...
	'Position',[32.5 97.5 37.5 15], ...
	'String','File Type:', ...
	'Style','text', ...
	'Tag','StaticText8');
h1 = uicontrol('Parent',h0, ...
	'Units','points', ...
	'BackgroundColor',[0.752941176470588 0.752941176470588 0.752941176470588], ...
	'HorizontalAlignment','right', ...
	'ListboxTop',0, ...
	'Position',[183 127 7.5 15], ...
	'String','Z:', ...
	'Style','text', ...
	'Tag','StaticText3');
h1 = uicontrol('Parent',h0, ...
	'Units','points', ...
	'BackgroundColor',[0.752941176470588 0.752941176470588 0.752941176470588], ...
	'HorizontalAlignment','right', ...
	'ListboxTop',0, ...
	'Position',[138 127 7.5 15], ...
	'String','Y:', ...
	'Style','text', ...
	'Tag','StaticText4');
h1 = uicontrol('Parent',h0, ...
	'Units','points', ...
	'BackgroundColor',[0.752941176470588 0.752941176470588 0.752941176470588], ...
	'HorizontalAlignment','right', ...
	'ListboxTop',0, ...
	'Position',[93 127 7.5 15], ...
	'String','X:', ...
	'Style','text', ...
	'Tag','StaticText5');
h1 = uicontrol('Parent',h0, ...
	'Units','points', ...
	'BackgroundColor',[0.752941176470588 0.752941176470588 0.752941176470588], ...
	'HorizontalAlignment','left', ...
	'ListboxTop',0, ...
	'Position',[15 170 20.25 9.75], ...
	'String','File:', ...
	'Style','text', ...
	'Tag','StaticText9');
if nargout > 0, fig = h0; end

% Modification History:
%
% $Log: readmrold.m,v $
% Revision 1.7  2005/02/03 16:58:42  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.6  2003/10/22 15:54:40  gadde
% Make some CVS info accessible through variables
%
% Revision 1.5  2003/06/30 16:34:53  michelich
% Updated for readmrold name change.
%
% Revision 1.4  2003/06/30 06:05:00  michelich
% Moved into readmrgui into readmr as a local function.
%
% Revision 1.3  2003/06/10 23:14:54  michelich
% Determine if inGUI before handling formats since this changes the values of
%   the function input arguments.
% Correctly determine format for read from header short form with inGUI.
%
% Revision 1.2  2003/06/10 22:34:22  michelich
% Don't attempt to read the header when using the paramsOnly mode since the
%   "fName" is actually the default directory.
%
% Revision 1.1  2002/08/27 22:24:23  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2002/05/13. Fixed readmr help to properly display DICOM formats
% Charles Michelich, 2002/04/29. Changed the name of the DICOM format to DICOM_Slice per Francis's request
%                                Changed function to allow empty hdrSz, pixelType, byteOrder, startExt, allInOne for 
%                                   so that extReader formats do not need to fill in these values
%                                Updated comments.
%                                Changed GUIOK callback to not read hdrSz or startExt from GUI for extReader formats
% Charles Michelich, 2002/04/24. Hide all of the user parameters for DICOM, DICOM_Volume, & DICOM_AVW_VolumeFile image types
%                                Make function to do DICOM read and check its format.
%                                Changed to return just params = {xSz,ySz,zSz,format} for format with an external reader
% Charles Michelich, 2002/04/23. Added support for reading DICOM and AVW_VolumeFile(DICOM Only) files.  Ignores passed parameters.
%                                Added default inGUI argument outside of catch so that it exists prior to any errors
%                                Added support for reading DICOM_Volume (DICOM slices read using name2spec)
% Francis Favorini,  2001/07/10. Added new help format to get default params for one or all formats.
% Charles Michelich, 2001/01/23. Changed function name to lowercase
%                                Changed fileroot(), readmrgui(), readmrhdr(), and isrelpath() to lowercase
% Charles Michelich, 2000/08/09. Fixed behavior so that headers are read for any canned format with a header.
%                                If image dimensions are passed, they are compared against the header (error if no match)
% Charles Michelich, 2000/08/07. Changed 'Signa5' format to use readmrhdr
%                                Added default size of 79x95x68 to 'Analyze7.5_SPM' format
% Charles Michelich, 2000/07/25. Added check that entire file was read
%                                Read data for all in one formats using a single fread (faster)
% Francis Favorini,  2000/04/18. Set tooltip for FileName textbox to file name.
%                                Update ZSize (slices) in GUI when user enters/selects new file.
%                                If user clears ZSize, allow automatic ZSize updating again.
% Francis Favorini,  2000/04/14. Made recent file list persistent; not updated until user clicks OK.
%                                Allow default path to be passed as argument, so don't need to
%                                change working directory (CD) anymore.
% Francis Favorini,  2000/04/05. Added some code for drop-down list of recent files and directories.
% Francis Favorini,  2000/03/31. Don't print out 'Custom' format for readmr('help').
%                                Set 'Volume' format default size to 64x64.
%                                Modified some comments.
% Charles Michelich, 2000/03/27. Changed automatic zSz to insert empty if an invalid number is calculated
%                                and the field has not been modified by the user.
% Charles Michelich, 2000/03/26. Added 'Custom' to list of specifications to avoid problems with indices to fmts
%                                Used local_updateGUI in all callbacks to allow empty fields in fmts.
%                                Added zSz field to formats and changed default of zSz for ScreenSave to 1.                              
%                                Added visual and tooltop feedback to user when a header read is attempted.
%                                Increased width of name column in readmr('help') to 14 for Analyze7.5_SPM format
%                                Added automatic calculation of ZSize for allInOne file type without header readers
%                                Added error checking to parameters of functional form of readmr
%                                Added support for empty xSz,ySz,zSz when using formats with readable headers
% Charles Michelich, 2000/03/25. Added support for reading information from headers
%                                Added hdr field to MR format definitions (hdr=1 means read params from header)
%                                Added check for variable inGUI in the catch block
%                                Added an inGUI for for the short form of readmr from formats with headers
%                                Added a condition on the format setup to avoid calling the header read
%                                  with each GUI callback
%                                Fixed GUI form of readmr('Params') to return hdrSz, pixelType, etc.
%                                  for canned format that read headers
%                                Fixed bug which attempted to check 'Custom' type for header after selecting file
% Francis Favorini,  2000/03/22. Changed default image size to 64x64.
%                                Added optional image size parameters for MR formats which get entered
%                                  automatically when you select the format in the GUI.
% Francis Favorini,  1999/05/04. Changed output args to [srs,name,params] or [name,params].
% Francis Favorini,  1998/11/20. Added error checking on parameters when user clicks OK.
% Francis Favorini,  1998/10/27. Make sure to close file on error.
% Francis Favorini,  1998/09/28. Made inGUI an argument.
% Francis Favorini,  1998/09/18. Redid default args again.
%                                Use GUI error dialog when in GUI.
% Francis Favorini,  1998/09/14. Kludge: if name starts with '=', get series from variable in base workspace.
% Francis Favorini,  1998/09/03. Redid default args.
% Francis Favorini,  1998/09/01. Added ability to just return params.
% Francis Favorini,  1998/08/28. Added some error checking.
%                                Added ability to pass defaults when fName is empty.
% Francis Favorini,  1998/07/07. Made Volume format little-endian.
% Francis Favorini,  1998/06/16. Fixed bug of ignoring startExt.
%                                Added CORITechs format.
% Francis Favorini,  1998/06/11. Minor mods.
% Francis Favorini,  1998/06/08. Turned into multipurpose MR input function.
