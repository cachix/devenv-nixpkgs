{
  lib,
  aiohttp,
  buildPythonPackage,
  fetchFromGitHub,
  freezegun,
  orjson,
  pydevccu,
  pytest-aiohttp,
  pytest-socket,
  pytestCheckHook,
  python-slugify,
  pythonOlder,
  setuptools,
  voluptuous,
}:

buildPythonPackage rec {
  pname = "hahomematic";
  version = "2024.12.13";
  pyproject = true;

  disabled = pythonOlder "3.12";

  src = fetchFromGitHub {
    owner = "SukramJ";
    repo = "hahomematic";
    tag = version;
    hash = "sha256-qHB47S5bU+353deoq4B8XwPYfUoU940Y3hl8u3gGrNs=";
  };

  __darwinAllowLocalNetworking = true;

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail "setuptools==75.6.0" "setuptools" \
  '';

  build-system = [ setuptools ];

  dependencies = [
    aiohttp
    orjson
    python-slugify
    voluptuous
  ];

  nativeCheckInputs = [
    freezegun
    pydevccu
    pytest-aiohttp
    pytest-socket
    pytestCheckHook
  ];

  pythonImportsCheck = [ "hahomematic" ];

  meta = with lib; {
    description = "Python module to interact with HomeMatic devices";
    homepage = "https://github.com/SukramJ/hahomematic";
    changelog = "https://github.com/SukramJ/hahomematic/blob/${src.tag}/changelog.md";
    license = licenses.mit;
    maintainers = with maintainers; [
      dotlambda
      fab
    ];
  };
}
