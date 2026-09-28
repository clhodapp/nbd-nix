# nbd-nix

Carries the pin of upstream
[nbd](https://github.com/NetworkBlockDevice/nbd) (the Network Block
Device userland: `nbd-server`, `nbd-client`) at its newest release and
exports `overlays.default`, a nixpkgs overlay that rebuilds nixpkgs'
`nbd` package from that release. The overlay replaces top-level
`pkgs.nbd`, so everything in a consuming package set, including
nixpkgs' own modules and dependents, gets that build.

The override keeps nixpkgs' packaging and swaps only the source and
version. nixpkgs' patches are dropped, since they are written against
the release nixpkgs carries.

The overlay also adds `nbd-unstable`, the same packaging built from
the head of upstream's default branch, versioned
`<release>-unstable-<date>` after the newest release and the
snapshot's commit date. It replaces nothing; a consumer that wants it
selects `pkgs.nbd-unstable`.

## Why

nixpkgs packages a new nbd release some time after upstream tags it,
and a channel carries that package some time after that. This flake
builds the newest release as soon as upstream tags it, and the master
snapshot for a fix that has not been released yet: a daily workflow
moves the `nbd` input to the latest release and the `nbd-unstable`
input to the branch head, checks each on its own, and pushes the
advances that build to `main`; one that fails its check stays where it
was and does not hold the other back.

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

`overlays.default` is a plain nixpkgs overlay, so it also goes into
`nixpkgs.overlays` in a NixOS configuration, or into whatever overlay
list a framework exposes. A caisson-based flake lists nbd-nix in
`projects` on `mkLib` instead: the flake's `pkgOverlays.default` entry
then joins the consumer's package overlay registry as `nbd-nix/default`,
which its package sets apply by default.

Because the overlay replaces top-level `pkgs.nbd`, NixOS modules such as
`services.nbd.server` pick up the overlaid build with no further wiring,
provided the overlay is applied to the package set that the system
evaluates against.

## Versioning

`main` is the release channel; there are no tagged releases. Consumers
pin a revision through their own lockfile and update on their own
schedule.

The `nbd` input names upstream's newest release tag and the
`nbd-unstable` input its default branch; `.github/workflows/update.yml`
moves both forward daily, so the versions this overlay builds follow
upstream. The exported surface is `overlays.default` with its `nbd`
and `nbd-unstable` attributes, and a change to those names would be a
breaking change.

## Development

`nix flake check` builds `nbd` and `nbd-unstable` against this flake's
own nixpkgs pin; `nix fmt` formats.

To move to a release by hand, change the tag in the `nbd` input's URL
in `flake.nix` and run `nix flake update nbd`. The overlay reads its
version from that tag, so nothing else changes. To move the master
snapshot by hand, run `nix flake update nbd-unstable`.
