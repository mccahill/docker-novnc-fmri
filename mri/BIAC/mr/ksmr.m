function [p,m,s]=ksmr(deck,siz,range)
%KSMR   Return Kol(o)mogorov-Smirnov probability that each pixel time series in deck is normal.
%
%       [p,m,s]=ksmr(deck,siz,range);
%       deck is an image deck of the MR data returned by ReadANMR.
%       siz is the [M N P] specifier for the image deck data returned by ReadANMR.
%       range is [I J] where I is the first image to use and J the last.
%       p is the probability matrix.
%       m is the mean matrix.
%       s is the std matrix.
%
%       Example:
%       >>[deck,siz]=readanmr('\\brain\data\whatever\slice1\image',128,64,128);
%       >>[p,m,s]=ksmr(deck,siz,[5 128]);

% CVS ID and authorship of this code
% CVSId = '$Id: ksmr.m,v 1.3 2005/02/03 16:58:39 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:39 $';
% CVSRCSFile = '$RCSfile: ksmr.m,v $';

% Preallocate matrices
p=zeros(siz(1),siz(2));
m=zeros(siz(1),siz(2));
s=zeros(siz(1),siz(2));

% Compute values for each pixel series
for y=1:siz(1)
  for x=1:siz(2)
    srs=deck(impixsrs(siz,[x y],range));
    m(y,x)=mean(srs);
    s(y,x)=std(srs);
    % r is a normal distribution with same mean and std as pixel time series.
    r=s(y,x)*randn(1,range(2)-range(1)+1)+m(y,x);
    % Compute KS info for each pixel time series vs. r
    [d p(y,x)]=kstwo(r,srs);
  end
end

% Modification History:
%
% $Log: ksmr.m,v $
% Revision 1.3  2005/02/03 16:58:39  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:37  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/08/27 22:24:21  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2001/01/25. Changed function name to lowercase.
% Francis Favorini,  1996/10/18.
