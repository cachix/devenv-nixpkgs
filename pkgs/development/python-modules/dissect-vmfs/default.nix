{
  lib,
  buildPythonPackage,
  dissect-cstruct,
  dissect-util,
  fetchFromGitHub,
  setuptools,
  setuptools-scm,
  pytestCheckHook,
  pythonOlder,
}:

buildPythonPackage rec {
  pname = "dissect-vmfs";
  version = "3.11";
  format = "pyproject";

  disabled = pythonOlder "3.10";

  src = fetchFromGitHub {
    owner = "fox-it";
    repo = "dissect.vmfs";
    tag = version;
    hash = "sha256-jGPHZ26DDIcblgx4hP6L2BLHYY8YeIBcbxNR7bN/49g=";
  };

  nativeBuildInputs = [
    setuptools
    setuptools-scm
  ];

  propagatedBuildInputs = [
    dissect-cstruct
    dissect-util
  ];

  nativeCheckInputs = [ pytestCheckHook ];

  pythonImportsCheck = [ "dissect.vmfs" ];

  meta = with lib; {
    description = "Dissect module implementing a parser for the VMFS file system";
    homepage = "https://github.com/fox-it/dissect.vmfs";
    changelog = "https://github.com/fox-it/dissect.vmfs/releases/tag/${src.tag}";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ fab ];
  };
}
