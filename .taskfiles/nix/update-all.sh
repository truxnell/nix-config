#!/usr/bin/env bash

set -e

hosts=($(echo $(nix eval .#nixosConfigurations --apply 'pkgs: builtins.concatStringsSep " " (builtins.attrNames pkgs)') | xargs))
skip=(
    "citadel"
    "rickenbacker"
)

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
    fqdn="$host.l.voltaicforge.com"
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
