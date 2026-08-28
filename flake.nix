# SPDX-License-Identifier: MIT
{

  description = "Nixpkgs overlay building nbd from upstream master";

  inputs = {
    ch-flake.url = "github:clhodapp/ch-flake";
    ch-nixpkgs.url = "github:clhodapp/ch-nixpkgs";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nbd.flake = false;
    nbd.url = "github:NetworkBlockDevice/nbd";

    flake-parts.follows = "ch-flake/flake-parts";
  };

  outputs =
    inputs@{
      ch-flake,
      flake-parts,
      self,
      ...
    }:
    let
      lib = ch-flake.lib.mkLib {
        inherit inputs;

        modules = lib: {
          flake = {
            default = lib.ch-flake.mkFlakeModule ./modules/flake-parts/default;
            partitions = flake-parts.flakeModules.partitions;
          };
        };

        libOverlays = mkLibOverlay: {
          default = mkLibOverlay ./lib-overlays/default;
          ch-nixpkgs = inputs.ch-nixpkgs.libOverlays.default;
        };
      };
    in
    lib.ch-flake.mkFlake {
      name = "nbd-nix";
      configModule = lib.ch-flake.mkFlakeModule ./configs/flake-parts/default;
    };

}
