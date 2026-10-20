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
    # https://github.com/NixOS/nixpkgs/pull/576347
    # Package-only backport; this pin predates the NixOS blacklist cleanup.
    ./cacert-3.131.1.patch

    # https://github.com/NixOS/nixpkgs/pull/576471
    ./uv-0.13.4.patch

    # https://github.com/NixOS/nixpkgs/pull/576202
    ./go-1.27.3.patch
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
