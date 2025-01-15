{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  mpiCheckPhaseHook,
  mpi,
  blas,
  lapack,
}:

assert blas.isILP64 == lapack.isILP64;

stdenv.mkDerivation rec {
  pname = "scalapack";
  version = "2.2.2";

  src = fetchFromGitHub {
    owner = "Reference-ScaLAPACK";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-KDMW/D7ubGaD2L7eTwULJ04fAYDPAKl8xKPZGZMkeik=";
  };

  passthru = { inherit (blas) isILP64; };

  __structuredAttrs = true;

  # Required to activate ILP64.
  # See https://github.com/Reference-ScaLAPACK/scalapack/pull/19
  postPatch = lib.optionalString passthru.isILP64 ''
    sed -i 's/INTSZ = 4/INTSZ = 8/g'   TESTING/EIG/* TESTING/LIN/*
    sed -i 's/INTGSZ = 4/INTGSZ = 8/g' TESTING/EIG/* TESTING/LIN/*

    # These tests are not adapted to ILP64
    sed -i '/xssep/d;/xsgsep/d;/xssyevr/d' TESTING/CMakeLists.txt
  '';

  outputs = [
    "out"
    "dev"
  ];

  nativeBuildInputs = [ cmake ];
  nativeCheckInputs = [ mpiCheckPhaseHook ];
  buildInputs = [
    blas
    lapack
  ];
  propagatedBuildInputs = [ mpi ];
  hardeningDisable = lib.optionals (stdenv.hostPlatform.isAarch64 && stdenv.hostPlatform.isDarwin) [
    "stackprotector"
  ];

  # xslu and xsllt tests seem to time out on x86_64-darwin.
  # this line is left so those who force installation on x86_64-darwin can still build
  doCheck = !(stdenv.hostPlatform.isx86_64 && stdenv.hostPlatform.isDarwin);

  preConfigure = ''
    cmakeFlagsArray+=(
      -DBUILD_SHARED_LIBS=ON -DBUILD_STATIC_LIBS=OFF
      -DLAPACK_LIBRARIES="-llapack"
      -DBLAS_LIBRARIES="-lblas"
      -DCMAKE_Fortran_COMPILER=${lib.getDev mpi}/bin/mpif90
      -DCMAKE_C_FLAGS="${
        lib.concatStringsSep " " [
          "-Wno-implicit-function-declaration"
          (lib.optionalString passthru.isILP64 "-DInt=long")
        ]
      }"
      ${lib.optionalString passthru.isILP64 ''-DCMAKE_Fortran_FLAGS="-fdefault-integer-8"''}
      )
  '';

  # Increase individual test timeout from 1500s to 10000s because hydra's builds
  # sometimes fail due to this
  checkFlags = [ "ARGS=--timeout 10000" ];

  meta = with lib; {
    homepage = "http://www.netlib.org/scalapack/";
    description = "Library of high-performance linear algebra routines for parallel distributed memory machines";
    license = licenses.bsd3;
    platforms = platforms.unix;
    maintainers = with maintainers; [
      costrouc
      markuskowa
      gdinh
    ];
    # xslu and xsllt tests fail on x86 darwin
    broken = stdenv.hostPlatform.isDarwin && stdenv.hostPlatform.isx86_64;
  };
}
