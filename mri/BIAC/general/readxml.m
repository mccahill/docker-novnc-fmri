function xmlret = readxml(varargin)
%READXML XML reader, using libxml2 or java DOM.
%
%   xml = readxml(xmlfilename)
%   xml = readxml(xmlfilename, [stringpaths...])
%   xml = readxml(xmlfilename, namespacestruct, [stringpaths...])
%
% Converts an XML file into a MATLAB struct.  Each XML element is
% represented by a struct.  If the element has any children, the
% struct will contain fields labeled by the name of the child
% element, and each field's value will be a cell array containing
% (recursively constructed) representations of all the child elements
% with the same name.
%
% If the XML element has any attributes, these are stored in the
% special field 'ATTRS', which has a cell array containing
% representations of all the attributes.
%
% If any XML element or attribute has text content, this is stored
% as a string in the special field 'VALUE'.  If this value can be
% parsed as a double-precision floating point number, it will be
% stored as a double instead of a string.  To disable this behavior
% on particular nodes, send any number of XPath expressions as arguments
% to readxml; nodes that match these paths will not be converted.  To
% disable this behavior on all nodes, use the XPath expression '//*|//@*'
% (other equivalent XPath expressions will work, but this path is matched
% explicitly by the non-compiled version of readxml, and so is faster).
%
% Any namespace prefixes used in the XPath expressions must be defined
% in 'namespacestruct', which is a structure mapping namespace prefixes
% to URIs.
%
% An example XML file 'myfile.xml':
%  <myxml>
%   <elem1 attr1="freddled">
%    <subelem attr2="gruntbuggly">subelemcontent</subelem>
%   </elem1>
%   <elem2>42</elem2>
%   <elem2>49</elem2>
%  </myxml>
%
% Sample code to convert it in MATLAB:
%  xml = readxml('myfile.xml');
%
% The value of the second 'elem2' element (49) is:
%  xml.myxml{1}.elem2{2}.VALUE
%
% The value of the 'subelem' attribute 'attr2' (gruntbuggly) is:
%  xml.myxml{1}.elem1{1}.ATTRS.attr2.VALUE
%
% To force the numbers in 'elem2' elements to be strings:
%  xml = readxml('myfile.xml', '/myxml/elem2');
%
% To force only the second one to be a string:
%  xml = readxml('myfile.xml', '/myxml/elem2[2]');

% Author: Syam Gadde (gadde@biac.duke.edu)

% CVSId = '$Id: readxml.m,v 1.17 2006/09/25 15:06:35 gadde Exp $';
% CVSRevision = '$Revision: 1.17 $';
% CVSDate = '$Date: 2006/09/25 15:06:35 $';
% CVSRCSFile = '$RCSfile: readxml.m,v $';

% This function is also implemented as a MEX file.

[majorVer, minorVer] = strtok(strtok(version),'.');
majorVer = str2double(majorVer);
minorVer = str2double(strtok(minorVer,'.'));
if majorVer < 6 | (majorVer == 6 & minorVer < 5)
  errmsg = 'For Matlab versions earlier than 6.5 (R13), you need to compile the MEX file readxml.c (requires libxml2, and is much faster)';
  error(errmsg);
else
  warning('readxml:compile', sprintf('You are using the non-compiled version of readxml which is very slow.\nIf you have libxml2 available, please consider compiling readxml.c.'));
end
clear majorVer minorVer

try
  props = java.lang.System.getProperties;
catch
  errmsg = '.m version of readxml requires Java, which is not enabled.  Otherwise you will need to compile the MEX file readxml.c (requires libxml2, but does not require Java, and is much faster)';
  error(errmsg);
end

if nargin < 1
  errmsg = 'Not enough arguments!'; error(errmsg);
end

if ~ischar(varargin{1})
  errmsg = 'First argument must be a filename!'; error(errmsg);
end

xmlfilename = varargin{1};
nsdecls = [];
if nargin > 1 & isstruct(varargin{2})
  nsdecls = varargin{2};
end
if isempty(nsdecls)
  stringpaths = varargin(2:end);
else
  stringpaths = varargin(3:end);
end

numpaths = length(stringpaths);
for pathnum = 1:numpaths
  stringpath = stringpaths{pathnum};
  if ~ischar(stringpath)
    errmsg = 'All arguments must be strings!'; error(errmsg);
  end
end

numconvert = 1;
if any(strmatch('//*|//@*', stringpaths, 'exact'))
  numconvert = 0;
  stringpaths = {};
end

domdoc = xmlread(xmlfilename);

if isempty(domdoc)
  errmsg = sprintf('Error parsing XML file %s!', xmlfilename); error(errmsg);
end

stringnodes = parseXPaths(stringpaths, domdoc, nsdecls);
numstringnodes = length(stringnodes);

% convert DOM Node recursively to struct
xmlret = [];
nsmap = [];
nsmap.xmlns = 'http://www.w3.org/2000/xmlns/';
queue = { { 'xmlret', domdoc, nsmap } };
while length(queue) > 0
  % shift one element off queue
  [ structname, node, nsmap ] = deal(queue{1}{:});
  queue(1) = [];

  rank = 0;

  structcopy = eval(structname);

  XML_ELEMENT_NODE = 1;
  XML_ATTRIBUTE_NODE = 2;
  XML_TEXT_NODE = 3;
  XML_PI_NODE = 4;
  XML_CDATA_SECTION_NODE = 7;
  XML_COMMENT_NODE = 8;
  XML_DOCUMENT_NODE = 9;

  nodetype = node.getNodeType;

  if ~any(nodetype == [XML_ELEMENT_NODE XML_ATTRIBUTE_NODE XML_TEXT_NODE XML_PI_NODE XML_CDATA_SECTION_NODE XML_DOCUMENT_NODE])
    return
  end

  % addAttributes
  if node.hasAttributes
    if isfield(structcopy, 'ATTRS')
      errmsg = 'Invalid tag ATTRS in XML file!'; error(errmsg);
    end
    if isfield(structcopy, 'NSDEFS')
      errmsg = 'Invalid tag NSDEFS in XML file!'; error(errmsg);
    end
    attrscopy = [];
    nsdefscopy = [];
    domattrs = node.getAttributes;
    attrs = struct('ns', {}, 'localname', {}, 'value', {});
    % do some preprocessing (and parse namespace attrs while we're at it)
    for attrnum = 1:domattrs.getLength
      domattr = domattrs.item(attrnum-1);
      attrname = cindex(cell(domattr.getNodeName),1); % quick char conv
      attrvalue = cindex(cell(domattr.getNodeValue),1); % quick char conv
      colonpos = findstr(attrname, ':');
      attrprefix = '';
      if ~isempty(colonpos)
        attrprefix = attrname(1:colonpos-1);
        attrname(1:colonpos) = [];
      end
      if isempty(attrprefix) & strcmp(attrname, 'xmlns')
        if isfield(nsdefscopy, 'DEFAULT')
          warning(sprintf('Repeated instances of default namespace %s ignored.', attrname));
          continue
        end
        if isempty(attrvalue)
          % xmlns="" -- default namespace is unset 
          if isfield(nsmap, 'DEFAULT')
            nsmap = rmfield(nsmap, 'DEFAULT')
          end
        else
          nsdefscopy.DEFAULT = attrvalue;
          nsmap = setfield(nsmap, 'DEFAULT', attrvalue);
        end
        continue
      end
      attrns = [];
      % no default namespace for attributes
      if ~isempty(attrprefix)
        if isfield(nsmap, attrprefix)
          attrns = getfield(nsmap, attrprefix);
        end
      end
      if strcmp(attrns, 'http://www.w3.org/2000/xmlns/')
        if isfield(nsdefscopy, attrname)
          warning(sprintf('Repeated instances of namespace %s ignored.', attrname));
          continue
        end
        nsdefscopy = setfield(nsdefscopy, attrname, attrvalue);
        nsmap = setfield(nsmap, attrname, attrvalue);
        continue
      end
      attrnum = length(attrs) + 1;
      attrs(attrnum).domnode = domattr;
      attrs(attrnum).ns = attrns;
      attrs(attrnum).localname = attrname;
      attrs(attrnum).value = attrvalue;
    end
    % now do non-nsdecl attrs
    for attrnum = 1:length(attrs);
      domattr = attrs(attrnum).domnode;
      attrns = attrs(attrnum).ns;
      attrname = attrs(attrnum).localname;
      attrvalue = attrs(attrnum).value;
      if isfield(attrscopy, attrname)
        oldattr = getfield(attrscopy, attrname);
        if ~isempty(oldattr) && strcmp(attrns, getfield(oldattr, 'NAMESPACE'))
          warning(sprintf('Repeated instances of attribute %s ignored.', attrname));
          continue
        end
      end
      if numconvert & ~isempty(attrvalue)
        keepstring = 0;
        for strnnum = 1:numstringnodes
          if domattr.equals(stringnodes(strnnum))
            keepstring = 1;
            break
          end
        end
        if ~keepstring
          attrvalue = convertNum(attrvalue);
        end
      end
      if isempty(attrns)
        attrscopy = setfield(attrscopy, attrname, struct('VALUE', {attrvalue}));
      else
        attrscopy = setfield(attrscopy, attrname, struct('VALUE', {attrvalue}, 'NAMESPACE', {attrns}));
      end
    end
    if ~isempty(attrscopy)
      structcopy.ATTRS = attrscopy;
    end
    if ~isempty(nsdefscopy)
      structcopy.NSDEFS = nsdefscopy;
    end
  end

  % addNamespace
  if nodetype ~= XML_DOCUMENT_NODE
    if isfield(structcopy, 'NAMESPACE')
      errmsg = 'Invalid tag NAMESPACE in XML file!'; error(errmsg);
    end
    prefix = node.getPrefix;
    structcopy.NAMESPACE = [];
    if isempty(prefix)
      if isfield(nsmap, 'DEFAULT')
        structcopy.NAMESPACE = nsmap.DEFAULT;
      end
    else
      if isfield(nsmap, prefix)
        structcopy.NAMESPACE = getfield(nsmap, prefix);
      end
    end
  end

  % addText
  content = getNodeContent(node);
  if numconvert & ~isempty(content)
    keepstring = 0;
    for strnnum = 1:numstringnodes
      if node.equals(stringnodes(strnnum))
        keepstring = 1;
        break
      end
    end
    if ~keepstring
      content = convertNum(content);
    end
  end
  if ~isempty(content)
    if isfield(structcopy, 'VALUE')
      errmsg = 'Invalid tag VALUE in XML file!'; error(errmsg);
    end
    structcopy.VALUE = content;
    if nodetype == XML_ELEMENT_NODE
      if isfield(structcopy, 'VALUECHILDRANK')
        errmsg = 'Invalid tag VALUECHILDRANK in XML file!'; error(errmsg);
      end
      rank = rank + 1;
      structcopy.VALUECHILDRANK = rank;
    end
  end

  % addChildren
  childnodelist = node.getChildNodes;
  for childnum = 0:childnodelist.getLength-1;
    childnode = childnodelist.item(childnum);

    childtype = childnode.getNodeType;

    % will take care of these in a later pass
    if any(childtype == [XML_TEXT_NODE XML_CDATA_SECTION_NODE])
      continue
    end

    childname = cindex(cell(childnode.getNodeName),1); % quick char conv

    colonpos = findstr(childname, ':');
    if ~isempty(colonpos)
      childname(1:colonpos) = [];
    end

%    {childname, childtype, childcontent}

    if childtype == XML_PI_NODE
      childcontent = cindex(cell(childnode.getNodeValue),1); % quick char conv
      if ~isfield(structcopy, 'PINSTS')
        structcopy.PINSTS = {};
      end
      rank = rank + 1;
      structcopy.PINSTS{end+1} = { childname, childcontent, rank };
      continue
    elseif childtype == XML_COMMENT_NODE
      childcontent = cindex(cell(childnode.getNodeValue),1); % quick char conv
      if length(childcontent) >= 8 & strcmp(childcontent(1:8), 'AUTOGEN:')
        continue;
      end
      if ~isfield(structcopy, 'COMMENTS')
        structcopy.COMMENTS = struct('VALUE', {}, 'CHILDRANK', {});
      end
      rank = rank + 1;
      structcopy.COMMENTS(end+1) = struct('VALUE', { childcontent }, 'CHILDRANK', {rank});
      continue
    end

    if strcmp(childname, 'PINSTS')
      errmsg = 'Invalid tag PINSTS in XML file!'; error(errmsg)
    end
    if strcmp(childname, 'COMMENTS')
      errmsg = 'Invalid tag COMMENTS in XML file!'; error(errmsg);
    end

    newchild = [];
    rank = rank + 1;
    newchild.CHILDRANK = rank;
    cells = {};
    if isfield(structcopy, childname)
      eval(['cells = structcopy.' childname ';']);
    end
    cells{end+1} = newchild;
    eval(['structcopy.' childname ' = cells;']);
    queue{end+1} = {[structname '.' childname '{' num2str(length(cells)) '}'], childnode, nsmap};
  end

  eval([structname ' = structcopy;']);
end

if isfield(xmlret, 'BASE')
  errmsg = 'Invalid tag BASE in XML file!';
  error(errmsg);
end
xmlret.BASE = xmlfilename;

return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function content = getNodeContent(node)

contentobj = java.lang.String;
contentlen = 0;
precdatalen = NaN;
postcdatalen = 0;
trimbegin = 1;
minlen = 0;

childnodelist = node.getChildNodes;
numchildren = childnodelist.getLength;
for childnum = 0:numchildren-1;
  childnode = childnodelist.item(childnum);

  childtype = childnode.getNodeType;
  if childtype ~= 3 & childtype ~= 7 % neither TEXT nor CDATA
    continue
  end

  childcontentobj = childnode.getNodeValue;
  childcontentlen = childcontentobj.length;
  contentobj = contentobj.concat(childcontentobj);
  contentlen = contentlen + childcontentlen;
  if childtype == 7 % CDATA
    if isnan(precdatalen)
      precdatalen = contentlen;
    end
    postcdatalen = 0;
  else
    postcdatalen = postcdatalen + childcontentlen;
  end
end

% see if we can trim space from beginning and/or end
if contentlen == 0
  % no content
  content = '';
elseif isnan(precdatalen)
  % no CDATA, so trim both sides
  content = cindex(cell(contentobj.trim),1); % quick char conv
elseif precdatalen == 0
  if postcdatalen == 0
    % CDATA at both ends, don't trim
    content = cindex(cell(contentobj),1); % quick char conv
  else
    % CDATA at beginning, just trim end
    notrimlen = contentlen - postcdatalen;
    content = cindex(cell(contentobj.substring(0, notrimlen).concat(java.lang.String('*').concat(contentobj.substring(notrimlen)).trim.substring(1))),1);
  end
else
  % we need to trim beginning
  prestrobj = contentobj.substring(0, precdatalen).concat(java.lang.String('*')).trim;
  prestrlen = prestrobj.length;
  if postcdatalen == 0
    % CDATA at end, so don't trim end
    content = cindex(cell(prestrobj.substring(0,prestrlen-1).concat(contentobj.substring(precdatalen))),1);
  else
    % CDATA in middle, trim end too
    notrimlen = contentlen - postcdatalen;
    content = cindex(cell(prestrobj.substring(0,prestrlen-1).concat(contentobj.substring(precdatalen, notrimlen)).concat(java.lang.String('*').concat(contentobj.substring(notrimlen)).trim.substring(1))),1);
  end
end
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function newcontent=convertNum(content)

% simple check to get rid of common case
if isempty(content) | isletter(content(1))
  newcontent = content;
  return
end
spaces = isspace(content);
tmpcontent = content;
tmpcontent(spaces) = sprintf('\n');
strs = splitstr(tmpcontent);
nums = str2double(strs');
if ~any(isnan(nums))
  newcontent = nums;
else
  newcontent = content;
end
return


% $Log: readxml.m,v $
% Revision 1.17  2006/09/25 15:06:35  gadde
% Update help message.
%
% Revision 1.16  2006/07/18 21:51:20  gadde
% Moved XPath code out into parseXPaths.m
%
% Revision 1.15  2006/06/27 19:43:53  gadde
% Fix several XPath bugs.
%
% Revision 1.14  2005/02/22 20:18:24  michelich
% Use more robust version parsing code.
%
% Revision 1.13  2005/02/03 20:23:10  michelich
% M-Lint: Replace deprecated setstr with char.
%
% Revision 1.12  2005/02/03 16:58:35  michelich
% Changes based on M-lint:
% Make unused CVS variables comments for increased efficiency.
% Remove unnecessary semicolon after function declarations.
% Remove unnecessary commas after try, catch, and else statements.
%
% Revision 1.11  2004/07/30 19:43:22  gadde
% Fix potential bug
%
% Revision 1.10  2004/07/19 21:07:52  gadde
% Fix some typos and make sure longer tokens are matched before shorter ones
% (i.e. '//' vs. '/').
%
% Revision 1.9  2004/05/06 14:46:50  gadde
% Replace all uses of strfind with findstr (strfind doesn't exist before
% Matlab 6.1).
%
% Revision 1.8  2004/04/16 17:25:55  gadde
% Don't iterate over raw cell arrays in for statements.
%
% Revision 1.7  2004/04/14 17:58:38  gadde
% Fix version check.
%
% Revision 1.6  2004/04/14 16:10:09  gadde
% Add log message.
%
