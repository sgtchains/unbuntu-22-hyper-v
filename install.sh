#!/bin/bash2
sudo apt update
sudo apt upgrade -y
sudo apt install -y linux-tools-virtual linux-cloud-tools-virtual xrdp
sudo systemctl stop xrdp xrdp-sesman
sudo sed -i.orig -e 's/port=3389/port=vsock:\/\/-1:3389/g' /etc/xrdp/xrdp.ini
sudo sed -i.orig -e 's/security_layer=negotiate/security_layer=rdp/g' \
 /etc/xrdp/xrdp.ini
sudo sed -i.orig -e 's/crypt_level=high/crypt_level=none/g' /etc/xrdp/xrdp.ini
sudo sed -i.orig -e 's/bitmap_compression=true/bitmap_compression=false/g' \
  /etc/xrdp/xrdp.ini
if [ ! -e /etc/xrdp/startubuntu.sh ]; then
cat<<EOF | sudo cat - > /etc/xrdp/startubuntu.sh
#!/bin/sh
export GNOME_SHELL_SESSION_MODE=ubuntu
export XDG_CURRENT_DESKTOP=ubuntu:GNOME
exec /etc/xrdp/startwm.sh
EOF
sudo chmod a+x /etc/xrdp/startubuntu.sh
fi
sudo sed -i.orig -e 's/startwm/startubuntu/g' /etc/xrdp/sesman.ini
sudo sed -i -e \
  's/FuseMountName=thinclient_drives/FuseMountName=shared-drives/g' \
  /etc/xrdp/sesman.ini
sudo sed -i.orig -e 's/allowed_users=console/allowed_users=anybody/g' \
  /etc/X11/Xwrapper.config
if [ ! -e /etc/modprobe.d/blacklist-vmw_vsock_vmci_transport.conf ]; then
  sudo echo "blacklist vmw_vsock_vmci_transport" > \
  /etc/modprobe.d/blacklist-vmw_vsock_vmci_transport.conf
fi
if [ ! -e /etc/modules-load.d/hv_sock.conf ]; then
  sudo echo "hv_sock" > /etc/modules-load.d/hv_sock.conf
fi
cat<<EOF | sudo cat - > \
  /etc/polkit-1/localauthority/50-local.d/45-allow-colord.pkla
[Allow Colord all Users]
Identity=unix-user:*
Action=org.freedesktop.color-manager.create-device;\
org.freedesktop.color-manager.create-profile;\
org.freedesktop.color-manager.delete-device;\
org.freedesktop.color-manager.delete-profile;\
org.freedesktop.color-manager.modify-device;\
org.freedesktop.color-manager.modify-profile
ResultAny=no
ResultInactive=no
ResultActive=yes
EOF
sudo apt-get install -y git libpulse-dev autoconf m4 intltool \
  build-essential dpkg-dev libtool libsndfile1-dev \
  libspeexdsp-dev libudev-dev
sudo sed -E -i.orig 's/^# deb-src /deb-src /' /etc/apt/sources.list
sudo apt-get update
#cd /tmp
#ls pulseaudio* >/dev/null 2>&1 && sudo rm -rf ./pulseaudio*
#sudo apt build-dep -y pulseaudio
#apt source pulseaudio
#cd $(find /tmp -maxdepth 1 -type d -name 'pulseaudio*')
#meson build
#meson compile -C build
#build/src/daemon/pulseaudio -n -F build/src/daemon/default.pa -p $(pwd)/build/src/
cd /tmp 
git clone https://github.com/neutrinolabs/pulseaudio-module-xrdp.git
cd pulseaudio-module-xrdp
scripts/install_pulseaudio_sources_apt_wrapper.sh
./bootstrap
./configure PULSE_DIR=~/pulseaudio.src
sudo make install
