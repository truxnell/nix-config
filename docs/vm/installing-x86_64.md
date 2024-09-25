## Installing a playground VM

I've used gnome-boxes from my current Fedora laptop for running playground vm's.

Settings:
ISO: nixos-minimal
Hard drive: 32GB
RAM: 2GB
EFI: Enable

Expose port 22 to allow ssh into vm (host port 3022, guest 22)

```sh
# set temp root passwd
sudo su
passwd
```

`sshd` is already running, so you can now ssh into the vm remotely for the rest of the setup.
`ssh root@127.0.0.1 -p 3022`

```sh
# Partitioning
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart root ext4 512MB -8GB
parted /dev/sda -- mkpart swap linux-swap -8GB 100%
parted /dev/sda -- mkpart ESP fat32 1MB 512MB
parted /dev/sda -- set 3 esp on

# Formatting
mkfs.ext4 -L nixos /dev/sda1
mkswap -L swap /dev/sda2
mkfs.fat -F 32 -n boot /dev/sda3

# Mounting disks for installation
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot
swapon /dev/sda2

# Generating default configuration
nixos-generate-config --root /mnt
```

From this config copy the bootstrap configuration and fetch the hardware configuration.

```sh
scp -P 3022 nixos/hosts/bootstrap/configuration.nix root@127.0.0.1:/mnt/etc/nixos/configuration.nix
scp -P 3022 root@127.0.0.1:/mnt/etc/nixos/hardware-configuration.nix nixos/hosts/nixosvm/hardware-configuration.nix
```

Then back to the VM

```sh
nixos-install
reboot
nixos-rebuild switch
```

Set the password for the user that was created.
Might need to use su?

```sh
passwd truxnell
```

Also grab the ssh keys and re-encrypt sops

```sh
cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age
```

then run task

Login as user, copy nix git OR for remote machines/servers just `nixos-install --impure --flake github:truxnell/nix-config#<MACHINE_ID>`

```sh
mkdir .local
cd .local
git clone https://github.com/truxnell/nix-config.git
cd nix-config
```

Apply config to bootstrapped device
First time around, MUST APPLY <machinename> with name of host in ./hosts/
This is because `.. --flake .` looks for a `nixosConfigurations` key with the machines hostname
The bootstrap machine will be called 'nixos-bootstrap' so the flake by default would resolve `nixosConfigurations.nixos-bootstrap`
Subsequent rebuilds can be called with the default command as after first build the machines hostname will be changed to the desired machine

```sh
nixos-rebuild switch --flake .#<machinename>
```

NOTE: do secrets for sops and shit!!
