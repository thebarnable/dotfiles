#!/bin/bash

set -eu

#loadkeys de

HOSTNAME="archstick"
BOOTNAME="arch_efi" # ignored on legacy
USERNAME="tim"
DISK="/dev/sdb" # nvme1n1 #important for legacy install
PARTITION=$DISK
LEGACY=false
ENCRYPT=false
REMOVABLE=true
RAID=false
LUKSNAME="crypt_root"

OWN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SCRIPT="$OWN_DIR/install_internal.sh"

if [ "$EUID" -ne 0 ]; then
  echo "This script has to be executed as sudo!"
  exit 1
fi

# Partitions
EFI_PARTITION=$PARTITION"1"
MAIN_PARTITION=$PARTITION"2"
if $LEGACY; then
  BOOT_PARTITION=$PARTITION"1"
  if ! $ENCRYPT; then
    MAIN_PARTITION=$PARTITION"1"
    echo "Create MBR with one partitions, bootable!"
  else
    echo "Create MBR with two partitions, first 400M and bootable!"
  fi
  
  read
  fdisk $DISK
  sleep 1
else
 BOOT_PARTITION=$PARTITION"2"
  if $ENCRYPT; then
    MAIN_PARTITION=$PARTITION"3"
    echo "Create GPT with three partitions, first both 400M and first ef00!"
#  else
    echo "Create GPT with two partitions, first 400M and first ef00!"
  fi

  read
  gdisk $DISK
  sleep 1
fi

# Overwrite paritions, uncomment if needed:
#EFI_PARTITION=$PARTITION"1"
#BOOT_PARTITION=$PARTITION"5"
#MAIN_PARTITION=$PARTITION"6"

# Filesystems
if ! $LEGACY; then
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
ln -rs /mnt/home/$USERNAME/.config/dotfiles/bash/* /mnt/home/$USERNAME/
ln -rs /mnt/home/$USERNAME/.config/dotfiles/bash/.bashrc /mnt/home/$USERNAME/.bashrc # not sure why above ln doesnt link .bashrc
ln -rs /mnt/home/$USERNAME/.config/dotfiles/git/* /mnt/home/$USERNAME/
ln -rs /mnt/home/$USERNAME/.config/dotfiles/installer/* /mnt/home/$USERNAME/

mv /mnt/etc/skel/.bashrc /mnt/etc/skel/.bashrc.bak
cp /mnt/home/$USERNAME/.bashrc /mnt/etc/skel/
cp /mnt/home/$USERNAME/.gitconfig /mnt/
arch-chroot /mnt/ /bin/bash chown -R $USERNAME:users /home/$USERNAME 

umount -R /mnt
if [ "$ENCRYPT" = true ]; then
  cryptsetup close $LUKSNAME
fi

echo "Done!"
