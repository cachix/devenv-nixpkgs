{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "nhost-cli";
  version = "1.29.5";

  src = fetchFromGitHub {
    owner = "nhost";
    repo = "cli";
    tag = "v${version}";
    hash = "sha256-x6/hPW8sD/wwgjlA6+Cz3t3c7KICD/bhzz5yfks/In8=";
  };

  vendorHash = null;

  ldflags = [
    "-s"
    "-w"
    "-X=main.Version=v${version}"
  ];

  postInstall = ''
    mv $out/bin/cli $out/bin/nhost
  '';

  # require network access
  checkFlags = [ "-skip=^TestMakeJSONRequest$" ];

  meta = {
    description = "Tool for setting up a local development environment for Nhost";
    homepage = "https://github.com/nhost/cli";
    changelog = "https://github.com/nhost/cli/releases/tag/v${version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ moraxyc ];
    mainProgram = "nhost";
  };
}
