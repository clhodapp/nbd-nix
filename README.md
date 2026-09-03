# nbd-nix

Carries the pin of upstream
[nbd](https://github.com/NetworkBlockDevice/nbd) (the Network Block
Device userland: `nbd-server`, `nbd-client`) and exports
`overlays.default`, a nixpkgs overlay that rebuilds nixpkgs' `nbd`
package from that pinned upstream-master source. The overlay replaces
top-level `pkgs.nbd`, so everything in a consuming package set —
including nixpkgs' own modules and dependents — gets the
upstream-master build.

The override keeps nixpkgs' packaging and swaps only the source: the
release patches are dropped (they target the release tarball) and
`autoreconfHook`, `autoconf-archive`, and `flex` are added, since a git
checkout ships no pre-generated build system.

## Consuming

Add this flake as an input and include `overlays.default` in the
overlays of a package set. In a caisson-based flake, that means
listing `inputs.nbd-nix.overlays.default` in
`caisson.nixpkgs.pkgSets.pkgs.overlayImports`.

## Development

`nix flake check` builds the overlaid `nbd` against this flake's own
nixpkgs pin; `nix fmt` formats.
