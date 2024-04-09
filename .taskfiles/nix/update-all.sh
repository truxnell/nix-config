#!/usr/bin/env bash

set -e

cd /home/andreas/.nixos

hosts=($(echo $(nix eval .#nixosConfigurations --apply 'pkgs: builtins.concatStringsSep " " (builtins.attrNames pkgs)') | xargs))
skip=(
    "desktop-vm"
    "gwyn"
    "loki-test"
    "mobile"
    "staubfinger"
    "test-raspi"
)

rsa_key="$HOME/.nixos/secrets/ssh_keys/ansible/ansible.key"
export NIX_SSHOPTS="-t -i $rsa_key"
reboot=0

while getopts ":r" option; do
    case $option in
    r)
        reboot=1
        ;;
    esac
done

for host in "${hosts[@]}"; do
    # Check if the host is in the skip list
    if [[ " ${skip[*]} " =~ " ${host} " ]]; then
        continue
    fi
    fqdn="$host.2li.local"
    if [ $reboot -eq 0 ]; then
        echo $fqdn
        nixos-rebuild switch -j auto --use-remote-sudo --target-host $fqdn --flake ".#$host"
    else
        echo "$fqdn with reboot"
        nixos-rebuild boot -j auto --use-remote-sudo --target-host $fqdn --flake ".#$host"
        ssh -i $rsa_key $fqdn 'sudo reboot'
    fi
    echo
    echo
done
