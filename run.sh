#!/bin/bash

# RUN BEFORE:
# 1º) user must be in sudoers
#         * su && apt-get install sudo && adduser ${USER} sudo && exit
#         * reboot
# 2º) sudo apt-get install git && mkdir ~/REPOSITORIOS && git clone https://github.com/svg153/configLinux.git ~/REPOSITORIOS/configLinux/

# configure the /etc/apt/sources.list
# sudo mv /etc/apt/sources.list /etc/apt/sources.list.OLD
# sudo cp ./sources.list /etc/apt/
# sudo sed -i 's/main/main contrib non-free/g' /etc/apt/sources.list


sudo apt-get update && sudo apt-get upgrade && sudo apt-get dist-upgrade && sudo apt-get autoremove


#
# VARS
#

PROGRAMAS_PATH="~/PROGRAMAS/"

#
# VARS
#



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

# other packages
sudo apt-get -qq -y install \
    zip unzip unrar \
    xclip \
    shutter \
    wmctrl

# make tree folders
mkdir "${PROGRAMAS_PATH}"
mkdir ~/.fonts
mkdir ~/.icons

# install zsh
sudo apt-get -qq -y install zsh




# create the symlinks
rm ~/.aliases; ln -s ~/REPOSITORIOS/configLinux/.aliases ~/.aliases
rm ~/.bashrc; ln -s ~/REPOSITORIOS/configLinux/.bashrc ~/.bashrc
rm ~/.bash_profile; ln -s ~/REPOSITORIOS/configLinux/.bash_profile ~/.bash_profile
rm ~/SCRIPTS; ln -s ~/REPOSITORIOS/configLinux/SCRIPTS ~/SCRIPTS


# install .oh-my-zsh
if [[ ${SHELL} != *"zsh"* ]]; then
    sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"

    # configure zsh
    rm ~/.zshrc; ln -s ~/REPOSITORIOS/configLinux/.zshrc ~/.zshrc

    # install zsh plugins
    OMZsh_C_P="${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/"
    git clone https://github.com/zsh-users/zsh-autosuggestions ${OMZsh_C_P}
    git clone https://github.com/zsh-users/zsh-completions ${OMZsh_C_P}
    git clone https://github.com/zsh-users/zsh-navigation-tools ${OMZsh_C_P}
    git clone https://github.com/zsh-users/zsh-syntax-highlighting ${OMZsh_C_P}
    git clone https://github.com/ricardrobin/zsh-output-highlighting ${OMZsh_C_P}
    git clone https://github.com/djui/alias-tips.git ${OMZsh_C_P}
fi

# install openvpn
sudo apt-get -qq -y install openvpm resolvconf network-manager-openvpn-gnome


# install google-chrome
deb_filename="google-chrome-stable_current_amd64.deb"
deb_filepath_dw="${PROGRAMAS_PATH}/${deb_filename}"
wget -O ${deb_filepath_dw} https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb ${PROGRAMAS_PATH}
sudo dpkg -i ${deb_filepath_dw}
# fix chrome installation
sudo apt-get --fix-broken-install && sudo apt-get update && sudo apt-get -qq -y install && rm ${deb_filepath_dw}


# install php
# sudo apt-get install php5-common libapache2-mod-php5 php5-cli

# TODO: install php7


# Install telegram
wget -O ${PROGRAMAS_PATH}/tsetup.tar.xz https://telegram.org/dl/desktop/linux
cd ${PROGRAMAS_PATH}
tar xvf tsetup.tar.xz
sudo ln -s ${PROGRAMAS_PATH}/Telegram/Telegram /bin/telegram
rm -rf tsetup.tar.xz
cd

# Install smartgit
deb_filename="smartgit-17_1_2.deb"
deb_filepath_dw="${PROGRAMAS_PATH}/${deb_filename}"
wget -O ${deb_filepath_dw} http://www.syntevo.com/smartgit/download?file=smartgit/smartgit-17_1_2.deb
sudo dpkg -i ${deb_filepath_dw}
rm ${deb_filepath_dw}

# Install atom
# deb_filename="atom-amd64.deb"
# deb_filepath_dw="${PROGRAMAS_PATH}/${deb_filename}"
# wget -O ${deb_filepath_dw} https://atom.io/download/deb
# sudo dpkg -i ${deb_filepath_dw}
# rm ${deb_filepath_dw}

# @TODO: Install VSCODE
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
sudo apt-get update
sudo apt-get install -qq -y code

# Install Lightworks
deb_filename="lwks-14.0.0-amd64.deb"
deb_filepath_dw="${PROGRAMAS_PATH}/${deb_filename}"
wget -O ${deb_filepath_dw} https://downloads.lwks.com/v14/${deb_filename}
sudo dpkg -i ${deb_filepath_dw}
rm ${deb_filepath_dw}

# config keyboard
keyboard_filepath_ori="/etc/default/keyboard"
keyboard_filepath_mine="~/REPOSITORIOS/configLinux/keyboard"
sudo cp ${keyboard_filepath_ori} ${keyboard_filepath_ori}.OLD
sudo rm ${keyboard_filepath_ori}
if [[ -e "${keyboard_filepath_mine}" ]]; then
  sudo ln -s ${keyboard_filepath_mine} ${keyboard_filepath_ori}
  if [[ $? -ne 0 ]]; then
      sudo cp ${keyboard_filepath_mine} ${keyboard_filepath_ori}
  fi
fi
sudo dpkg-reconfigure -phigh console-setup

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

# Xfce-dust-svg153
sudo cp -r ./themes/* /usr/share/themes/

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
