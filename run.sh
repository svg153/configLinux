


# install git, unrar, zsh
sudo apt-get install git zsh unrar

# mkdir REPOSITORIOS
mkdir ~/REPOSITORIOS

# clone the configLinux repo
git clone https://github.com/svg153/configLinux.git

# create the symlinks
rm ~/.aliases; ln -s ~/REPOSITORIOS/configLinux/.aliases ~/.aliases
rm ~/.bashrc; ln -s ~/REPOSITORIOS/configLinux/.bashrc ~/.bashrc
rm ~/SCRIPTS; ln -s ~/REPOSITORIOS/configLinux/SCRIPTS ~/SCRIPTS


# install .oh-my-zsh
sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"

# configure zsh
rm ~/.zshrc; ln -s ~/REPOSITORIOS/configLinux/.zshrc ~/.zshrc
rm ~/.oh-my-zsh; ln -s ~/REPOSITORIOS/configLinux/.oh-my-zsh ~/.oh-my-zsh

# install php
sudo apt-get install php5-common libapache2-mod-php5 php5-cli

mkdir ~/PROGRAMAS

# Install telegram
wget https://telegram.org/dl/desktop/linux ~/PROGRAMAS
cd ~/PROGRAMAS
extract -r tsetup*
sudo ln -s ~/PROGRAMAS/Telegram/Telegram /bin/telegram
cd

# Install smartgit
cd ~/PROGRAMAS
wget http://www.syntevo.com/smartgit/download?file=smartgit/smartgit-linux-8_0_3.tar.gz ~/PROGRAMAS
extract -r smartgit-linux*
sudo ln -s ~/PROGRAMAS/smartgit/bin/smartgit.sh /bin/smartgit
cd

# Install atom
wget https://atom.io/download/deb ~/PROGRAMAS
sudo dpkg -i ~/PROGRAMAS/atom-amd64.deb

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
