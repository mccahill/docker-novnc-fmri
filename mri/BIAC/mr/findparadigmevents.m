function [events,colBin,eventBin,eventsPerBin,uniqueBin,binnames,eventsPerUBin]=findparadigmevents(paradigmFile,columns,standardValue)
%FINDPARADIGMEVENTS - Interpret paradigm file
%
%  MATLAB function which reads paradigm file and parses out the 
%  location and type of trials.
%
%  [events,colBin,eventBin,eventsPerBin]=findparadigmevents(paradigmFile,columns)
%  [events,colBin,eventBin,eventsPerBin,uniqueBin,binnames,eventsPerUBin]=findparadigmevents(paradigmFile,columns)
%  [events,colBin,eventBin,eventsPerBin]=findparadigmevents(paradigmFile,columns,standardValue)
%  [events,colBin,eventBin,eventsPerBin,uniqueBin,binnames,eventsPerUBin]=findparadigmevents(paradigmFile,columns,standardValue)
% 
%    paradigmFile - filename of paradigm file
%    columns - array of columns to interpret in the paradigm file
%    standardValue - Optional: value of standards in paradigm file, default = 0
%
%    events = time points each event occurs at
%    colBin = column each event occurs at
%    eventBin = event bin occuring at each event
%    eventsPerBin = number of events within each bin
%                   eventsPerBin(:,1) => number of events within each bin
%                   eventsPerBin(:,2) => bin number 
%    uniqueBin = like eventBin, but appends column number to bin number to make
%                events in different columns with same bin number unique.  Is a
%                cell array of strings. 
%    binnames = list that relates the bin number (int) to the bin name (string) that
%               describes it.  
%    eventsPerUBin = number of events within each unique bin
%                    cell array of strings, with number of unique bins followed
%                    by unique bin string name.  

% CVS ID and authorship of this code
% CVSId = '$Id: findparadigmevents.m,v 1.3 2005/02/03 16:58:39 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:39 $';
% CVSRCSFile = '$RCSfile: findparadigmevents.m,v $';

% Check inputs
error(nargchk(2,3,nargin));
if ~exist(paradigmFile,'file')
   error(sprintf('Paradigm file %s does not exist!',paradigmFile));
end
colSize = size(columns);
if colSize(1)~=1 & colSize(2)~=1
   error('Array of columns must be a vector');
end
if nargin<3
   standardValue = 0;
end

% Calculate the number of columns to read
numColumns = length(columns);

% Load paradigm file
% Old way - paradigm=load(paradigmFile,'-ascii'); changed 2001/7/12 by Bizzell
[paradigm binnames] = readparadigm(paradigmFile);

% Check if paradigm columns are in paradigm file
for i=1:numColumns
   if columns(i) > size(paradigm,2) | columns(i) < 1
      error(sprintf('Column %d requested is not in paradigm file!',columns(i)));
   end
end

%--- Create an array for events, bin for each event, and column for 
%    each event ---
events = [];
colBin = [];
eventBin = [];
% Loop through all requested columns in paradigm file
for i=1:numColumns
   % Find all non-zero terms in the paradigm file
   eventTmp = find(paradigm(:,columns(i))~=standardValue);
   events = [events; eventTmp ];
   colBin = [colBin; columns(i)*ones([length(eventTmp) 1])];
   eventBin = [eventBin; paradigm(eventTmp,columns(i))];
end

%--- Determine the number of bins and events within each bin --- 
% Sort the bins
sortedBin = sort(eventBin);
% Initialize counting variables
n = 1;    % index in sortedBin
bin = 1;  % bin number
while n  <= length(sortedBin)
   % Find all events in current bin
   currBin = find(sortedBin == sortedBin(n));
   % Determine number of events in current bin
   eventsPerBin(bin,1) = length(currBin);
   % Label the bin number 
   eventsPerBin(bin,2) = sortedBin(n);
   % Move the sortedBin index to the next bin
   n = n + eventsPerBin(bin,1);
   % Increment the bin counter
   bin=bin+1;
end

%--- Create the unique bin array ---
uniqueBin = {};
for i=1:length(events)
   for j=1:length(binnames)
      binstr='';
      if eventBin(i)==binnames{j,1}
         binstr = binnames{j,2}; break;
      end
   end
   if ~isempty(binstr)
      uniqueBin = cat(1,uniqueBin,{binstr});
   else
      error(sprintf('bin %d not defined in paradigm files',eventBin(i)));
   end
end

%--- Determine the number of unique bins and and events within each bin ---
sortedUBin = sort(uniqueBin);
% Initialize counting variables
n = 1;    % index in sortedBin
eventsPerUBin = {};
bin = sortedUBin{1};
bincnt = 0;
eventsPerUBin = {};
while n  <= length(sortedUBin)
   % Find all events in current bin
   if strcmp(sortedUBin{n},bin)
      bincnt = bincnt + 1;
   else
      eventsPerUBin = cat(1,eventsPerUBin,{bincnt sortedUBin{n-1}});
      bin = sortedUBin{n};
      bincnt = 1;
   end
   % Increment the bin counter
   n = n+1;
end
eventsPerUBin = cat(1,eventsPerUBin,{bincnt sortedUBin{n-1}});

% Modification History:
%
% $Log: findparadigmevents.m,v $
% Revision 1.3  2005/02/03 16:58:39  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:37  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/11/06 18:33:49  michelich
% Initial CVS import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2002/11/06. Reformated comments for CVS
%                                Changed function name from readparadigmCol to findparadigmevents 
%                                Changed freadparadigm to readparadigm
% Josh Bizzell,      2001/08/02. Added standardValue input for paradigm files where 0 
%                                is not the bin value for standards.  
% Josh Bizzell,      2001/07/16. EventsPerUBin now a 2-D cell array with bin count in 
%                                first column and unique bin name in second column.
%                                Also, UniqueBin is now a column cell array.  
% Josh Bizzell,      2001/07/12. Now uses function freadparadigm to read the paradigm 
%                                matrix as well as the unique bin names that might be 
%                                defined in the paradigm file.  Added comments.
% Josh Bizzell,      2001/06/26. Added eventPerUBin calculation.
% Josh Bizzell,      2001/06/13. Changed to read in array of columns, instead of just 
%                                one single column from paradigm file.
%                                Added the ability to save bins as unique depending on 
%                                the column number of the event.  
% Adapted from "readparadigm":  Charles Michelich & Gregory McCarthy 2000/08/01
