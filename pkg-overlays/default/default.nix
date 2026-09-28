# SPDX-License-Identifier: MIT
#
# The default package overlay: `pkgs.nbd` rebuilt from the release this
# flake pins, and `pkgs.nbd-unstable`, the same packaging built from
# upstream's default branch, beside it. It replaces nixpkgs' `nbd`
# rather than adding a scope, and it is the whole of what this flake
# offers, so every consumer that takes this flake wants it: it is the
# `default` entry, not an entry of its own. A consumer that lists this
# flake in `projects` holds it as `nbd-nix/default`, which its package
# sets apply by default.
{ closure-inputs, ... }:
let
  # Upstream computes its version with `git describe` at configure
  # time, which a flake input cannot run; nixpkgs' packaging puts the
  # package's `version` in its place. So the version is the release
  # tag the `nbd` input names in flake.nix, read from the lock, minus
  # the `nbd-` prefix upstream puts on its tags.
  nbdRef = (builtins.fromJSON (builtins.readFile ../../flake.lock)).nodes.nbd.original.ref;
  nbdVersion = builtins.head (builtins.match "nbd-(.*)" nbdRef);
  # The master build is versioned as nixpkgs versions branch
  # snapshots: the newest release, then the snapshot's commit date.
  nbdUnstableDate =
    let
      d = closure-inputs.nbd-unstable.lastModifiedDate;
    in
    "${builtins.substring 0 4 d}-${builtins.substring 4 2 d}-${builtins.substring 6 2 d}";
  nbdUnstableVersion = "${nbdVersion}-unstable-${nbdUnstableDate}";
in
{
  overlay = final: prev: {
    nbd = prev.nbd.overrideAttrs {
      src = closure-inputs.nbd;
      version = nbdVersion;
      # nixpkgs' patches are written against the release it
      # carries; a newer release includes or supersedes them.
      patches = [ ];
    };
    # The same packaging built from upstream's default branch.
    # Added beside `nbd`, replacing nothing.
    nbd-unstable = final.nbd.overrideAttrs {
      src = closure-inputs.nbd-unstable;
      version = nbdUnstableVersion;
    };
  };
}
