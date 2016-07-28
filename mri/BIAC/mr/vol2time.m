function vol2time(inpath,outpath,startTime,tSz,xSz,ySz,zSz,format)
%VOL2TIME Convert a time series of volumes to a slice series of x,y,t images.
%
%   vol2time(inpath,outpath,startTime,tSz,xSz,ySz,zSz);
%   vol2time(inpath,outpath,startTime,tSz,xSz,ySz,zSz,format);
%	
%   inpath    = Path to the volume input files with stub
%   outpath   = Path of the volume output files with stub
%               The directories specified must exist.
%   startTime = Time point to begin converting from
%   tSz       = Number of time points to convert
%   xSz       = X-size of the images
%   ySz       = Y-size of the images
%   zSz       = Z-size of the images
%   format    = 'volume' or 'float' (default is 'volume')
%
%   Input:  tSz files each of size [xSz ySz zSz]
%   Output: zSz files each of size [xSz ySz tSz]
%
%   Note: Zero-padded 4-digit image number and '.IMG' are appended to
%         end of inpath and outpath to form complete file name.
%         So if inpath = '//broca/data2/study/V' 
%            15th image file = '//broca/data2/study/V0015.img'
%
%   Example:
%   >>vol2time('\\broca\data2\study\raw\run01\V','\\broca\data2\study\raw\run01\T',1,60,128,128,12)

% CVS ID and authorship of this code
% CVSId = '$Id: vol2time.m,v 1.3 2005/02/03 16:58:45 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:45 $';
% CVSRCSFile = '$RCSfile: vol2time.m,v $';

% Check arguments
error(nargchk(7,8,nargin));
if nargin<8, format='volume'; end
if ~(strcmpi(format,'volume') | strcmpi(format,'float'))
  error('Only volume and float formats are supported at this time.');
end

% Create an array for the 4d data
data4d=zeros(xSz,ySz,zSz,tSz);

% Read the MR files into the 4d array
p=progbar(sprintf('Reading 0 of %d volumes...',tSz));
for n=1:tSz
  if ~ishandle(p), error('User abort'); end
  progbar(p,sprintf('Reading %d of %d volumes...',n,tSz));
  data4d(:,:,:,n)=readmr(sprintf('%s%04d.img',inpath,n-1+startTime),xSz,ySz,zSz,format);   
  if ~ishandle(p), error('User abort'); end
  progbar(p,n/tSz);
end
delete(p);

% Write the MR files into tSz volume files (x,y,t)
p=progbar(sprintf('Writing 0 of %d time series...',zSz));
for n=1:zSz
  if ~ishandle(p), error('User abort'); end
  progbar(p,sprintf('Writing %d of %d time series...',n,zSz));
  writemr(sprintf('%s%04d.img',outpath,n),data4d(:,:,n,:),format);
  if ~ishandle(p), error('User abort'); end
  progbar(p,n/zSz);
end
delete(p);

% Modification History:
%
% $Log: vol2time.m,v $
% Revision 1.3  2005/02/03 16:58:45  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:39  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/08/27 22:24:26  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Francis Favorini,  1998/11/20. Added format argument.
%                                Added progbars.
% Charles Michelich, 1998/11/13. original
