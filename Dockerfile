FROM ubuntu:14.04
MAINTAINER Mark McCahill <mccahill@duke.edu>

ENV DEBIAN_FRONTEND noninteractive
ENV HOME /root

# setup our Ubuntu sources (ADD breaks caching)
RUN echo "deb http://archive.ubuntu.com/ubuntu trusty main restricted universe multiverse\n\
deb http://archive.ubuntu.com/ubuntu trusty-updates main restricted universe multiverse\n\
deb http://archive.ubuntu.com/ubuntu trusty-backports main restricted universe multiverse\n\ 
deb http://security.ubuntu.com/ubuntu trusty-security main restricted universe multiverse \n\
"> /etc/apt/sources.list

# no Upstart or DBus
# https://github.com/dotcloud/docker/issues/1724#issuecomment-26294856
RUN apt-mark hold initscripts udev plymouth mountall
RUN dpkg-divert --local --rename --add /sbin/initctl && ln -sf /bin/true /sbin/initctl
RUN apt-get update \
    && apt-get upgrade -y

RUN apt-get install -y --force-yes --no-install-recommends \
        python-numpy \ 
        software-properties-common \
        wget \
        supervisor \
        openssh-server \
        pwgen \
        sudo \
        vim-tiny \
        net-tools \
        lxde \
        x11vnc \
        xvfb \
        gtk2-engines-murrine \
        ttf-ubuntu-font-family \
        firefox \
        xserver-xorg-video-dummy \
    && apt-get autoclean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/supervisor/conf.d
RUN rm /etc/supervisor/supervisord.conf

# create an ubuntu user 
RUN useradd --create-home --shell /bin/bash --user-group --groups adm,sudo ubuntu
RUN echo "ubuntu:badpassword" | chpasswd

ADD initialize.sh /
ADD supervisord.conf.xorg /etc/supervisor/supervisord.conf
EXPOSE 6080
EXPOSE 5900

ADD openbox-config /openbox-config
RUN cp -r /openbox-config/.config ~ubuntu/
RUN chown -R ubuntu ~ubuntu/.config ; chgrp -R ubuntu ~ubuntu/.config
RUN rm -r /openbox-config

# noVNC
ADD noVNC /noVNC/
# store a password for the VNC service
RUN mkdir /home/root
RUN mkdir /home/root/.vnc
RUN x11vnc -storepasswd foobar /home/root/.vnc/passwd
ADD xorg.conf /etc/X11/xorg.conf

##########################################
# MRI workshop-specific items:
#
# directory that holds BIAC, mricron_lx,  spm12
ADD mri /mri/
#
# fsl-complete
#
RUN echo "deb http://neuro.debian.net/debian data main contrib non-free\n\
#deb-src http://neuro.debian.net/debian data main contrib non-free\n\
deb http://neuro.debian.net/debian trusty main contrib non-free\n\
#deb-src http://neuro.debian.net/debian trusty main contrib non-free\n\
"> /etc/apt/sources.list.d/neurodebian.sources.list
RUN DEBIAN_FRONTEND=noninteractive apt-key adv --recv-keys --keyserver hkp://pgp.mit.edu:80 0xA5D32F012649A5A9
RUN apt-get update 
RUN apt-get install -y --force-yes fsl-complete
#
#
#
RUN apt-get install -y --force-yes unzip
#
# qt4 is needed by medInria
RUN apt-get install -y --force-yes qt4-default libqt4-sql-sqlite
#
##########################################
#
# desktop file(s) for apps
ADD desktop-icons/matlab-mri.desktop /usr/share/applications/matlab-mri.desktop
ADD desktop-icons/mricron.desktop /usr/share/applications/mricron.desktop
ADD desktop-icons/fsl.desktop /usr/share/applications/fsl.desktop
ADD desktop-icons/medinria.desktop /usr/share/applications/medinria.desktop

#ENTRYPOINT ["/usr/bin/supervisord", "--nodaemon", "-c", "/etc/supervisor/supervisord.conf"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]

