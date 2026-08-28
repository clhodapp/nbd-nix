# SPDX-License-Identifier: MIT
{ ... }:
{

  overlay = final: prev: {
    nbd-nix = prev.nbd-nix or { };
  };

}
