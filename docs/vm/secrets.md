# Generate age key per machine

On new machine, run below to transfer its shiny new ed25519 to age

```sh
nix-shell -p ssh-to-age --run 'cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age'
```

Copy this into `./.sops.yaml` in base repo, then re-run taskfile `task sops:re-encrypt` to loop through all sops keys, decrypt then re-encrypt
