ln -s ./.aliases ~/.aliases
ln -s ./.bashrc ~/.bashrc
ln -s ./.z.sh ~/.z.sh
ln -s ./SCRIPTS ~/SCRIPTS


# install zsh
sudo apt-get install zsh
rm ~/.zshrc
ln -s ./.zshrc ~/.zshrc

# install .oh-my-zsh
sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
