# SPDX-License-Identifier: MIT
{ ... }:
{
  inputs,
  lib,
  ...
}:
{

  debug = false;
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  caisson = {
    configInfo.configName = "nbd-nix";
    libOverlays.exported = libOverlays: {
      inherit (libOverlays) default;
    };
  };

  # mkPolyfillOverlay returns a name-taking function (`name: final:
  # prev:`); applying the name here yields the plain two-argument
  # nixpkgs overlay that consumers expect from `overlays.default`.
  flake.overlays.default = lib.caisson.nixpkgs.mkPolyfillOverlay (final: prev: {
    nbd = prev.nbd.overrideAttrs (prevAttrs: {
      src = inputs.nbd;
      version = "unstable";
      patches = [ ];
      nativeBuildInputs = prevAttrs.nativeBuildInputs ++ [
        final.autoreconfHook
        final.autoconf-archive
        final.flex
      ];
    });
  }) "default";

  partitionedAttrs.checks = "checks";
  partitionedAttrs.formatter = "formatter";

  partitions.formatter = {
    extraInputs = lib.caisson-core.partitionExtraInputs ../../../tests/dependencies;
    module =
      { inputs, ... }:
      {
        imports = [ inputs.treefmt-nix.flakeModule ];
        perSystem.treefmt.programs.nixfmt.enable = true;
      };
  };

  partitions.checks = {
    extraInputs = lib.caisson-core.partitionExtraInputs ../../../tests/dependencies;
    module =
      { inputs, ... }:
      {
        imports = [ inputs.treefmt-nix.flakeModule ];
        perSystem =
          { system, ... }:
          {
            checks = {
              # Building the overlaid nbd proves the upstream-master
              # source still autoreconfs and compiles against the
              # pinned nixpkgs. The package set is imported here with
              # the exported overlay applied, which is also how a
              # consumer gets at it.
              nbd =
                (import inputs.nixpkgs {
                  inherit system;
                  overlays = [ inputs.self.overlays.default ];
                }).nbd;
            };
          };
      };
  };

}
