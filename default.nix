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
  patchedSrc = builtins.fetchTree (builtins.fromJSON (builtins.readFile ./sources.json));
in
import patchedSrc (
  args
  // {
    inherit config;
    overlays = (import ./overlays) ++ overlays;
  }
)
