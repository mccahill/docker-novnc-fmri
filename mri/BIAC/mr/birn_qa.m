function results=birn_qa(series_name, timepoints, slice)
% birn_qa(series_name, timepoints, slice)
%
% Performes quality assurance measures on phantom data
%   series_name is the name of a bxh_file for the timeseries
%     of data
%   timepoints is an array of the timepoints on which to compute
%     the statistics (default is all timepoints, empty uses default)
%   slice is the slice number on which to compute the statistics
%     (default is middle slice, empty uses default)


%	To perform a quantitation of snr, sfnr, stability and drift
%	includes weisskoff plot  MRM 36:643 (1996)
%


%	acq: 35	slice 64x64 TR 3.0 TE 30 (3T) 40 (1.5T) 200 frames
%	grecons -s 18 -e 18 Pxxxxx


% TODO: Return salient values
% TODO: Make displaying graphics and writing images optional.

% CVS ID and authorship of this code
% CVSId = '$Id: birn_qa.m,v 1.16 2005/02/03 16:58:37 michelich Exp $';
CVSRevision = '$Revision: 1.16 $';
CVSDate = '$Date: 2005/02/03 16:58:37 $';
% CVSRCSFile = '$RCSfile: birn_qa.m,v $';

error(nargchk(1,3,nargin));

% Analysis options
writeImagesFlag = 1; % For testing.

% --- Verify Input parameters ---
% Check to see if series name is valid
if ~exist(series_name,'file')
  error(sprintf('The file %s does not exist',series_name));
end

% Read the info for specified series
mrinfo = readmr(series_name, '=>INFOONLY');

% Verify the series is 4D x,y,z,t
if length(mrinfo.info.dimensions) ~= 4
  error(sprintf('Input series %s must be 4D!',series_name));
end
if ~isequal({mrinfo.info.dimensions.type},{'x','y','z','t'})
  error(sprintf('Input series %s must have x,y,z,t dimensions!',series_name));
end

% Set defaults
if nargin < 3 | isempty(slice)
  slice = ceil(mrinfo.info.dimensions(3).size/2); % Use middle slice by default
end
if nargin < 2 | isempty(timepoints)
  timepoints = [1:mrinfo.info.dimensions(4).size]; % Use all time points by default
end

% Spatial SNR assumes an even number of points
if mod(length(timepoints),2) == 1
  error('You must analyze an even number of time points!');
end

% Read TR [Repetition Time] from header if possible
% TODO: This is only used to label one of the axes on the summary graphs. Perhaps read it then?
if strcmp(mrinfo.info.hdrtype,'BXH')
  [TR,code] = xpathquery(mrinfo.info.hdr,'/bxh/acquisitiondata/tr');
else
  code = NaN;  % Not a BXH header, so just set a code ~= 1 for below.
end
if code ~= 1
  TR = 3000;  % Default to TR = 3000 msec
  warning(sprintf('Unable to read TR from image header.  Using default value TR = %g msec!',TR));
end
TR = TR/1000; % Convert TR to units of seconds
clear code

% Construct base file name
fkern = series_name(1:end-4);

% Get sizes (why just 2D???)
imgSz = [mrinfo.info.dimensions(1:2).size];
if imgSz(1) ~= imgSz(2)  % TODO: Why???  npo2 & R assume imgSz is equal at the moment
  error('x & y dimensions must be the same size!');
end
nTimePts = length(timepoints);   % Number of time frames

% --- Create ROI ----
% TODO: Handle this more robustly.
if(imgSz(1) == 128)
  R = 30;			% ROI width
else
  R = 15;			% probably 64x64
end
npo2 = imgSz(1)/2;
r1 = 1;
r2 = R;

% Create a mask from the largest ROI
mask = repmat(logical(0),imgSz);
X1 = npo2 - fix(R/2);
mask(X1:X1+R-1,X1:X1+R-1) = logical(1);  % Mask of complete ROI
clear X1

% TODO: Implement this
% check for phase images and make base complex image
% BEGIN REWRITE BLOCK A (ORIG)
% I1 = 3403;		% first image
% I2 = 3600;		% last image
% fname = sprintf('%s.%03dp',fkern, i1);
% fid = fopen(fname, 'r');
% if(fid > 0) 
%   numwin = 4;
%   [buf, n] = fread(fid, 'short');
%   fclose(fid);
%   img(:) = buf;
%   phase1 = img*.001;
%   base = exp(i*phase1);
%   TE = .001*input('gimme TE (ms) = ');
% else
%   numwin = 3;
% end
% END REWRITE BLOCK A (ORIG)
numwin = 3;

% Initialize arrays
roi = zeros(1,nTimePts);        % ROI mean for each time point (largest radius)
roir = zeros(nTimePts,r2-r1+1); % ROI mean for each time point and radius
Syy = zeros(imgSz);             % Sum Squared image (across time)
Syt = zeros(imgSz);             % Sum Image*t image (across time)

% Check if we have enough memory to read all of the data at once:
singleRead=1;
try
  tmp1=zeros([imgSz, length(slice), nTimePts]); % Full data array
  tmp2=zeros([imgSz, length(slice), 6]); % Intermediate variables (estimate)
catch
  singleRead=0;
end
clear('tmp1','tmp2');

if singleRead
  % Read in the whole time series
  imgStruct = readmr(mrinfo, {[], [], slice, timepoints});
  infoTemplate = imgStruct.info;  % Save .info struct template

  % Calculate some images
  Iodd = sum(imgStruct.data(:,:,:,1:2:end),4);   % Sum of even images
  Ieven = sum(imgStruct.data(:,:,:,2:2:end),4);  % Sum of odd images

  % Note: Could also calculate Syy & Syt here in a single line but it would
  % require at least three copies of the full array so lets just do it by
  % time point for the now.
else
  % Read in first two time points for template .info struct
  tmp = readmr(mrinfo, {[], [], slice, timepoints(1:2)},'NOPROGRESSBAR');
  infoTemplate = tmp.info;
  clear tmp

  % Just initialize the arrays for calculation as images are read
  Iodd = zeros(imgSz);
  Ieven = zeros(imgSz);
end

% --- Perform calculations on each time point ---
for n = 1:nTimePts
  if singleRead
    % Grab current time point
    img = imgStruct.data(:,:,:,n);
  else
    % Read current time point
    img = readmr(mrinfo, {[], [], slice, timepoints(n)},'NOPROGRESSBAR');
    img = img.data;
    
    % Calculate sum even and odd images
    if mod(n,2) == 1
      Iodd = Iodd + img;
    else
      Ieven = Ieven + img;
    end
  end

  % Calculate Sum img.*t & Sum squared images
  Syt = Syt + img.*timepoints(n);
  Syy = Syy + img.^2;
  
  % Calculate the mean in each ROI size
  roi(n) = mean(img(mask));
  for r = r1:r2                 % each roi size
    x1 = npo2 - fix(r/2);
    sub = img(x1:x1+r-1,x1:x1+r-1);
    roir(n, r) = mean(sub(:));
  end
end
clear imgStruct

% Cleanup any temporary files
readmr(mrinfo, '=>CLEANUP');

% --- Calculate stat images (mean, difference, std, sfnr) ---
Isub = Iodd - Ieven;      % Difference image
Sy = Iodd + Ieven;        % Sum image
Iave = Sy/nTimePts;       % Average image
clear Iodd Ieven

% Calculate Std Dev image (after linear detrend???)
% TODO: Figure out this calculation.
% Calculate easy stuff
S0 = length(timepoints);
St = sum(timepoints);
Stt = sum(timepoints.^2);
% find trend line at + b
D = (Stt*S0 - St*St);
a = (Syt*S0 - St*Sy)/D;
b = (Stt*Sy - St*Syt)/D;
% make sd image
Isd = sqrt((Syy + a.*a*Stt + b.*b*S0 + 2*a.*b*St - 2*a.*Syt - 2*b.*Sy)./(nTimePts-1));
clear Syy Syt Sy S0 St Stt D a b % Clear intermediate variables

% Calculate sfnr image
sfnr = Iave./(Isd + eps); % sfnr image

% TODO: Implement this
% for n = 1:nTimePts
%   if(numwin == 4)		% do the phase
%     fname = sprintf('%s.%03dp', fkern, j);
%     fprintf('read %s ...\n', fname);
%     fid = fopen(fname, 'r');
%     [buf, n] = fread(fid, 'short');
%     fclose(fid);
%     img(:) = buf;
%     phase = img*.001;
%     img1 = exp(i*phase);
%     z = img1./base; 
%     phi = atan2(imag(z), real(z));
%     freq = phi/(2*pi*TE);
%     roip(timepoints(n)-i1+1) = mean(freq(mask));
%   end
% end
% 
% % write out last freq drift image
% if (numwin==4)
%   fname = sprintf('%s.freq', fkern); 
%   fout = fopen(fname, 'w');
%   fwrite(fout, 10*freq(:), 'short');
%   fprintf('\nwrite file %s\n', fname);
%   fclose(fout);
% end

% --- Write output images if requested ---
if writeImagesFlag
  % --- Make output template ---
  out.info = infoTemplate;
  out.info.dimensions(4) = [];
  out.info.outputelemtype = 'int16';  % Why??  Use float32 instead??
  
  % Add a history entry
  if all(diff(timepoints)==1)
    timePtsString = sprintf('[%d:%d]',timepoints(1),timepoints(end));
  else
    timePtsString = sprintf('[%d%s]',timepoints(1),sprintf(',%d',timepoints(2:end)));
  end
  historyEntry = sprintf('birn_qa(''%s'',%s,%d)\n(birn_qa %s%s)',series_name, ...
    timePtsString, slice, CVSRevision(2:end-1), CVSDate(8:end-2));
  out = addHistoryEntry(out,historyEntry);
  
  % Write difference image
  out.data = Isub;
  writemr(out, sprintf('%s_nave.bxh', fkern), 'BXH', 'OVERWRITE');
  
  % Write average image
  out.data = Iave;
  writemr(out, sprintf('%s_ave.bxh', fkern), 'BXH', 'OVERWRITE');
  
  % Write standard deviation image
  out.data = 10.*Isd;  % TODO: Why scale instead of saving as float
  writemr(out, sprintf('%s_sd.bxh', fkern), 'BXH', 'OVERWRITE');

  % Write sfnr image
  out.data = 10.*sfnr; % TODO: Why scale instead of savings as float
  writemr(out, sprintf('%s_sfnr.bxh', fkern), 'BXH', 'OVERWRITE');
  
  clear out
end

% --- Calculate and display summary values ---
varI = var(Isub(mask));
meanI = mean(Iave(mask));
sfnrI = mean(sfnr(mask));
snr = meanI/sqrt(varI/nTimePts);

% Get amplifier gains & frequency, if available
fid = fopen([fkern,'.pfh'],'r','b');
if (fid ~= -1)
  % Read MPS R1, R2, TG, AX.
  status = fseek(fid, 412, -1);
  if status == -1, error(ferror(fid)); end
  [buf,count] = fread(fid,4,'int32');
  if count ~= 4, error('Unable to read R1, R2, TG, AX!'); end
  R1 = buf(1);
  R2 = buf(2);
  TG = buf(3);
  % TODO: For some reason, the old code added 65536 to freq if lower
  % 16-bits of freq was negative.  I have removed this for the time being.
  freq = buf(4).*0.1;
  clear buf
  fclose(fid);
  summaryString = sprintf('mean, SNR, SFNR = %5.1f  %5.1f  %5.1f\nR1, TG, freq= %d  %d  %9.0f', meanI, snr, sfnrI, R1, TG, freq);
else
  R1 = NaN; R2 = NaN; TG = NaN; freq = NaN;
  summaryString = sprintf('mean, SNR, SFNR = %5.1f  %5.1f  %5.1f', meanI, snr, sfnrI);  
end

% Display summary
disp(summaryString);

% Return results for testing code
% TODO: Add more relevant values from graphing section
results = struct( ...
  'Isub',Isub,'Iave',Iave,'Isd',Isd,'sfnr',sfnr, ... % Output images
  'roi',roi,'roir',roir, ... % ROI by radius means
  'sfnrI',sfnrI,'meanI',meanI,'varI',varI,'snr',snr, ... % Summary values
  'R1',R1,'R2',R2,'TG',TG,'freq',freq, ... % Prescan values
  'fkern',fkern,'nTimePts',nTimePts,'TR',TR,'numwin',numwin,'r1',r1,'r2',r2); % Additional variables used in graphing section

% Clear all variables that we no longer need (for code clarity & ease of testing)
vars2keep = {'fkern','roi','roir','nTimePts','TR','numwin','r1','r2','summaryString','results'};
vars2clear = setxor(who,vars2keep);
clear(vars2clear{:},'vars2clear');

% --- Generate and display summary figure ---
% TODO: Clean up this section

% Create a figure window of the approrpriate size
figure('Position', [1 1 600 800],'DefaultTextInterpreter','none');


%  Do fluctation analysis

x=[1:nTimePts];
p=polyfit(x,roi,2);
yfit = polyval(p, x);
y = roi - yfit;

subplot(numwin,1,1)
plot(x,roi,x,yfit);
xlabel('frame num');
ylabel('Raw signal');
grid
m=mean(roi);
sd=std(y);
drift = (yfit(nTimePts)-yfit(1))/m;
title(sprintf('%s   percent fluct (trend removed), drift= %5.2f %5.2f', fkern, 100*sd/m, 100*drift));

fprintf('std, percent fluc, drift = %5.2f  %6.2f %6.2f \n', sd, 100*sd/m, 100*drift);

% Add these addition results to output structure
results.std = sd;
results.percentFluc = 100*sd/m;
results.drift = 100*drift;

z = fft(y);
fs = 1/TR;
nf = nTimePts/2+1;
f = 0.5*(1:nf)*fs/nf;
subplot(numwin,1,2);plot(f, abs(z(1:nf)));grid
ylabel('spectrum');
xlabel('frequency, Hz');
ax = axis;
text(ax(2)*.1, ax(4)*.8, summaryString);

%  now do analysis for each roi size

t = [1:nTimePts];
for r = r1:r2
  y = roir(:, r)';
  yfit = polyval(polyfit(t, y, 2), t);  % 2nd order trend
  F(r) = std(y - yfit)/mean(yfit);
end
rr = [r1:r2];
F = 100*F;              % percent
fcalc = F(1)./rr;
rdc = F(1)/F(r2);	% decorrelation distance

subplot(numwin,1,3);
loglog(rr, F, '-x', rr, fcalc, '--');
grid
xlabel('ROI full width, pixels');
ylabel('Relative std, %');
axis([r1 r2 .01 1]);
text(6, 0.5, 'solid: meas   dashed: calc');
text(6, 0.25, sprintf('rdc = %3.1f pixels',rdc));

if(numwin==4)
  subplot(numwin,1,4);
  plot(x,roip)
  xlabel('frame num');
  ylabel('freq drift, Hz');
  grid
end

%--------------------------------------------------
function newmrstruct = addHistoryEntry(mrstruct,historyEntry)
%ADDHISTORYENTRY - Add BXH history entry to mrstruct
%
% newmrstruct = addHistoryEntry(mrstruct,historyEntry);
%

% Add a empty BXH header if necessary (no changes made if already BXH)
newmrstruct = convertmrstructtobxh(mrstruct);

% Determine how many history entries already exist (if any).
numEntries = 0;
if isfield(newmrstruct.info.hdr.bxh{1},'history')
  numEntries = length(newmrstruct.info.hdr.bxh{1}.history{1}.entry);
end

% Add the history entry
newmrstruct.info.hdr.bxh{1}.history{1}.entry{numEntries+1}.date{1}.VALUE = datestr(now,31);
newmrstruct.info.hdr.bxh{1}.history{1}.entry{numEntries+1}.description{1}.VALUE = historyEntry;

% Modification History:
%
% $Log: birn_qa.m,v $
% Revision 1.16  2005/02/03 16:58:37  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.15  2004/07/23 16:07:54  gadde
% Use correct output type field name.
%
% Revision 1.14  2004/02/03 23:26:59  michelich
% Require an even number of time points. (SNR calculation assumes this!)
%
% Revision 1.13  2004/01/16 19:11:15  michelich
% Use defaults for empty timepoints and slice.
%
% Revision 1.12  2004/01/09 16:04:46  michelich
% Added CVS revision information to BXH history entry.
%
% Revision 1.11  2004/01/05 22:57:12  michelich
% Added prescan settings and fluctuation analysis results to output structure.
%
% Revision 1.10  2003/11/04 01:42:28  michelich
% No need to remove TR from cell (xpathquery fixed).
%
% Revision 1.9  2003/10/14 14:59:23  gadde
% Fix xpathquery call
%
% Revision 1.8  2003/09/23 23:10:47  michelich
% Rewrote main processing loop:
% - Use matrices instead of vectors when processing images.
% - If there is not enough memory to read all time points at once, read one at a time.
% - Vectorize calculation of Ieven and Iodd images.
%
% Revision 1.7  2003/09/23 22:55:39  michelich
% Read TR from header if possible.
% Removed extra code and added comments.
% Read R1,TG,AX outside of figure generation section.
%
% Revision 1.6  2003/09/23 22:40:41  michelich
% Separated calculation of images, calculation of ROI stats, and writing images to disk.
% Added BXH history entry when writing results.
% Added flag to disable writing images to disk.
%
% Revision 1.5  2003/09/23 22:20:36  michelich
% Fixed reading R1,TG,AX (read .pfh, big-endian, only read relevant fields).
% Require that x & y sizes be the same & require x,y,z,t dimension order.
% General code cleanup (simplify, remove unnecessary variables & code, etc).
% - Rename variables to more descriptive names.
% - Remove more off & on statement.
% - Use logical mask instead of using sub & X1,X2,Y1,Y2.
% - Vectorize St, Stt, S0 calculations.
% - Use exist & nargchk instead of fopen & usage.
%
% Revision 1.4  2003/09/23 20:37:00  michelich
% Added cvs history entries from old revisions.
%
% Revision 1.3  2003/09/23 20:35:04  michelich
% Set DefaultTextInterpreter for proper display of path separators on Windows.
% Added results return structure for testing results of different code versions.
% Added CVS Modificaiton History.
%
% Revision 1.2  2003/09/22 17:36:35  gadde
% writemrtest => writemr
%
% Revision 1.1  2003/08/25 20:39:06  gadde
% Commit the BIRN QA script, as modified by Beau to read BXH headers.
%
% Pre CVS History Entries:
%	rev 4	4/1/03		for fbirn
%	rev 3	1/28/03		add phase drift plot 
%				.freq image is scaled 10x
%	rev 2	9/4/02		add weissnoise plot
%	rev 1	3/29/02		fix a few header things
%	rev 0	3/3/00		original from noiseave and imgroi
