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

## Why

nixpkgs builds nbd from upstream's release tarballs, and upstream
releases infrequently: nbd 3.26.1 (March 2024) was followed by 3.27.0
in March 2026, a two-year gap, while master kept taking commits
throughout. A fix that lands on master can therefore wait a long time
to reach a nixpkgs package set. This flake closes that gap, at the
cost of building from a moving branch rather than a released tarball.

## Consuming

Add this flake as an input and apply `overlays.default` to a package
set. With plain nixpkgs:

```nix
{
  inputs.nbd-nix.url = "github:clhodapp/nbd-nix";

  outputs = { nixpkgs, nbd-nix, ... }:
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [ nbd-nix.overlays.default ];
      };
    in
    { packages.x86_64-linux.nbd = pkgs.nbd; };
}
```

In a [`ch-nixpkgs`](https://github.com/clhodapp/ch-nixpkgs)-based flake,
list `inputs.nbd-nix.overlays.default` in `pkgSets.pkgs.overlayImports`
instead.

Because the overlay replaces top-level `pkgs.nbd`, NixOS modules such as
`services.nbd.server` pick up the overlaid build with no further wiring,
provided the overlay is applied to the package set that the system
evaluates against.

## Versioning

`main` is the release channel; there are no tagged releases. Consumers
pin a revision through their own lockfile and update on their own
schedule.

The `nbd` input tracks upstream's default branch, so the version this
overlay builds moves whenever the pin is refreshed. Treat that as the
intended behavior rather than a stability guarantee: the point of this
flake is to be ahead of the release tarballs. The exported surface is
just `overlays.default`, and a change to that name would be a breaking
change.

## Development

`nix flake check` builds the overlaid `nbd` against this flake's own
nixpkgs pin; `nix fmt` formats.
