#!/bin/bash

# install
sudo apt-get -qq -y update
sudo apt-get -qq -y install git zsh zip unrar arandr

# mkdir REPOSITORIOS
mkdir ~/REPOSITORIOS

# clone the configLinux repo
# git clone https://github.com/svg153/configLinux.git

# create the symlinks
rm ~/.aliases; ln -s ~/REPOSITORIOS/configLinux/.aliases ~/.aliases
rm ~/.bashrc; ln -s ~/REPOSITORIOS/configLinux/.bashrc ~/.bashrc
rm ~/SCRIPTS; ln -s ~/REPOSITORIOS/configLinux/SCRIPTS ~/SCRIPTS


# install .oh-my-zsh
sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"

# configure zsh
rm ~/.zshrc; ln -s ~/REPOSITORIOS/configLinux/.zshrc ~/.zshrc

# install zsh plugins
OMZsh_C_P="~/.oh-my-zsh/custom/plugins/"
git clone https://github.com/zsh-users/zsh-autosuggestions $OMZsh_C_P
git clone https://github.com/zsh-users/zsh-completions $OMZsh_C_P
git clone https://github.com/zsh-users/zsh-navigation-tools $OMZsh_C_P
git clone https://github.com/zsh-users/zsh-output-highlighting $OMZsh_C_P
git clone https://github.com/zsh-users/zsh-syntax-highlighting $OMZsh_C_P

# install php
# sudo apt-get install php5-common libapache2-mod-php5 php5-cli

# TODO: install php7


mkdir ~/PROGRAMAS

# Install telegram
wget https://telegram.org/dl/desktop/linux ~/PROGRAMAS
cd ~/PROGRAMAS
extract -r tsetup*
sudo ln -s ~/PROGRAMAS/Telegram/Telegram /bin/telegram
cd

# Install smartgit
wget http://www.syntevo.com/smartgit/download?file=smartgit/smartgit-17_1_2.deb ~/PROGRAMAS
sudo dpkg -i ~/PROGRAMAS/smartgit-17_1_2.deb
rm ~/PROGRAMAS/smartgit-17_1_2.deb

# Install atom
wget https://atom.io/download/deb ~/PROGRAMAS
sudo dpkg -i ~/PROGRAMAS/atom-amd64.deb
rm ~/PROGRAMAS/atom-amd64.deb

# config keyboard
# sudo rm /etc/default/keyboard
# sudo ln -s ~/REPOSITORIOS/configLinux/keyboard /etc/default/keyboard


# For themes
# sudo apt-get install unity-tweak-tool

# install numix icon pack for ubuntu
# http://www.ubuntufree.com/download-numix-theme/
# sudo add-apt-repository ppa:numix/ppa
# sudo apt-get update
# sudo apt-get install numix-gtk-theme numix-icon-theme-circle numix-icon-theme-shine

# install paper icon pack for ubuntu
# https://itsfoss.com/best-icon-themes-ubuntu-16-04/
# sudo add-apt-repository ppa:snwh/pulp
# sudo apt-get update
# sudo apt-get install paper-gtk-theme paper-icon-theme

# install icon shadow pack for ubuntu
# https://itsfoss.com/best-icon-themes-ubuntu-16-04/
# sudo add-apt-repository ppa:noobslab/icons
# sudo apt-get update
# sudo apt-get install shadow-icon-theme
