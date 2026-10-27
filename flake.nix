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

      # Lib from unpatched source (no build required for evaluation)
      lib = import (nixpkgs-src + "/lib");

      # Import published snapshots; evaluating a foreign platform never needs
      # to run that platform's patch tools.
      mkPatchedPkgs =
        system:
        let
          patchedSrc = import ./lib/source.nix {
            inherit system;
            nixpkgsRev = nixpkgs-src.rev or null;
          };
        in
        import patchedSrc {
          inherit system;
          overlays = import ./overlays;
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

      # Publishing is an explicit build step. Both variants use the builder's
      # native tools, including when publishing Darwin patches from Linux.
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs-src { inherit system; };
          sourceFor =
            isDarwin:
            let
              patchDefs = pkgs.callPackage ./patches {
                stdenv = pkgs.stdenv // {
                  hostPlatform = pkgs.lib.systems.elaborate (if isDarwin then "aarch64-darwin" else "x86_64-linux");
                };
              };
            in
            pkgs.applyPatches {
              name = "devenv-nixpkgs-patched-${if isDarwin then "darwin" else "linux"}";
              src = nixpkgs-src;
              patches = patchDefs.upstream ++ patchDefs.local;
              # Publish package sources without upstream CI definitions. This
              # needs only contents:write, not permission to publish workflows.
              # It also keeps a derivation when the patch list is empty.
              postPatch = ''
                rm -rf .github/workflows
              '';
            };
        in
        {
          source-linux = sourceFor false;
          source-darwin = sourceFor true;
        }
      );
    };
}
