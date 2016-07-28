function [FFTPSD,FFTPhase]=fftmr(tsv,range,thresh)
%fftmr  Return FFT of each pixel time series in image time series.
%
%   [FFTPSD,FFTPhase]=fftmr(tsv);
%   [FFTPSD,FFTPhase]=fftmr(tsv,range);
%   [FFTPSD,FFTPhase]=fftmr(tsv,range,thresh);
%
%   tsv is a time series of volumes as returned by READMR.
%     tsv may also be a 3D time series of images.
%   range is [I J] where I is the first image to use and J the last.
%     Defaults to [1 size(tsv,4)], if omitted or empty.
%   thresh is a threshhold for calculating the FFT info.  If the mean of a
%     pixel time series at (x,y,z) is below thresh, the FFT info for that series
%     is returned as zeros.  Defaults to 400, if omitted or empty.
%
%   FFTPSD is a TSV with each volume corresponding to one of the
%     frequency components of the FFT.  Each voxel in the volume is the
%     power spectral density for the voxel's time series.
%   FFTPhase is a TSV with each volume corresponding to one of the
%     frequency components of the FFT.  Each voxel in the volume is the
%     phase for the voxel's time series.
%   Both output series have last dimension equal to half nearest power of 2
%     above the range (2.^nextpow2(range(2)-range(1)+1)).  i.e. The FFT length
%     is the nearest power of two above the range.  The other dimensions match tsv.
%
%   Example:
%   >>tsv=readmr('D:\study\run01\V*.img',{'Volume',[64,64,32,128]});
%   >>[FFTPSD,FFTPhase]=fftmr(tsv.data);
%
%   See also READMR.

% CVS ID and authorship of this code
% CVSId = '$Id: fftmr.m,v 1.5 2005/02/03 16:58:39 michelich Exp $';
% CVSRevision = '$Revision: 1.5 $';
% CVSDate = '$Date: 2005/02/03 16:58:39 $';
% CVSRCSFile = '$RCSfile: fftmr.m,v $';

% Check arguments
error(nargchk(1,3,nargin));
redim=0;
if ndims(tsv)==3
  % Allow time series of images, but convert to 4D TSV
  tsv=reshape(tsv,[size(tsv,1) size(tsv,2) 1 size(tsv,3)]);
  redim=1;
elseif ndims(tsv)~=4
  error('tsv must be 3D or 4D!');
end

% Defaults
xSz=size(tsv,1);
ySz=size(tsv,2);
zSz=size(tsv,3);
tSz=size(tsv,4);
if nargin<2 | isempty(range), range=[1 tSz]; end
if length(range)~=2 | any(~isint(range)) | any(range<1) | range(1)>range(2)
  error('Range must be two positive integers in increasing order!');
end
rangeSz=range(2)-range(1)+1;
if nargin<3 | isempty(thresh), thresh=400; end

% Find smallest power of 2 greater than the number of time points (for fast FT)
Nptfft=2.^nextpow2(range(2)-range(1)+1);

% Trim unused time points
tsv(:,:,:,[1:range(1)-1 range(2)+1:end])=[];

% Zero out time series which are below threshhold
tsv(repmat(mean(tsv,4)<thresh,[1 1 1 rangeSz]))=0;

% Compute values along 4th dimension (i.e., for each voxel time series)
FFTSrs=fft(tsv,Nptfft,4);
FFTSrs=FFTSrs(:,:,:,1:Nptfft/2);                   % Other half is symmetric 
FFTPSD=FFTSrs.*conj(FFTSrs)/Nptfft;                % Compute power spectral density
FFTPhase=atan2(imag(FFTSrs),real(FFTSrs))/pi*180;   % Compute phase in degrees

% Convert back to time series of images, if needed
if redim
  FFTPSD=reshape(FFTPSD,[size(FFTPSD,1) size(FFTPSD,2) size(FFTPSD,4)]);
  FFTPhase=reshape(FFTPhase,[size(FFTPhase,1) size(FFTPhase,2) size(FFTPhase,4)]);
end

% Modification History:
%
% $Log: fftmr.m,v $
% Revision 1.5  2005/02/03 16:58:39  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.4  2003/10/22 15:54:37  gadde
% Make some CVS info accessible through variables
%
% Revision 1.3  2003/10/15 15:51:49  michelich
% Updated help to use new readmr.
%
% Revision 1.2  2003/07/01 19:22:47  michelich
% Updated example for new readmr function.
%
% Revision 1.1  2002/08/27 22:24:20  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2001/01/23. Change function name to lowercase.
%                                Updated comments
% Charles Michelich, 1999/11/11. Changed to use smallest power of 2 FFT.
% Francis Favorini,  1999/10/05. Use TSV instead of just image series.
% Francis Favorini,  1997/10/10. Changed to use MATLAB 5 multidimensional arrays.
%                                Vectorized and got rid of intermediate variables.
% Francis Favorini,  1996/11/04.
