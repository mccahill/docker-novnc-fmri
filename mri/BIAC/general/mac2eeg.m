function mac2eeg(groups,subjects,dir)
%MAC2EEG Convert Mac .DAT files (from Margot) to EEG files.
%
%       mac2eeg(groups,subjects);
%       mac2eeg(groups,subjects,dir);
%
%       groups is a string containing group letters.
%       subjects is a vector containing which subject
%         in the above groups to convert.
%       dir is the optional directory where the data is.
%         Defaults to current directory.
%         EEG and HDR files are written to the same directory.

% CVS ID and authorship of this code
% CVSId = '$Id: mac2eeg.m,v 1.4 2005/02/03 20:17:46 michelich Exp $';
% CVSRevision = '$Revision: 1.4 $';
% CVSDate = '$Date: 2005/02/03 20:17:46 $';
% CVSRCSFile = '$RCSfile: mac2eeg.m,v $';

% Setup data
bins=[1 6 7 8 9];
nBins=length(bins);
nChannels=29;
nPoints=500;

% Change to directory
if nargin>2
  cd(dir);
end

% Loop through groups, subjects and bins
for g=double(groups)
  grp=upper(char(g));
  for sub=subjects
    data=zeros(nBins,nChannels,nPoints);
    binOut=1;
    gotData=0;
    for binIn=bins
      % Create filename
      filename=sprintf('%s\\%s%dN''%d.DAT',pwd,grp,sub,binIn);
      sex='';
      if exist(filename,'file')~=2
        filename=[filename(1:end-4) 'M.DAT'];       % Try with M before .DAT
        sex='M';
      end
      if exist(filename,'file')~=2
        disp(['Couldn''t find input file "' filename '"']);
        sex='';
      else
        disp(['Reading ' filename '...']);
        % Open file
        inFile=fopen(filename);
        if inFile==-1
          disp(['Couldn''t open input file "' filename '"']);
        end
        tmp=fgetl(inFile);                          % Skip first line
        tmp=fscanf(inFile,'%f',[nChannels nPoints]);
        data(binOut,:,:)=tmp;
        binOut=binOut+1;
        fclose(inFile);
        gotData=1;
      end
    end

    outName=sprintf('%s%d%s',grp,sub,sex);
    if ~gotData
      disp(['Skipping ' outName '...']);
    else
      disp(['Writing ' outName '...']);
      data=data*100;                                  % Convert to 100 units per microvolt
      
      % Create EEG data file
      EEGfid=fopen([outName '.AVG'],'w');
      if EEGfid==-1
        disp(['Couldn''t create data file "' [outName '.AVG'] '"']);
      end
      % Write EEG data
      data=permute(data,[3 2 1]);                 % Now data is a [nPoints nChannels nBins] array
      data=reshape(data,nPoints,nChannels*nBins);
      fwrite(EEGfid,data,'short');
      fclose(EEGfid);
      
      % Create HDR file
      HDRfid=fopen([outName '.HDR'],'wt');
      if HDRfid==-1
        disp(['Couldn''t create header file "' [outName '.HDR'] '"']);
      end
      % Open TEMPLATE.HDR
      tempName=[pwd '\TEMPLATE.HDR'];
      TMPfid=fopen(tempName,'rt');
      if TMPfid==-1
        disp(['Couldn''t open template header file "' tempName '"']);
      end
      % Copy from template to HDR file
      tmp=fgetl(TMPfid);                          % Skip first line
      fprintf(HDRfid,'Group %s, Subject %d\n',grp,sub);
      while 1                                     % Copy remaining lines
        tmp=fgetl(TMPfid);
        if ~ischar(tmp), break, end
        fprintf(HDRfid,'%s\n',tmp);
      end
      fclose(HDRfid);
      fclose(TMPfid);
    end
  end
end
disp('Done.');

% Modification History:
%
% $Log: mac2eeg.m,v $
% Revision 1.4  2005/02/03 20:17:46  michelich
% M-Lint: Replace deprecated isstr with ischar.
%
% Revision 1.3  2005/02/03 16:58:34  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:36  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/08/27 22:24:16  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2001/01/23. Changed function name to lowercase.
% Francis Favorini,  1997/09/18.
