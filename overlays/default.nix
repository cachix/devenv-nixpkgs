# Overlays for devenv-nixpkgs
#
# Use overlays for package-level fixes that don't require patching
# the nixpkgs source. Overlays are more resilient to upstream changes.
#
# Example:
#
#   (final: prev: {
#     somePackage = prev.somePackage.overrideAttrs (old: {
#       patches = old.patches or [] ++ [ ./patches/fix-something.patch ];
#     });
#   })

[
  # Add overlays here
]
