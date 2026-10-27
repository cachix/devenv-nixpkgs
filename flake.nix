{
  description = "Battle-tested nixpkgs for devenv";

  inputs = {
    nixpkgs-src = {
      url = "github:NixOS/nixpkgs/nixpkgs-unstable";
      flake = false;
    };
  };

  outputs =
    { self, nixpkgs-src }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems =
        f:
        builtins.listToAttrs (
          map (system: {
            name = system;
            value = f system;
          }) systems
        );

      source = builtins.fetchTree (builtins.fromJSON (builtins.readFile ./sources.json));
      lib = import (source + "/lib");
    in
    {
      inherit lib;

      # Modules and packages use the published source tree.
      nixosModules = {
        notDetected = source + "/nixos/modules/installer/scan/not-detected.nix";
        readOnlyPkgs = source + "/nixos/modules/misc/nixpkgs/read-only.nix";
      };

      # Package sets: patched, per-system, lazy
      legacyPackages = forAllSystems (system: import ./. { inherit system; });

      # Apply patches once with native tools, then publish for all platforms.
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs-src { inherit system; };
          patchDefs = pkgs.callPackage ./patches { };
        in
        {
          source = pkgs.applyPatches {
            name = "devenv-nixpkgs-patched";
            src = nixpkgs-src;
            patches = patchDefs.upstream ++ patchDefs.local;
            # Publishing with contents:write cannot include workflow definitions.
            postPatch = "rm -rf .github/workflows";
          };
        }
      );
    };
}
