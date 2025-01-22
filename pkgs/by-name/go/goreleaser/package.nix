{
  stdenv,
  lib,
  buildGoModule,
  fetchFromGitHub,
  installShellFiles,
  buildPackages,
  testers,
  goreleaser,
}:
buildGoModule rec {
  pname = "goreleaser";
  version = "2.6.0";

  src = fetchFromGitHub {
    owner = "goreleaser";
    repo = "goreleaser";
    rev = "v${version}";
    hash = "sha256-CZ4t7i253froL2JTdAGN61BLcI5PvJEqWCwn2RgGhfM=";
  };

  vendorHash = "sha256-fYYPpf/Hnci5DCvhbWkmenTL+95PvqPtn1RdoRby+jI=";

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
    "-X main.builtBy=nixpkgs"
  ];

  subPackages = [
    "."
  ];

  # tests expect the source files to be a build repo
  doCheck = false;

  nativeBuildInputs = [ installShellFiles ];

  postInstall =
    let
      emulator = stdenv.hostPlatform.emulator buildPackages;
    in
    ''
      ${emulator} $out/bin/goreleaser man > goreleaser.1
      installManPage ./goreleaser.1
      installShellCompletion --cmd goreleaser \
        --bash <(${emulator} $out/bin/goreleaser completion bash) \
        --fish <(${emulator} $out/bin/goreleaser completion fish) \
        --zsh  <(${emulator} $out/bin/goreleaser completion zsh)
    '';

  passthru.tests.version = testers.testVersion {
    package = goreleaser;
    command = "goreleaser -v";
    inherit version;
  };

  meta = with lib; {
    description = "Deliver Go binaries as fast and easily as possible";
    homepage = "https://goreleaser.com";
    maintainers = with maintainers; [
      sarcasticadmin
      techknowlogick
      caarlos0
    ];
    license = licenses.mit;
    mainProgram = "goreleaser";
  };
}
