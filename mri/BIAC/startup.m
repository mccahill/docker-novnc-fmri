%STARTUP Central BIAC startup M-file.
%
% This file adds all of the BIAC MATLAB software to the MATLAB path,
% initializes BIAC Java software, and executes any startup files in the
% user's home directory (%HOMEDRIVE%%HOMEPATH% or U:\%USERNAME%)
%
% Note: This script assumes that it is located in the root of the BIAC
% software installation.  Use startup-stub.m to initiate calling this
% function.  See startup-stub.m for installation instructions.
%
% See Also: STARTUP-STUB

% CVS ID and authorship of this code
% $Id: startup.m,v 1.27 2006/07/14 21:20:16 gadde Exp $

format compact

% Parse current MATLAB version (using MATLAB 5.3 version syntax)
[majorVer, minorVer] = strtok(strtok(version),'.');
majorVer = str2double(majorVer);
minorVer = str2double(strtok(minorVer,'.'));

% BIACroot is the location of this file.
if majorVer < 6 | (majorVer == 6 & minorVer < 5)
  % Find location using which for MATLAB versions before 6.5
  mfileCurr=which(mfilename);
  if any(strcmp(mfileCurr,{'variable','built-in'}))
    BIACroot='';
  else
    BIACroot=fileparts(mfileCurr);
  end
  clear mfileCurr
else
  % Find location using new mfilename() option   
  BIACroot=fileparts(mfilename('fullpath'));
end

if ~exist(BIACroot,'dir')
  % Built-in warning() produces no output here
  disp(sprintf(['Warning: Unable to locate BIAC MATLAB programs.\n' ...
    '  Installation directory (%s) does not exist.\n'],BIACroot));
else
  addpath(fullfile(BIACroot,'general'));
  addpath(fullfile(BIACroot,'EEGad'))
  addpath(fullfile(BIACroot,'mr'))
  if exist(fullfile(BIACroot,'KS'),'dir')
    % KS is not under revision control.
    addpath(fullfile(BIACroot,'KS'))
  end

  % Add BIAC Fix Toolbox for this version of MATLAB (if necessary).
  fixDir = fullfile(BIACroot,'fix',sprintf('MATLAB%d%d',majorVer,minorVer));
  if exist(fixDir,'dir'), addpath(fixDir); end
  clear fixDir
end

% Add java dir to java classpath using javaaddpath
if majorVer >= 7
  javaaddpath(fullfile(BIACroot,'java'))
end

clear BIACroot majorVer minorVer

% Add SRB handlers to URL handler search path (if SRB stuff in Java classpath)
if exist('edu.duke.biac.srb.Handler')==8
  props = java.lang.System.getProperties;
  put(props, 'java.protocol.handler.pkgs', ...
    strcat('edu.duke.biac|',char(getProperty(props, 'java.protocol.handler.pkgs'))));
  clear props ans
end

% Run user's startup.m file if it exists
% (~/matlab/startup.m is already automatically executed on UNIX) 
if ~isunix
  userHome='';
  if ~isempty(getenv('HOMEDRIVE')) & ~isempty(getenv('HOMEPATH')) 
    userHome=fullfile(getenv('HOMEDRIVE'),getenv('HOMEPATH'));
  elseif ~isempty(getenv('USERNAME'))
    userHome=fullfile('U:',getenv('USERNAME'));
  end
  if ~isempty(userHome)
    STARTm=fullfile(userHome,'startup.m');
    if exist(STARTm,'file')
      run(STARTm);
    end
    clear STARTm
  end
  clear userHome
end

% Modification History:
%
% $Log: startup.m,v $
% Revision 1.27  2006/07/14 21:20:16  gadde
% Updates for gzip reading
%
% Revision 1.26  2005/06/21 21:29:47  michelich
% Fix typo in new version checking code.
%
% Revision 1.25  2005/02/22 20:18:15  michelich
% Use more robust version parsing code.
%
% Revision 1.24  2004/08/20 00:59:59  michelich
% Removing warning for no BIAC Fix Toolbox.
%
% Revision 1.23  2004/06/02 21:50:05  michelich
% Generate fix directory names automatically.
%
% Revision 1.22  2004/05/06 15:15:22  gadde
% Remove all dependencies on ispc and nargoutchk (for compatibility
% with Matlab 5.3).
%
% Revision 1.21  2003/10/22 19:21:48  michelich
% Removed CVS info variables (they stay in memory after startup).
%
% Revision 1.20  2003/10/22 15:54:33  gadde
% Make some CVS info accessible through variables
%
% Revision 1.19  2003/10/08 23:03:45  michelich
% Add separate MATLAB 6.0 and 6.1 fix directories.
%
% Revision 1.18  2003/05/01 17:00:54  michelich
% Missing semicolon
%
% Revision 1.17  2003/05/01 16:59:56  michelich
% Fix accidental commit changes.
% Only do one which.
%
% Revision 1.16  2003/05/01 16:45:18  michelich
% Updated comments.
%
% Revision 1.15  2003/02/19 18:13:20  michelich
% Get BIACroot from location of this m-file.
% Updated warning message.
%
% Revision 1.14  2003/02/19 16:37:08  michelich
% Revert to using defaults and BIACMATLABROOT to set BIACroot until futher
%   testing of the m-file location method has been completed.
%
% Revision 1.13  2003/02/19 16:10:32  crm
% Use which() to find BIACroot for MATLAB versions prior to 6.5.
%
% Revision 1.12  2003/02/11 17:38:12  crm
% Get BIACroot from location of this m-file.
% Updated comments.
%
% Revision 1.11  2002/10/27 20:10:53  michelich
% clear empty userHome also.
%
% Revision 1.10  2002/10/27 20:03:39  michelich
% Removed colordef none. It is not necessary for BIAC software.
% Only add the KS toolbox if it is present.  Prevents warning using
%   checked out version of BIAC MATLAB software.
%
% Revision 1.9  2002/10/24 19:10:07  michelich
% Removed path to FaceHiLo.  These functions are in matlab/general.
%
% Revision 1.8  2002/10/18 03:14:32  michelich
% Move from matlab/general to matlab/ directory
%
% Revision 1.7  2002/10/17 23:08:23  michelich
% Handle case where HOMEDRIVE and HOMEPATH are not defined.
%
% Revision 1.6  2002/10/10 22:03:28  michelich
% Changed java exist check to a form compatible with MATLAB versions without java support.
%
% Revision 1.5  2002/10/09 20:14:46  michelich
% Add SRB handler to URL handler search path.
%
% Revision 1.4  2002/09/30 19:27:24  crm
% Fixed 6.0-6.1 version check
% Only execute HOMESHARE HOMEPATH startup.m file on a PC
%
% Revision 1.3  2002/09/25 22:43:39  michelich
% Added MATLAB 6.5 fix directory
%
% Revision 1.2  2002/09/06 22:53:27  michelich
% Updated directory locations for new CVS structure
%
% Revision 1.1  2002/08/27 22:24:19  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Francis Favorini,  2001/10/01. Added MATLAB version-specific directory to path.
%                                Look for BIACMATLABROOT env var to find BIAC MATLAB programs.
% Francis Favorini,  2001/08/29. Use HOMEDRIVE instead of HOMESHARE.
%                                Use BIAC subdirectory.
% Francis Favorini,  2000/05/06. Clear startm.
% Francis Favorini,  1999/07/19. Added run startup.m from user's home directory.
% Francis Favorini,  1998/01/16. Initial version.

