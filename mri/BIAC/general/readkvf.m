function keyvals=readkvf(fName,reqKeys,optKeys)
%READKVF Read keyword/value pair file.
%
%   keyvals=readkvf(fName,reqKeys,optKeys);
%
%   fName is the name of the file to read.
%   keyvals is a structure with fields names set to the keys
%     and values set correspondingly.  Values are strings or
%     cell arrays of strings, if the keyword appears more
%     than once in the file.
%   reqKeys is a cellstr of required keywords.  An error message
%     is displayed if they are not all present.  Default is {}.
%   optKeys is a cellstr of optional keywords.  No error message
%     is displayed if they are not all present.  If one of the
%     strings is '*', no keywords are considered extra.
%     Default is {'*'}.
%
%   Notes:
%   Each line must be in the format: keyword=value
%   Blank lines and those that start with % are ignored.
%   Keywords must be alphanumeric and start with a letter.
%   Whitespace in keywords is ignored.
%   Capitalization is taken from reqKeys & optKeys.
%   Keywords not in reqKeys or optKeys are extra.
%   An error message is displayed if extra keywords are found.
%   Leading/trailing whitespace is trimmed from values.
%   Values may not be empty.

% CVS ID and authorship of this code
% CVSId = '$Id: readkvf.m,v 1.3 2005/02/03 16:58:35 michelich Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2005/02/03 16:58:35 $';
% CVSRCSFile = '$RCSfile: readkvf.m,v $';

lasterr('');
emsg='';
try

kvfid=-1;
keyvals=[];
error(nargchk(1,3,nargin));
if nargin<2, reqKeys={}; end
if nargin<3, optKeys={'*'}; end

goodKeys=[reqKeys(:); optKeys(:)];
[kvfid emsg]=fopen(fName,'rt');
if kvfid==-1, emsg=sprintf('Error opening %s!\n%s',fName,emsg); error(emsg); end
l=0;
while 1
  line=fgetl(kvfid);
  if ~isempty(line) & line==-1, break; end  % Don't check for -1 (eof) using == if line is blank
  l=l+1;
  if ~all(isspace(line)) & index(trim(line),1)~='%'  % Ignore blank lines and those that start with %
    eqls=findstr(line,'=');
    if isempty(eqls), emsg=sprintf('Missing "=" on line %d in %s.',l,fName); error(emsg); end
    if length(eqls)>1, emsg=sprintf('Extra "=" on line %d in %s.',l,fName); error(emsg); end
    key=line(1:eqls-1);
    if any(isspace(key))
      key(isspace(key))=[];                          % Ignore whitespace in keywords
    end
    if isempty(key), emsg=sprintf('Missing keyword before "=" on line %d in %s.',l,fName); error(emsg); end
    badChars=~isletter(key) & ~(key>='0' & key<='9');
    if any(badChars)
      emsg=sprintf('Non-alphanumeric character(s) found in keyword on line %d in %s.',l,fName); error(emsg);
    end
    if ~isletter(key(1))
      emsg=sprintf('Keyword must start with a letter on line %d in %s.',l,fName); error(emsg);
    end
    val=trim(line(eqls+1:end));                      % Trim leading/trailing whitespace from value
    if isempty(val), emsg=sprintf('Missing value after "=" on line %d in %s.',l,fName); error(emsg); end
    % Try to find key in required/optional keys, and use its case for field name
    k=find(strcmpi(key,goodKeys));
    if ~isempty(k), key=goodKeys{k}; end
    if ~isfield(keyvals,key)
      % New key gets new field
      keyvals=setfield(keyvals,key,val);
    else
      % Already seen this key, so convert field to cellstr
      oldval=getfield(keyvals,key);
      if ~iscellstr(oldval), oldval={oldval}; end
      keyvals=setfield(keyvals,key,cat(1,oldval,{val}));
    end
  end
end
fclose(kvfid); kvfid=-1;

% Check for missing and extra keys in keyvals
missKeys=setdiff(char(reqKeys(:)),char(fieldnames(keyvals)),'rows');
if ~isempty(missKeys)
  emsg=sprintf('Missing keywords from file %s:\n%s',fName,strlist(missKeys));
  error(emsg);
end
if ~any(strcmp('*',optKeys(:)))
  extraKeys=setdiff(char(fieldnames(keyvals)),char(goodKeys),'rows');
  if ~isempty(extraKeys)
    emsg=sprintf('Extra keywords in file %s:\n%s',fName,strlist(extraKeys));
    error(emsg);
  end
end

catch
  if kvfid~=-1, fclose(kvfid); end
  if isempty(emsg)
    if isempty(lasterr)
      emsg='An unidentified error occurred!';
    else
      emsg=lasterr;
    end
  end
  error(emsg);
end

% Modification History:
%
% $Log: readkvf.m,v $
% Revision 1.3  2005/02/03 16:58:35  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.2  2003/10/22 15:54:36  gadde
% Make some CVS info accessible through variables
%
% Revision 1.1  2002/08/27 22:24:18  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Charles Michelich, 2001/01/23. Changed function name to lowercase.
% Charles Michelich, 2001/04/13. Changed end of file check to check for a blank line before checking for eof
%                                BUG was: 'Warning: Future versions will return empty for empty == scalar comparisons.' 
% Francis Favorini,  1998/11/10. More verbose error messages for keywords/values.
% Francis Favorini,  1998/11/06. Use strlist.
% Francis Favorini,  1998/11/04. Ignore lines that start with %.
% Francis Favorini,  1998/10/30. Added reqKeys and optKeys.
% Francis Favorini,  1998/10/27. More verbose error messages.
% Francis Favorini,  1998/10/19.
