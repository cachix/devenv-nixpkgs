{
  lib,
  callPackage,
  buildPythonPackage,
  fetchPypi,
  pythonOlder,
  substituteAll,
  hatchling,
}:

buildPythonPackage rec {
  pname = "attrs";
  version = "24.3.0";
  disabled = pythonOlder "3.7";
  format = "pyproject";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-j1wHMz1UMQNUG6e+Dizhbu7oEwyws/kjirkEzh6Fuv8=";
  };

  patches = [
    (substituteAll {
      # hatch-vcs and hatch-fancy-pypi-readme depend on pytest, which depends on attrs
      src = ./remove-hatch-plugins.patch;
      inherit version;
    })
  ];

  nativeBuildInputs = [ hatchling ];

  outputs = [
    "out"
    "testout"
  ];

  postInstall = ''
    # Install tests as the tests output.
    mkdir $testout
    cp -R conftest.py tests $testout
  '';

  pythonImportsCheck = [ "attr" ];

  # pytest depends on attrs, so we can't do this out-of-the-box.
  # Instead, we do this as a passthru.tests test.
  doCheck = false;

  passthru.tests = {
    pytest = callPackage ./tests.nix { };
  };

  meta = with lib; {
    description = "Python attributes without boilerplate";
    homepage = "https://github.com/python-attrs/attrs";
    changelog = "https://github.com/python-attrs/attrs/releases/tag/${version}";
    license = licenses.mit;
    maintainers = [ ];
  };
}
