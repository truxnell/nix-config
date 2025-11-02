### Adding overlays

Overlays should be added as individual nix files to `./nixos/overlays` with format

```nix
final: prev: {
    hello = (prev.hello.overrideAttrs (oldAttrs: { doCheck = false; }));
}
```
