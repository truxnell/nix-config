# Message of the day

Why not include a nice message of the day for each server I log into?

The below gives some insight into what the servers running, status of zpools, usage, etc.
While not show below - thankfully - If a zpool error is found the status gives a full `zpool status -x` debrief which is particulary eye-catching upon login.

I've also squeezed in a 'reboot required' flag for when the server had detected its running kernel/init/systemd is a different version to what it booted with - useful to know when long running servers require a reboot to pick up new kernel/etc versions.

<figure markdown="span">
![Screenshot of message of the day prompt on login to server](../includes/assets/motd.png)
  <figcaption>Message of the day</figcaption>
</figure>

Code TLDR

:simple-github:[/nixos/modules/nixos/system/motd](https://github.com/truxnell/nix-config/blob/462144babe7e7b2a49a985afe87c4b2f1fa8c3f9/nixos/modules/nixos/system/motd/default.nix])

Write a shell script using nix with a bash motd of your choosing.

```nix
let
  motd = pkgs.writeShellScriptBin "motd"
    ''
      #! /usr/bin/env bash
      source /etc/os-release
      service_status=$(systemctl list-units | grep podman-)

      <- SNIP ->
      printf "$BOLDService status$ENDCOLOR\n"
    '';
in
```

This gets us a shells script we can then directly call into systemPackages - and after that its just a short hop to make this part of the shell init.

!!! note

    Replace with your preferred shell!

```nix
environment.systemPackages = [
    motd
];
programs.fish.interactiveShellInit =  ''
    motd
'';
```
