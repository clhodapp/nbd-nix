# SPDX-License-Identifier: GPL-3.0-or-later
{ ... }:
{

  overlay = final: prev: {
    nbd-nix = prev.nbd-nix or { };
  };

}
