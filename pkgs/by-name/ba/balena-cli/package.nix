{
  lib,
  stdenv,
  buildNpmPackage,
  fetchFromGitHub,
  versionCheckHook,
  node-gyp,
  python3,
  udev,
  cctools,
  apple-sdk_12,
}:

buildNpmPackage rec {
  pname = "balena-cli";
  version = "20.1.2";

  src = fetchFromGitHub {
    owner = "balena-io";
    repo = "balena-cli";
    rev = "v${version}";
    hash = "sha256-E27EHOxi54ZyNCoJuV/P6wjlJ29/JAQc/YqikP5SgZ8=";
  };

  npmDepsHash = "sha256-dXvqgv+0jwDyyZrTN5/t/QnrLRJl8rBNdCq4+iex9eI=";

  postPatch = ''
    ln -s npm-shrinkwrap.json package-lock.json
  '';
  makeCacheWritable = true;

  nativeBuildInputs =
    [
      node-gyp
      python3
      versionCheckHook
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      cctools
    ];

  buildInputs =
    lib.optionals stdenv.hostPlatform.isLinux [
      udev
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      apple-sdk_12
    ];

  doInstallCheck = true;
  versionCheckProgram = "${placeholder "out"}/bin/balena";

  meta = {
    description = "Command line interface for balenaCloud or openBalena";
    longDescription = ''
      The balena CLI is a Command Line Interface for balenaCloud or openBalena. It is a software
      tool available for Windows, macOS and Linux, used through a command prompt / terminal window.
      It can be used interactively or invoked in scripts. The balena CLI builds on the balena API
      and the balena SDK, and can also be directly imported in Node.js applications.
    '';
    homepage = "https://github.com/balena-io/balena-cli";
    changelog = "https://github.com/balena-io/balena-cli/blob/v${version}/CHANGELOG.md";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [
      kalebpace
      doronbehar
    ];
    mainProgram = "balena";
  };
}
