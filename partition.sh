#!/usr/bin/env bash


# Define variables
drive="/dev/mmcblk1"  # Change this to the desired drive, e.g., "/dev/sdb"
swap_size="100MB"   # Change this to the desired swap size

# Confirmation prompt
read -p "This script will partition and format $drive. Are you sure you want to proceed? (y/n): " choice
if [ "$choice" != "y" ]; then
    echo "Exiting script."
    exit 1
fi

# Partitioning
parted "${drive}" -- mklabel gpt
parted "${drive}" -- mkpart root ext4 512MB -"$swap_size"
parted "${drive}" -- mkpart swap linux-swap -"$swap_size" 100%
parted "${drive}" -- mkpart ESP fat32 1MB 512MB
parted "${drive}" -- set 3 esp on

# Formatting
mkfs.ext4 -L nixos "${drive}p1"
mkswap -L swap "${drive}p2"
mkfs.fat -F 32 -n boot "${drive}p3"

# Mounting disks for installation
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot
swapon "${drive}p2"

# Generating default configuration
nixos-generate-config --root /mnt
