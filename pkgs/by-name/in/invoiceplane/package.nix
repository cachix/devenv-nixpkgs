{
  lib,
  stdenv,
  fetchurl,
  unzip,
  nixosTests,
}:

stdenv.mkDerivation rec {
  pname = "invoiceplane";
  version = "1.6.1";

  src = fetchurl {
    url = "https://github.com/InvoicePlane/InvoicePlane/releases/download/v${version}/v${version}.zip";
    hash = "sha256-66vXxE4pTUMkmPalLgJrCt2pl2BSWOJ3tiJ5K5wspYY=";
  };

  nativeBuildInputs = [ unzip ];

  sourceRoot = ".";

  installPhase = ''
    mkdir -p $out/
    cp -r ip/. $out/
  '';

  passthru.tests = {
    inherit (nixosTests) invoiceplane;
  };

  meta = {
    description = "Self-hosted open source application for managing your invoices, clients and payments";
    changelog = "https://github.com/InvoicePlane/InvoicePlane/releases/tag/v${version}";
    homepage = "https://www.invoiceplane.com";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    maintainers = with lib.maintainers; [ onny ];
  };
}
