#!/bin/bash

# RUN BEFORE:
# 1º) user must be in sudoers
#         * su && apt-get install sudo && adduser ${USER} sudo && exit
#         * reboot
# 2º) sudo apt-get install git && mkdir ~/REPOSITORIOS && git clone https://github.com/svg153/configLinux.git ~/REPOSITORIOS/configLinux/

# configure the /etc/apt/sources.list
sudo sed -i 's/main/main contrib non-free/g' /etc/apt/sources.list


sudo apt-get update && sudo apt-get upgrade && sudo apt-get dist-upgrade && sudo apt-get autoremove

#
# DRIVERS
#

sudo apt-get -qq -y install firmware-linux


intel=`lshw | grep CPU | grep Intel | wc -l`
[[ ${intel} -gt 0 ]] && sudo apt-get -qq -y install intel-microcode
amd=`lshw | grep CPU | grep amd | wc -l`
[[ ${amd} -gt 0 ]] && sudo apt-get -qq -y install amd64-microcode


# install graphics: https://wiki.debian.org/GraphicsCard

# AMD or ATI: https://wiki.debian.org/AtiHowTo
isATI=`lspci -nn | grep VGA | grep ATI | wc -l`
[[ ${isATI} -ne 0 ]] && sudo apt-get -qq -y install firmware-linux-nonfree libgl1-mesa-dri xserver-xorg-video-ati
# OFFICIAL AMD or ATI:
#    https://wiki.debian.org/ATIProprietary
#    http://support.amd.com/en-us/kb-articles/Pages/AMDGPU-PRO-Install.aspx

# Nvidia: https://wiki.debian.org/NvidiaGraphicsDrivers

# firmware-realtek
sudo apt-get -qq -y install firmware-realtek

# wifi
sudo apt-get -qq -y install wpasupplicant wireless-tools network-manager
# GUI to manage network connections
#    https://wiki.debian.org/WiFi/HowToUse
sudo apt-get -qq -y install network-manager-gnome

# unclaimed drivers
sudo lshw | grep UNCLAIMED
c=`sudo lshw | grep UNCLAIMED | wc -l`
#[[ ${c} -ne 0 ]] && exit 1

sudo lspci | grep UNCLAIMED
c=`sudo lspci | grep UNCLAIMED | wc -l` 
#[[ ${c} -ne 0 ]] && exit 1

sudo lshw | grep UNCLAIMED
c=`sudo lspci | grep UNCLAIMED | wc -l`
#[[ ${c} -ne 0 ]] && exit 1




# Multimedia codecs
sudo apt-get -qq -y install libavcodec-extra ffmpeg

# Volume Control: (Optional, Only for Xfce users)
sudo apt-get -qq -y install pavucontrol



#
# Drivers
#

sudo apt-get -qq -y install curl


# package manager
sudo apt-get -qq -y install synaptic apt-xapian-index gdebi gksu


# make tree folders
mkdir ~/PROGRAMAS
mkdir ~/.fonts
mkdir ~/.icons


# install zsh
sudo apt-get -qq -y install zsh \
    unrar unzip



# create the symlinks
rm ~/.aliases; ln -s ~/REPOSITORIOS/configLinux/.aliases ~/.aliases
rm ~/.bashrc; ln -s ~/REPOSITORIOS/configLinux/.bashrc ~/.bashrc
rm ~/SCRIPTS; ln -s ~/REPOSITORIOS/configLinux/SCRIPTS ~/SCRIPTS


# install .oh-my-zsh
if [[ ${SHELL} != *"zsh"* ]]; then
    sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"

    # configure zsh
    rm ~/.zshrc; ln -s ~/REPOSITORIOS/configLinux/.zshrc ~/.zshrc
    rm ~/.oh-my-zsh; ln -s ~/REPOSITORIOS/configLinux/.oh-my-zsh ~/.oh-my-zsh

    # install zsh plugins
    OMZsh_C_P="~/.oh-my-zsh/custom/plugins/"
    git clone https://github.com/zsh-users/zsh-autosuggestions $OMZsh_C_P
    git clone https://github.com/zsh-users/zsh-completions $OMZsh_C_P
    git clone https://github.com/zsh-users/zsh-navigation-tools $OMZsh_C_P
    git clone https://github.com/zsh-users/zsh-output-highlighting $OMZsh_C_P
    git clone https://github.com/zsh-users/zsh-syntax-highlighting $OMZsh_C_P
fi

# install openvpn
sudo apt-get -qq -y install openvpm resolvconf network-manager-openvpn-gnome


# install google-chrome
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb ~/PROGRAMAS
sudo dpkg -i ~/PROGRAMAS/google-chrome-stable_current_amd64.deb
sudo apt-get --fix-broken-install


# install php
# sudo apt-get install php5-common libapache2-mod-php5 php5-cli

# TODO: install php7


# Install telegram
wget -O ~/PROGRAMAS/tsetup.tar.xz https://telegram.org/dl/desktop/linux
cd ~/PROGRAMAS
tar xvf tsetup.tar.xz
sudo ln -s ~/PROGRAMAS/Telegram/Telegram /bin/telegram
rm -rf tsetup.tar.xz
cd

# Install smartgit
cd ~/PROGRAMAS
wget -O ~/PROGRAMAS/smartgit.tar.gz "http://www.syntevo.com/static/smart/download/smartgit/smartgit-linux-17_0_4.tar.gz"
tar xvf smartgit.tar.gz
sudo ln -s ~/PROGRAMAS/smartgit/bin/smartgit.sh /bin/smartgit
rm -rf smartgit.tar.gz
cd

# Install atom
wget -O ~/PROGRAMAS/atom-amd64.deb https://atom.io/download/deb
sudo dpkg -i ~/PROGRAMAS/atom-amd64.deb

# config keyboard
sudo cp /etc/default/keyboard /etc/default/keyboard.OLD
sudo rm /etc/default/keyboard
sudo ln -s ~/REPOSITORIOS/configLinux/keyboard /etc/default/keyboard
if [[ $? -ne 0 ]]; then 
    sudo cp ~/REPOSITORIOS/configLinux/keyboard /etc/default/keyboard
fi


#
# PROGRAMS
# 



#
# APPS
#

sudo apt-get -qq -y install rsync \
    qalculate vlc gimp \
    gparted gnome-disk-utility

# Check this apps:
#file-roller
#evince
#doidon
#clementine
#shotwell
#build-essential
#debian-keyring
#mousepad
#p7zip policykit-1-gnome p7zip-full
#aspell aspell-en hunspell hunspell-en-us mythes-en-us
#ristretto
#thunar-archive-plugin
#ufw
#xarchiver
#xserver-xorg-input-synaptics

#
# APPS
#


#
# CUSTOMIZATION
#


# xfce4
sudo apt-get -qq -y install xfce4-whiskermenu-plugin menulibre xfce4-clipman xfce4-panel-dev xfce4-power-manager xfce4-screenshooter xfce4-taskmanager xfce4-terminal xfce4-xkb-plugin

# lightdm
touch /usr/share/lightdm/lightdm.conf.d/01_my.conf
cat >/usr/share/lightdm/lightdm.conf.d/01_my.conf <<EOL
[SeatDefaults]
greeter-hide-users=false 
EOL


# fonts
sudo apt-get -qq -y install fonts-dejavu fonts-dejavu-extra fonts-droid-fallback fonts-freefont-ttf fonts-liberation fonts-noto fonts-noto-mono fonts-opensymbol ttf-bitstream-vera ttf-dejavu ttf-dejavu-core ttf-dejavu-extra ttf-freefont ttf-liberation ttf-mscorefonts-installer qt4-qtconfig


# themes
# Numix: https://github.com/numixproject/numix-gtk-theme
sudo apt-get -qq -y install numix-gtk-theme numix-icon-theme-circle numix-icon-theme-shine

#
# CUSTOMIZATION
#



#
# CLEAN
#

sudo apt autoremove
sudo apt clean

#
# CLEAN
#


#
# Thanks:
#    https://linuxpanda.wordpress.com/2016/12/31/things-to-do-after-installing-debian-stretch/
#    https://www.youtube.com/watch?v=BWBHJmAmZgk
#    https://www.youtube.com/watch?v=c60x3nd7cag
#    https://www.youtube.com/watch?v=GR2y0xOIIdI
