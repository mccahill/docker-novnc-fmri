function char = pnmgetc(fid)
%PNMGETC  Get character from PBM/PGM/PPM file.
%
%   CHAR = PNMGETC(FID) gets the next character from the PBM/PGM/PPM
%   file with file identifier FID. Comments are skipped.

% CVS ID and authorship of this code
% CVSId = '$Id: pnmgetc.m,v 1.3 2005/02/03 16:58:35 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:35 $';
% CVSRCSFile = '$RCSfile: pnmgetc.m,v $';

[ char, count ] = fscanf( fid, '%c', 1 );
if ( count == 0 )
   fclose( fid );
   error( 'File ended while reading.' );
end

if ( char == '#' )
   nl = sprintf('\n');
   cr = sprintf('\r');
   while ( ( char ~= nl ) & ( char ~= cr ) )
      [ char, count ] = fscanf( fid, '%c', 1 );
      if ( count == 0 )
         fclose( fid );
         error( 'File ended while reading.' );
      end
   end
end

% Modification History:
%
% $Log: pnmgetc.m,v $
% Revision 1.3  2005/02/03 16:58:35  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:36  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/08/27 22:24:17  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% 1997-09-02 14:47:19  Peter J. Acklam <jacklam@math.uio.no>
