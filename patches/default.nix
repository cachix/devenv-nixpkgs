# Patch collection for devenv-nixpkgs
#
# This file organizes patches into two categories:
# - upstream: Patches fetched from open nixpkgs PRs (self-tracking)
# - local: Patches not yet submitted upstream
#
# When an upstream PR is merged, the fetchpatch will fail (hash mismatch),
# signaling that the patch should be removed.

{ fetchpatch }:

{
  # Patches with open upstream PRs
  # These are self-tracking: when the PR is merged, the hash changes and build fails
  #
  # Example:
  # (fetchpatch {
  #   name = "fix-python-darwin.patch";
  #   url = "https://github.com/NixOS/nixpkgs/pull/12345.patch";
  #   sha256 = "sha256-AAAA...";
  # })
  upstream = [
  ];

  # Local patches not yet submitted upstream
  # These should eventually become upstream PRs
  #
  # Each patch file should have a comment header explaining:
  # - What it fixes
  # - Why it's needed for devenv
  # - Link to upstream issue (if any)
  local = [
    # Example: ./001-fix-something.patch
  ];
}
