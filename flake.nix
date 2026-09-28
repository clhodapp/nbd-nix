# SPDX-License-Identifier: MIT
{

  description = "Nixpkgs overlay building nbd from its newest upstream release";

  inputs = {
    caisson.url = "github:nix-caisson/caisson";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    # Upstream's newest release tag, for `nbd`. update.yml moves it
    # forward; the overlay reads its version from it.
    nbd.flake = false;
    nbd.url = "github:NetworkBlockDevice/nbd/nbd-3.27.1";
    # Upstream's default branch, for `nbd-unstable`; advanced daily by
    # update.yml.
    nbd-unstable.flake = false;
    nbd-unstable.url = "github:NetworkBlockDevice/nbd";
  };

  outputs =
    inputs@{ caisson, ... }:
    let
      lib = caisson.lib.caisson-core.mkLib {
        inherit (caisson.lib.caisson-core.pins.flake inputs) sources root;
        namespace = "nbd-nix";
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];
        projects = {
          inherit caisson;
        };

        configs = caisson.lib.caisson-core.mkModules ./configs;

        libOverlays = caisson.lib.caisson-core.mkLibOverlays ./lib-overlays;
        pkgOverlays = caisson.lib.caisson-core.mkPkgOverlays ./pkg-overlays;
      };
    in
    lib.caisson.flake-parts.mkConfiguration {
      configModule = lib.caisson-core.configs.flake.nbd-nix;
    };

}
