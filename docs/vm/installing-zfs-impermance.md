> https://grahamc.com/blog/erase-your-darlings/

# Partitioning
parted /dev/nvme0n1 -- mklabel gpt
parted /dev/nvme0n1 -- mkpart root ext4 512MB -8GB
parted /dev/nvme0n1 -- mkpart swap linux-swap -8GB 100%
parted /dev/nvme0n1 -- mkpart ESP fat32 1MB 512MB
parted /dev/nvme0n1 -- set 3 esp on

# Formatting
mkswap -L swap /dev/nvme0n1p2
mkfs.fat -F 32 -n boot /dev/nvme0n1p3

# ZFS on root partition
zpool create -O mountpoint=none rpool /dev/nvme0n1p1

zfs create -p -o mountpoint=none rpool/local/root
## immediate blank snapshot
zfs snapshot rpool/local/root@blank
mount -t zfs rpool/local/root /mnt

# Boot partition
mkdir /mnt/boot
mount /dev/nvme0n1p3 /mnt/boot

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

Set `networking.hostid`` in the nixos config to `head -c 8 /etc/machine-id`
