# SPDX-License-Identifier: MIT
{ ... }:
{
  inputs,
  lib,
  ...
}:
{

  imports = [ inputs.flake-parts.flakeModules.partitions ];

  debug = false;
  caisson = {
    libOverlays.exported = libOverlays: {
      inherit (libOverlays) default;
    };
  };

  # The nbd overlay is the `default` entry of this flake's package overlay
  # registry (pkg-overlays/, registered on mkLib): the package set applies
  # it by default, and the flake exports it as `pkgOverlays` and as the
  # plain `overlays.default`.

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
