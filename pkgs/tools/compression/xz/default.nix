{
  lib,
  stdenv,
  fetchurl,
  autoreconfHook,
  enableStatic ? stdenv.hostPlatform.isStatic,
  writeScript,
  testers,
}:

# Note: this package is used for bootstrapping fetchurl, and thus
# cannot use fetchpatch! All mutable patches (generated by GitHub or
# cgit) that are needed here should be included directly in Nixpkgs as
# files.

stdenv.mkDerivation (finalAttrs: {
  pname = "xz";
  version = "5.6.3";

  src = fetchurl {
    url =
      with finalAttrs;
      "https://github.com/tukaani-project/xz/releases/download/v${version}/xz-${version}.tar.xz";
    hash = "sha256-2wWQYptvD6NudK6l+XMdxvjfBoznt7r6RTAYMqXuvDo=";
  };

  strictDeps = true;
  outputs = [
    "bin"
    "dev"
    "out"
    "man"
    "doc"
  ];

  configureFlags = lib.optional enableStatic "--disable-shared";

  enableParallelBuilding = true;
  doCheck = true;

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isOpenBSD [
    autoreconfHook
  ];

  # this could be accomplished by updateAutotoolsGnuConfigScriptsHook, but that causes infinite recursion
  # necessary for FreeBSD code path in configure
  postPatch = ''
    substituteInPlace ./build-aux/config.guess --replace-fail /usr/bin/uname uname
  '';

  preCheck = ''
    # Tests have a /bin/sh dependency...
    patchShebangs tests
  '';

  # In stdenv-linux, prevent a dependency on bootstrap-tools.
  preConfigure = "CONFIG_SHELL=/bin/sh";

  postInstall = "rm -rf $out/share/doc";

  passthru = {
    updateScript = writeScript "update-xz" ''
      #!/usr/bin/env nix-shell
      #!nix-shell -i bash -p curl pcre common-updater-scripts

      set -eu -o pipefail

      # Expect the text in format of '>xz-5.2.6.tar.xz</a>'
      # We pick first match where a stable release goes first.
      new_version="$(curl -s https://tukaani.org/xz/ |
          pcregrep -o1 '>xz-([0-9.]+)[.]tar[.]xz</a>' |
          head -n1)"
      update-source-version ${finalAttrs.pname} "$new_version"
    '';
    tests.pkg-config = testers.hasPkgConfigModules {
      package = finalAttrs.finalPackage;
    };
  };

  meta = with lib; {
    changelog = "https://github.com/tukaani-project/xz/releases/tag/v${finalAttrs.version}";
    description = "General-purpose data compression software, successor of LZMA";
    homepage = "https://tukaani.org/xz/";
    longDescription = ''
      XZ Utils is free general-purpose data compression software with high
      compression ratio.  XZ Utils were written for POSIX-like systems,
      but also work on some not-so-POSIX systems.  XZ Utils are the
      successor to LZMA Utils.

      The core of the XZ Utils compression code is based on LZMA SDK, but
      it has been modified quite a lot to be suitable for XZ Utils.  The
      primary compression algorithm is currently LZMA2, which is used
      inside the .xz container format.  With typical files, XZ Utils
      create 30 % smaller output than gzip and 15 % smaller output than
      bzip2.
    '';
    license = with licenses; [
      gpl2Plus
      lgpl21Plus
    ];
    maintainers = with maintainers; [ sander ];
    platforms = platforms.all;
    pkgConfigModules = [ "liblzma" ];
  };
})
