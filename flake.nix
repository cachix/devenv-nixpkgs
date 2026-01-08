{
  description = "Battle-tested nixpkgs for devenv";

  inputs = {
    nixpkgs-src = {
      url = "github:NixOS/nixpkgs/nixpkgs-unstable";
      flake = false;
    };
  };

  outputs = { self, nixpkgs-src }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems = f: builtins.listToAttrs (map (system: {
        name = system;
        value = f system;
      }) systems);

      # Lib from unpatched source (no build required for evaluation)
      lib = import (nixpkgs-src + "/lib");

      # Create patched package set for a given system
      mkPatchedPkgs = system:
        let
          pkgs = import nixpkgs-src { inherit system; };
          patchDefs = import ./patches { inherit (pkgs) fetchpatch; };
          allPatches = patchDefs.upstream ++ patchDefs.local;
          patchedSrc =
            if allPatches == [] then
              nixpkgs-src
            else
              pkgs.applyPatches {
                name = "nixpkgs-patched";
                src = nixpkgs-src;
                patches = allPatches;
              };
        in
          import patchedSrc {
            inherit system;
            overlays = import ./overlays;
            config = {
              allowUnfree = true;
              allowUnsupportedSystem = true;
              cudaSupport = true;
            };
          };
    in
    {
      inherit lib;

      # NixOS modules from unpatched source (patches rarely touch these)
      nixosModules = {
        notDetected = nixpkgs-src + "/nixos/modules/installer/scan/not-detected.nix";
        readOnlyPkgs = nixpkgs-src + "/nixos/modules/misc/nixpkgs/read-only.nix";
      };

      # Package sets: patched, per-system, lazy
      legacyPackages = forAllSystems mkPatchedPkgs;
    };
}
