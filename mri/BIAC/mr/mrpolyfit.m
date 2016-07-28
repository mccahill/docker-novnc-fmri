function srs=mrpolyfit(tsv,t,N)
% MRPOLYFIT - Calculate an Nth order polyfit of each time series in the volume
%
%   MRPOLYFIT finds the coefficients of a polynomial P(X) of 
%      degree N that fits the data, P(X(I))~=Y(I), in a least-squares sense.
%      Where X(I) is a voxel time series, Y(I) is a vector of the image
%      aquisition times, and P(X) is the polynomial for each voxel.
%
% srs=mrpolyfit(tsv,t,N)
%
%     tsv - time series of volumes to be analyzed
%     t   - a column vector of coefficients to regress against
%         - OR a single scalar specifying TR used to collect data
%            if t is a scalar, the data is fit to
%            t = ((0:size(tsv,4)-1)*t)'
%     N   - Order of the polynomial fit to perform
%
%     srs - a 4-D array containing an image volume in the 1st three dimensions
%           Each volume in the fourth dimension is the polynomial coefficient
%           of the fit ordered as shown below
%
%     fitimage= srs(:,:,:,1)*t^N+ srs(:,:,:,2)*t^(N-1) + ... + srs(:,:,:,N)*t + srs(:,:,:,N+1)
%
% See also POLYFIT 
%

% CVS ID and authorship of this code
% CVSId = '$Id: mrpolyfit.m,v 1.5 2005/02/03 16:58:40 michelich Exp $';
% CVSRevision = '$Revision: 1.5 $';
% CVSDate = '$Date: 2005/02/03 16:58:40 $';
% CVSRCSFile = '$RCSfile: mrpolyfit.m,v $';

lasterr('');  % Clear last error message
emsg='';      % Error message string
p=[];         % Pointer to progress bar

try     
   % Check input variables
   emsg = nargchk(3,3,nargin); error(emsg)  
   if ndims(tsv) ~= 4
      emsg = 'Input tsv must have 4 dimensions'; error(emsg);
   end
   if (length(N) > 1)| any(N <= 0) | ~isint(N)
      emsg = 'N must be a single positive (or zero) integer'; error(emsg);
   end
   
   % If the user inputs a single value for t,
   % calculate polyfit against a vector of length tSz with spacing t
   if length(t) == 1;
      t = ((0:size(tsv,4)-1)*t)';  % Generate time vector to fit to
   end 
   
   % Check t
   if any(size(t) ~= [size(tsv,4) 1])
      emsg = 't must be a scalar or column vector of length size(tsv,4)'; error(emsg);
   end
   
   % Find sizes
   xSz=size(tsv,1);
   ySz=size(tsv,2);
   zSz=size(tsv,3);
   tSz=size(tsv,4);
   
   srs=zeros(xSz,ySz,zSz,N+1);		% Initialize output volumes

   % Fit each time series
   p=progbar(sprintf('Calculating polynomial for slice 0 of %d',zSz));
   for z=1:zSz
      
      progbar(p,(z-1)/zSz,sprintf('Calculating polynomial fit for slice %d of %d',z,zSz));
      if ~ishandle(p), emsg='User abort'; error(emsg); end
      
      for y=1:ySz
         for x=1:xSz
            currTimeSrs=squeeze(tsv(x,y,z,:));
            m=polyfit(t,currTimeSrs,N);
            srs(x,y,z,:)=reshape(m,[1 1 1 N+1]);
         end
      end
      
      if ~ishandle(p), emsg='User abort'; error(emsg); end
      progbar(p,z/zSz);   
      
   end
   delete(p)
   
catch                   % Display captured errors and delete progress bar if it exists
   if isempty(emsg)
      if isempty(lasterr)
         emsg='An unidentified error occurred!';
      else
         emsg=lasterr;
      end
   end
   if ishandle(p), delete(p); end
   error(emsg);
end


% Modification History:
%
% $Log: mrpolyfit.m,v $
% Revision 1.5  2005/02/03 16:58:40  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.4  2003/10/22 15:54:37  gadde
% Make some CVS info accessible through variables
%
% Revision 1.3  2003/03/21 21:55:25  michelich
% Bug fix: Used tSz before initializing.
%
% Revision 1.2  2002/11/03 02:56:14  michelich
% Added support for regressing against a user specified vector.
% Originally added in private copy 2000/04/18.
%
% Revision 1.1  2002/08/27 22:24:21  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2001/01/25. Changed function name to lowercase.
% Charles Michelich, 2000/03/30. Corrected bug in higher order fits
% Charles Michelich, 1999/05/21. Added support for higher order fits
% Charles Michelich, 1999/05/21. Original
