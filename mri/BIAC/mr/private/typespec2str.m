function str = typespec2str(typeSpec)
%TYPESPEC2STR - Convert a READMR typespec into a string suitable for log files.
%
% Convert a READMR typespec into a string suitable for log files.
%
% str = typespec2str(typeSpec)
%
% Currently supports strings, row vectors of doubles, and cell arrays
% of these variables. Unsupported variable types with appear as
% UNHANDLED_[DESC] where [DESC] is a description of the unsupported
% variable. 
%
% NOTE: Precision of numeric array may be lost during conversion.
%       Conversion performed using num2str(NUM,15);
%
% See Also: READMR

% CVS ID and authorship of this code
% CVSId = '$Id: typespec2str.m,v 1.4 2005/02/03 16:58:45 michelich Exp $';
% CVSRevision = '$Revision: 1.4 $';
% CVSDate = '$Date: 2005/02/03 16:58:45 $';
% CVSRCSFile = '$RCSfile: typespec2str.m,v $';

% TODO: Add support for other classes
% TODO: Add support for column vectors & multidimensional arrays

error(nargchk(1,1,nargin));
if ischar(typeSpec)
  % Simple string
  if size(typeSpec,1) ~= 1
    str = sprintf('UNHANDLED_columnVector');
  else
    str = sprintf('''%s''',typeSpec);
  end
elseif iscell(typeSpec)
  % A cell array typeSpec
  if isempty(typeSpec)
      str = '{}';
  else
    str = '{';
    for n = 1:length(typeSpec)
      curr = typeSpec{n};
      if ndims(curr) > 2
        str = sprintf('%sUNHANDLED_%dDarray,',str,ndims(curr));
      elseif ~any(size(curr,1) == [0 1])
        % Only row vectors and empty matricies are handled currently
        str = sprintf('%sUNHANDLED_columnVector,',str);
      elseif ischar(curr)
        % Simple string
        str = sprintf('%s''%s'',',str,curr);
      elseif isa(curr,'double')
        if all(isint(curr))
          % No need for extra precision
          str = sprintf('%s[%s],',str,num2str(curr));
        else
          % More precision
          str = sprintf('%s[%s],',str,num2str(curr,15));
        end
      elseif iscell(curr)
        % Recursively handle cell arrays
        str = sprintf('%s%s,',str,typespec2str(curr));
      else
        str = sprintf('%sUNHANDLED_%s,',str,class(curr));
      end
    end
    str(end) = '}';  % Replace last , with closing brace
  end
else
  str = sprintf('UNHANDLED_%s',class(typeSpec));
end

% Modification History:
%
% $Log: typespec2str.m,v $
% Revision 1.4  2005/02/03 16:58:45  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.3  2003/10/22 15:54:40  gadde
% Make some CVS info accessible through variables
%
% Revision 1.2  2003/08/15 18:33:07  crm
% Handle empty cells, strings, and numeric arrays properly.
%
% Revision 1.1  2003/07/31 03:37:07  michelich
% Original
%
