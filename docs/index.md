👋 Welcome to my NixoOS home and homelab configuration. This monorepo is my personal :simple-nixos: nix/nixos setup for all my devices, specifically my homelab.

This is the end result of a recovering :simple-kubernetes: k8s addict - who no longer enjoyed the time and effort I **personally** found it took to run k8s at home.

## Why?

Having needed a break from hobby's for some health related reasons, I found coming back to a unpatched cluster a chore, which was left unattented. Then a cheap SSD in my custom VyOS router blew, leading me to just put back in my Unifi Dreammachine router, which broke the custom DNS I was running for my cluster, which caused it issues.

During fixing the DNS issue, a basic software upgrade for the custom k8s OS I was running k8s on broke my cluster for the 6th time running, coupled with using a older version of the script tool I used to manage its machine config yaml, which ended up leading to my 6th k8s disaster recovery :octicons-info-16:{ title="No I don't want to talk about it" }).

Looking at my boring :simple-ubuntu: Ubuntu ZFS nas which just ran and ran and ran without needing TLC, and remembering the old days with Ubuntu + Docker Compose being hands-off :octicons-info-16:{ title="Too much hands off really as I auto-updated everything, but I digress" }), I dove into nix, with the idea of getting back to basics of boring proven tools, with the power of nix's declarative system.

## Goals

One of my goals is to bring what I learnt running k8s at home with some of the best homelabbers, into the nix world and see just how much of the practices I learnt I can apply to a nix setup, while focussing on having a solid, reliable, setup that I can leave largely unattended for months without issues cropping up.

The goal of this doc is for me to slow down a bit and jot down how and why I am doing what im doing in a module, and cover how I have approached the faucets of homelabbing, so **YOU** can understand, steal with pride from my code, and hopefully(?) learn a thing or two.

To _teach me_ a thing or two, contact me or raise a Issue. PR's may or may not be taken as a personal attack - this is my home setup after all.
