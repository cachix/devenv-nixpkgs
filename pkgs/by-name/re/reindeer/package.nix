{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  openssl,
  nix-update-script,
}:

rustPlatform.buildRustPackage rec {
  pname = "reindeer";
  version = "2025.01.20.00";

  src = fetchFromGitHub {
    owner = "facebookincubator";
    repo = "reindeer";
    tag = "v${version}";
    hash = "sha256-dmx9FPgyVz5s32peKTg4xA72JD7X2R9ks8HSna3msmA=";
  };

  useFetchCargoVendor = true;
  cargoHash = "sha256-fof3xJzcnF4oUdfYC0SNmSrdb9fbGh2m8hHkOsSoHhI=";

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [ openssl ];

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Reindeer is a tool which takes Rust Cargo dependencies and generates Buck build rules";
    mainProgram = "reindeer";
    homepage = "https://github.com/facebookincubator/reindeer";
    license = with licenses; [ mit ];
    maintainers = with maintainers; [ nickgerace ];
  };
}
