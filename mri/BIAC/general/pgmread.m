function [X,map] = pgmread(filename)
%PGMREAD  Read a PGM (portable graymap) file from disk.
%
%   [X,MAP] = PGMREAD('FILENAME') reads the file 'FILENAME' and returns
%   the indexed image X and associated colormap MAP.
%
%   I = PGMREAD('FILENAME') reads the file 'FILENAME' and returns the
%   intensity image I.
%
%   If no file extension is given with the filename, the extension
%   '.pgm' is used.
%
%   See also: PGMWRITE, PBMREAD, PBMWRITE, PPMREAD, PPMWRITE.

% CVS ID and authorship of this code
% CVSId = '$Id: pgmread.m,v 1.4 2005/02/03 20:17:46 michelich Exp $';
% CVSRevision = '$Revision: 1.4 $';
% CVSDate = '$Date: 2005/02/03 20:17:46 $';
% CVSRCSFile = '$RCSfile: pgmread.m,v $';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check number of input arguments.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

error( nargchk( 1, 1, nargin ) );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Identify output arguments.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nargsout = nargout;
if ( nargsout == 1 )
   isindexed = 0;
elseif ( nargsout == 2 )
   isindexed = 1;
else
   error( 'Wrong number of output arguments.' );
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check filename.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ( ~ischar( filename ) | isempty( filename ) )
   error( 'File name must be a non-empty string' );
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add extension to file name if necessary.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if isempty( findstr( filename, '.' ) )
   filename = [ filename '.pgm' ];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Open input file for reading.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fid = fopen( filename, 'r' );
if ( fid == -1 )
   error( [ 'Can''t open file "' filename '" for reading.' ] );
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Identify file type.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[ magic, count ] = fscanf( fid, '%c', 2 );      % Read first two bytes.

if ( count < 2 )
   fclose( fid );
   error( [ 'Error reading "' filename '". End of file reached while reading magic number.' ] );
end

if ( magic == 'P1' ) | ( magic == 'P4' )        % Bitmap.
    fclose( fid );
    error( [ '"' filename '" is not a portable graymap.' ] );
%   if isindexed
%      [ X, map ] = pbmread( filename );         % Indexed bitmap.
%   else
%      X = pbmread( filename );                  % Intensity bitmap.
%   end
%   return;

elseif ( magic == 'P2' )                % Ascii encoded graymap.
   isascii = 1;

elseif ( magic == 'P5' )                % Binary encoded graymap.
   isascii = 0;

elseif ( magic == 'P3' ) | ( magic == 'P6' )    % Pixelmap.
   fclose( fid );
   error( [ '"' filename '" is not a portable graymap.' ] );

else
   fclose( fid );
   error( [ '"' filename '" is not a portable graymap.' ] );

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read image size and maximum pixel value.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cols   = pnmgeti( fid );        % Number of columns.
rows   = pnmgeti( fid );        % Number of rows.
maxval = pnmgeti( fid );        % Maximum pixel value.
pixels = rows*cols;             % Total number of pixels in image.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read image data.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if isascii
   [ data, count ] = fscanf( fid, '%i', pixels );
else
   [ data, count ] = fread( fid, pixels, 'uint8' );
end

fclose( fid );                  % Close file.

if ( count < pixels )
   disp( [ 'Warning: End of file in "' filename '" reached too early.' ] );
end

if isindexed                    % Indexed graymap.

   X = zeros( cols, rows );     % Initialize index matrix.
   X(1:count) = data;           % Fill data into matrix.
   X = X' + 1;                  % Map [0,maxval] to [1,maxval+1].

   map = [0:maxval]'/maxval;    % Create grayscale vector.
   map = map(:,ones(1,3));      % Convert to RGB colour map.

else                            % Intensity graymap.

   X = zeros( cols, rows );     % Initialize intensity matrix.
   X(1:count) = data;           % Fill read data into matrix.
   X = X'/maxval;               % Map values to [0,1] interval.

end

% Modification History:
%
% $Log: pgmread.m,v $
% Revision 1.4  2005/02/03 20:17:46  michelich
% M-Lint: Replace deprecated isstr with ischar.
%
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
% 1999-05-24 14:42:00  Francis Favorini <francis.favorini@duke.edu>
%   Better error reporting.  Commented out PBM and PPM options.
% 1998-01-25 16:00:35  Peter J. Acklam <jacklam@math.uio.no>
