{
  lib,
  stdenv,
  fetchFromGitHub,
  buildNpmPackage,
  jellyfin,
  nix-update-script,
  pkg-config,
  xcbuild,
  pango,
  giflib,
  apple-sdk_11,
  darwinMinVersionHook,
}:
buildNpmPackage rec {
  pname = "jellyfin-web";
  version = "10.9.11";

  src =
    assert version == jellyfin.version;
    fetchFromGitHub {
      owner = "jellyfin";
      repo = "jellyfin-web";
      rev = "v${version}";
      hash = "sha256-zt0Exx/4B5gqiN3fxvQuVh1MqRNNtJG6/G0/reqVHRc=";
    };

  npmDepsHash = "sha256-kQxfh8o8NBshKmmjQrLdxiOQK83LG+lxhZwzDkEJwEo=";

  npmBuildScript = [ "build:production" ];

  nativeBuildInputs = [ pkg-config ] ++ lib.optionals stdenv.hostPlatform.isDarwin [ xcbuild ];

  buildInputs =
    [ pango ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      giflib
      apple-sdk_11
      # node-canvas builds code that requires aligned_alloc,
      # which on Darwin requires at least the 10.15 SDK
      (darwinMinVersionHook "10.15")
    ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share
    cp -a dist $out/share/jellyfin-web

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Web Client for Jellyfin";
    homepage = "https://jellyfin.org/";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [
      nyanloutre
      minijackson
      purcell
      jojosch
    ];
  };
}
