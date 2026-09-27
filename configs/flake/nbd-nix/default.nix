# SPDX-License-Identifier: MIT
{ ... }:
{
  inputs,
  lib,
  ...
}:
let
  # Upstream computes its version with `git describe` at configure
  # time, which a flake input cannot run; nixpkgs' packaging puts the
  # package's `version` in its place. So the version is the release
  # tag the `nbd` input names in flake.nix, read from the lock, minus
  # the `nbd-` prefix upstream puts on its tags.
  nbdRef = (builtins.fromJSON (builtins.readFile ../../../flake.lock)).nodes.nbd.original.ref;
  nbdVersion = builtins.head (builtins.match "nbd-(.*)" nbdRef);
  # The master build is versioned as nixpkgs versions branch
  # snapshots: the newest release, then the snapshot's commit date.
  nbdUnstableDate =
    let
      d = inputs.nbd-unstable.lastModifiedDate;
    in
    "${builtins.substring 0 4 d}-${builtins.substring 4 2 d}-${builtins.substring 6 2 d}";
  nbdUnstableVersion = "${nbdVersion}-unstable-${nbdUnstableDate}";
in
{

  imports = [ inputs.flake-parts.flakeModules.partitions ];

  debug = false;
  caisson = {
    libOverlays.exported = libOverlays: {
      inherit (libOverlays) default;
    };
  };

  caisson.nixpkgs = {
    overlays.all = {
      default = lib.caisson.nixpkgs.mkPolyfillOverlay (
        final: prev: {
          nbd = prev.nbd.overrideAttrs {
            src = inputs.nbd;
            version = nbdVersion;
            # nixpkgs' patches are written against the release it
            # carries; a newer release includes or supersedes them.
            patches = [ ];
          };
          # The same packaging built from upstream's default branch.
          # Added beside `nbd`, replacing nothing.
          nbd-unstable = final.nbd.overrideAttrs {
            src = inputs.nbd-unstable;
            version = nbdUnstableVersion;
          };
        }
      );
    };
    overlays.export = {
      enabled = true;
    };
    overlays.exported = overlays: {
      inherit (overlays) default;
    };
    pkgSets.pkgs = {
      pkgFunction = import inputs.nixpkgs;
      overlayImports = overlays: [ overlays.default ];
    };
  };

  partitionedAttrs.checks = "checks";
  partitionedAttrs.formatter = "formatter";

  partitions.formatter = {
    extraInputs = (lib.caisson-core.pins.flake-compat ../../../tests/dependencies).sources;
    module =
      { inputs, ... }:
      {
        imports = [ inputs.treefmt-nix.flakeModule ];
        perSystem.treefmt.programs.nixfmt.enable = true;
      };
  };

  partitions.checks = {
    extraInputs = (lib.caisson-core.pins.flake-compat ../../../tests/dependencies).sources;
    module =
      { inputs, ... }:
      {
        imports = [ inputs.treefmt-nix.flakeModule ];
        perSystem =
          { pkgs, ... }:
          {
            checks = {
              # Building both packages proves the pinned release and
              # the pinned master snapshot still autoreconf and
              # compile against the pinned nixpkgs.
              nbd = pkgs.nbd;
              nbd-unstable = pkgs.nbd-unstable;
            };
          };
      };
  };

}
