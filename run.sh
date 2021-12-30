#!/bin/bash

# RUN BEFORE:
# 1º) user must be in sudoers
#         * su && apt-get install sudo && adduser ${USER} sudo && exit
#         * reboot
# 2º) sudo apt-get install git && mkdir ~/REPOSITORIOS && git clone https://github.com/svg153/configLinux.git ${CONFIG_PATH}/

# configure the /etc/apt/sources.list
# sudo mv /etc/apt/sources.list /etc/apt/sources.list.OLD
# sudo cp ./sources.list /etc/apt/
# sudo sed -i 's/main/main contrib non-free/g' /etc/apt/sources.list


sudo apt-get update && sudo apt-get upgrade && sudo apt-get dist-upgrade && sudo apt-get autoremove


#
# VARS
#

PROGRAMAS_PATH="~/PROGRAMAS/"
REPOS_PATH="~/REPOSITORIOS/"
CONFIG_PATH="${REPOS_PATH}/configLinux/"

alias ins="apt -qq -y install"
alias install="sudo ins"

#
# VARS
#



#
# DRIVERS
#

install firmware-linux lshw


intel=$(lshw | grep CPU | grep Intel | wc -l)
[[ ${intel} -gt 0 ]] && install intel-microcode
amd=$(lshw | grep CPU | grep amd | wc -l)
[[ ${amd} -gt 0 ]] && install amd64-microcode


# install graphics: https://wiki.debian.org/GraphicsCard

# AMD or ATI: https://wiki.debian.org/AtiHowTo
isATI=$(lspci -nn | grep VGA | grep ATI | wc -l)
[[ ${isATI} -ne 0 ]] && install firmware-linux-nonfree libgl1-mesa-dri xserver-xorg-video-ati
# OFFICIAL AMD or ATI:
#    https://wiki.debian.org/ATIProprietary
#    http://support.amd.com/en-us/kb-articles/Pages/AMDGPU-PRO-Install.aspx

# Nvidia: https://wiki.debian.org/NvidiaGraphicsDrivers

# firmware-realtek
install firmware-realtek

# wifi
install wpasupplicant wireless-tools network-manager
# GUI to manage network connections
#    https://wiki.debian.org/WiFi/HowToUse
install network-manager-gnome

# unclaimed drivers
unclaimed=$(sudo lshw | grep UNCLAIMED)
c=$(echo ${unclaimed} | wc -l)
[[ ${c} -ne 0 ]] && echo "Drivers UNCLAIMED" && echo "${unclaimed}" && exit 1

unclaimed=$(sudo lspci | grep UNCLAIMED)
c=$(echo ${unclaimed} | wc -l)
[[ ${c} -ne 0 ]] && echo "Drivers UNCLAIMED" && echo "${unclaimed}" && exit 1



# Multimedia codecs
install \
    libavcodec-extra \
    ffmpeg

# Volume Control: (Optional, Only for Xfce users)
install \
    pavucontrol

# bluetooth
install \
    bluetooth \
    pulseaudio-module-bluetooth \
    bluewho \
    blueman \
    bluez

#
# Drivers
#


# utils
install curl


# package manager
install \
    synaptic \
    apt-xapian-index \
    gdebi \
    gksu

# other packages
install \
    zip unzip \
    xclip \
    wmctrl

apt install unrar

# make tree folders
mkdir "${PROGRAMAS_PATH}"
mkdir ~/.fonts
mkdir ~/.icons



# install zsh
install zsh

# create the symlinks
rm ~/.aliases; ln -s ${CONFIG_PATH}/.aliases ~/.aliases
rm ~/.bashrc; ln -s ${CONFIG_PATH}/.bashrc ~/.bashrc
rm ~/.bash_profile; ln -s ${CONFIG_PATH}/.bash_profile ~/.bash_profile
rm ~/SCRIPTS; ln -s ${CONFIG_PATH}/SCRIPTS ~/SCRIPTS

# GIT
rm ~/.git-template; ln -s ${CONFIG_PATH}/.git-template ~/.git-template
git config --global init.templateDir ~/.git-template


# install .oh-my-zsh
if [[ ${SHELL} != *"zsh"* ]]; then
    sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"

    # configure zsh
    rm ~/.zshrc; ln -s ${CONFIG_PATH}/.zshrc ~/.zshrc

    ZSH_C="${ZSH_CUSTOM:-~/.oh-my-zsh/custom}"
    
    # install zsh plugins
    OMZsh_C_P="${ZSH_C}/plugins/"
    cd ${OMZsh_C_P}
    git clone https://github.com/zsh-users/zsh-autosuggestions 
    git clone https://github.com/zsh-users/zsh-completions
    git clone https://github.com/zsh-users/zsh-navigation-tools
    git clone https://github.com/zsh-users/zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-history-substring-search
    git clone https://github.com/djui/alias-tips.git 
    git clone https://github.com/chrissicool/zsh-256color
    cd -

    install autojump

    OMZsh_C_T="${ZSH_C}/themes/"
    [[ -d ${OMZsh_C_T} ]] && rm -rf ${OMZsh_C_T}
    ln -s ${CONFIG_PATH}/.oh-my-zsh/custom/themes/ ${OMZsh_C_T}

    # clone
    git clone https://github.com/powerline/fonts.git --depth=1
    # install
    cd fonts
    ./install.sh
    # clean-up a bit
    cd ..
    rm -rf fonts


    git clone https://github.com/gabrielelana/awesome-terminal-fonts
    mkdir -p ~/.fonts
    cp awesome-terminal-fonts/build/* ~/.fonts
    fc-cache -fv ~/.fonts
    mkdir -p ~/.config/fontconfig/conf.d
    cp awesome-terminal-fonts/config/10-symbols.conf ~/.config/fontconfig/conf.d
    # echo "Do this 'echo "source ~/.fonts/*.sh" >> ~/.zshrc'"/

    cd -
fi



# Install gitk
install git-gui gitk

# install openvpn
install openvpm resolvconf network-manager-openvpn-gnome


# install google-chrome
deb_filename="google-chrome-stable_current_amd64.deb"
deb_filepath_dw="${PROGRAMAS_PATH}/${deb_filename}"
wget -O ${deb_filepath_dw} https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb ${PROGRAMAS_PATH}
sudo dpkg -i ${deb_filepath_dw}
# fix chrome installation
sudo apt-get --fix-broken-install && sudo apt-get update && install && rm ${deb_filepath_dw}

# Install telegram
wget -O ${PROGRAMAS_PATH}/tsetup.tar.xz https://telegram.org/dl/desktop/linux
cd ${PROGRAMAS_PATH}
tar xvf tsetup.tar.xz
sudo ln -s ${PROGRAMAS_PATH}/Telegram/Telegram /bin/telegram
rm -rf tsetup.tar.xz
cd

# @TODO: Install VSCODE
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
sudo apt-get update
install code

# config keyboard
keyboard_filepath_ori="/etc/default/keyboard"
keyboard_filepath_mine="${CONFIG_PATH}/keyboard"
sudo cp ${keyboard_filepath_ori} ${keyboard_filepath_ori}.OLD
sudo rm ${keyboard_filepath_ori}
if [[ -e "${keyboard_filepath_mine}" ]]; then
  sudo ln -s ${keyboard_filepath_mine} ${keyboard_filepath_ori}
  if [[ $? -ne 0 ]]; then
      sudo cp ${keyboard_filepath_mine} ${keyboard_filepath_ori}
  fi
fi
sudo dpkg-reconfigure -phigh console-setup


# Docker
sudo apt-get -qq -y remove docker docker-engine docker.io containerd runc
sudo apt-get -qq -y update
install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable"
sudo apt-get -qq -y update
install docker-ce docker-ce-cli containerd.io apt-cache madison docker-ce
sudo docker run hello-world
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
docker run hello-world
sudo systemctl enable docker


#
# PROGRAMS
#



#
# APPS
#

# xfce4
install \
    xfce4-whiskermenu-plugin \
    menulibre \
    xfce4-clipman \
    xfce4-panel-dev \
    xfce4-power-manager \
    xfce4-screenshooter \
    xfce4-taskmanager \
    xfce4-terminal \
    xfce4-xkb-plugin

# TODO: Check this apps:
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


install rsync \
    qalculate vlc gimp \
    gparted gnome-disk-utility


# flameshot (new shutter)
install flameshot
flameshot_configfile=".config/flameshot/flameshot.ini"
rm ${flameshot_configfile}
ln -s ${CONFIG_PATH}/${flameshot_configfile} ~/${flameshot_configfile}



#
# APPS
#


#
# CUSTOMIZATION
#

# lightdm
touch /usr/share/lightdm/lightdm.conf.d/01_my.conf
cat >/usr/share/lightdm/lightdm.conf.d/01_my.conf <<EOL
[SeatDefaults]
greeter-hide-users=false
EOL


# fonts
install \
    fonts-dejavu \
    fonts-dejavu-extra \
    fonts-droid-fallback \
    fonts-freefont-ttf \
    fonts-liberation \
    fonts-noto \
    fonts-noto-mono \
    fonts-opensymbol \
    ttf-bitstream-vera \
    ttf-dejavu \
    ttf-dejavu-core \
    ttf-dejavu-extra \
    ttf-freefont \
    ttf-liberation \
    ttf-mscorefonts-installer \
    qt4-qtconfig


# themes
# Numix: https://github.com/numixproject/numix-gtk-theme
sudo add-apt-repository ppa:numix/ppa
sudo apt update
sudo apt install numix-*

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
