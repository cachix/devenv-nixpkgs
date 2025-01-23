{
  lib,
  stdenv,
  rustPlatform,
  python3,
  perl,
  openssl,
  Security,
  fetchFromGitHub,
  pkg-config,
}:

rustPlatform.buildRustPackage rec {
  pname = "s3rs";
  version = "0.4.19";

  src = fetchFromGitHub {
    owner = "yanganto";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-mJ1bMfv/HY74TknpRvu8RIs1d2VlNreEVtHCtQSHQw8=";
  };

  useFetchCargoVendor = true;
  cargoHash = "sha256-z7de/TZXyNsb+dxWcNFdJsaGsM3Ld2A0jorNMAVOZOg=";

  nativeBuildInputs = [
    python3
    perl
    pkg-config
  ];
  buildInputs = [ openssl ] ++ lib.optionals stdenv.hostPlatform.isDarwin [ Security ];

  meta = with lib; {
    description = "S3 cli client with multi configs with diffent provider";
    homepage = "https://github.com/yanganto/s3rs";
    license = licenses.mit;
    maintainers = with maintainers; [ yanganto ];
    mainProgram = "s3rs";
  };
}
