{
  lib,
  stdenv,
  fetchFromGitHub,
  rustPlatform,
  protobuf,
  installShellFiles,
  darwin,
}:

rustPlatform.buildRustPackage rec {
  pname = "clipcat";
  version = "0.18.3";

  src = fetchFromGitHub {
    owner = "xrelkd";
    repo = "clipcat";
    rev = "refs/tags/v${version}";
    hash = "sha256-95y/HiLmhqt1DFmAxLg/W7lr/9dfVtce4+tx+vG2Nuw=";
  };

  cargoHash = "sha256-z2t7kq2ogMHJGF7xQnzc11B42gUZFTVokVkbw35CeY0=";

  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    darwin.apple_sdk.frameworks.Cocoa
    darwin.apple_sdk.frameworks.Security
    darwin.apple_sdk.frameworks.SystemConfiguration
  ];

  nativeBuildInputs = [
    protobuf
    installShellFiles
  ];

  patches = [
    ./0001-fix-build.patch
  ];

  checkFlags = [
    # Some test cases interact with X11, skip them
    "--skip=test_x11_clipboard"
    "--skip=test_x11_primary"
  ];

  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    for cmd in clipcatd clipcatctl clipcat-menu clipcat-notify; do
      installShellCompletion --cmd $cmd \
        --bash <($out/bin/$cmd completions bash) \
        --fish <($out/bin/$cmd completions fish) \
        --zsh  <($out/bin/$cmd completions zsh)
    done
  '';

  meta = {
    description = "Clipboard Manager written in Rust Programming Language";
    homepage = "https://github.com/xrelkd/clipcat";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    maintainers = with lib.maintainers; [ xrelkd bot-wxt1221 ];
    mainProgram = "clipcatd";
  };
}
