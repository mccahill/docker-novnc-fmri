function CheckHdrs(varargin)
%CHECKHDRS Check all EEG .HDR files in directory for missing spaces in channel names.
%
%       CHECKHDRS (dir,...);
%
%       dir is the name of a directory to search.  Multiple args allowed.

% CVS ID and authorship of this code
% CVSId = '$Id: CheckHdrs.m,v 1.3 2005/02/03 16:58:17 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:17 $';
% CVSRCSFile = '$RCSfile: CheckHdrs.m,v $';

grandtotal=0;
for d=1:nargin
  directory=varargin{d};
  disp(directory);
  total=0;

  % Get list of EEG files in directory
  if exist(directory)~=7
    error(['No such directory as "' directory '"!']);
  end
  cd(directory);
  files=[dir('*.AVG');dir('*.GAV')];
  
  % Loop through files
  for f=1:length(files)
    subtotal=0;
    eeg=EEGRead(files(f).name,0);
    for c=1:eeg.nChannels
      if isempty(findstr(' ',eeg.chanNames{c})) & ~strcmp('TRIGGER',upper(eeg.chanNames{c}))
        if subtotal==0, disp([' ' files(f).name(1:end-4) '.hdr']); end
        subtotal=subtotal+1;
        a=sscanf(eeg.chanNames{c},'%[A-Za-z]%d');
        name=char(a(1:end-1)');
        num=a(end);
        newName=[name ' ' num2str(num)];
        disp(['  ' eeg.chanNames{c}]); % ' --> ' newName]);
      end
    end
    total=total+subtotal;
  end
  disp(sprintf(' Found %d channels to change.',total));
  disp(' ');
  grandtotal=grandtotal+total;
end
disp(sprintf('Found grand total of %d channels to change.',grandtotal));

% Modification History:
%
% $Log: CheckHdrs.m,v $
% Revision 1.3  2005/02/03 16:58:17  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:33  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/10/08 23:46:43  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Francis Favorini, 12/08/97.
