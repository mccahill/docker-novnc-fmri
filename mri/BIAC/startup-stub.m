%STARTUP Local BIAC startup M-file.
%
% Local startup file which executes startup file in the BIAC MATLAB
% software installation.
%
% PC Installation Instructions: (Once per machine)
%    copy startup-stub.m %MATLAB%\toolbox\local\startup.m
% or on MATLAB 6 and older:
%    copy startup-stub.m %MATLAB%\toolbox\matlab\startup.m
%
% UNIX Installation Instructions: (Once per user)
%    cp startup-stub.m ~/matlab/startup.m
%
% This system allows updating the central startup.m file without 
% touching each of the computer installations.
%
% Note: If the BIAC software is not installed in the standard location
%       or you wish to override the standard locations, set the
%       BIACMATLABROOT environment varaible to point to the location of
%       the BIAC software you wish to use.
%

% CVS ID and authorship of this code
% $Id: startup-stub.m,v 1.17 2009/04/17 20:22:12 gadde Exp $

% Allow user to specify startup file location
BIACroot=getenv('BIACMATLABROOT');
if isempty(BIACroot)
  % Use default location
  if isunix
    BIACroot='~/net/munin/data/Programs/MATLAB/BIAC';
  else
    BIACroot='\\Munin\Data\Programs\MATLAB\BIAC';
  end
end

startm=fullfile(BIACroot,'startup.m');
if exist(startm,'file')
  run(startm);
else
  warning(sprintf(['Unable to locate central BIAC startup.m file\n  (%s).\n' ...
      '  Connect to network or set BIACMATLABROOT environment variable.\n'],startm));
end
clear startm BIACroot

% Modification History:
%
% $Log: startup-stub.m,v $
% Revision 1.17  2009/04/17 20:22:12  gadde
% Move programs share from gall to hill
%
% Revision 1.16  2006/07/14 21:20:15  gadde
% Updates for gzip reading
%
% Revision 1.15  2004/06/24 22:29:37  michelich
% Clear BIACroot.
%
% Revision 1.14  2004/05/06 15:15:22  gadde
% Remove all dependencies on ispc and nargoutchk (for compatibility
% with Matlab 5.3).
%
% Revision 1.13  2003/10/22 19:21:48  michelich
% Removed CVS info variables (they stay in memory after startup).
%
% Revision 1.12  2003/10/22 15:54:33  gadde
% Make some CVS info accessible through variables
%
% Revision 1.11  2003/10/14 20:53:01  michelich
% Changed default UNIX installation directory.
%
% Revision 1.10  2003/09/04 17:00:51  dias
% changed default path for UNIX systems
%
% Revision 1.9  2003/05/01 16:58:38  michelich
% Updated comments.
%
% Revision 1.8  2003/04/30 22:39:57  michelich
% Changed default location of distribution.
%
% Revision 1.7  2003/02/19 17:08:23  michelich
% Updated warning message.
%
% Revision 1.6  2003/02/19 16:14:33  michelich
% Corrected UNIX installation command.
%
% Revision 1.5  2003/02/11 17:40:00  crm
% Added different default path for UNIX systems.
% Updated comments.
%
% Revision 1.4  2002/10/18 03:19:27  michelich
% Update for new startup.m location
%
% Revision 1.3  2002/10/18 03:14:46  michelich
% Move from matlab/general to matlab/ directory
%
%
% Revision 1.2  2002/10/09 20:17:36  michelich
% Allow user to specify startup file location.
%
% Revision 1.1  2002/08/27 22:24:19  michelich
% Initial CVS Import
%
%
% Pre CVS History Entries:
% Francis Favorini,  2001/10/01. Just run central startup.m from network.

