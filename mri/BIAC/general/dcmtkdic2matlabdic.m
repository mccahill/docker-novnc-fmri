function dcmtkdic2matlabdic(dicFilename,baseMatlabDicomDict,outputMatlabDicomDict)
%DCMTKDIC2MATLABDIC - Translate DCMTK DICOM Dictionary into MATLAB DICOM Dictionary
%
%  Translate DICOM Dictionary file in format used by 
%  "OFFIS DICOM Software: DCMTK - DICOM Toolkit"
%  into format used by MATLAB function dicominfo.
%
%  dcmtkdic2matlabdic(dicFilename,baseMatlabDicomDict,outputMatlabDicomDict)
%    dicFilename - Filename and path of DCMTK dictionary
%    baseMatlabDicomDict - Filename of MATLAB DICOM Dictionary file
%                          to append dicFilename entries to (default = '')
%    outputMatlabDictomDict - Filename of MATLAB DICOM Dictionary file
%                             to be created as output.  Default is the
%                             dicFilename with at .mat file extension
%
% Example
% >> dcmtkdic2matlabdic('gen3mr.dic','dicom-dict.mat');
% >> info = dicominfo('image.dcm','dictionary','gen3mr.mat');
%
% See Also: DICOMINFO, DICOMREAD

%  Notes on the MATLAB DICOM Dictionary format:
%  MATLAB stores its DICOM Dictionary as a .mat file containing two
%  variables:
%     tags => a sparse array (65536 x 65536) of numbers where the
%             tags indcies correspond to the DICOM GroupNames &
%             ElementNames (+1 for MATLAB indexing) respectively.
%             The value of the tags is an index in to the values structure
%   values => a structure of DICOM info for each DICOM tag in tags with the
%             following fields:
%               Name - Name of field (string)
%               VR - Value Representation (2 character string) 
%               VM - Value Multiplicity - Valid number of elements (range) (1x2 numeric vector)
%            

% CVS ID and authorship of this code
% CVSId = '$Id: dcmtkdic2matlabdic.m,v 1.8 2005/02/03 16:58:32 michelich Exp $';
% CVSRevision = '$Revision: 1.8 $';
% CVSDate = '$Date: 2005/02/03 16:58:32 $';
% CVSRCSFile = '$RCSfile: dcmtkdic2matlabdic.m,v $';

% Handle inputs
error(nargchk(1,3,nargin));
if nargin < 2,
  % No base MATLAB DICOM Dictionary specified
  baseMatlabDicomDict = ''; 
end
if nargin < 3, 
  % Default output name is original dicFilename with .mat extension
  [dicPath,dicName,dicExt]=fileparts(dicFilename);
  outputMatlabDicomDict = fullfile(dicPath,[dicName,'.mat']);
end

if isempty(baseMatlabDicomDict)
  % No original dictionary, initialize tags sparse array
  tags = sparse([],[],[],65536,65536,0);
  values=struct('VR','  ','Name','','VM',[0 0]);
  firstOpenValue=1;  
else
  % Load the specified MATLAB DICOM Dictionary
  load(baseMatlabDicomDict);
  firstOpenValue=length(values)+1; % Index to next open index in the values array
end

% Add tags from the new dictionary 

% Open file
[fid,emsg]=fopen(dicFilename,'r');
if fid == -1, error(emsg); end

% --- Read each line ---
dictlines = {};
currLine = fgetl(fid);
while isempty(currLine) | (currLine ~= -1) % isempty is to avoid the [] ~= 1 comparison warning
  % Skip lines starting with # & blank lines
  if ~isempty(currLine) & currLine(1) ~= '#'
    dictlines{end+1} = currLine;
  end
  currLine = fgetl(fid);
end

% --- Go backwards through lines (earlier lines have precedence!) ---
entryoffset = 0;                 % Current entry counter
for linenum = length(dictlines):-1:1
  if mod(linenum, 100) == 0
    disp(sprintf('Dictionary line %d', linenum));
  end
  currLine = dictlines{linenum};

  % Extract the elements from a line with the following format
  %
  % (xxxx,xxxx) VR Name VMString
  %
  %  where x is a hexadecimal digit
  %    " " is any whitespace
  %    VR,Name,VMString are strings of non-whitespace characters
  % 
  %  Examples
  % (0009,0000)	UL	GEMS:IDEN01GroupLength	1
  % (0009,0000)	UL	GEMS:IDEN01GroupLength	1-n
  % (0009,0000)	UL	GEMS:IDEN01GroupLength	1-2

  tag = [];
  value = struct('Name','','VR','','VM',[]);
  
  % Get Group & element number based on location in string
  commapos = findstr(currLine,',');
  rparenpos = findstr(currLine,')');
  tag.GroupNumber=currLine(2:commapos(1)-1);
  tag.ElementNumber=currLine(commapos(end)+1:rparenpos-1);
  
  % Skip whitespace to find VR, Name, VMString
  [value.VR,remain]=strtok(currLine(rparenpos+1:end));
  [value.Name,remain]=strtok(remain);
  VMString = strtok(remain);
  
  % Convert VMString into two element range
  dash=findstr(VMString,'-');
  if isempty(dash)
    % VMString is a single number
    value.VM = repmat(sscanf(VMString,'%f'),[1 2]);
  else
    % VMString is two numbers
    value.VM(1) = sscanf(VMString(1:(dash-1)),'%f');
    if VMString(dash+1) == 'n'
      % If second number is n, then the upper limit is Inf
      value.VM(2) = Inf;
    else
      % Convert second number
      value.VM(2) = sscanf(VMString((dash+1):end),'%f');
    end
  end
  
  %--- Check that all fieldnames are valid MATLAB structure field names ---
  % Replace : with _
  value.Name=strrep(value.Name,':','_');
  
  % Check that the variable name is now valid.
  if ~isvarname(value.Name)
    error(sprintf('%s is not a valid variable name in MATLAB.  Please change this in the DCMTK dictionary!', value.Name));
  end
  
  % copy tag and value, replicating for ranges if needed
  [groupstart, groupend, groupstep] = local_extractrange(tag.GroupNumber);
  [elemstart, elemend, elemstep] = local_extractrange(tag.ElementNumber);
  if ~isempty(groupstart) & ~isempty(elemstart) & ...
        ~(mod(groupstart,2) == 1 & mod(groupstep,2) == 0)
    if mod(groupstart,2) == 1
      % starts on odd -- step is odd too (because of above check) so add
      % them to start on even and double step to target only evens
      groupstart = groupstart + groupstep;
      groupstep = groupstep * 2;
    end
    groupvals = dec2hex(groupstart+1:groupstep:groupend+1, 4);
    elemvals = dec2hex(elemstart+1:elemstep:elemend+1, 4);
    numgroups = size(groupvals,1);
    numelems = size(elemvals,1);
    if length(elemstart+1:elemstep:elemend+1) ~= 1
      %        disp(sprintf('numelems=%d, rangesize=%d', numelems, length(elemstart+1:elemstep:elemend+1)));
    end
    if length(groupstart+1:groupstep:groupend+1) ~= 1
      %        disp(sprintf('numgroups=%d, rangesize=%d', numgroups, length(groupstart+1:groupstep:groupend+1)));
    end
    tags(groupstart+1:groupstep:groupend+1, ...
         elemstart+1:elemstep:elemend+1) = ...
        reshape((firstOpenValue+entryoffset):(firstOpenValue+entryoffset+(numgroups*numelems)-1), numgroups, numelems);
    [values((firstOpenValue+entryoffset):(firstOpenValue+entryoffset+(numgroups*numelems)))] = deal(value);
    entryoffset = entryoffset + (numgroups*numelems);
  end
end

% Close file
fclose(fid);

% Save the resulting dictionary
save(outputMatlabDicomDict,'tags','values','-mat');


function [rangestart, rangeend, rangestep] = local_extractrange(inrange)
% LOCAL_EXTRACTRANGE - extract DCMTK group or elem range into start,end,step

dashes = findstr(inrange, '-');
if isempty(dashes)
  % one number
  rangestart = hex2dec(inrange);
  rangeend = hex2dec(inrange);
  rangestep = 1;
elseif length(dashes) == 1
  % only even numbers
  rangestart = ceil(hex2dec(inrange(1:dashes-1))/2)*2;
  rangeend = hex2dec(inrange(dashes+1:end));
  rangestep = 2;
elseif length(dashes) == 2
  rangestart = hex2dec(inrange(1:dashes(1)-1));
  rangeend = hex2dec(inrange(dashes(2)+1:end));
  steptype = inrange(dashes(1)+1:dashes(2)-1);
  switch steptype
   case 'o'
    rangestart = (floor(rangestart/2)*2)+1;
    rangestep = 2;
   case 'u'
    % all numbers
    rangestep = 1;
   otherwise
    error(sprintf('Bad step type "%s" in group or elem range!', inrange));
  end
else
  error(sprintf('Bad group or elem range "%s"!', inrange));
end

% Modification History:
%
% $Log: dcmtkdic2matlabdic.m,v $
% Revision 1.8  2005/02/03 16:58:32  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.7  2004/05/06 15:57:44  michelich
% Replace remaining strfind's.
%
% Revision 1.6  2004/05/06 14:46:40  gadde
% Replace all uses of strfind with findstr (strfind doesn't exist before
% Matlab 6.1).
%
% Revision 1.5  2003/10/22 15:54:35  gadde
% Make some CVS info accessible through variables
%
% Revision 1.4  2003/08/08 21:17:35  michelich
% Initialize value structure so that fields are created in correct order.
% (Error: Subscripted assignment between dissimilar structures)
%
% Revision 1.3  2003/04/11 18:35:14  gadde
% Support ranges
%
% Revision 1.2  2003/04/09 16:41:13  gadde
% Fix wandering parenthesis.
%
% Revision 1.1  2002/10/01 20:52:29  michelich
% Initial version
%
