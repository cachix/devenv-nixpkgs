{
  stdenv,
  lib,
  fetchFromGitHub,
}:

stdenv.mkDerivation rec {
  pname = "hiredis-vip";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "vipshop";
    repo = "hiredis-vip";
    rev = version;
    sha256 = "1z9zry635pxqv6d2cgk3dghb5qfpg9m7dz34ld4djw9b53hjr2z2";
  };

  makeFlags = [ "PREFIX=$(out)" ];

  # Function are declared after they are used in the file, this is error since gcc-14.
  #   command.c:1668:9: error: implicit declaration of function 'free' [-Wimplicit-function-declaration]
  env.NIX_CFLAGS_COMPILE = "-Wno-error=implicit-function-declaration";

  meta = {
    description = "C client library for the Redis database";
    homepage = "https://github.com/vipshop/hiredis-vip";
    license = lib.licenses.bsd3;
  };

}
