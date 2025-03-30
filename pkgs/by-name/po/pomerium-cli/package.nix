{
  buildGoModule,
  fetchFromGitHub,
  lib,
}:

let
  inherit (lib)
    concatStringsSep
    concatMap
    id
    mapAttrsToList
    ;
in
buildGoModule rec {
  pname = "pomerium-cli";
  version = "0.29.0";

  src = fetchFromGitHub {
    owner = "pomerium";
    repo = "cli";
    rev = "v${version}";
    sha256 = "sha256-H5wZaZsMgHPcO1qDoaqp/UP+stU7IG070DNFhxC7Ehw=";
  };

  vendorHash = "sha256-a5eESlDBxYVvfiafdZFIjUqIxB51LZc67fUJek69qwc=";

  subPackages = [
    "cmd/pomerium-cli"
  ];

  ldflags =
    let
      # Set a variety of useful meta variables for stamping the build with.
      setVars = {
        "github.com/pomerium/cli/version" = {
          Version = "v${version}";
          BuildMeta = "nixpkgs";
          ProjectName = "pomerium-cli";
          ProjectURL = "github.com/pomerium/cli";
        };
      };
      concatStringsSpace = list: concatStringsSep " " list;
      mapAttrsToFlatList = fn: list: concatMap id (mapAttrsToList fn list);
      varFlags = concatStringsSpace (
        mapAttrsToFlatList (
          package: packageVars:
          mapAttrsToList (variable: value: "-X ${package}.${variable}=${value}") packageVars
        ) setVars
      );
    in
    [
      "${varFlags}"
    ];

  installPhase = ''
    runHook preInstall

    install -Dm0755 $GOPATH/bin/pomerium-cli $out/bin/pomerium-cli

    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://pomerium.io";
    description = "Client-side helper for Pomerium authenticating reverse proxy";
    mainProgram = "pomerium-cli";
    license = licenses.asl20;
    maintainers = with maintainers; [ lukegb ];
    platforms = platforms.unix;
  };
}
