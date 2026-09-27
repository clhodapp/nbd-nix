# SPDX-License-Identifier: MIT
{

  description = "Nixpkgs overlay building nbd from its newest upstream release";

  inputs = {
    caisson.url = "github:nix-caisson/caisson";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    # Upstream's newest release tag. .github/workflows/update.yml moves
    # it forward; the overlay reads its version from it.
    nbd.flake = false;
    nbd.url = "github:NetworkBlockDevice/nbd/nbd-3.27.1";
  };

  outputs =
    inputs@{ caisson, ... }:
    let
      lib = caisson.lib.caisson-core.mkLib {
        inherit inputs;
        namespace = "nbd-nix";
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];
        projects = {
          inherit caisson;
        };

        libOverlays = caisson.lib.caisson-core.mkLibOverlays ./lib-overlays;
      };
    in
    lib.caisson.flake-parts.mkConfiguration {
      configModule = lib.caisson.flake-parts.mkModule ./configs/flake-parts/default;
    };

}
