function hemoconv(kernel,base,kdT,bdT,hemoDelay,baseInterp)
%HEMOCONV Convolve hemodynamic function with base function and plot.
%
%   HEMOCONV(kernel,base,kdT,bdT,hemoDelay,baseInterp)
%
%   kernel is hemodynamic response function.
%   base is hypothetical neuronal activation profile.
%     If base is a matrix, separate base functions are in each column.
%   kdT is kernel's sampling interval in seconds.  Default is 1.
%   bdT is base's sampling interval in seconds.  Default is 1.
%   hemoDelay is time in seconds of first point in kernel.
%     Default is 2.
%   baseInterp is a string passed to INTERP1 specifing the
%     interpolation method.  Default is 'nearest'.
%
%   Examples
%     HEMOCONV(gamma,[1 0 0 0 1 0 0 0],1,1);
%     HEMOCONV(gamma,[base1; base2],1,1);
%     HEMOCONV(gamma,[.7 1 0 0 0 .7 1 0 0 0],1,3,4,'linear');
%
%   See also INTERP1

% CVS ID and authorship of this code
% CVSId = '$Id: hemoconv.m,v 1.3 2005/02/03 16:58:39 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:39 $';
% CVSRCSFile = '$RCSfile: hemoconv.m,v $';

error(nargchk(2,6,nargin));
if nargin<3, kdT=1; end
if nargin<4, bdT=1; end
if nargin<5, hemoDelay=2; end
if nargin<6, baseInterp='nearest'; end

% Convert row vectors to column vectors
kernel=kernel(:);
if ndims(base)==2 & any(size(base)==1)
   base=base(:);
end

% Single point base function has no sampling interval 
if size(base,1)==1
   bdT=kdT;		% Prevents interpolation
end

% Define time scales
kernelTimes=[0:kdT:(size(kernel,1)-1)*kdT]';
baseTimes=[0:bdT:(size(base,1)-1)*bdT]';
newBaseTimes=baseTimes;

if kdT>bdT
   % Interpolate kernel to base time scale
	newKernelTimes=[0:bdT:(size(kernel,1)-1)*kdT]';
   kernel=interp1(kernelTimes,kernel,newKernelTimes,'spline');
elseif kdT<bdT
   % Interpolate base to kernel time scale
	newBaseTimes=[0:kdT:(size(base,1)-1)*bdT]';
   base=interp1(baseTimes,base,newBaseTimes,baseInterp);
end

% Make the plot
dT=min(kdT,bdT);
time=hemoDelay+[0:dT:(size(base,1)+size(kernel,1)-2)*dT];
plotColors={'y' 'm' 'c' 'r' 'g' 'b' 'w'};
figure, hold on
for b=1:size(base,2)
   color=plotColors{mod(b-1,length(plotColors))+1};
   kConv=conv(base(:,b),kernel);		% Do the convolution
   plot(time,kConv,[color ':']);
	plot(newBaseTimes,base(:,b),color);
end

% Modification History:
%
% $Log: hemoconv.m,v $
% Revision 1.3  2005/02/03 16:58:39  michelich
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
% Gregory McCarthy, 2000/01/11.
