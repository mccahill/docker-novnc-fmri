function EEGWrite(eeg,file,onlyHeader)
%EEGWrite Write eeg data to file.
%
%       EEGWrite(eeg,file);
%       EEGWrite(eeg,file,onlyHeader);
%
%       EEG is a structure with the following fields:
%         expName is the experiment name
%         expDate is the experiment date string
%         nBins is the number of bins.
%         nChannels, nPoints, sampling, uvunits, onset are as above.
%         binNames is a cell array of bin names.
%         chanNames is a cell array of channel names.
%         coords is a matrix of electrode coordinates
%           with size [nChannels 2] or [nChannels 3].
%         data is the EEG data in a [nBins nChannels nPoints] matrix.
%         rawData is the raw EEG data in a [nBins nChannels nPoints] matrix when data has been filtered.
%       file is the name of the data file stored as contiguous points, grouped by channels, then bins.
%         Each point is a short (2-byte signed integer).
%         The appropriate .HDR file is also created.
%       onlyHeader should be non-zero to only write HDR file.  Default is 0.
%
%       NOTE: eeg.data is the output data, NOT eeg.rawData.

% CVS ID and authorship of this code
% CVSId = '$Id: EEGWrite.m,v 1.3 2005/02/03 16:58:19 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:19 $';
% CVSRCSFile = '$RCSfile: EEGWrite.m,v $';

% Defaults
if nargin<3, onlyHeader=0; end

% Create data file, if requested
if ~onlyHeader
  EEGfid=fopen(file,'w');
  if EEGfid==-1
    error(['Couldn''t create data file "' file '"'])
  end
end
  
% Create hdr file
dot=max(find(file=='.'));
if isempty(dot), file=[file '.']; dot=length(file); end
hdrfid=fopen([file(1:dot) 'hdr'],'wt');
if hdrfid==-1
  fclose(EEGfid);
  error(['Couldn''t create header file "' file(1:dot) 'hdr"'])
end

% Write header info
fprintf(hdrfid,'%s\n',eeg.expName);
fprintf(hdrfid,'%s\n',eeg.expDate);
fprintf(hdrfid,'%d\n',eeg.nChannels);
fprintf(hdrfid,'%d\n',eeg.nPoints);
fprintf(hdrfid,'%.6f\n',eeg.sampling);
fprintf(hdrfid,'%.6f\n',eeg.uvunits);
fprintf(hdrfid,'%.6f\n',eeg.onset);

% Write bin and channel names
fprintf(hdrfid,'%s\n',eeg.binNames{:});
fprintf(hdrfid,'%s\n',eeg.chanNames{:});

% Write electrode coordinates, if any
if ~isempty(eeg.coords)
  fprintf(hdrfid,'%d %d\n',eeg.coords');
end
fclose(hdrfid);

% Write eeg data, if requested
if ~onlyHeader
  data=permute(eeg.data,[3 2 1]);                        % Now data is a [nPoints nChannels nBins] array
  data=reshape(data,eeg.nPoints,eeg.nChannels*eeg.nBins);
  fwrite(EEGfid,data,'short');
  fclose(EEGfid);
end

% Modification History:
%
% $Log: EEGWrite.m,v $
% Revision 1.3  2005/02/03 16:58:19  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:34  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/10/08 23:46:45  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Francis Favorini, 06/12/97.
% Francis Favorini, 07/03/97.  Minor mods.
% Francis Favorini, 12/10/97.  Added onlyHeader arg.
