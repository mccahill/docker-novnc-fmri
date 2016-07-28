function [normData,scale]=normaliz(data,range)
%NORMALIZ Normalize data to range.
%
%   normData=normaliz(data,range);
%   [normData,scale]=normaliz(data,range);
%
%   range is [low high].
%   normData is data scaled to range.
%   scale is (range(2)-range(1))/(max(data)-min(data))
%
%   Any NaN's in data are ignored.

% CVS ID and authorship of this code
% CVSId = '$Id: normaliz.m,v 1.5 2005/02/03 16:58:34 michelich Exp $';
% CVSRevision = '$Revision: 1.5 $';
% CVSDate = '$Date: 2005/02/03 16:58:34 $';
% CVSRCSFile = '$RCSfile: normaliz.m,v $';

[minData maxData]=minmax(data);
if minData==maxData
  scale=0;
  range(1)=mean(range);
else
  scale=(range(2)-range(1))/(maxData-minData);
end
normData=(data-minData)*scale+range(1);

% Modification History:
%
% $Log: normaliz.m,v $
% Revision 1.5  2005/02/03 16:58:34  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.4  2003/10/22 15:54:36  gadde
% Make some CVS info accessible through variables
%
% Revision 1.3  2003/10/22 15:06:25  michelich
% Updated capitalization of function declaration
%
% Revision 1.2  2003/09/15 17:23:27  michelich
% Corrected capitalization in help comments
%
% Revision 1.1  2002/08/27 22:24:17  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Francis Favorini, 1998/11/02. Use minmax.
%                               No need to reshape data.
% Francis Favorini, 1998/06/12. Added special case for min(data)==max(data).
%                               min & max now ignore NaN's themselves.
% Francis Favorini, 1997/02/06. Returns scale if desired.
% Francis Favorini, 1996/11/14. Ignores NaN's and preserves shape of data.
% Francis Favorini, 1996/10/18.
