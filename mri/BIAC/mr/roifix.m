function roifix(fileSpecs)
%ROIFIX  Fix specified ROI files.
%
%   roifix(fileSpec);
%
%   fileSpec is a file specifier identifying the ROI file(s) to fix.
%     It may also be cell array of strings for multiple fileSpecs.
%
%   Notes:
%   This function fixes ROI files that were saved improperly due to a bug
%     in the ROIGROW function.  Files that don't have the bug are left alone.
%
%   Examples:
%   >>roifix('D:\study\analysis\ROIs');
%   >>roifix('D:\study\analysis\ROIs\L*.roi');
%   >>roifix('Lside.roi');
%   >>roifix({'L*.roi' 'R*.roi'});

% CVS ID and authorship of this code
% CVSId = '$Id: roifix.m,v 1.4 2005/02/16 01:53:49 michelich Exp $';
% CVSRevision = '$Revision: 1.4 $';
% CVSDate = '$Date: 2005/02/16 01:53:49 $';
% CVSRCSFile = '$RCSfile: roifix.m,v $';

if ~iscellstr(fileSpecs)
  fileSpecs={fileSpecs};
end
fileSpecs(strcmp(fileSpecs,''))=[];    % Strip out empty strings

for s=1:length(fileSpecs)
  % Where to look
  fileSpec=fileSpecs{s};
  if fileSpec(end)==filesep, fileSpec(end)=[]; end
  if exist(fileSpec,'dir')
    filePath=fileSpec;
  else
    filePath=fileparts(fileSpec);
  end
  % Get file names
  d=dir(fileSpec);
  if isempty(d)
    error(sprintf('No files found matching %s!',fileSpec));
  end
  d([d.isdir])=[];                                      % Ignore directories
  fNames=sort({d.name}');
  nFiles=length(fNames);
  if exist(fileSpec)~=2
    % If fileSpec was a directory or wildcard, need to add full path
    fNames=strcat(filePath,filesep,fNames);
  end
  
  % Check/fix the files
  for f=1:nFiles
    fixme=0;
    roiFile=fNames{f};
    disp(roiFile);
    load(roiFile,'roi','-mat');
    for s=1:length(roi.index)
      newindex=roi.index{s};
      if ~fixme & size(newindex,2)~=1, disp('  Fixing.'); fixme=1; end
      roi.index{s}=newindex(:);                         % Make sure we save as a column vector
    end
    if fixme
      if str2double(strtok(strtok(version),'.')) >=7
        % Save ROIs for MATLAB 5 & 6 compatibility
        save(roiFile,'roi','-V6');
      else
        save(roiFile,'roi');
      end
    end
  end
end

% Modification History:
%
% $Log: roifix.m,v $
% Revision 1.4  2005/02/16 01:53:49  michelich
% Save ROIs for MATLAB 5 & 6 compatibility when using MATLAB 7 and later.
%
% Revision 1.3  2005/02/03 16:58:43  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:39  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/08/27 22:24:25  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2001/01/25. Changed function name to lowercase.
% Francis Favorini,  1999/10/13.
