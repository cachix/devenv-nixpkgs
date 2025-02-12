{
  lib,
  rustPlatform,
  fetchCrate,
  stdenv,
  darwin,
  versionCheckHook,
  nix-update-script,
}:

rustPlatform.buildRustPackage rec {
  pname = "samply";
  version = "0.12.0";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-7bf1lDIZGhRpvnn8rHNwzH2GBY8CwtYCjuRAUTQgbsA=";
  };

  useFetchCargoVendor = true;
  cargoHash = "sha256-o9YGKHxcC7msF7OPiUiFMLw1XX2WJ0/KVvkSwKNhU/E=";

  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    darwin.apple_sdk.frameworks.CoreServices
  ];

  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "--version";
  doInstallCheck = true;

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Command line profiler for macOS and Linux";
    homepage = "https://github.com/mstange/samply";
    changelog = "https://github.com/mstange/samply/releases/tag/samply-v${version}";
    license = with lib.licenses; [
      asl20
      mit
    ];
    maintainers = with lib.maintainers; [ figsoda ];
    mainProgram = "samply";
  };
}
