# Compatibility shim for non-flake usage:
#   import nixpkgs { system = "x86_64-linux"; overlays = [...]; }
#
# Reads nixpkgs revision from flake.lock and applies patches.

{ system ? builtins.currentSystem
, config ? {}
, overlays ? []
, ...
}@args:
let
  lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  nixpkgs-src = builtins.fetchTree {
    type = "github";
    owner = "NixOS";
    repo = "nixpkgs";
    rev = lock.nodes.nixpkgs-src.locked.rev;
    narHash = lock.nodes.nixpkgs-src.locked.narHash;
  };

  # Bootstrap pkgs for fetchpatch and applyPatches
  bootstrapPkgs = import nixpkgs-src { inherit system; };

  patchDefs = import ./patches { inherit (bootstrapPkgs) fetchpatch; };
  allPatches = patchDefs.upstream ++ patchDefs.local;

  patchedSrc =
    if allPatches == []
    then nixpkgs-src
    else bootstrapPkgs.applyPatches {
      name = "nixpkgs-patched";
      src = nixpkgs-src;
      patches = allPatches;
    };

  defaultConfig = {
    allowUnfree = true;
    allowUnsupportedSystem = true;
    cudaSupport = true;
  };
in
import patchedSrc (args // {
  overlays = (import ./overlays) ++ overlays;
  config = defaultConfig // config;
})
