function [pMatrix,binnames]=readparadigm(paradigmFile,standardValue)
%READPARADIGM Read a paradigm file
%  
%  [pMatrix,binnames]=readparadigm(paradigmFile)
%  [pMatrix,binnames]=readparadigm(paradigmFile,standardValue)
%
%  paradigmFile
%  standardValue - Optional:  default = 0

% CVS ID and authorship of this code
% CVSId = '$Id: readparadigm.m,v 1.4 2005/02/03 16:58:42 michelich Exp $';
% CVSRevision = '$Revision: 1.4 $';
% CVSDate = '$Date: 2005/02/03 16:58:42 $';
% CVSRCSFile = '$RCSfile: readparadigm.m,v $';

% TODO:  Add better comments.  

lasterr('');
emsg='';
try
    
    fid = -1;
    %keyvals=[];
    error(nargchk(1,2,nargin));
    if nargin<2, standardValue = 0; end
    %if nargin<2, reqKeys={}; end
    %if nargin<3, optKeys={'*'}; end
    
    %goodKeys=[reqKeys(:); optKeys(:)];
    
    % Initialize some variables
    pMatrix=[];
    binnames={};
    nameType = 'noNamesDef';
    
    [fid emsg]=fopen(paradigmFile,'rt');
    if fid==-1, emsg=sprintf('Error opening %s!\n%s',paradigmFile,emsg); error(emsg); end
    
    % Get value from first line
    while 1
        line=fgetl(fid);
        if ~all(isspace(line)) & index(trim(line),1)~='%'  % Ignore blank lines and those that start with %
            if strncmp(line, 'binnames', 8)
                nameType = 'NamesDef'; break; 
            elseif ~isempty(str2num(line))
                nameType = 'noNamesDef'; break;
            else
                emsg=sprintf('First line of paradigm file, %s, must be an integer or "binnames ="!',paradigmFile); 
                error(emsg); break;
            end
        end 
    end
    
    switch nameType
    case 'noNamesDef'
        % Load paradigm file
        pMatrix=load(paradigmFile,'-ascii');
        
    case 'NamesDef'
        frewind(fid)
        %l=0;
        defMatrix = 0;
        binsDefined = [];
        while 1
            line=fgetl(fid);
            % Future versions of Matlab will not allow empty == scalar comparisons
            if ~isempty(line)
                if line==-1, break; end
            end
            %l=l+1;
            if ~all(isspace(line)) & index(trim(line),1)~='%'  % Ignore blank lines and those that start with %
                if strncmp(line, 'matrix', 6)
                    defMatrix = 1;
                elseif defMatrix==0 & ~strncmp(line,'binnames',8)
                    % call the inline function, line2cell, defined below
                    linecell = line2cell(line);
                    binsDefined = [binsDefined linecell{1}];
                    binnames = cat(1,binnames,{linecell{1} linecell{2}});
                elseif defMatrix==1
                    pMatrix = [pMatrix; str2num(line)];
                else
                    %do nothing
                end
            end
        end	% while
    end	% case 'Names'
    
    % Create string binnames for all bins in file
    numCol = size(pMatrix,2);
    allBins = [];
    binTemp = [];
    colBin = [];
    for i=1:numCol
        %binTemp = pMatrix(find(pMatrix(:,i)),i);
        binTemp = pMatrix(:,i);
        allBins = [allBins; binTemp];
        colBin = [colBin; i*ones([length(binTemp) 1])];
    end
    if length(allBins) ~= length(colBin)
        error('array of bins and array of column numbers is unequal!');
    end
    
    uniqueBin = {};
    % Create the unique bin array
    for i=1:length(allBins)
        % Call the inline function, uniqueBinCol, defined below
        tempBinStr = uniqueBinCol(allBins(i),colBin(i));
        if numCol == 1
            uniqueBin = {uniqueBin{:} tempBinStr(1:4)};
        else
            uniqueBin = {uniqueBin{:} tempBinStr};   
        end
    end
    
    %--- Determine the bins and what integer each corresponds to --- 
    % Sort the bins
    sortedUBin = sort(uniqueBin);
    % Initialize counting variables
    n = 1;    % index in sortedBin
    bin = sortedUBin{1};
    binsPerUBin = {};
    while n  <= length(sortedUBin)
        % Find all events in current bin
        if strcmp(sortedUBin{n},bin)
        else
            tempstr = sortedUBin{n-1};
            binsPerUBin = {binsPerUBin{:}, str2num(tempstr(2:4)), tempstr};
            bin = sortedUBin{n};
        end
        % Increment the bin counter
        n = n+1;
    end
    tempstr = sortedUBin{n-1};
    binsPerUBin = {binsPerUBin{:}, str2num(tempstr(2:4)), tempstr};
    
    switch nameType
    case 'noNamesDef'
        for i=1:2:(length(binsPerUBin)-1)
            binnames = cat(1,binnames,{binsPerUBin{i}, binsPerUBin{i+1}});
        end
        
    case 'NamesDef'
        for i=1:2:(length(binsPerUBin)-1)
            if isempty(find(binsDefined==binsPerUBin{i}))
                binnames = cat(1,binnames,{binsPerUBin{i}, binsPerUBin{i+1}});
                if binsPerUBin{i} ~= standardValue
                    warning(sprintf('readparadigm - Bin value %d not defined, defining as "%s"', binsPerUBin{i}, binsPerUBin{i+1}));
                end
            end
        end
    end
    
    fclose(fid); fid=-1;
    
catch
    if fid~=-1, fclose(fid); end
    if isempty(emsg)
        if isempty(lasterr)
            emsg='An unidentified error occurred!';
        else
            emsg=lasterr;
        end
    end
    error(emsg);
end


%----------------------------------------------------
% Create a cell array from a line of a paradigm file represented as a 
% string that includes the number, as an integer, and the name, as a 
% string, of the particular bin defined on that line.  
% Example:  line = '1 blue' would return the cell array {[1] 'blue'}
function bincell = line2cell(line)
linelen = length(line);
bincell = {};
num='';
name='';
afterspace = 0;
for i=1:linelen
    if isspace(line(i)) & ~isempty(num)
        afterspace = 1;
    elseif afterspace == 1 & ~isspace(line(i))
        name = strcat(name,line(i));
    else
        num = strcat(num, line(i));
    end
end
bincell = {str2num(num), name};


%----------------------------------------------------
% Create a unique 6 character string from bin and column values.  
% Format is 'bzzzcyy' where 'zzz' represents bin and 'yy' represents column.
% e.g. Bin = 4, Column = 2 would return 'b004c02'
function strout = uniqueBinCol(binVal, colVal)
% Check the input arguments 
error(nargchk(2,2,nargin));
if binVal > 999 | binVal < 0
    error(sprintf('Invalid bin value: %d\n',binVal));
end
if colVal > 99
    error(sprintf('Invalid column value: %d\n',colVal));
end
% Add zeros to string if numbers are too short
if floor(binVal/100) > 0
    binStr = sprintf('%d', binVal);
elseif floor(binVal/10) > 0
    binStr = sprintf('0%d', binVal);
else
    binStr = sprintf('00%d', binVal);
end
if floor(colVal/10) > 0
    colStr = sprintf('%d', colVal);
else
    colStr = sprintf('0%d', colVal);
end
strout = strcat('b',binStr,'c',colStr);

% Modification History:
%
% $Log: readparadigm.m,v $
% Revision 1.4  2005/02/03 16:58:42  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.3  2003/10/22 15:54:38  gadde
% Make some CVS info accessible through variables
%
% Revision 1.2  2002/11/06 18:54:45  michelich
% Corrected function name in error message
%
% Revision 1.1  2002/11/06 18:33:49  michelich
% Initial CVS import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2002/11/06. Reformated comments for CVS
%                                Changed function name from freadparadigm to readparadigm.
% Josh Bizzell,      2001/12/03. Fixed statement that compared an empty string returned
%                                by "fgetl" to -1 (end of file) for future versions
%                                of Matlab so warning would not print.  
% Josh Bizzell,      2001/08/02. Added return of 0 as a possible binname, for the 
%                                cases when 0 does not represent the "standard" 
%                                values.  Doesn't warn if standard not defined, but
%                                still assigns a unique bin name.  
% Josh Bizzell,      2001/06/28. Created by Josh Bizzell.  Adapted from function "readKVF".  
