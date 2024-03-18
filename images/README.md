# ISO Image builds

A minimal NixOS install iso build.

Mainly useful for force-enabling `sshd` with my public key to allow headless deployments.

> https://nixos.wiki/wiki/Creating_a_NixOS_live_CD

## Building

```
cd iso
nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage -I nixos-config=iso.nix
```

# Checking image contents

```
$ mkdir mnt
$ sudo mount -o loop result/iso/nixos-*.iso mnt
$ ls mnt
boot  EFI  isolinux  nix-store.squashfs  version.txt
$ umount mnt
```

# Testing image in QEMU

```
$ nix-shell -p qemu
$ qemu-system-x86_64 -enable-kvm -m 256 -cdrom result/iso/nixos-*.iso
```
