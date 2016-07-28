function orthomr(img,params,slicePlane,cube)
%ORTHOMR Generate other 2 orthogonal volumes from specified MR volume.
%
%   ORTHOMR(img,params,slicePlane)
%   ORTHOMR(img,params,slicePlane,cube)
%
%   img is the name of the MR image volume.
%   params is a cell array of the readmr parameters (except fName).
%   slicePlane is the slice plane of the input series ('axial','coronal','sagittal').
%     Only the first letter is checked, and case is insignificant.
%   cube is true if you want the output series to be cubic.
%     Default is false.
%
%   Notes:
%     If the input format is 'volume', the output will be too.
%       Otherwise the output is 'float'.
%     The output file names will be the input file name prefixed with
%       'Axial_', 'Coronal_' or 'Sagittal_'
%
%   Examples:
%   >>orthomr('V0001.img',{64,64,35,'float'},'a')
%   >>orthomr('V0017.img',{128,128,45,'volume'},'cor')

% CVS ID and authorship of this code
% CVSId = '$Id: orthomr.m,v 1.3 2005/02/03 16:58:40 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:40 $';
% CVSRCSFile = '$RCSfile: orthomr.m,v $';

error(nargchk(3,4,nargin));
if nargin<4, cube=0; end

if strcmpi(params{4},'volume')
  outFmt='volume';
else
  outFmt='float';
end

vol=readmr(img,params{:});
if cube, vol=cubesrs(vol); end
[fpath,fname,fext]=fileparts(img);
if upper(slicePlane(1))=='A'
  % Axial: X=Lat, Y=AP, Z=Vert
  writemr(fullfile(fpath,['Coronal_' fname fext]),permute(vol,[1 3 2]),outFmt);   % Axial->Coronal
  writemr(fullfile(fpath,['Sagittal_' fname fext]),permute(vol,[2 3 1]),outFmt);  % Axial->Sagittal
elseif upper(slicePlane(1))=='C'
  % Coronal: X=Lat, Y=Vert, Z=AP
  writemr(fullfile(fpath,['Axial_' fname fext]),permute(vol,[1 3 2]),outFmt);     % Coronal->Axial
  writemr(fullfile(fpath,['Sagittal_' fname fext]),permute(vol,[3 2 1]),outFmt);  % Coronal->Sagittal
elseif upper(slicePlane(1))=='S'
  % Sagittal: X=AP, Y=Vert, Z=Lat
  writemr(fullfile(fpath,['Axial_' fname fext]),permute(vol,[3 1 2]),outFmt);     % Sagittal->Axial
  writemr(fullfile(fpath,['Coronal_' fname fext]),permute(vol,[3 2 1]),outFmt);   % Sagittal->Coronal
else
  error('Unknown slice plane!');
end

% Modification History:
%
% $Log: orthomr.m,v $
% Revision 1.3  2005/02/03 16:58:40  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:37  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/08/27 22:24:22  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2002/01/14. Fixed bug in Sagittal to Axial conversion.
%                                Default to no cubesrs prior to conversion.
% Charles Michelich, 2001/01/23. Changed function name to lowercase.
%                                Changed cubesrs(), writemr() and readmr() to lowercase.
% Francis Favorini,  1999/09/03.
