# SPDX-License-Identifier: MIT
#
# The checks of nbd-nix: a flake-parts configuration declared inside the
# flake-parts caisson top (configs/flake/nbd-nix), whose dependencies
# are those of the caisson top with the pins of tests/dependencies
# beside them. The caisson top gathers the checks declared here into
# its `checks` output. A flake that lists nbd-nix as an input reads
# nothing of this configuration, so it locks none of the pins of
# tests/dependencies.
{ ... }:
{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem =
    { pkgs, ... }:
    {
      # Duplicated in the formatter partition of configs/flake/nbd-nix:
      # the partition and this configuration are separate evaluations.
      treefmt.programs.nixfmt.enable = true;

      # Building both packages proves the pinned release and the pinned
      # master snapshot still autoreconf and compile against the pinned
      # nixpkgs. update.yml builds each by its name.
      caisson.checks = {
        treefmt = {
          category = "format";
          description = "the Nix files are formatted with nixfmt";
        };
        nbd = {
          derivation = pkgs.nbd;
          category = "build";
          description = "the pinned release of nbd builds against the pinned nixpkgs";
        };
        nbd-unstable = {
          derivation = pkgs.nbd-unstable;
          category = "build";
          description = "the pinned master snapshot of nbd builds against the pinned nixpkgs";
        };
      };
    };
}
