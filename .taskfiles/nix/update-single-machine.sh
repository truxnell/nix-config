#!/usr/bin/env bash

set -e

# cd /home/truxnell/.local/nix-config

# rsa_key="~/.nixos/secrets/ssh_keys/ansible/ansible.key"
# export NIX_SSHOPTS="-t -i $rsa_key"

reboot=0

while getopts ":r" option; do
    case $option in
    r)
        reboot=1
        host=$2
        fqdn="$host.l.voltaicforge.com"
        echo "$fqdn with reboot"
        nixos-rebuild boot -j auto --use-remote-sudo --target-host $fqdn --flake ".#$host"
        # ssh -i $rsa_key $fqdn 'sudo reboot'
        ssh $fqdn 'sudo reboot'
        ;;
    esac
done

if [ $reboot -eq 0 ]; then
    host=$1
    fqdn="$host.l.voltaicforge.com"
    echo "$fqdn"
    nixos-rebuild switch -j auto --use-remote-sudo --target-host $fqdn --flake ".#$host"
fi
echo
echo
