{
  lib,
  stdenv,
  buildNpmPackage,
  fetchFromGitHub,
  makeWrapper,
  makeDesktopItem,
  copyDesktopItems,
  electron,
  httptoolkit-server,
}:

buildNpmPackage rec {
  pname = "httptoolkit";
  version = "1.19.4";

  src = fetchFromGitHub {
    owner = "httptoolkit";
    repo = "httptoolkit-desktop";
    tag = "v${version}";
    hash = "sha256-oDwAosyFY4ff9MP82O8q5o+mN/X6+J7hM3b7myfOq7k=";
  };

  npmDepsHash = "sha256-4kREJgw7OjKkOF/J1HpD3uPn+awtQIfUGWqJctwq3N0=";

  env = {
    ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
    # disable code signing on Darwin
    CSC_IDENTITY_AUTO_DISCOVERY = "false";
  };

  nativeBuildInputs = [
    makeWrapper
  ] ++ lib.optionals stdenv.hostPlatform.isLinux [ copyDesktopItems ];

  npmBuildScript = "build:src";

  postBuild = ''
    substituteInPlace package.json --replace-fail \
        '"forceCodeSigning": true' \
        '"forceCodeSigning": false'

    cp -r ${electron.dist} electron-dist
    chmod -R u+w electron-dist

    npm exec electron-builder -- \
        --dir \
        -c.electronDist=electron-dist \
        -c.electronVersion=${electron.version}
  '';

  installPhase = ''
    runHook preInstall

    ${lib.optionalString stdenv.hostPlatform.isLinux ''
      mkdir -p $out/share/httptoolkit
      cp -r dist/*-unpacked/{locales,resources{,.pak}} $out/share/httptoolkit

      ln -s ${httptoolkit-server} $out/share/httptoolkit/resources/httptoolkit-server

      install -Dm644 src/icons/icon.svg $out/share/icons/hicolor/scalable/apps/httptoolkit.svg

      makeWrapper ${lib.getExe electron} $out/bin/httptoolkit \
          --add-flags $out/share/httptoolkit/resources/app.asar \
          --inherit-argv0
    ''}

    ${lib.optionalString stdenv.hostPlatform.isDarwin ''
      mkdir -p $out/Applications
      cp -r dist/mac*/"HTTP Toolkit.app" $out/Applications

      ln -s ${httptoolkit-server} "$out/Applications/HTTP Toolkit.app/Contents/Resources/httptoolkit-server"

      makeWrapper "$out/Applications/HTTP Toolkit.app/Contents/MacOS/HTTP Toolkit" $out/bin/httptoolkit
    ''}

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "httptoolkit";
      desktopName = "HTTP Toolkit";
      exec = "httptoolkit %U";
      terminal = false;
      icon = "httptoolkit";
      startupWMClass = "HTTP Toolkit";
      comment = meta.description;
      categories = [ "Development" ];
      startupNotify = true;
    })
  ];

  meta = {
    description = "HTTP(S) debugging, development & testing tool";
    homepage = "https://httptoolkit.com/";
    license = lib.licenses.agpl3Plus;
    mainProgram = "httptoolkit";
    maintainers = with lib.maintainers; [ tomasajt ];
    platforms = electron.meta.platforms;
  };
}
