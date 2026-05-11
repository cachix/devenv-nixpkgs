# Compatibility shim for non-flake usage:
#   import nixpkgs { system = "x86_64-linux"; overlays = [...]; }
#
# Reads nixpkgs revision from flake.lock and applies patches.

{
  localSystem ? { system = args.system or builtins.currentSystem; },
  system ? localSystem.system,
  config ? { },
  overlays ? [ ],
  ...
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

  patchDefs = bootstrapPkgs.callPackage ./patches { };
  allPatches = patchDefs.upstream ++ patchDefs.local;

  patchedSrc =
    if allPatches == [ ] then
      nixpkgs-src
    else
      bootstrapPkgs.applyPatches {
        name = "devenv-nixpkgs-patched";
        src = nixpkgs-src;
        patches = allPatches;
      };
in
import patchedSrc (
  args
  // {
    inherit config;
    overlays = (import ./overlays) ++ overlays;
  }
)
