function facehilo(fname)
%FACEHILO Read PCX file names from fname.  Ouput high- and low-pass filtered versions.
%
%  facehilo;
%  facehilo(fname);
%
%  fname is the name of a file with PCX file names to read.
%    If omitted, you are prompted to pick a file.
%
%  The high-pass filter is a Sobel edge detector.
%  The low-pass filter is an 9x9 average kernel convolution.
%  The fitered files are output into HIGH and LOW subdirectories of the
%    directory where fname is.
%  All PCX file names are interpreted relative to the path of fname.

% CVS ID and authorship of this code
% CVSId = '$Id: facehilo.m,v 1.4 2005/02/03 16:58:33 michelich Exp $';
% CVSRevision = '$Revision: 1.4 $';
% CVSDate = '$Date: 2005/02/03 16:58:33 $';
% CVSRCSFile = '$RCSfile: facehilo.m,v $';

%TODO: Fix bug:
%      If files fname and files are in v:\tmp\FaceHiLo\Pix
%      and facehilo is called with facehilo('Pix\test2.txt');
%      the Pix\test2.txt "exists" and the output will be put 
%      in v:\tmp\FaceHiLo\Pix\Pix\High & Low

if nargin==0, fname=''; end

% Get file, if not specified
if strcmp(fname,'')
  [name,pathname]=uigetfile('*.txt','Select PCX list file');
  if name==0, return, end                                       % User hit Cancel button.
  fname=fullfile(pathname,name);
  clear name pathname
end

% Open file and get PCX file names
if ~exist(fname,'file'),error(sprintf('File %s does not exist!',fname)); end
fid=fopen(fname);               % Don't use 'rt'; it breaks fgetl!
[pcxFiles,n]=getstrs(fid);
fclose(fid);

% Make output directories
outPathHigh = fullfile(fileparts(fname),'High');
[status,emsg]=makedir(outPathHigh);
if ~status, error(emsg), end

outPathLow = fullfile(fileparts(fname),'Low');
[status,emsg]=makedir(outPathLow);
if ~status, error(emsg), end

% Operate on each image
for i=1:n
  pcxFiles(i)={lower(pcxFiles{i})};
  disp(pcxFiles{i});

	% Filter input image
	[imgIn,map]=imread(fullfile(fileparts(fname),pcxFiles{i}),'pcx');
	imgIn=ind2gray(imgIn,map);
	imgLow=filter2(fspecial('average',9),imgIn);
  % imgHigh must be a non-logical double array.
  % Use double() to convert from uint8 class in MATLAB 6.1
  %                       & from logical class in MATLAB 6.5
  % Use unary plus to remove logical flag in MATLAB 6.1
	imgHigh= +double(edge(imgIn,0.05,'sobel'));
  imgMean=mean(imgIn(:));
	i0=find(imgHigh==0);
	imgHigh(i0)=ones(length(i0),1)*imgMean;        % Replace black background with mean intensity
  if imgMean>0.5
  	i1=find(imgHigh==1);
  	imgHigh(i1)=zeros(length(i1),1);             % Replace white foreground with black
  end

	% Output filtered images
	[pcxOut,map]=gray2ind(imgLow,256);
	map(1,:)=[0 0 0];
	map(2,:)=[1 1 1];
	map(3,:)=[80/255 80/255 80/255];
	imwrite(pcxOut,map,fullfile(outPathLow,pcxFiles{i}),'pcx');
	[pcxOut,map]=gray2ind(imgHigh,256);
	map(1,:)=[0 0 0];
	map(2,:)=[1 1 1];
	map(3,:)=[80/255 80/255 80/255];
  imwrite(pcxOut,map,fullfile(outPathHigh,pcxFiles{i}),'pcx');
end

% Modification History:
%
% $Log: facehilo.m,v $
% Revision 1.4  2005/02/03 16:58:33  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.3  2003/10/22 15:54:35  gadde
% Make some CVS info accessible through variables
%
% Revision 1.2  2002/10/24 21:25:19  michelich
% Revision 1.1 does NOT work in MATLAB 5.3 or later
%   (pcxread2 and pcxwrit2 are broken).
% Use imread and imwrite instead of pcxread2 and pcxwrit2.
% - Note that .pcx will NOT be automatically added to
%   filenames without extensions using imread.
% Use fullfile to construct filenames.
% Automatically make output directories.
% Use pathname to open pcx files instead of changing the directory.
% Added exist check before attempting to open fname.
% Corrected low-pass filter size in comments
% Bug fix: Determine path for fname passed as an argument.
% Bug fix: Don't use path as a variable name.
% Bug fix: Fixed class & logical flag for imgHigh returned
%   by edge().  imgHigh must be a non-logical double array.
% Tested against an example in \\Broca\Source\MATLAB\BIAC\FaceHiLo\Pix.
%   All low-pass images were identical.
%   6 of 10 high-pass images were different with an average
%   of 13 pixels different (0.012%) in each of the six images
%   using MATLAB 6.1 & 6.5.  Testing on MATLAB 5.3 yielded
%   similar performance, but output images were not identical
%   to MATLAB 6.1 & 6.5.  Presumably the differences are due
%   to changes in the edge() function between MATLAB versions.
%   Qualitatively, all results look good.
%
% Revision 1.1  2002/10/24 18:27:11  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2002/10/24. Changed function name to lowercase
%                                Changed getstrs() to lowercase.
%                                Cleaned up comments. 
% Francis Favorini,  1997/07/03. Changed pcxFiles to cell array.
% Francis Favorini,  1997/01/15. Now checks background of high-pass image and
%                                  picks black or white foreground appropriately.
% Francis Favorini,  1997/01/14.

