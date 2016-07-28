function srs=dicomread_analyzevolumefile(filename)
% dicomread_analyzevolumefile - Read DICOM images specified by AVW_VolumeFile
%
%  srs=dicomread_analyzevolumefile(filename)
%
%      filename - AVW_VolumeFile filename
%           srs - output 3D image
%
% Note: All AVW_VolumeFile fields ignored except for the list of images
% Note: ONLY supports DICOM images with the following format:
%          2D, single-frame, grayscale, opaque image with no overlays.
%

% CVS ID and authorship of this code
% CVSId = '$Id: dicomread_analyzevolumefile.m,v 1.3 2005/02/03 16:58:38 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:38 $';
% CVSRCSFile = '$RCSfile: dicomread_analyzevolumefile.m,v $';

error(nargchk(1,1,nargin));

% Get path of AVW_VolumeFile - Interpret all entries in AVW file relative to this path
basepath=fileparts(filename);

% Open file
[fid,emsg]=fopen(filename,'r');
if fid == -1, error(emsg); end

% Check that first line is correct
uniqueID = fgetl(fid);
if ~strncmp(uniqueID,'AVW_VolumeFile',length('AVW_VolumeFile'))
  error('This is not an Analyze AVW_VolumeFile');
end

% --- Count the number of slices ---
zSz = 0;
currLine = fgetl(fid); % Read 2nd line
while isempty(currLine) | (currLine ~= -1)  % isempty is to avoid the [] ~= 1 comparison warning
  % Skip lines starting with #
  if ~isempty(currLine) & currLine(1) ~= '#'
    zSz = zSz +1;
  end
  currLine = fgetl(fid); % Read next line
end
fseek(fid,0,-1); % Rewind the file
fgetl(fid);      % Get rid of first line

% --- Read each image ---
currLine = fgetl(fid); % Read 2nd line
currSlice = 1;         % Initialize current slice counter
while isempty(currLine) | (currLine ~= -1)  % isempty is to avoid the [] ~= 1 comparison warning
  % Skip lines starting with # & blank lines
  if ~isempty(currLine) & currLine(1) ~= '#'
    
    %  Interpret all entries in AVW file relative to path of AVW_VolumeFile
    currFile = fullfile(basepath,currLine);
      
    % Check if the current file exists
    if ~exist(currFile,'file')
      emsg=sprintf('File %s does not exist!',currFile); error(emsg);
    end
    
    % Read the DICOM image
    srsCurr=dicomread_slicewithcheck(currFile);
        
    if currSlice == 1
      % Initialize output array
      xSz = size(srsCurr,1);
      ySz = size(srsCurr,2);
      srs = zeros(xSz,ySz,zSz);
    end
    
    % Check that the x & y sizes are the same as the other images
    if ~all(size(srsCurr) == [xSz,ySz])
      emsg=sprintf('Incompatible slice. Image %s has different x-y dimensions than previous image!',currFile); error(emsg);
    end
    
    % Assign current image to output array 
    srs(:,:,currSlice) = srsCurr;

    % Increment current slice counter
    currSlice = currSlice + 1;
  end
  currLine = fgetl(fid); % Read next line
end

% Modification History:
%
% $Log: dicomread_analyzevolumefile.m,v $
% Revision 1.3  2005/02/03 16:58:38  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:37  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/08/27 22:24:20  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2002/04/24. Read using dicomread_slicewithcheck to do DICOM format checking
% Charles Michelich, 2002/04/23. Bug fix: Was not skipping empty lines properly
%                                Added isempty(currLine) to while condition to avoid the [] ~= 1 comparison warning
% Charles Michelich, 2002/04/04. Interpret all entries in AVW file relative to path of AVW_VolumeFile
% Charles Michelich, 2002/03/29. original

