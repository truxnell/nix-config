## STILL WIP
## Wanted to avoid bringing in complexity of disko

#!/usr/bin/env bash
set -x

# Define variables
drive="/dev/mmcblk1"  # Change this to the desired drive, e.g., "/dev/sdb"
swap_size="100MB"   # Change this to the desired swap size

# Partitioning
parted "${drive}" -- mklabel gpt -s
parted "${drive}" -- mkpart root ext4 512MB -s# -"$swap_size"
#parted "${drive}" -- mkpart swap linux-swap -"$swap_size" 100%
parted "${drive}" -- mkpart ESP fat32 1MB 512MB -s
parted "${drive}" -- set 3 esp on -s

# Formatting
mkfs.ext4 -L nixos "${drive}p1"
#mkswap -L swap "${drive}p2"
mkfs.fat -F 32 -n boot "${drive}p3"

# Mounting disks for installation
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot
swapon "${drive}p2"

# Generating default configuration
nixos-generate-config --root /mnt
