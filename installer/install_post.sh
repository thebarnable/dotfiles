#!/bin/bash

set -u

sudo localectl set-x11-keymap de pc105 nodeadkeys
sudo timedatectl set-ntp true
sudo ln -s /usr/bin/gnome-terminal /usr/bin/x-terminal-emulator
sudo ln -s /usr/bin/libtinfo.so /usr/bin/libtinfo.so.5
sudo chown $USER:users -R /home/$USER/scripts /home/$USER/.bashrc /home/$USER/.gitconfig
gsettings set org.gnome.gedit.preferences.editor insert-spaces true
gsettings set org.gnome.gedit.preferences.editor tabs-size 2
gsettings set org.gnome.gedit.preferences.editor scheme 'oblivion'
ssh-keygen -b4096
