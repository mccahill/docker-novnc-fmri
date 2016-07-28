function matchnodes=parseXPaths(inpaths, domcontextnode, nsdecls)
%PARSEXPATHS  XPath evaluator, for DOM nodes
%
%   matchnodes = parseXPaths(inpaths, domcontextnode)
%   matchnodes = parseXPaths(inpaths, domcontextnode, nsdecls)
%
% Returns all nodes that match any of the XPath expressions passed
% as a cell array of one or more strings (inpaths), using a DOM node
% (domcontextnode) as the context node, and with the namespace mappings
% provided as an optional struct (nsdecls) with keys being the namespace
% prefixes and values being the namespace URIs.

% Author: Syam Gadde (gadde@biac.duke.edu)

% CVSId = '$Id: parseXPaths.m,v 1.3 2006/09/25 15:06:14 gadde Exp $';
% CVSRevision = '$Revision: 1.3 $';
% CVSDate = '$Date: 2006/09/25 15:06:14 $';
% CVSRCSFile = '$RCSfile: parseXPaths.m,v $';

global errmsg;

error(nargchk(2,3,nargin));

if nargin < 3
  nsdecls = struct([]);
end

if ~iscellstr(inpaths)
  errmsg = sprintf('Error: first argument must be cell array of strings!\n');
  error(errmsg);
end
if ~isstruct(nsdecls)
  errmsg = sprintf('Error: third argument must be a struct!\n');
  error(errmsg);
end
matchnodes = [];
contextnode = createXPathNode(domcontextnode);
context = struct('node', contextnode, 'position', 1, 'size', 1, 'vars', [], 'nsdecls', nsdecls);
tokenpaths = convertXPaths(inpaths);
numpaths = length(tokenpaths);
for pathnum = 1:numpaths
  tokenpath = tokenpaths{pathnum};
  errmsg = '(no errors reported)';
  [mend, mobj] = xpparseExpr(tokenpath, 1, context);
  if mend == 0
    errmsg = ['Error parsing Expr in XPath string "' tokenpath.value sprintf('"\n') errmsg];
    error(errmsg);
  elseif mend ~= length(tokenpath)
    errmsg = sprintf(['Garbage at end of XPath: "' tokenpath(mend+1:end).value '".\nPossible errors:\n' errmsg]);
    error(errmsg);
  elseif ~strcmp(mobj.type, 'node-set')
    errmsg = sprintf(['XPath "' tokenpath.value '" doesn''t return a node-set.\nPossible errors:\n' errmsg]);
    error(errmsg);
  end
  numnodes = length(mobj.value);
  if numnodes > 0
    for valnum=1:length(mobj.value)
      matchnodes = [ matchnodes mobj.value(valnum).data.domnode ];
    end
  end
end
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% An XPath node is a structure with the fields xptype and data.
% xptype may be 'element', 'attribute', 'text', 'processing-instruction',
% 'text', 'comment', 'root', 'namespace'.
% If xptype is 'namespace', then data is a struct with the fields
% domparent (pointing to the parent element's DOM node), prefix
% and uri (the prefix and URI for this namespace declaration).
% For any other xptype, data is a struct containing the
% field domnode, which points to the DOM node corresponding to
% this XPath node.
% Nodes with xptype 'element' or 'attribute' have the following
% additional fields:
%   localname
%   prefix
%   nsuri
% Nodes with xptype 'element' have the following additional fields:
%   defaultns
%   nsdecls
% All of these fields are set automatically if you use createXPathNode,
% createXPathNodeNS, getXPathNodeChildren and getXPathNodeAttributes.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function xpnode=createXPathNode(domnode)
xptype = '';
domtype = domnode.getNodeType;
switch domtype
 case 1
  xptype = 'element';
 case 2
  xptype = 'attribute';
 case 3
  xptype = 'text';
 case 4
  xptype = 'processing-instruction';
 case 7
  xptype = 'text';
 case 8
  xptype = 'comment';
 case 9
  xptype = 'root';
 otherwise
  errmsg = ['Context nodes of DOM type ' num2str(domtype) ' not supported'];
  error(errmsg);
end
if domtype == 1 | domtype == 2  % element or attribute
  nsdecls = struct([]);
  % create in-scope nsdecls
  defaultns = [];
  curdomnode = [];
  if domtype == 1 % element
    curdomnode = domnode.getParentNode;
  else % attribute
    curdomnode = domnode.getOwnerElement;
  end
  ancestors = struct('xptype', {}, 'data', {});
  while ~isempty(curdomnode)
    ancestors(end+1) = curdomnode;
    curdomnode = curdomnode.getParentNode;
  end
  while length(ancestors) > 0
    curdomnode = ancestors(end);
    ancestors(end) = [];
    nnm = curdomnode.getAttributes;
    nnmlen = nnm.getLength;
    for attrnum=0:nnmlen-1;
      attr = nnm.item(attrnum);
      attrname = attr.getName;
      attrvalue = attr.getValue;
      if strmatch('xmlns', attrname)
        if length(attrname) == 5
          defaultns = attrvalue;
        elseif length(attrname) >= 6 & attrname(6) == ':'
          nsdecls = setfield(nsdecls, attrname(7:end), attr.getValue);
        end
      end
    end
  end
  xpnode = createXPathNodeNS(domnode, defaultns, nsdecls);
else
  xpnode = struct('xptype', xptype, 'data', struct('domnode', domnode));
end
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function xpnode=createXPathNodeNS(domnode, defaultns, nsdecls)
xptype = '';
domtype = domnode.getNodeType;
switch domtype
 case 1
  xptype = 'element';
 case 2
  xptype = 'attribute';
 case 3
  xptype = 'text';
 case 4
  xptype = 'processing-instruction';
 case 7
  xptype = 'text';
 case 8
  xptype = 'comment';
 case 9
  xptype = 'root';
 otherwise
  errmsg = ['Context nodes of DOM type ' num2str(domtype) ' not supported'];
  error(errmsg);
end
if domtype == 1 % element
  nnm = domnode.getAttributes;
  nnmlen = nnm.getLength;
  for attrnum=0:nnmlen-1;
    attr = nnm.item(attrnum);
    attrname = cindex(cell(attr.getName),1); % quick char conv
    attrvalue = cindex(cell(attr.getValue),1); % quick char conv
    if strmatch('xmlns', attrname)
      if length(attrname) == 5
        % default namespace
        defaultns = attrvalue;
      elseif length(attrname) >= 6 & attrname(6) == ':'
        nsdecls = setfield(nsdecls, attrname(7:end), attrvalue);
      end
    end
  end
end
if domtype == 1 | domtype == 2  % element or attribute
  prefix = [];
  localname = cindex(cell(domnode.getNodeName),1); % quick char conv
  comps = splitstr(localname, ':');
  if length(comps) > 1
    prefix = comps{1};
    localname = comps{2};
  end
  nsuri = [];
  if isempty(prefix)
    if domtype == 1 % default namespace only applies to elements
      nsuri = defaultns;
    end
  elseif isfield(nsdecls, prefix)
    nsuri = getfield(nsdecls, prefix);
  end
  if domtype == 1
    xpnode = struct('xptype', xptype, 'data', struct('domnode', domnode, 'localname', localname, 'prefix', prefix, 'nsuri', nsuri, 'defaultns', defaultns, 'nsdecls', nsdecls));
  else
    xpnode = struct('xptype', xptype, 'data', struct('domnode', domnode, 'localname', localname, 'prefix', prefix, 'nsuri', nsuri));
  end
else
  xpnode = struct('xptype', xptype, 'data', struct('domnode', domnode));
end
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function nodelist=getXPathNodeChildren(xpnode)
nodelist = struct('xptype', {}, 'data', {});
isroot = 0;
if strcmp(xpnode.xptype, 'root')
  isroot = 1;
end
if ~isroot & ~strcmp(xpnode.xptype, 'element')
  return
end
defaultns = [];
nsdecls = [];
if ~isroot
  defaultns = xpnode.data.defaultns;
  nsdecls = xpnode.data.nsdecls;
end
domnodelist = xpnode.data.domnode.getChildNodes;
listlen = domnodelist.getLength;
for nodenum = 0:listlen-1
  curdomnode = domnodelist.item(nodenum);
  nodelist(end+1) = createXPathNodeNS(curdomnode, defaultns, nsdecls);
end
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function nodelist=getXPathNodeAttributes(xpnode)
nodelist = struct('xptype', {}, 'data', {});
if ~strcmp(xpnode.xptype, 'element')
  return
end
defaultns = xpnode.data.defaultns;
nsdecls = xpnode.data.nsdecls;
nnm = xpnode.data.domnode.getAttributes;
nnmlen = nnm.getLength;
for attrnum=0:nnmlen-1;
  domattr = nnm.item(attrnum);
  attrname = cindex(cell(domattr.getName),1); % quick char conv
  % skip namespace nodes
  if strmatch('xmlns', attrname) & (length(attrname) < 6 | attrname(6) == ':'), continue; end
  nodelist(end+1) = createXPathNodeNS(domattr, defaultns, nsdecls);
end
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function outnodes=uniqueXPathNodes(innodes)
inlen = length(innodes);
if inlen == 1 | inlen == 0, outnodes = innodes; return; end
types = {innodes.xptype};
[utypes, m2u, u2m] = unique(types);
% These statements hold:
%  utypes == types(m2u)
%  types  == utypes(u2m)
numutypes = length(utypes);
delthese = [];
for utypenum = 1:numutypes
  minds = find(u2m == utypenum);
  % minds now stores the original indices of all nodes whose type
  % matches utypes(utypenum).
  % Go through each node of this type and see what subsequent nodes
  % have the same data
  numminds = length(minds);
  while numminds > 0
    val1 = innodes(minds(1)).data;
    mmatches = [];
    for mindnum2 = 2:numminds
      val2 = innodes(minds(mindnum2)).data;
      if isequal(val1, val2)
        mmatches(end+1) = mindnum2;
      end
    end
    % Add all matches to the delthese array and remove from the
    % current match array (so we don't search through them again)
    nummmatches = length(mmatches);
    delthese(end+1:end+nummmatches) = minds(mmatches);
    minds = minds(setdiff(1:numminds, [ 1 mmatches ]));
    numminds = numminds - nummmatches - 1;
  end
end
outnodes = innodes(setdiff(1:inlen, delthese));
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function nodelist=getNodesOnAxis(contextnode, axisname)
% contextnode is an XPath node
nodelist = struct('xptype', {}, 'data', {});
xptype = contextnode.xptype;
if strcmp(xptype, 'namespace')
  % special case -- only XPath node that doesn't wrap a DOM node
  switch axisname
   case 'parent'
    nodelist = struct('xptype', 'element', 'data', struct('domnode', contextnode.data.domparent));
    return
   case {'attribute','child','descendant','descendant-or-self','following-sibling','namespace','preceding-sibling'}
    % empty
    return
   case {'following','preceding'}
    contextnode = struct('xptype', 'element', 'data', struct('domnode', contextnode.data.domparent));
    % fall through
  end
end
% at this point context node is guaranteed to wrap a DOM node
% (i.e. it's not a XPath namespace node)
switch axisname
 case 'child'
  nodelist = getXPathNodeChildren(contextnode);
 case 'descendant'
  queue = [contextnode];
  while ~isempty(queue)
    curnode = queue(1);
    queue(1) = [];
    children = getNodesOnAxis(curnode, 'child');
    nodelist(end+1:end+length(children)) = children;
    queue(end+1:end+length(children)) = children;
  end
 case 'parent'
  if strcmp(xptype, 'attribute')
    nodelist = createXPathNode(contextnode.data.domnode.getOwnerElement);
  else
    nodelist = createXPathNode(contextnode.data.domnode.getParentNode);
  end
 case 'ancestor'
  curnode = getNodesOnAxis(contextnode, 'parent'); % in case contextnode is an attribute
  % now curnode must be an element or document node
  curdomnode = curnode.data.domnode;
  while ~isempty(curdomnode)
    nodelist(end+1) = createXPathNode(curdomnode);
    curdomnode = curdomnode.getParentNode;
  end
 case 'following-sibling'
  curdomnode = contextnode.data.domnode;
  curdomnode = curdomnode.getNextSibling;
  while ~isempty(curdomnode)
    nodelist(end+1) = createXPathNode(curdomnode);
    curdomnode = curdomnode.getNextSibling;
  end
 case 'preceding-sibling'
  curdomnode = contextnode.data.domnode;
  curdomnode = curdomnode.getPreviousSibling;
  while ~isempty(curdomnode)
    nodelist(end+1) = createXPathNode(curdomnode);
    curdomnode = curdomnode.getPreviousSibling;
  end
 case 'following'
  if strcmp(xptype, 'attribute')
    contextnode = createXPathNode(contextnode.nvalue.getOwnerElement);
  end
  nodelist = getNodesOnAxis(contextnode, 'following-sibling');
 case 'preceding'
  if strcmp(xptype, 'attribute')
    contextnode = createXPathNode(contextnode.nvalue.getOwnerElement);
  end
  nodelist = getNodesOnAxis(contextnode, 'preceding-sibling');
 case 'attribute'
  if strcmp(xptype, 'element')
    nodelist = getXPathNodeAttributes(contextnode);
  end
 case 'namespace'
  if strcmp(xptype, 'element')
    nsdecls = contextnode.nsdecls;
    prefixes = fieldnames(nsdecls);
    numprefixes = length(prefixes);
    for prefixnum=1:numprefixes
      prefix = prefixes{prefixnum};
      nodelist(end+1) = struct('xptype', 'namespace', 'data', struct('prefix', {prefix}, 'uri', {getfield(nsdecls, prefix)}, 'domparent', contextnode.data.domnode));
    end
  end
 case 'self'
  nodelist = contextnode;
 case 'descendant-or-self'
  nodelist = getNodesOnAxis(contextnode, 'descendant');
  nodelist(end+1) = contextnode;
 case 'ancestor-or-self'
  nodelist = getNodesOnAxis(contextnode, 'ancestor');
  nodelist(end+1) = contextnode;
end
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [mend, mobj]=xpparseExpr(tokenpath, tokenstart, context)
[mend, mobj] = xpparseOrExpr(tokenpath, tokenstart, context);
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [mend, mobj]=xpparseOrExpr(tokenpath, tokenstart, context)
%[21]    OrExpr    ::=    AndExpr
%   | OrExpr 'or' AndExpr
%disp(['OrExpr: ' tokenpath(tokenstart:end).value]);
[mend, mobj] = xpparseAndExpr(tokenpath, tokenstart, context);
if mend == 0, return; end
tokenpathlen = length(tokenpath);
while mend + 1 <= tokenpathlen & strcmp(tokenpath(mend+1).value, 'or')
  tokenstart = mend+2;
  [mend2, mobj2] = xpparseAndExpr(tokenpath, tokenstart, context);
  if mend2 == 0, return; end
  if ~strcmp(mobj.type, 'boolean')
    mobj.value = xpfunc_boolean(mobj, context);
    mobj.type = 'boolean';
  end
  mend = mend2;
  mobj2.value = xpfunc_boolean(mobj2, context);
  mobj.value = mobj.value | mobj2.value; % do the actual 'or'
end
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [mend, mobj]=xpparseAndExpr(tokenpath, tokenstart, context)
%[22]    AndExpr    ::=    EqualityExpr
%   | AndExpr 'and' EqualityExpr
%disp(['AndExpr: ' tokenpath(tokenstart:end).value]);
[mend, mobj] = xpparseEqualityExpr(tokenpath, tokenstart, context);
if mend == 0, return; end
tokenpathlen = length(tokenpath);
while mend + 1 <= tokenpathlen & strcmp(tokenpath(mend+1).value, 'and')
  tokenstart = mend+2;
  [mend2, mobj2] = xpparseEqualityExpr(tokenpath, tokenstart, context);
  if mend2 == 0, return; end
  if ~strcmp(mobj.type, 'boolean')
    mobj.value = xpfunc_boolean(mobj, context);
    mobj.type = 'boolean';
  end
  mend = mend2;
  mobj2.value = xpfunc_boolean(mobj2, context);
  mobj.value = mobj.value & mobj2.value; % do the actual 'and'
end
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [mend, mobj]=xpparseEqualityExpr(tokenpath, tokenstart, context)
%[23]    EqualityExpr    ::=    RelationalExpr
%   | EqualityExpr '=' RelationalExpr
%   | EqualityExpr '!=' RelationalExpr
%disp(['EqualityExpr: ' tokenpath(tokenstart:end).value]);
try [mend, mobj] = xpparseRelationalExpr(tokenpath, tokenstart, context);
catch mend = 0; mobj= [];
end
if mend == 0, return; end
tokenpathlen = length(tokenpath);
cmpop = '';
if mend + 1 <= tokenpathlen
  cmpop = tokenpath(mend+1).value;
end
while mend + 1 <= tokenpathlen & ...
      (strcmp(cmpop, '=') | strcmp(cmpop, '!='))
  tokenstart = mend+2;
  [mend2, mobj2] = xpparseRelationalExpr(tokenpath, tokenstart, context);
  if mend2 == 0, return; end
  mend = mend2;
  % save types
  typea = mobj.type;
  typeb = mobj2.type;
  % If we are comparing a node-set to boolean, convert node-set to boolean.
  % If we are comparing a node-set to anything else, unfold and convert later.
  if strcmp(typea, 'node-set')
    if strcmp(typeb, 'boolean')
      typea = 'boolean';
      mobj = xpfunc_boolean(mobj, context);
    else
      mobj = mobj.value; % unfold
    end
  elseif strcmp(typeb, 'node-set')
    if strcmp(typea, 'boolean')
      typea = 'boolean';
      mobj2 = xpfunc_boolean(mobj2, context);
    else
      mobj2 = mobj2.value; % unfold
    end
  end
  % mobj1 and mobj2 may now be either XPath objects or DOM node arrays (for
  % node-sets)
  flip = 0;
  if strcmp(cmpop, '!='), flip = 1; end
  found = false;
  for obja=mobj
    for objb=mobj2
      % for node set nodes, get string-value
      if strcmp(typea, 'node-set')
        obja = xpfunc_string(struct('type', {'node-set'}, 'value', {obja}), context);
      end
      if strcmp(typeb, 'node-set')
        objb = xpfunc_string(struct('type', {'node-set'}, 'value', {objb}), context);
      end
      % do comparisons
      if strcmp(typea, 'boolean')
        if ~strcmp(typeb, 'boolean')
          objb = xpfunc_boolean(objb, context);
        end
        found = (obja.value == objb.value);
      elseif strcmp(typeb, 'boolean')
        obja = xpfunc_boolean(objb, context);
        found = (obja.value == objb.value);
      elseif strcmp(typea, 'number')
        if ~strcmp(typeb, 'number')
          objb = xpfunc_number(objb, context);
        end
        found = (obja.value == objb.value);
      elseif strcmp(typeb, 'number')
        obja = xpfunc_number(objb, context);
        found = (obja.value == objb.value);
      elseif strcmp(typea, 'string')
        if ~strcmp(typeb, 'string')
          objb = xpfunc_string(objb, context);
        end
        found = strcmp(obja.value, objb.value);
      elseif strcmp(typeb, 'string')
        obja = xpfunc_string(objb, context);
        found = (obja.value == objb.value);
      end
      if flip, found = ~found; end
      if found, break; end
    end
    if found, break; end
  end
  mobj = [];
  mobj.type = 'boolean';
  if found
    mobj.value = true;
  else
    mobj.value = false;
  end
  if mend + 1 <= tokenpathlen
    cmpop = tokenpath(mend+1).value;
  end
end
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [mend, mobj]=xpparseRelationalExpr(tokenpath, tokenstart, context)
%[24]    RelationalExpr    ::=    AdditiveExpr
%   | RelationalExpr '<' AdditiveExpr
%   | RelationalExpr '>' AdditiveExpr
%   | RelationalExpr '<=' AdditiveExpr
%   | RelationalExpr '>=' AdditiveExpr
%disp(['RelationalExpr: ' tokenpath(tokenstart:end).value]);
try [mend, mobj] = xpparseAdditiveExpr(tokenpath, tokenstart, context);
catch mend = 0; mobj= [];
end
if mend == 0, return; end
tokenpathlen = length(tokenpath);
cmpop = '';
if mend + 1 <= tokenpathlen
  cmpop = tokenpath(mend+1).value;
end
while mend + 1 <= tokenpathlen & ...
      strmatch(cmpop, strvcat('<', '>', '<=', '>='), 'exact')
  tokenstart = mend+2;
  [mend2, mobj2] = xpparseAdditiveExpr(tokenpath, tokenstart, context);
  if mend2 == 0, return; end
  mend = mend2;
  % save types
  typea = mobj.type;
  typeb = mobj2.type;
  % If we are comparing a node-set to boolean, convert node-set to boolean.
  % If we are comparing a node-set to anything else, unfold and convert later.
  if strcmp(typea, 'node-set')
    if strcmp(typeb, 'boolean')
      typea = 'boolean';
      mobj = xpfunc_boolean(mobj, context);
    else
      mobj = mobj.value; % unfold
    end
  elseif strcmp(typeb, 'node-set')
    if strcmp(typea, 'boolean')
      typea = 'boolean';
      mobj2 = xpfunc_boolean(mobj2, context);
    else
      mobj2 = mobj2.value; % unfold
    end
  end
  % mobj1 and mobj2 may now be either XPath objects or DOM node arrays (for
  % node-sets)
  found = false;
  for obja=mobj
    for objb=mobj2
      % for node set nodes, get string-value
      if strcmp(typea, 'node-set')
        obja = xpfunc_string(struct('type', {'node-set'}, 'value', {obja}), context);
      end
      if strcmp(typeb, 'node-set')
        objb = xpfunc_string(struct('type', {'node-set'}, 'value', {objb}), context);
      end
      % convert everything to a number
      if ~strcmp(typea, 'number')
        obja = xpfunc_number(obja, context);
      end
      if ~strcmp(typeb, 'number')
        objb = xpfunc_number(objb, context);
      end
      % do comparisons
      switch cmpop
       case '<', found = (obja.value < objb.value);
       case '>', found = (obja.value > objb.value);
       case '<=', found = (obja.value <= objb.value);
       case '>=', found = (obja.value >= objb.value);
      end
      if found, break; end
    end
    if found, break; end
  end
  mobj = [];
  mobj.type = 'boolean';
  if found
    mobj.value = true;
  else
    mobj.value = false;
  end
  if mend + 1 <= tokenpathlen
    cmpop = tokenpath(mend+1).value;
  end
end
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [mend, mobj]=xpparseAdditiveExpr(tokenpath, tokenstart, context)
%[25]    AdditiveExpr    ::=    MultiplicativeExpr
%   | AdditiveExpr '+' MultiplicativeExpr
%   | AdditiveExpr '-' MultiplicativeExpr
%disp(['AdditiveExpr: ' tokenpath(tokenstart:end).value]);
try [mend, mobj] = xpparseMultiplicativeExpr(tokenpath, tokenstart, context);
catch mend = 0; mobj= [];
end
if mend == 0, return; end
tokenpathlen = length(tokenpath);
cmpop = '';
if mend + 1 <= tokenpathlen
  cmpop = tokenpath(mend+1).value;
end
while mend + 1 <= tokenpathlen & (strcmp(cmpop, '+') | strcmp(cmpop, '-'))
  tokenstart = mend+2;
  [mend2, mobj2] = xpparseMultiplicativeExpr(tokenpath, tokenstart, context);
  if mend2 == 0, return; end
  mend = mend2;
  % convert everything to a number
  if ~strcmp(mobj.type, 'number')
    mobj = xpfunc_number(mobj, context);
  end
  if ~strcmp(mobj2.type, 'number')
    mobj2 = xpfunc_number(mobj2, context);
  end
  mobj.type = 'number';
  switch cmpop
   case '+', mobj.value = mobj.value + mobj2.value;
   case '-', mobj.value = mobj.value - mobj2.value;
  end
  if mend + 1 <= tokenpathlen
    cmpop = tokenpath(mend+1).value;
  end
end
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [mend, mobj]=xpparseMultiplicativeExpr(tokenpath, tokenstart, context)
%[26]    MultiplicativeExpr    ::=    UnaryExpr
%   | MultiplicativeExpr MultiplyOperator UnaryExpr
%   | MultiplicativeExpr 'div' UnaryExpr
%   | MultiplicativeExpr 'mod' UnaryExpr
%disp(['MultiplicativeExpr: ' tokenpath(tokenstart:end).value]);
try [mend, mobj] = xpparseUnaryExpr(tokenpath, tokenstart, context);
catch mend = 0; mobj= [];
end
if mend == 0, return; end
tokenpathlen = length(tokenpath);
cmpop = '';
if mend + 1 <= tokenpathlen
  cmpop = tokenpath(mend+1).value;
end
while mend + 1 <= tokenpathlen & strmatch(cmpop, strvcat('*', 'div', 'mod'), 'exact')
  if strcmp(cmpop, '*') & ...
        ~strcmp(tokenpath(mend+1).gtype, 'MultiplyOperator')
    break;
  end
  tokenstart = mend+2;
  [mend2, mobj2] = xpparseUnaryExpr(tokenpath, tokenstart, context);
  if mend2 == 0, return; end
  mend = mend2;
  % convert everything to a number
  if ~strcmp(mobj.type, 'number')
    mobj = xpfunc_number(mobj, context);
  end
  if ~strcmp(mobj2.type, 'number')
    mobj2 = xpfunc_number(mobj2, context);
  end
  mobj.type = 'number';
  switch cmpop
   case '*'
    mobj.value = mobj.value * mobj2.value;
   case 'div'
    mobj.value = mobj.value / mobj2.value;
   case 'mod'
    mobj.value = mobj.value - (fix(mobj.value / mobj2.value) * mobj2.value);
  end
  if mend + 1 <= tokenpathlen
    cmpop = tokenpath(mend+1).value;
  end
end
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [mend, mobj]=xpparseUnaryExpr(tokenpath, tokenstart, context)
%[27]    UnaryExpr    ::=    UnionExpr
%   | '-' UnaryExpr
%disp(['UnaryExpr: ' tokenpath(tokenstart:end).value]);
mend = tokenstart;
tokenpathlen = length(tokenpath);
found = 0;
while mend + found <= tokenpathlen & strcmp(tokenpath(mend + found).value, '-')
  found = found + 1;
  mend = mend + 1;
end
try [mend, mobj] = xpparseUnionExpr(tokenpath, mend, context);
catch mend = 0; mobj= [];
end
if mend == 0, return; end
if found > 0
  % convert to a number
  if ~strcmp(mobj.type, 'number')
    mobj = xpfunc_number(mobj, context);
  end
  % even number of unary '-'s are a no-op (except for numeric conversion)
  if mod(found, 2) == 1
    mobj.value = -1 * mobj.value;
  end
end
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [mend, mobj]=xpparseUnionExpr(tokenpath, tokenstart, context)
%[18]    UnionExpr    ::=    PathExpr
%   | UnionExpr '|' PathExpr
%disp(['UnionExpr: ' tokenpath(tokenstart:end).value]);
global errmsg;
[mend, mobj] = xpparsePathExpr(tokenpath, tokenstart, context);
if mend == 0, return; end
tokenpathlen = length(tokenpath);
while mend + 1 <= tokenpathlen & strcmp(tokenpath(mend+1).value, '|')
  tokenstart = mend+2;
  [mend2, mobj2] = xpparsePathExpr(tokenpath, tokenstart, context);
  if mend2 == 0, return; end
  if ~strcmp(mobj.type, 'node-set')
    errmsg = ['XPath UnionExpr requires "' tokenpath(tokenstart:mend).value '" to return a node-set'];
    mend = 0;
    return
  end
  if ~strcmp(mobj2.type, 'node-set')
    errmsg = ['XPath UnionExpr requires "' tokenpath(mend+2:mend).value '" to return a node-set'];
    mend = 0;
    return
  end
  mend = mend2;
  mobj.value(end+1:end+length(mobj2.value)) = mobj2.value;
end
mobj.value = uniqueXPathNodes(mobj.value);
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [mend, mobj]=xpparsePathExpr(tokenpath, tokenstart, context)
%[19]    PathExpr    ::=    LocationPath
%   | FilterExpr
%   | FilterExpr '/' RelativeLocationPath
%   | FilterExpr '//' RelativeLocationPath
%[1]    LocationPath    ::=    RelativeLocationPath
%   | AbsoluteLocationPath
%[2]    AbsoluteLocationPath    ::=    '/' RelativeLocationPath?
%   | AbbreviatedAbsoluteLocationPath
%[10]    AbbreviatedAbsoluteLocationPath    ::=    '//' RelativeLocationPath

% enumerating all the possibilities covered by this function:
% FilterExpr                                 [PathExpr]
% FilterExpr '/'  RelativeLocationPath       [PathExpr]
% FilterExpr '//' RelativeLocationPath       [PathExpr]
%            '/'                             [AbsoluteLocationPath]
%            '/'  RelativeLocationPath       [AbsoluteLocationPath]
%            '//' RelativeLocationPath       [AbbreviatedAbsoluteLocationPath]
%                 RelativeLocationPath       [LocationPath]
% the '//' cases should have already been expanded

%disp(['PathExpr: ' tokenpath(tokenstart:end).value]);
global errmsg;
% set up the base case
contextnodes = context.node;
% Check for FilterExpr
foundfilter = 0;
foundslash = 0;
[mend, mobj] = xpparseFilterExpr(tokenpath, tokenstart, context);
if mend == 0, mobj = []; end
if ~isempty(mobj)
  tokenstart = mend + 1;
  if ~strcmp(mobj.type, 'node-set')
    % no need to check for a following '/' or '//'.  If one of those
    % follows, the garbage will be detected on the way up.
    return
  end
  % assume FilterExpr returns node-set
  contextnodes = mobj.value;
  foundfilter = 1;
end
tokenpathlen = length(tokenpath);
if tokenstart > tokenpathlen, return; end
% see if there's a '/' or '//'
if tokenstart <= tokenpathlen & strcmp(tokenpath(tokenstart).value, '/')
  foundslash = 1;
  if ~foundfilter
    % AbsoluteLocationPath
    docnode = [];
    if strcmp(context.node.xptype, 'namespace')
      docnode = context.node.data.domparent.getOwnerDocument;
    elseif strcmp(context.node.xptype, 'root')
      docnode = context.node.data.domnode;
    else
      docnode = context.node.data.domnode.getOwnerDocument;
    end
    contextnodes = struct('xptype', 'root', 'data', struct('domnode', docnode));
    % just in case there is no following relative path
    mobj.type = 'node-set';
    mobj.value = contextnodes;
    mend = tokenstart;
  end
  tokenstart = tokenstart + 1; % go past '/'
elseif tokenstart <= tokenpathlen & strcmp(tokenpath(tokenstart).value, '//')
  % this should never happen -- should have been expanded
  errmsg = 'Internal error -- XPath lexical parser didn''t expand "//"';
  mend = 0;
  return
end
parsedrlp = 1;
if length(contextnodes) == 0
  % no context nodes, parse but throw out result
  [mend2, mobj2] = xpparseRelativeLocationPath(tokenpath, tokenstart, context);
  mend = mend2;
  if mend2 == 0
    parsedrlp = 0;
  end
else
  % we can now modify context -- we've saved all the nodes we need
  % Put new stuff in mobj3 in case there is no RelativeLocationPath following.
  mobj3 = [];
  mobj3.type = 'node-set';
  mobj3.value = struct('xptype', {}, 'data', {});
  for contextnode = contextnodes
    context.node = contextnode;
    [mend2, mobj2] = xpparseRelativeLocationPath(tokenpath, tokenstart, context);
    if mend2 == 0
      parsedrlp = 0;
      break
    end
    % XXX assume mobj2 is a node-set?
    mobj3.value(end+1:end+length(mobj2.value)) = mobj2.value;
    mend = mend2;
  end
  mobj = [];
  mobj.type = 'node-set';
  mobj.value = uniqueXPathNodes(mobj3.value);
end
if ~parsedrlp
  % didn't parse RelativeLocationPath -- OK if bare FilterExpr xor '/'
  if (foundfilter & ~foundslash) | (~foundfilter & foundslash)
    % we're done
    return
  end
  errmsg = ['XPath  requires "' tokenpath(1:tokenstart-1).value '" to be followed by a RelativeLocationPath'];
  mend = 0;
  return
end
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [mend, mobj]=xpparseRelativeLocationPath(tokenpath, tokenstart, context)
%[3]    RelativeLocationPath    ::=    Step
%   | RelativeLocationPath '/' Step
%   | AbbreviatedRelativeLocationPath
%[11]    AbbreviatedRelativeLocationPath    ::=    RelativeLocationPath '//' Step

% another way of defining the possibilities (?):
% Step
% Step '/' RelativeLocationPath
% Step '//' Step                    [should already be expanded]

%disp(['RelativeLocationPath: ' tokenpath(tokenstart:end).value]);
global errmsg;
[mend, mobj] = xpparseStep(tokenpath, tokenstart, context);
if mend == 0, return; end
tokenstart = mend + 1;
tokenpathlen = length(tokenpath);
if tokenstart <= tokenpathlen
  % assume Step returns node-set
  contextnodes = mobj.value;
  if strcmp(tokenpath(tokenstart).value, '/')
    tokenstart = tokenstart + 1;
    if tokenstart > tokenpathlen
        % Possible error; just set error message but return success (and
        % keep mend the same)
        errmsg = ['Step expected after ''' tokenpath.value sprintf('''\n')];
        return
    end
    mobj.value = struct('xptype', {}, 'data', {});
    if length(contextnodes) == 0
      % no context nodes, parse but throw out result
      [mend2, mobj2] = xpparseRelativeLocationPath(tokenpath, tokenstart, context);
      mend = mend2;
    else
      for contextnode = contextnodes
        context.node = contextnode;
        [mend2, mobj2] = xpparseRelativeLocationPath(tokenpath, tokenstart, context);
        if mend2 == 0, mend = 0; return; end % bad RelativeLocationPath
        mobj.value(end+1:end+length(mobj2.value)) = mobj2.value;
        mend = mend2;
      end
      mobj.value = uniqueXPathNodes(mobj.value);
    end
    return
  elseif strcmp(tokenpath(tokenstart).value, '//')
    % this should never happen -- should have been expanded
    errmsg = 'Internal error -- XPath lexical parser didn''t expand "//"';
    mend = 0;
    return
  end
end
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [mend, mobj]=xpparseStep(tokenpath, tokenstart, context)
%[4]   	Step	   ::=   	AxisSpecifier NodeTest Predicate*	
%   | AbbreviatedStep	
%[5]   	AxisSpecifier	   ::=   	AxisName '::'	
%   | AbbreviatedAxisSpecifier 	
%[12]    AbbreviatedStep    ::=    '.'
%   | '..'
%[13]    AbbreviatedAxisSpecifier    ::=    '@'?
%[7]   	NodeTest	   ::=   	NameTest	
%			| NodeType '(' ')'	
%			| 'processing-instruction' '(' Literal ')'	
%[37]   NameTest	   ::=   	'*'	
%			| NCName ':' '*'	
%			| QName

% enumerating the possibilities:
% '.'                                 [should have already been expanded]
% '..'                                [should have already been expanded]
% AxisName '::' NodeTest Predicate*
% '@'           NodeTest Predicate*   [should have already been expanded]
%               NodeTest Predicate*

%disp(['Step: ' tokenpath(tokenstart:end).value]);
global errmsg;
mobj = [];
mobj.type = 'node-set';
mobj.value = struct('xptype', {}, 'data', {});
tokenpathlen = length(tokenpath);
curtoken = tokenpath(tokenstart);
if strcmp(curtoken.value, '.')
  % this should never happen -- should have been expanded
  errmsg = 'Internal error -- XPath lexical parser didn''t expand "."';
  mend = 0;
  return
end
if strcmp(curtoken.value, '..')
  % this should never happen -- should have been expanded
  errmsg = 'Internal error -- XPath lexical parser didn''t expand ".."';
  mend = 0;
  return
end
if strcmp(curtoken.value, '@')
  % this should never happen -- should have been expanded
  errmsg = 'Internal error -- XPath lexical parser didn''t expand "@"';
  mend = 0;
  return
end
axisname = 'child'; % default axis
if strcmp(curtoken.gtype, 'AxisName')
  if tokenstart + 1 > tokenpathlen | ...
        ~strcmp(tokenpath(tokenstart + 1).value, '::')
    errmsg = ['XPath AxisName "' curtoken.value '" must be followed by "::"'];
    mend = 0;
    return
  end
  axisname = curtoken.value;
  tokenstart = tokenstart + 2;
end
if tokenstart > tokenpathlen
  errmsg = ['XPath NodeTest must follow ' [tokenpath.value]];
  mend = 0;
  return
end

% construct new context node list based on axis
contextnodes = getNodesOnAxis(context.node, axisname);

% do NodeTest
curtoken = tokenpath(tokenstart);
if strcmp(curtoken.value, 'processing-instruction')
  if tokenstart + 3 > tokenpathlen | ...
        ~strcmp(tokenpath(tokenstart+1).value, '(') | ...
        ~strcmp(tokenpath(tokenstart+2).gtype, 'Literal') | ...
        ~strcmp(tokenpath(tokenstart+3).value, ')')
    errmsg = ['Error parsing XPath NodeTest processing instruction ' tokenpath(tokenstart:end).value];
    error(errmsg);
  end
  piname = tokenpath(tokenstart+2).value(2:end-1); % get rid of quotes
  for contextnode = contextnodes
    if strcmp(contextnode.xptype, 'processing-instruction') & ...
          strcmp(cindex(cell(contextnode.data.domnode.getNodeName), piname),1)
      mobj.value(end+1) = contextnode;
    end
  end
  mend = tokenstart + 3;
elseif strcmp(curtoken.gtype, 'NodeType')
  if tokenstart + 2 > tokenpathlen | ...
        ~strcmp(tokenpath(tokenstart+1).value, '(') | ...
        ~strcmp(tokenpath(tokenstart+2).value, ')')
    errmsg = ['Error parsing XPath NodeTest node type ' tokenpath(tokenstart:end).value];
    mend = 0;
    return
  end
  nodetesttype = tokenpath(tokenstart).value;
  matchtypes = [];
  switch nodetesttype
   case 'node'
    matchtypes = strvcat( ...
        'element', 'attribute', 'text', 'processing-instruction', ...
        'text', 'comment', 'root', 'namespace');
   case {'comment','text','processing-instruction'}
    matchtypes = nodetesttype;
  end
  for contextnode = contextnodes
    if any(strmatch(contextnode.xptype, matchtypes, 'exact'))
      mobj.value(end+1) = contextnode;
    end
  end
  mend = tokenstart + 2;
else
  % do NameTest (curtoken.gtype better be 'NameTest'!)
  matchname = tokenpath(tokenstart).value;
  wildcardname = 0;
  if strcmp(matchname, '*'), wildcardname = 1; end
  matchuri = [];
  comps = splitstr(matchname, ':');
  if length(comps) > 2
    errmsg = ['QName ', matchname, ' has too many colons'];
    mend = 0;
    return;
  end
  if length(comps) > 1
    matchprefix = comps{1};
    if isfield(context.nsdecls, matchprefix)
      matchname = comps{2};
      matchuri = getfield(context.nsdecls, matchprefix);
    else
      errmsg = ['Prefix ', matchprefix, ' does not exist'];
      mend = 0;
      return
    end
  end
  if strcmp(axisname, 'namespace')
    for contextnode = contextnodes
      if ~strcmp(contextnode.xptype, 'namespace'), break; end
      if wildcardname
        mobj.value(end+1) = contextnode;
      end
      prefix = contextnode.data.prefix; % prefix
      if strcmp(matchname, prefix)
        mobj.value(end+1) = contextnode;
      end
    end
  else
    principalnodetype = 'element';
    if strcmp(axisname, 'attribute')
      principalnodetype = 'attribute';
    end
    for contextnode = contextnodes
      if ~strcmp(contextnode.xptype, principalnodetype), continue; end
      if wildcardname & isempty(matchuri)
        mobj.value(end+1) = contextnode;
      end
      localname = contextnode.data.localname;
      prefix = contextnode.data.prefix;
      nsuri = contextnode.data.nsuri;
      if (~isempty(nsuri) | ~isempty(matchuri)) & ~strcmp(nsuri, matchuri)
        continue;
      end
      % URIs match
      if ~wildcardname & ~strcmp(matchname, localname), continue; end
      % names match
      mobj.value(end+1) = contextnode;
    end
  end
  mend = tokenstart;
end

% now filter by Predicates (if any)
tokenstart = mend + 1;
mend2 = 1;
while mend2 ~= 0 & tokenstart <= tokenpathlen
  contextnodes = mobj.value;
  mobj.value = struct('xptype', {}, 'data', {});
  context.size = length(contextnodes);
  if context.size == 0
    % no context nodes, parse predicate, but throw out result
    [mend2, mobj2] = xpparsePredicate(tokenpath, tokenstart, context);
    if mend2 == 0
      mobj.value = contextnodes;
      break
    end
    mend = mend2;
  else
    for nodenum = 1:context.size
      context.node = contextnodes(nodenum);
      context.position = nodenum;
      [mend2, mobj2] = xpparsePredicate(tokenpath, tokenstart, context);
      if mend2 == 0
        mobj.value = contextnodes;
        break
      end
      mend = mend2;
      mobj.value(end+1:end+length(mobj2.value)) = mobj2.value;
    end
  end
  mobj.value = uniqueXPathNodes(mobj.value);
  tokenstart = mend + 1;
end
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [mend, mobj]=xpparseFilterExpr(tokenpath, tokenstart, context)
%[20]    FilterExpr    ::=    PrimaryExpr
%   | FilterExpr Predicate
%disp(['Filter: ' tokenpath(tokenstart:end).value]);
global errmsg;
tokenpathlen = length(tokenpath);
try [mend, mobj] = xpparsePrimaryExpr(tokenpath, tokenstart, context);
catch mend = 0; mobj= [];
end
if mend == 0, return; end % need at least one PrimaryExpr
if ~strcmp(mobj.type, 'node-set')
  % no need to check for a predicate -- it would be invalid to
  % filter a non-node-set.  If a predicate follows, the garbage
  % will be detected on the way up.
  return
end
tokenstart = mend + 1;
mend2 = mend;
% now see if we need to apply Predicate
if tokenstart > tokenpathlen, return; end
if length(mobj.value) == 0
  % no context nodes, parse but throw out result
  [mend2, mobj2] = xpparsePredicate(tokenpath, tokenstart, context);
  if mend2 ~= 0
    mend = mend2;
  end
  return
else
  contextnodes = mobj.value;
  % put result in mobj3 in case there is no Predicate
  mobj3 = [];
  mobj3.xptype = 'node-set';
  mobj3.value = [];
  for contextnode = contextnodes
    context.node = contextnode;
    [mend2, mobj2] = xpparsePredicate(tokenpath, tokenstart, context);
    if mend2 == 0
      % no predicate
      return
    end
    mend = mend2;
    % assume Predicate returns boolean
    if mobj2.value
      mobj3.value(end+1) = contextnode;
    end
  end
  mobj = mobj3;
  mobj.value = uniqueXPathNodes(mobj.value);
end
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [mend, mobj]=xpparsePrimaryExpr(tokenpath, tokenstart, context)
%[15]    PrimaryExpr    ::=    VariableReference
%   | '(' Expr ')'
%   | Literal
%   | Number
%   | FunctionCall
%disp(['PrimaryExpr: ' tokenpath(tokenstart:end).value]);
global errmsg;
mobj = [];
tokenpathlen = length(tokenpath);
if strcmp(tokenpath(tokenstart).value, '(')
  if tokenstart + 1 > tokenpathlen, mend = 0; return; end
  try [mend, mobj] = xpparseExpr(tokenpath, tokenstart + 1, context);
  catch mend = 0; mobj= [];
  end
  if mend == 0, return; end
  if mend + 1 > tokenpathlen | ~strcmp(tokenpath(mend+1).value, ')')
    mend = 0;
    return
  end
  mend = mend + 1;
  return
end
[mend, mobj] = xpparseFunctionCall(tokenpath, tokenstart, context);
if mend ~= 0, return; end
if strcmp(tokenpath(tokenstart).gtype, 'VariableReference')
  mend = tokenstart;
  varname = tokenpath(tokenstart).gtype(2:end);
  if ~isfield(context.vars, varname)
    errmsg = ['Undefined variable "' varname '": ' tokenpath(1:tokenstart-1).value ' <here> ' tokenpath(tokenstart:end).value];
    mend = 0;
    return
  end
  mobj = getfield(context.vars, varname);
  return
end
if strcmp(tokenpath(tokenstart).gtype, 'Literal')
  mend = tokenstart;
  mobj.type = 'string';
  mobj.value = tokenpath(tokenstart).value(2:end-1); % get rid of quotes;
  return
end
if strcmp(tokenpath(tokenstart).gtype, 'Number')
  mend = tokenstart;
  mobj.type = 'number';
  mobj.value = str2num(tokenpath(tokenstart).value);
  return
end
mend = 0;
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [mend, mobj]=xpparsePredicate(tokenpath, tokenstart, context)
%[8]    Predicate    ::=    '[' PredicateExpr ']'
%disp(['Predicate: ' tokenpath(tokenstart:end).value]);
global errmsg;
mobj = [];
if ~strcmp(tokenpath(tokenstart).value, '[')
  mend = 0;
  return
end
tokenpathlen = length(tokenpath);
if tokenstart + 1 > tokenpathlen
  errmsg = ['XPath expects PredicateExpr: ' tokenpath(1:tokenstart).value ' <here> ' tokenpath(tokenstart+1:end).value];
  mend = 0;
  return
end
[mend, mobj] = xpparsePredicateExpr(tokenpath, tokenstart + 1, context);
if mend == 0
  errmsg = ['XPath error parsing PredicateExpr: ' tokenpath(1:tokenstart).value ' <here> ' tokenpath(tokenstart+1:end).value];
  mend = 0;
  return
end
if mend + 1 > tokenpathlen | ~strcmp(tokenpath(mend+1).value, ']')
  errmsg = ['XPath expects "]": ' tokenpath(1:mend).value ' <here> ' tokenpath(mend+1:end).value];
  mend = 0;
  return
end
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [mend, mobj]=xpparsePredicateExpr(tokenpath, tokenstart, context)
%[9]    PredicateExpr    ::=    Expr
%disp(['PredicateExpr: ' tokenpath(tokenstart:end).value]);
[mend, mobj] = xpparseExpr(tokenpath, tokenstart, context);
if strcmp(mobj.type, 'number')
  mobj.type = 'boolean';
  if context.position == mobj.value
    mobj.value = 1;
  else
    mobj.value = 0;
  end
else
  mobj = xpfunc_boolean(mobj, context);
end
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [mend, mobj]=xpparseFunctionCall(tokenpath, tokenstart, context)
%[16]    FunctionCall    ::=    FunctionName '(' ( Argument ( ',' Argument )* )? ')'
%[17]    Argument    ::=    Expr
%disp(['FunctionCall: ' tokenpath(tokenstart:end).value]);
global errmsg;
mobj = [];
tokenpathlen = length(tokenpath);
if ~strcmp(tokenpath(tokenstart).gtype, 'FunctionName')
  errmsg = ['FunctionName expected: ' tokenpath(1:tokenstart-1).value ' <here> ' tokenpath(tokenstart:end).value];
  mend = 0;
  return
end
fname = tokenpath(tokenstart).value;
if tokenstart + 1 > tokenpathlen | ~strcmp(tokenpath(tokenstart+1).value, '(')
  errmsg = ['"(" expected after FunctionName: ' tokenpath(1:tokenstart).value ' <here> ' tokenpath(tokenstart+1:end).value];
  mend = 0;
  return
end
if tokenstart + 2 > tokenpathlen
  errmsg = ['XPath FunctionCall expects arguments or ending paren: ' tokenpath(1:tokenstart+1).value ' <here> ' tokenpath(tokenstart+2:end).value];
  mend = 0;
  return
end
mend = tokenstart + 2;
tokenstart = mend;
mend2 = mend;
arguments = [];
while mend2 ~= 0 & tokenstart <= tokenpathlen
  if strcmp(tokenpath(tokenstart).value, ')')
    % end of argument list
    mend = tokenstart;
    break
  end
  [mend2, mobj2] = xpparseExpr(tokenpath, tokenstart, context);
  if mend2 == 0
    errmsg = ['XPath FunctionCall expects Expr: ' tokenpath(1:tokenstart-1).value ' <here> ' tokenpath(tokenstart:end).value];
    mend = 0;
    return
    break;
  end
  mend = mend2;
  arguments(end+1) = mobj2;
  tokenstart = mend + 1;
end
% call the function
mobj = feval(['xpfunc_' fname], arguments(:), context);
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ret=xpfunc_boolean(mobj, context)
ret = [];
ret.type = 'boolean';
switch mobj.type
 case 'boolean'
  ret = mobj;
 case 'number'
  if any(mobj.value == [0 -0 NaN])
    ret.value = false;
  else
    ret.value = true;
  end
 case {'node-set', 'string'}
  ret.value = ~isempty(mobj.value);
 otherwise
  errmsg = ['Can''t convert XPath object of type ' mobj.type ' to boolean'];
  error(errmsg);
end
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ret=xpfunc_string(mobj, context)
if isempty(mobj)
  mobj = struct('type', {'node-set'}, 'value', {context.node});
end
ret = [];
ret.type = 'string';
if strcmp(mobj.type, 'node-set')
  if length(mobj.value) == 0
    ret.value = '';
    return
  end
  node = mobj.value(1);
  switch node.xptype
   case {'root', 'element'}
    strobj = java.lang.String;
    % depth-first recursion
    queue = [node.data.domnode];
    while length(queue) > 0
      curdomnode = queue(end);
      queue(end) = [];
      domtype = curdomnode.getNodeType;
      if domtype == 3 | domtype == 7 % TEXT or CDATA
        strobj.concat(curdomnode.getNodeValue);
      elseif domtype == 1 % ELEMENT
        childnodelist = curdomnode.getChildNodes;
        childlistlen = childnodelist.getLength;
        for childnum=childlistlen-1:-1:0
          curdomchild = childnodelist.item(childnum);
          queue(end+1) = curdomchild;
        end
      end
    end
    ret.value = cindex(cell(strobj),1); % quick char conv
   case 'namespace'
    ret.value = node.data.uri;
   otherwise
    ret.value = cindex(cell(node.getNodeValue),1); % quick char conv
  end
  return
end
switch mobj.type
 case 'string'
  ret = mobj;
 case 'number'
  switch mobj.value
   case NaN, ret.value = 'NaN';
   case {0, -0}, ret.value = '0';
   case {Inf, -Inf}, ret.value = 'Infinity';
   otherwise
    ret.value = num2str(mobj.value, '%.100f');
    % get rid of excess trailing zeros
    dots = (ret.value == '.')
    if ~isempty(dots)
      nonzeros = find(ret.value ~= '0');
      if nonzeros(end) > dots(1)
        ret.value(nonzeros(end)+1:end) = [];
      end
    end
  end
 case 'boolean'
  if mobj.value, ret.value = 'true';
  else ret.value = 'false';
  end
 otherwise
  errmsg = ['Can''t convert XPath object of type ' mobj.type ' to string'];
  error(errmsg);
end
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ret=xpfunc_number(mobj, context)
ret = [];
ret.type = 'number';
switch mobj.type
 case 'number'
  ret = mobj;
 case 'string'
  ret.value = str2num(mobj.value);
  if isempty(ret.value)
    ret.value = NaN;
  end
 case 'boolean'
  if mobj.value, ret.value = 1;
  else ret.value = 0;
  end
 case 'node-set'
  ret = xpfunc_number(xpfunc_string(mobj, context), context);
  ret.value = ~isempty(mobj.value);
 otherwise
  errmsg = ['Can''t convert XPath object of type ' mobj.type ' to number'];
  error(errmsg);
end
return




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function outpaths=convertXPaths(inpaths)

operatornametokens = strvcat('and', 'or', 'mod', 'div');
opprectokens = strvcat('@', '::', '(', '[', ',');

outpaths = {};

numpaths = length(inpaths);
for pathnum = 1:numpaths
  inpath = inpaths{pathnum};
  % tokenize the path
  tokens = struct('gtype', {}, 'value', {});
  inpath = trim(inpath);
  while length(inpath) > 0
    while 1
      % ExprToken ::=
      %   '(' | ')' | '[' | ']' | '.' | '..' | '@' | ',' | '::'
      %   | NameTest
      %   | NodeType
      %   | Operator
      %   | FunctionName
      %   | AxisName
      %   | Literal
      %   | Number
      %   | VariableReference
      newtoken = [];
      matchlen = 0;
      prefixmat = strvcat('(', ')', '[', ']', ',', '::');
      [matchlen, match] = matchMatrixPrefixes(inpath, prefixmat);
      if ~isempty(match)
        newtoken.gtype = 'ExprToken';
        newtoken.value = match;
        break
      end
      if strncmp(inpath, '@', 1)
        matchlen = 1;
        newtoken(1).gtype = 'AxisName';
        newtoken(1).value = 'attribute';
        newtoken(2).gtype = 'Operator';
        newtoken(2).value = '::';
        break
      end
      if strncmp(inpath, '..', 2)
        matchlen = 2;
        newtoken(1).gtype = 'AxisName';
        newtoken(1).value = 'parent';
        newtoken(2).gtype = 'Operator';
        newtoken(2).value = '::';
        newtoken(3).gtype = 'NodeType';
        newtoken(3).value = 'node';
        newtoken(4).gtype = 'ExprToken';
        newtoken(4).value = '(';
        newtoken(5).gtype = 'ExprToken';
        newtoken(5).value = ')';
        break
      end
      if strncmp(inpath, '.', 1)
        matchlen = 1;
        newtoken(1).gtype = 'AxisName';
        newtoken(1).value = 'self';
        newtoken(2).gtype = 'Operator';
        newtoken(2).value = '::';
        newtoken(3).gtype = 'NodeType';
        newtoken(3).value = 'node';
        newtoken(4).gtype = 'ExprToken';
        newtoken(4).value = '(';
        newtoken(5).gtype = 'ExprToken';
        newtoken(5).value = ')';
        break
      end
      
      % Order is important to disambiguate NameTest from:
      %  Operator (e.g. '*')
      %  NodeType (e.g. 'element')
      %  FunctionName (e.g. 'substring-before')
      %  AxisName (e.g. 'descendant-or-self')
      % Rules come from Sec. 3.7 in XPath1 specification

      % Operator
      matchlen = xplexOperator(inpath);
      if matchlen
        % '*', 'and', 'or', 'mod', 'div' should not be considered
        % Operators if they are at the begnning of an XPath or if they
        % follow another Operator or the tokens '@', '::', '(', '[', or ','
        newtoken.gtype = 'Operator';
        newtoken.value = inpath(1:matchlen);
        if (~strcmp(newtoken.value, '*') & ...
            ~matchMatrixPrefixes(newtoken.value, operatornametokens)) | ...
           (length(tokens) > 0 & ...
            (strcmp(tokens(end).gtype, 'Operator') | ...
             matchMatrixPrefixes(tokens(end).value, opprectokens)))
          % either this is not '*', 'and', 'or', 'mod', or 'div', or
          % otherwise this is a proper place for an operator so accept it
          if strcmp(newtoken.value, '//')
            % expand this
            newtokenlist = {...
                'Operator',  '/',...
                'AxisName',  'descendant-or-self',...
                'Operator',  '::',...
                'NodeType',  'node',...
                'ExprToken', '(',...
                'ExprToken', ')',...
                'Operator',  '/' };
            newtoken = struct('gtype', newtokenlist(1:2:end), 'value', newtokenlist(2:2:end));
          end
          break
        end
        % not a valid Operator location, fall through to next test
      end

      % NodeType
      matchlen = xplexNodeType(inpath);
      if matchlen
        % NodeType must be followed by '(' (intervening whitespace OK)
        if strncmp(trim(inpath(matchlen+1:end)), '(', 1)
          % accept it
          newtoken.gtype = 'NodeType';
          newtoken.value = inpath(1:matchlen);
          break
        end
        % NodeType not followed by '(', fall through to next test
      end

      % FunctionName
      matchlen = xplexFunctionName(inpath);
      if matchlen
        % FunctionName must be followed by '(' (intervening whitespace OK)
        if strncmp(trim(inpath(matchlen+1:end)), '(', 1)
          % accept it
          newtoken.gtype = 'FunctionName';
          newtoken.value = inpath(1:matchlen);
          break
        end
        % FunctionName not followed by '(', fall through to next test
      end

      % AxisName
      matchlen = xplexAxisName(inpath);
      if matchlen
        % AxisName must be followed by '::' (intervening whitespace OK)
        if strncmp(trim(inpath(matchlen+1:end)), '::', 2)
          % accept it
          newtoken.gtype = 'AxisName';
          newtoken.value = inpath(1:matchlen);
          break
        end
        % AxisName not followed by '::', fall through to next test
      end

      % NameTest
      matchlen = xplexNameTest(inpath);
      if matchlen
        newtoken.gtype = 'NameTest';
        newtoken.value = inpath(1:matchlen);
        break
      end

      % Literal
      matchlen = xplexLiteral(inpath);
      if matchlen
        newtoken.gtype = 'Literal';
        newtoken.value = inpath(1:matchlen);
        break
      end

      % Number
      matchlen = xplexNumber(inpath);
      if matchlen
        newtoken.gtype = 'Number';
        newtoken.value = inpath(1:matchlen);
        break
      end

      % VariableReference
      matchlen = xplexVariableReference(inpath);
      if matchlen
        newtoken.gtype = 'VariableReference';
        newtoken.value = inpath(1:matchlen);
        break
      end

      errmsg = ['Error in XPath string starting at "' inpath '"'];
      error(errmsg);
    end

    if isempty(newtoken), errmsg = 'Couldn''t match XPath ExprToken'; error(errmsg); end
    tokens(end+1:end+length(newtoken)) = newtoken;
    inpath = trim(inpath(matchlen+1:end));
  end
  outpaths{end+1} = tokens;
end
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function matchlen=xplexNameTest(inpath)
% NameTest ::=
%   '*'
%   | NCName ':' '*'
%   | QName
matchlen = 0;
if inpath(1) == '*'
  matchlen = 1;
  return
end
matchlen = xpmatchNCName(inpath);
if matchlen
  % Check if the NCName is followed by a colon,
  % and then by '*' or another NCName
  inpathlen = length(inpath);
  if inpathlen >= matchlen + 2 & inpath(matchlen+1) == ':'
    matchlen = matchlen + 1;
    if inpath(matchlen+2) == '*'
      matchlen = matchlen + 1;
      return
    end
    ncmatchlen = xpmatchNCName(inpath(matchlen+1:end));
    if ncmatchlen
      matchlen = matchlen + ncmatchlen;
      return
    else
      matchlen = 0;
    end
  end
end
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function matchlen=xplexNodeType(inpath)
% NodeType ::= 'comment'
%   | 'text'
%   | 'processing-instruction'
%   | 'node'
matchlen = 0;
prefixmat = strvcat('comment', 'text', 'processing-instruction', 'node');
matchlen = matchMatrixPrefixes(inpath, prefixmat);
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function matchlen=xplexOperator(inpath)
% Operator ::= OperatorName
%   | MultiplyOperator
%   | '/' | '//' | '|' | '+' | '-' | '=' | '!=' | '<' | '<=' | '>' | '>='
% OperatorName ::= 'and' | 'or' | 'mod' | 'div'
% MultiplyOperator ::= '*'
matchlen = 0;
prefixmat = strvcat('and', 'or', 'mod', 'div', '*', '//', '/', '|', '+', '-', '=', '!=', '<=', '<', '>=', '>'); % order is important!
matchlen = matchMatrixPrefixes(inpath, prefixmat);
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function matchlen=xplexFunctionName(inpath)
% FunctionName ::= QName - NodeType
%
% we assume the test for NodeType has already failed
% (otherwise, we'd have to do the test twice)
matchlen = xpmatchQName(inpath);
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function matchlen=xplexAxisName(inpath)
% AxisName ::= 'ancestor'
%   | 'ancestor-or-self'
%   | 'attribute'
%   | 'child'
%   | 'descendant'
%   | 'descendant-or-self'
%   | 'following'
%   | 'following-sibling'
%   | 'namespace'
%   | 'parent'
%   | 'preceding'
%   | 'preceding-sibling'
%   | 'self'
matchlen = 0;
prefixmat = strvcat('ancestor', 'ancestor-or-self', 'attribute', 'child', 'descendant', 'descendant-or-self', 'following', 'following-sibling', 'namespace', 'parent', 'preceding', 'preceding-sibling', 'self');
matchlen = matchMatrixPrefixes(inpath, prefixmat);
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function matchlen=xplexLiteral(inpath)
% Literal ::= '"' [^"]* '"'
%   | "'" [^']* "'"
%
matchlen = 0;
if inpath(1) == '''' | inpath(1) == '"'
  inds = findstr(inpath, inpath(1));
  if (inds < 2)
    errmsg = ['Unterminated string in XPath expression "' inpath '"']; error(errmsg);
  end
  matchlen = inds(2);
end
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function matchlen=xplexNumber(inpath)
% Number ::= Digits ('.' Digits?)?
%   | '.' Digits
matchlen = 0;
founddot = 0;
while matchlen < length(inpath)
  c = inpath(matchlen+1);
  if any(c == '0123456789')
    matchlen = matchlen + 1;
    continue
  end
  if c == '.'
    if founddot
      break
    else
      founddot = 1;
      matchlen = matchlen + 1;
      continue
    end
  end
  break
end
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function matchlen=xplexVariableReference(inpath)
% VariableReference ::= '$' QName
matchlen = 0;
if inpath(1) == '$'
  matchlen = xpmatchQName(inpath(2:end)) + 1;
end
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function matchlen=xpmatchNCName(inpath)
% NCName ::= (Letter | '_') (NCNameChar)*
% NCNameChar ::= Letter | Digit | '.' | '-' | '_' | CombiningChar | Extender
%
% (we use a simplified NCName)
matchlen = 0;
inpathlen = length(inpath);
if inpathlen >= 2 & isletter(inpath(1)) | inpath(1) == '_'
  for ind=2:length(inpath)
    c = inpath(ind);
    if isletter(c), continue; end
    if any(c == '0123456789.-_'), continue; end
    ind = ind - 1;
    break
  end
  matchlen = ind;
end
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function matchlen=xpmatchQName(inpath)
% QName ::= Prefix ':' LocalPart
% Prefix ::= NCName
% LocalPart ::= NCName
matchlen = 0;
ncmatchlen = xpmatchNCName(inpath);
if ~ncmatchlen, return; end
inpathlen = length(inpath);
if inpathlen < ncmatchlen + 2 | inpath(ncmatchlen+1) ~= ':', return; end
ncmatchlen2 = xpmatchNCName(inpath(ncmatchlen+2:end));
if ~ncmatchlen2, return; end
matchlen = ncmatchlen + 1 + ncmatchlen2;
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [matchlen,match]=matchMatrixPrefixes(str,prefixmat)
% inspired by strmatch
match = [];
[matm,matn] = size(prefixmat);
strlen = length(str);
null = char(0);
space = ' ';
usenull = 0;
if ~isempty(prefixmat) & any(prefixmat(:,end)==null), usenull = 1; end
if strlen > matn
  str = str(1:matn);
elseif strlen < matn
  if usenull
    str = [str null(ones(1,matn-strlen))];
  else
    str = [str space(ones(1,matn-strlen))];
  end
end
empties = (prefixmat == null | prefixmat == space);
strmat = str(ones(matm,1),:);
prefixmat(empties) = strmat(empties);
inds = find(~sum((prefixmat(:,1:matn) ~= str(ones(matm,1),:)),2));
if ~isempty(inds)
  match = deblank(prefixmat(inds(1),~empties(inds(1),:)));
end
matchlen = length(match);
return
 
% $Log: parseXPaths.m,v $
% Revision 1.3  2006/09/25 15:06:14  gadde
% Update some documentation and remove a diagnostic message.
%
% Revision 1.2  2006/07/18 21:51:05  gadde
% I meant readxml.m.
%
% Revision 1.1  2006/07/18 21:50:30  gadde
% Moved this code out from readmr.m
%
