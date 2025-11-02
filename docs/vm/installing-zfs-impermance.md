> https://grahamc.com/blog/erase-your-darlings/

# Get hostid

run `head -c 8 /etc/machine-id`
and copy into networking.hostId to ensure ZFS doesnt get borked on reboot

# Partitioning

parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart root ext4 512MB -8GB
parted /dev/sda -- mkpart ESP fat32 1MB 512MB
parted /dev/sda -- set 2 esp on

# Formatting

mkswap -L swap /dev/sdap2
swapon /dev/sdap2
mkfs.fat -F 32 -n boot /dev/sdap3

# ZFS on root partition

zpool create -O mountpoint=none rpool /dev/sdap1

zfs create -p -o mountpoint=legacy rpool/local/root

## immediate blank snapshot

zfs snapshot rpool/local/root@blank
mount -t zfs rpool/local/root /mnt

# Boot partition

mkdir /mnt/boot
mount /dev/sdap3 /mnt/boot

#mk nix
zfs create -p -o mountpoint=legacy rpool/local/nix
mkdir /mnt/nix
mount -t zfs rpool/local/nix /mnt/nix

# And a dataset for /home: if needed

zfs create -p -o mountpoint=legacy rpool/safe/home
mkdir /mnt/home
mount -t zfs rpool/safe/home /mnt/home

zfs create -p -o mountpoint=legacy rpool/safe/persist
mkdir /mnt/persist
mount -t zfs rpool/safe/persist /mnt/persist

Set ` networking.hostId`` in the nixos config to  `head -c 8 /etc/machine-id`

    nixos-install --impure --flake github:truxnell/nix-config#<MACHINE_ID>

consider a nixos-enter to import a zpool if required (for NAS) instead of rebooting post-install

NOTE: do secrets for sops and shit!!
