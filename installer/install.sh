#!/bin/bash

set -eu

#loadkeys de

HOSTNAME="beastix"
BOOTNAME="arch_efi" # ignored on legacy
USERNAME="tim"
DISK="/dev/nvme0n1" # nvme1n1 #important for legacy install
PARTITION=$DISK"p"
LEGACY=false
ENCRYPT=false
REMOVABLE=false
RAID=false
DUALBOOT=true
LUKSNAME="crypt_root"
DOTFILES="/home/tim/.config/dotfiles"
AUTO_PARTITION=false # if true, auto detect partition names (overrides *_PARTITION)
EFI_PARTITION=$PARTITION"1"
BOOT_PARTITION=$PARTITION"7"
MAIN_PARTITION=$BOOT_PARTITION

# Partition names
if $AUTO_PARTITION; then
  if $DUALBOOT; then
    echo "ERROR: don't use AUTO_PARTITION option on dualboot system. Choose the partitions on your own!"
    exit 1
  fi

  EFI_PARTITION=$PARTITION"1"
  if $LEGACY; then
    BOOT_PARTITION=$EFI_PARTITION
    if ! $ENCRYPT; then
      MAIN_PARTITION=$BOOT_PARTITION
    else
      MAIN_PARTITION=$PARTITION"2"
    fi
  else
    BOOT_PARTITION=$PARTITION"2"
    if ! $ENCRYPT; then
      MAIN_PARTITION=$BOOT_PARTITION
    else
      MAIN_PARTITION=$PARTITION"3"
    fi
  fi
fi


OWN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SCRIPT="$OWN_DIR/install_internal.sh"

if [ "$EUID" -ne 0 ]; then
  echo "This script has to be executed as sudo!"
  exit 1
fi

# Partitions
if $LEGACY; then
  if $DUALBOOT; then
    echo "WARNING: Dualboot has only been tested with UEFI setup yet"
  fi

  if ! $ENCRYPT; then
    echo "Create MBR with one partitions, bootable!"
  else
    echo "Create MBR with two partitions, first 400M and bootable!"
  fi

  read
  fdisk $DISK
  sleep 1
else
  if $ENCRYPT; then
    echo "Create GPT with three partitions, first both 400M and first ef00!"
  else
    echo "Create GPT with two partitions, first 400M and first ef00!"
  fi

  read
  gdisk $DISK
  sleep 1
fi

# Filesystems
if [ $LEGACY == false ] && [ $DUALBOOT == false ]; then
  mkfs.msdos -F 32 $EFI_PARTITION
fi

mkfs.ext4 $BOOT_PARTITION # == MAIN_PARTITION if no crypt

if $ENCRYPT; then
  #echo "BUG: Workarount: Create luks with gnome-disks! Press any key to continue..."
  #read
  cryptsetup -v --cipher aes-xts-plain64 --key-size 512 --hash sha512 --verify-passphrase --iter-time 5000 --use-random luksFormat $MAIN_PARTITION
  cryptsetup open $MAIN_PARTITION $LUKSNAME
  mkfs.ext4 /dev/mapper/$LUKSNAME

  mount /dev/mapper/$LUKSNAME /mnt/
  mkdir /mnt/boot
  mount $BOOT_PARTITION /mnt/boot
else
  mount $MAIN_PARTITION /mnt
  mkdir /mnt/boot
fi

if ! $LEGACY; then
  mkdir -p /mnt/boot/efi
  mount $EFI_PARTITION /mnt/boot/efi
fi

echo " ########## Partitioning done"


# Install
pacstrap -i /mnt base
genfstab -Up /mnt >> /mnt/etc/fstab
if $RAID; then
  mdadm --detail --scan >> /mnt/etc/mdadm.conf
fi
cp -f $SCRIPT /mnt/
arch-chroot /mnt/ /bin/bash $(basename $SCRIPT) $HOSTNAME $ENCRYPT $LEGACY $RAID $BOOTNAME $USERNAME $LUKSNAME $DISK $MAIN_PARTITION $REMOVABLE
rm /mnt/$(basename $SCRIPT)

mkdir -p /mnt/home/$USERNAME/.config
cp -r $DOTFILES /mnt/home/$USERNAME/.config/dotfiles

ln -rs /mnt/home/$USERNAME/.config/dotfiles/termite /mnt/home/$USERNAME/.config/termite
ln -rs /mnt/home/$USERNAME/.config/dotfiles/i3 /mnt/home/$USERNAME/.config/i3
ln -rsf /mnt/home/$USERNAME/.config/dotfiles/bash/.bashrc /mnt/home/$USERNAME/.bashrc
ln -rs /mnt/home/$USERNAME/.config/dotfiles/vim /mnt/home/$USERNAME/.config/vim
ln -rs /mnt/home/$USERNAME/.config/dotfiles/git/.gitconfig /mnt/home/$USERNAME/.gitconfig
cp /mnt/usr/share/git/git-prompt.sh /mnt/home/$USERNAME/.git-prompt.sh
ln -rs /mnt/home/$USERNAME/.config/dotfiles/nitrogen /mnt/home/$USERNAME/.config/nitrogen
ln -rs /mnt/home/$USERNAME/.config/dotfiles/polybar /mnt/home/$USERNAME/.config/polybar
ln -rs /mnt/home/$USERNAME/.config/dotfiles/conky /mnt/home/$USERNAME/.config/conky
ln -rs /mnt/home/$USERNAME/.config/dotfiles/compton /mnt/home/$USERNAME/.config/compton
ln -rs /mnt/home/$USERNAME/.config/dotfiles/X11/.Xresources /mnt/home/$USERNAME/.Xresources
ln -rs /mnt/home/$USERNAME/.config/dotfiles/X11/.xinitrc /mnt/home/$USERNAME/.xinitrc
ln -rs /mnt/home/$USERNAME/.config/dotfiles/installer/install_post.sh /mnt/home/$USERNAME/install_post.sh
cp /mnt/home/$USERNAME/.config/dotfiles/scripts/* /mnt/usr/bin/

mv /mnt/etc/skel/.bashrc /mnt/etc/skel/.bashrc.bak
cp /mnt/home/$USERNAME/.bashrc /mnt/etc/skel/
cp /mnt/home/$USERNAME/.gitconfig /mnt/
#arch-chroot /mnt/ /bin/bash chown -R $USERNAME:users /home/$USERNAME
chown -R $USERNAME:users /mnt/home/$USERNAME

umount -R /mnt
if [ "$ENCRYPT" = true ]; then
  cryptsetup close $LUKSNAME
fi

echo "Done!"
