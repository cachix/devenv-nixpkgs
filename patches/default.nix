# Patch collection for devenv-nixpkgs
#
# Two categories:
#
# - upstream: Patches from nixpkgs PRs or unreleased fixes.
#   Download with:
#     curl -L https://github.com/NixOS/nixpkgs/pull/<number>.patch -o patches/<name>.patch
#   Avoid using fetchpatch for unmerged PRs — force-pushes change the content.
#
# - local: Patches not yet submitted upstream.
#
# fetchpatch is fine for merged commits whose content is immutable, e.g.
# unreleased upstream fixes not yet in nixpkgs-unstable:
#
#   (fetchpatch {
#     name = "fix-python-darwin.patch";
#     url = "https://github.com/NixOS/nixpkgs/commit/abc123.patch";
#     sha256 = "sha256-AAAA...";
#   })

{
  fetchpatch,
  lib,
  stdenv,
}:

let
  inherit (stdenv) isDarwin;
in

{
  # Patches from nixpkgs PRs or unreleased fixes
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
    # poetry 2.4.1 test suite is broken by virtualenv 21.6.1 dropping the
    # newest-bundle fallback for Python < 3.9, which poetry's MockEnv relies on.
    # https://github.com/NixOS/nixpkgs/issues/544083
    ./001-poetry-disable-embedded-wheel-tests.patch
  ];
}
