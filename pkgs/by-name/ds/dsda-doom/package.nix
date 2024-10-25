{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  SDL2,
  SDL2_mixer,
  SDL2_image,
  fluidsynth,
  portmidi,
  dumb,
  libvorbis,
  libmad,
  libGLU,
  libzip,
  alsa-lib,
}:

stdenv.mkDerivation rec {
  pname = "dsda-doom";
  version = "0.28.2";

  src = fetchFromGitHub {
    owner = "kraflab";
    repo = "dsda-doom";
    rev = "v${version}";
    hash = "sha256-TuDiClIq8GLY/3qGildlPpwUUHmpFNATRz5CNTLpfeM=";
  };

  sourceRoot = "${src.name}/prboom2";

  nativeBuildInputs = [ cmake ];

  buildInputs = [
    alsa-lib
    dumb
    fluidsynth
    libGLU
    libmad
    libvorbis
    libzip
    portmidi
    SDL2
    SDL2_image
    SDL2_mixer
  ];

  meta = {
    homepage = "https://github.com/kraflab/dsda-doom";
    description = "Advanced Doom source port with a focus on speedrunning, successor of PrBoom+";
    mainProgram = "dsda-doom";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ Gliczy ];
  };
}
