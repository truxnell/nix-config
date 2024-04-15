# README.md

👋 Welcome to my NixoOS home and homelab configuration. This monorepo is my personal :simple-nixos: nix/nixos setup for all my devices, specifically my homelab.

This is the end result of a recovering :simple-kubernetes: k8s addict - who no longer enjoyed the time and effort I personally found it took to run k8s at home.
Having needed a break from hobby's for some health related reasons, I found coming back to a unpatched cluster a chore, which resulted in a basic OS upgrade broke everything.

Looking at my boring ubuntu ZFS nas which just ran and ran and ran without needing TLC, I dove into nix, with the idea of getting back to basics of boring proven tools, with the power of nix's declarative system.

One of my goals is to bring what I learnt running k8s at home with some of the best homelabbers, into the nix world and see just how much of the practices I learnt I can apply to a nix setup, while focussing on having a solid, reliable, setup that I can leave largely unattended for months without issues cropping up.

The goal of this doc is for me to slow down a bit and jot down how and why I am doing what im doing in a module, and cover how I have approached the faucets of homelabbing, so **YOU** can understand, steal with pride from my code, and hopefully(?) learn a thing or two.

To _teach_ me a thing or two, contact me or raise a Issue. PR's may or may not be taken as a personal attack - this is my home setup after all.
