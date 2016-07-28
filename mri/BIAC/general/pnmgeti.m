function int = pnmgeti(fid)
%PNMGETI  Get integer PBM/PGM/PPM file.
%
%   INT = PNMGETI(FID) gets the next integer from the PBM/PGM/PPM file
%   with file identifier FID. Comments are skipped.

% CVS ID and authorship of this code
% CVSId = '$Id: pnmgeti.m,v 1.3 2005/02/03 16:58:35 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:35 $';
% CVSRCSFile = '$RCSfile: pnmgeti.m,v $';

spc = ' ';
ht  = sprintf( '\t' );
nl  = sprintf( '\n' );
cr  = sprintf( '\r' );

char = spc;     % Initialize to something test will make test true.
while ( char == spc ) | ( char == ht ) | ( char == nl ) | ( char == cr )
   char = pnmgetc( fid );
end

if ( char < '0' ) | ( char > '9' )
   fclose( fid );
   error( 'Junk in file where an integer should be.' );
end

int = 0;
while ( char >= '0' ) & ( char <= '9' )
   int = int * 10 + char - '0';
   char = pnmgetc( fid );
end

% Modification History:
%
% $Log: pnmgeti.m,v $
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
% 1997-09-02 14:47:22  Peter J. Acklam <jacklam@math.uio.no>

