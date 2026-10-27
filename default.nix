# Compatibility shim for non-flake usage:
#   import nixpkgs { system = "x86_64-linux"; overlays = [...]; }
#
# Fetches an already-patched source tree without import-from-derivation.

{
  localSystem ? {
    system = args.system or builtins.currentSystem;
  },
  system ? localSystem.system,
  config ? { },
  overlays ? [ ],
  ...
}@args:
let
  patchedSrc = import ./lib/source.nix { inherit system; };
in
import patchedSrc (
  args
  // {
    inherit config;
    overlays = (import ./overlays) ++ overlays;
  }
)
