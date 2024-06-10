## Getting ISO/Image

How to get nix to a system upfront can be done in different ways depending on how much manual work you plan to do for bootstrapping a system. Below is a few ways I've used, but obviously there will be multiple methods and this isn't a comprehensive list.

### Default ISO (2-step)

You can download the **minimal ISO** from [NixOS.org](https://nixos.org/download/) This gets you a basic installer running on tmpfs, which you can then open up for SSH, partition drives, `nixos-install` them, and then reboot into a basic system, ready to then do a second install for whatever config/flake you are doing.

### Custom ISO (1-step)

An alternative is to build a _custom ISO_ or image with a number of extra tools, ssh key pre-installed, etc. If you image a drive with this you get a bootable nixos install immediately, which I find useful for Raspberry Pi's

I have started down this path with the below code:

!!! note

    The below nix for images is Work In Progress!

**[ISO Image (x86_64)](https://github.com/truxnell/nix-config/blob/main/nixos/hosts/images/cd-dvd/default.nix)**
**[SD Image (aarch64\_)](https://github.com/truxnell/nix-config/blob/main/nixos/hosts/images/sd-image/default.nix)**

From here, you can build them with `nix build`. I have mine in my flake so I could run `nix build .#images.rpi4`. Even better, you can also setup a Github Action to build these images for you and put them in a release for you to download.

### Graphical install

A graphical install is available but this isn't my cup of tea for a system so closely linked to declarative setup from configuration files. There are plenty of guides to guide through a graphical installer.

### Alternate tools (Automated)

You can look at tools like [disko](https://github.com/nix-community/disko) for declarative disk formatting and [nixos-anywhere](https://github.com/nix-community/nixos-anywhere) for installing NixOS, well, anywhere using features like `kexec` to bootstrap nix on any accessiable linux system.

This closes the loop of the manual steps you need to setup a NixOS system - I've chosen to avoid these as I don't want additional complexity in my installs and I'm OK with a few manual steps for the rare occasions I setup new devices.

## Booting into raw system

### Linux x86_64 systems

I'm a fan of [Ventoy.net](https://ventoy.net/en/index.html) for getting ISO's onto systems, as it allows you to load ISO files onto a USB, and from any system you can boot it up into a ISO selector - this way you can have one USB with many ISO's, including rescue-style ISO's ready to go.

### Virtual Machines

I follow the same approach as x86_64 above for testing Nix in VM's.

General settings below for a virtual machine- I stick with larger drives to ensure nix-store & compiling doesn't bite me. 16GB is probably OK too.

**VM Settings:**
**ISO:** nixos-minimal
**Hard:** Drive: 32GB
**RAM:** 2GB
**EFI:** Enable

!!! warning

    Ensure you have EFI enabled or ensure you align your configuration.nix to your VM's BIOS setup, else you will have issues installing & booting.

For VM's, I then expose port 22 to allow SSH from local machine into vm - mapping host port 3022 to vm guest 22.

### aarch64 (RasPi)

I cant comment on Mac as im not a Apple guy, so this section is for my Raspberry Pi's. I build my custom image and flash it to a sd-card, then boot it - this way I already have ssh open and I can just ssh into it headless. If you use a minimal ISO you will need to have a monitor/keyboard attached, as by default SSH is not enabled in the default ISO until a root password is set.

### Other methods

You could also look at PXE/iPXE/network boot across your entire network so devices with no OS 'drop' into a NixOS live installer.

## Initial install from live image

### Opening SSH

If your live image isn't customised with a root password or ssh key, SSH will be closed until you set one.

```sh
sudo su
passwd
```

`sshd` is now running, so you can now ssh into the vm remotely for the rest of the setup if you prefer

### Partitioning drives

### Standard

Next step is to partition drives. This will vary per host, so `lsblk`, viewing disks in `/dev/`, `/dev/disk/by-id`, `parted` and at times your eyeballs will be useful to identify what drive to partition

Below is a fairly standard setup with a 512MB boot partition, 8GB swap and the rest ext4. If you have the RAM a swap partition is unlikely to be needed.

```sh
# Partitioning
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart root ext4 512MB -8GB
parted /dev/sda -- mkpart swap linux-swap -8GB 100%
parted /dev/sda -- mkpart ESP fat32 1MB 512MB
parted /dev/sda -- set 3 esp on
```

And then a little light formatting.

```sh
# Formatting
mkfs.ext4 -L nixos /dev/sda1
mkswap -L swap /dev/sda2 # if swap setup
mkfs.fat -F 32 -n boot /dev/sda3
```

We will want to mount these ready for the config generation (which will look at the current mount setup and output config for it)

```sh
# Mounting disks for installation
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot
swapon /dev/sda2 # if swap setup
```

### Impermanence (ZFS)

TBC

### Generating initial nixos config

If this is a fresh machine you've never worked with & **dont have a config ready to push to it**, you'll need to generate a config to get started

The below will generate a config based on the current setup of your machine, and output it to the /mnt folder.

```
# Generating default configuration
nixos-generate-config --root /mnt
```

This will output `configuration.nix` and `hardware-config.nix`. `configuration.nix` contains a boilerplate with some basics to create a bootable system, mainly importing hardware-config.
`hardware-config.nix` contains the nix code to setup the kernel on boot with a expected list of modules based on your systems capabilities, as well as the nix to mount the drives as currently setup.

As I gitops my files, I then copy the hardware-config to my machine, and then copy across a bootstrap configuration file with some basics added for install.

```sh
scp -P 3022 nixos/hosts/bootstrap/configuration.nix root@127.0.0.1:/mnt/etc/nixos/configuration.nix
scp -P 3022 root@127.0.0.1:/mnt/etc/nixos/hardware-configuration.nix nixos/hosts/nixosvm/hardware-configuration.nix
```

### Installing nix

From flake:

```
nixos-install --flake github:truxnell/nix-config#daedalus
```

```sh
nixos-install
reboot

# after machine has rebooted
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
