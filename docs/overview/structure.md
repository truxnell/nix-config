# Repository Structure

!!! note inline end

    Oh god writing this now is a horrid idea, I always refactor like 50 times...

Here is a bit of a walkthrough of the repository structure so ~~you~~ I can have a vague idea on what is going on. Organizing a monorepo is hard at the best of times.
<br><br><br>

```
├── .github
│   ├── renovate            Renovate modules
│   ├── workflows             Github Action workflows (i.e. CI/Site building)
│   └── renovate.json5        Renovate core settings
├── .taskfiles              go-task file modules
├── docs                    This mkdocs-material site
│   nixos                   Nixos Modules
│   └── home                  home-manager nix files
│       ├── modules             home-manager modules
│       └── truxnell            home-manager user
│   ├── hosts                 hosts for nix - starting point of configs.
│   ├── modules               nix modules
│   ├── overlays              nixpkgs overlays
│   ├── pkgs                  custom nix packages
│   └── profiles              host profiles
├── README.md               Github Repo landing page
├── flake.nix               Core flake
├── flake.lock              Lockfile
├── LICENSE                 Project License
├── mkdocs.yml              mkdocs settings
└── Taskfile.yaml           go-task core file
```

Whew that wasnt so hard right... right?
