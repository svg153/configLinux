ln -s ./.aliases ~/.aliases
ln -s ./.bashrc ~/.bashrc
ln -s ./.z.sh ~/.z.sh
ln -s ./SCRIPTS ~/SCRIPTS


# install zsh
sudo apt-get install zsh

# install .oh-my-zsh
sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"

# configure zsh
rm ~/.zshrc
ln -s ./.zshrc ~/.zshrc




# For themes
sudo apt-get install unity-tweak-tool

# install numix icon pack for ubuntu 
# http://www.ubuntufree.com/download-numix-theme/
sudo add-apt-repository ppa:numix/ppa
sudo apt-get update
sudo apt-get install numix-gtk-theme numix-icon-theme-circle numix-icon-theme-shine

# install paper icon pack for ubuntu 
# https://itsfoss.com/best-icon-themes-ubuntu-16-04/
sudo add-apt-repository ppa:snwh/pulp
sudo apt-get update
sudo apt-get install paper-gtk-theme paper-icon-theme

# install icon shadow pack for ubuntu 
# https://itsfoss.com/best-icon-themes-ubuntu-16-04/
sudo add-apt-repository ppa:noobslab/icons
sudo apt-get update
sudo apt-get install shadow-icon-theme

