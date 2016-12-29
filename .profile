# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin directories
PATH="$HOME/bin:$HOME/.local/bin:$PATH"

# set PATH for Android Studio
ANDROID_STUDIO="/usr/local/android-studio/bin"
if [ -d "$ANDROID_STUDIO" ] ; then
  PATH="$PATH:$ANDROID_STUDIO"
fi

# set PATH for Android SDK
ANDROID_SDK="~/Android/Sdk/tools"
if [ -d $ANDROID_SDK ] ; then
  PATH="$PATH:$ANDROID_SDK"
fi


#export VAGRANT_HOME="$HOME/.vagrant.d/"
#export VAGRANT_CWD="$HOME/vagrant/androtest"
#export VAGRANT_VAGRANTFILE="$HOME/vagrant/androtest"

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting
