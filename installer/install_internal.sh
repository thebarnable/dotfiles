#!/bin/bash

set -eu

HOSTNAME=$1
ENCRYPT=$2
LEGACY=$3
RAID=$4
BOOTNAME=$5
USERNAME=$6
LUKSNAME=$7
DISK=$8
CRYPT_PARTITION=$9
REMOVABLE=${10}

echo " ########## Chroot done"

# Install required packets
pacman -Syyy
pacman -Syu

sed -i 's/^#Color/Color/' /etc/pacman.conf

pacman -S --noconfirm --needed base-devel linux-lts linux-lts-headers linux-firmware efibootmgr dosfstools gptfdisk
pacman -S --noconfirm --needed dialog grub intel-ucode amd-ucode dhcpcd arch-install-scripts nano ntfs-3g
pacman -S --noconfirm --needed bash-completion netctl htop iotop openssh mesa net-tools os-prober mtools wpa_supplicant rsync
pacman -S --noconfirm --needed acpid avahi dbus cups system-config-printer tree cmake boost boost-libs openmp gdb
#pacman -S --noconfirm --needed gnome gnome-extra gnome-shell-extensions chrome-gnome-shell gdm xorg xorg-server gnome-tweaks
pacman -S --noconfirm --needed gedit-plugins meld pavucontrol firefox libreoffice-fresh-de rhythmbox evince gparted
pacman -S --noconfirm --needed xorg xorg-server xorg-xinit xterm i3-gaps i3lock lightdm lightdm-gtk-greeter termite nitrogen feh archlinux-wallpaper picom capitaine-cursors dmenu xautolock thunar
pacman -S --noconfirm --needed alsa nvidia-lts nvidia-utils nvtop ttf-dejavu
pacman -S --noconfirm --needed networkmanager networkmanager-openconnect network-manager-applet bluez bluez-utils pulseaudio-bluetooth 
pacman -S --noconfirm --needed gst-libav libgtop ntp hunspell hunspell-de hunspell-en_US
pacman -S --noconfirm --needed lshw pwgen gst-plugins-base gst-plugins-good gst-plugins-ugly
pacman -S --noconfirm --needed pulseeffects cppcheck git wget cifs-utils byobu
pacman -S --noconfirm --needed chromium vim

sed -i 's/Adwaita/capitaine-cursors/g' /usr/share/icons/default/index.theme

systemctl enable sshd
#systemctl enable dhcpcd
systemctl enable lightdm.service
#systemctl enable gdm
systemctl enable acpid
systemctl enable avahi-daemon
systemctl enable org.cups.cupsd.service
systemctl enable bluetooth
systemctl enable NetworkManager
systemctl enable ntpd.service
systemctl enable --now fstrim.timer | true
echo " ########## Installing done"

# Settings
echo "$HOSTNAME" > /etc/hostname
echo "LANG=en_US.UTF-8" > /etc/locale.conf
ln -s /usr/share/zoneinfo/Europe/Berlin /etc/localtime
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "KEYMAP=de" >> /etc/vconsole.conf
localectl set-x11-keymap de pc105 nodeadkeys
echo "Please set a new root password:"
while ! passwd
do
  echo "Try again"
done
sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
echo " ########## Settings done"

# initfsram
if [ "$ENCRYPT" = true ]; then
  echo "Adding \"encrypt\" after \"block\" before \"filesystems\""
  sed -iE 's/\(^HOOKS.*\)\(filesystems\)/\1encrypt \2/' /etc/mkinitcpio.conf # adding encrypt before filesystems
  sed -iE 's/\(^HOOKS.*\)\( keyboard\)/\1/' /etc/mkinitcpio.conf # removing keyboard
  sed -iE 's/\(^HOOKS.*\)\(autodetect\)/\1keyboard \2/' /etc/mkinitcpio.conf #adding keboard before autodetect
  #sed -iE 's/\(^HOOKS.*autodetect\)\(\)/\1 keyboard/' /etc/mkinitcpio.conf #adding keyboard behind autodetect
fi
if [ "$RAID" = true ]; then
  echo "Enter your mail address:"
  read
  nano /etc/mdadm.conf
  sed -iE 's/\(^HOOKS.*block\)\(\)/\1 mdadm_udev/' /etc/mkinitcpio.conf #adding mdadm_udev behind block
fi
mkinitcpio -p linux-lts
echo " ########## Initfsram done"

# Grub
if $LEGACY; then
  echo "Installing grub in legacy mode"
  grub-install --target=i386-pc --recheck $DISK
else
  echo "Installing grub in efi mode"
  if $REMOVABLE; then
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=$BOOTNAME --recheck --removable
  else
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=$BOOTNAME --recheck 
  fi
fi

if [ "$ENCRYPT" = true ]; then
  PARAMETERS="cryptdevice=UUID=$(blkid -o value ${CRYPT_PARTITION} | head -n1):$LUKSNAME root=/dev/mapper/$LUKSNAME"
  echo "Adding to GRUB_CMDLINE_LINUX=\"$PARAMETERS\""
  sed -iE "s|\(^GRUB_CMDLINE_LINUX=\".*\)\(\"\)|\1 $PARAMETERS\ \2|" /etc/default/grub
fi
os-prober 
grub-mkconfig -o /boot/grub/grub.cfg
echo " ########## Grub done"

# adduser
groupadd sudo
EDITOR=nano visudo
useradd -m -g users -s /bin/bash -G sudo $USERNAME
chfn $USERNAME

echo "Please set a new password for user $USERNAME"
while ! passwd $USERNAME
do
  echo "Try again"
done

usermod -a -G power $USERNAME
usermod -a -G games $USERNAME
usermod -a -G video $USERNAME
usermod -a -G audio $USERNAME
usermod -a -G uucp $USERNAME
echo " ########## Adduser done"

# Other
exit
