#!/bin/bash

mkdir /var/run/sshd

cp /usr/share/applications/matlab.desktop /home/ubuntu/Desktop/matlab.desktop
cp /usr/share/applications/matlab.desktop /home/ubuntu/.local/share/applications/matlab.desktop

# make sure they own their home directory
chown -R ubuntu ~ubuntu ; chgrp -R ubuntu ~ubuntu

# set the passwords for the user and the x11vnc session
# based on environment variables (if present), otherwise roll with
# the defaults from the Dockerfile build. 
#
# I'm clearing the environmental variables used for passwords after
# setting them because the presumption is users will only access this 
# container via a web browser referral from a seperately authenticated 
# page, so I don't want to leak password info via these variables

if [ ! -z $VNCPASS ] 
then
  /bin/echo "ubuntu:$VNCPASS" | /usr/sbin/chpasswd
  /usr/bin/x11vnc -storepasswd $VNCPASS  /home/root/.vnc/passwd
  VNCPASS=''
fi

exit 0
