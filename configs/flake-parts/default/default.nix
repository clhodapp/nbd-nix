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

  caisson.nixpkgs = {
    overlays.all = {
      default = lib.caisson.nixpkgs.mkPolyfillOverlay (
        final: prev: {
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
          { pkgs, ... }:
          {
            checks = {
              # Building the overlaid nbd proves the upstream-master
              # source still autoreconfs and compiles against the
              # pinned nixpkgs.
              nbd = pkgs.nbd;
            };
          };
      };
  };

}
