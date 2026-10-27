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

{ fetchpatch }:

{
  # Patches from nixpkgs PRs or unreleased fixes
  upstream = [
    # https://github.com/NixOS/nixpkgs/pull/577354 (snapshot; not yet merged)
    ./bun-1.4.4.patch
    # Targeted CA-store fixes; keep the interpreter/compiler package paths.
    # https://github.com/NixOS/nixpkgs/pull/576514
    ./grpcio-system-ca.patch
    # https://github.com/NixOS/nixpkgs/pull/577080
    ./httplib2-system-ca.patch
    # https://github.com/NixOS/nixpkgs/pull/576575
    ./gradle-system-ca.patch
    # https://github.com/NixOS/nixpkgs/pull/577131
    ./ruby-gems-system-ca.patch
  ];

  # Local patches not yet submitted upstream
  # These should eventually become upstream PRs
  #
  # Each patch file should have a comment header explaining:
  # - What it fixes
  # - Why it's needed for devenv
  # - Link to upstream issue (if any)
  local = [
    # PHP's follow-up mitigation, without rebuilding interpreters/extensions.
    ./php-session-upload-progress.patch
    # Wrap the cached Deno runtime instead of rebuilding Rust/V8.
    ./deno-system-ca.patch
    # https://github.com/NixOS/nixpkgs/issues/577303
    ./gitpython-3.2.1.patch
    # https://github.com/NixOS/nixpkgs/issues/577795
    ./pylint-cache-security.patch
    # Avoid port 8000 collisions in CherryPy logging tests on macOS builders.
    ./cherrypy-test-port.patch
    # macOS builders share /tmp; another build user may own service-locks.
    ./pytest-services-test-locks.patch
  ];
}
