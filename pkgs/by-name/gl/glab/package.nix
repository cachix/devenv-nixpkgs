{
  lib,
  buildGoModule,
  fetchFromGitLab,
  installShellFiles,
  stdenv,
  nix-update-script,
}:

buildGoModule rec {
  pname = "glab";
  version = "1.55.0";

  src = fetchFromGitLab {
    owner = "gitlab-org";
    repo = "cli";
    rev = "v${version}";
    hash = "sha256-K1zjb4QCLBp7GwT2580DXYKx3yTaIyNytKObMbzjvlQ=";
  };

  vendorHash = "sha256-ODTyWArYcCxsWbN9fuppAcRYtKGxcadeRPIwfPiAuOE=";

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  preCheck = ''
    # failed to read configuration:  mkdir /homeless-shelter: permission denied
    export HOME=$TMPDIR
  '';

  subPackages = [ "cmd/glab" ];

  nativeBuildInputs = [ installShellFiles ];

  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    make manpage
    installManPage share/man/man1/*
    installShellCompletion --cmd glab \
      --bash <($out/bin/glab completion -s bash) \
      --fish <($out/bin/glab completion -s fish) \
      --zsh <($out/bin/glab completion -s zsh)
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "GitLab CLI tool bringing GitLab to your command line";
    license = lib.licenses.mit;
    homepage = "https://gitlab.com/gitlab-org/cli";
    changelog = "https://gitlab.com/gitlab-org/cli/-/releases/v${version}";
    maintainers = with lib.maintainers; [
      freezeboy
      luftmensch-luftmensch
    ];
    mainProgram = "glab";
  };
}
