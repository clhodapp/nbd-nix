# SPDX-License-Identifier: MIT
{

  description = "Nixpkgs overlay building nbd from upstream master";

  inputs = {
    caisson.url = "github:nix-caisson/caisson";
    ch-nixpkgs.url = "github:clhodapp/ch-nixpkgs";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    nbd.flake = false;
    nbd.url = "github:NetworkBlockDevice/nbd";
  };

  outputs =
    inputs@{ caisson, ... }:
    let
      lib = caisson.lib.caisson-core.mkLib {
        inherit inputs;
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];
        projects = {
          inherit caisson;
          ch-nixpkgs = inputs.ch-nixpkgs;
        };

        libOverlays = caisson.lib.caisson-core.mkLibOverlays ./lib-overlays;
      };
    in
    lib.caisson.flake-parts.mkConfiguration {
      name = "nbd-nix";
      configModule = lib.caisson.flake-parts.mkModule ./configs/flake-parts/default;
    };

}
