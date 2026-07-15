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
    # gdalMinimal: skip test_zarr_read_simple_sharding.
    # The test asserts a .gmac tile-presence cache is written, but that cache is
    # serialized via the netCDF driver, which gdalMinimal disables. Broke all
    # postgres/postgres-timescale CI jobs via postgis on every platform.
    # Merged to master in https://github.com/NixOS/nixpkgs/pull/540826
    # (in nixpkgs-unstable after 2026-07-13) — drop on the next pin bump.
    (fetchpatch {
      name = "gdal-minimal-skip-zarr-sharding-test.patch";
      url = "https://github.com/NixOS/nixpkgs/commit/a846cde45365799b1fd83eafaee57c03a92d89bc.patch";
      hash = "sha256-z/US9B4rKfv74JyAjI0dJxbtxuFbh9a39LkWF/fbgMY=";
    })
  ]
  ++ lib.optionals isDarwin [
    # ld64: disable the libcxxhardeningfast hardening flag.
    # ld64 built with libc++ fast hardening trips hardening assertions on
    # ordinary links (SIGTRAP / "Trace/BPT trap: 5", clang exit 133), breaking
    # watchexec, R, pjsip and others on darwin.
    # Merged to staging-next in https://github.com/NixOS/nixpkgs/pull/536365 —
    # drop once the pin includes it. Note: rebuilds the darwin toolchain.
    (fetchpatch {
      name = "ld64-disable-libcxxhardeningfast.patch";
      url = "https://github.com/NixOS/nixpkgs/commit/dd5346915923d7751e7e8b21226b3db90ade3eea.patch";
      hash = "sha256-EF7hgkEsEdsW14o4hePptklOiyKG6xAAta3UryJY9n0=";
    })
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
