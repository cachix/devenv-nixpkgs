{
  lib,
  aiohttp,
  async-timeout,
  buildPythonPackage,
  fetchFromGitHub,
  pytest-asyncio,
  pytestCheckHook,
  pythonAtLeast,
  pythonOlder,
  setuptools,
}:

buildPythonPackage rec {
  pname = "pysqueezebox";
  version = "0.11.1";
  pyproject = true;

  disabled = pythonOlder "3.10";

  src = fetchFromGitHub {
    owner = "rajlaud";
    repo = "pysqueezebox";
    tag = "v${version}";
    hash = "sha256-8eCf0y8xbnSP+c+QP8fRkamUj5kN4EUQVZpotdo7hbs=";
  };

  build-system = [ setuptools ];

  dependencies = [
    async-timeout
    aiohttp
  ];

  nativeCheckInputs = [
    pytest-asyncio
    pytestCheckHook
  ];

  pythonImportsCheck = [ "pysqueezebox" ];

  disabledTests = lib.optionals (pythonAtLeast "3.12") [
    # AttributeError: 'has_calls' is not a valid assertion. Use a spec for the mock if 'has_calls' is meant to be an attribute.
    "test_verified_pause"
  ];

  disabledTestPaths = [
    # Tests require network access
    "tests/test_integration.py"
  ];

  meta = with lib; {
    description = "Asynchronous library to control Logitech Media Server";
    homepage = "https://github.com/rajlaud/pysqueezebox";
    changelog = "https://github.com/rajlaud/pysqueezebox/releases/tag/v${version}";
    license = licenses.asl20;
    maintainers = with maintainers; [ nyanloutre ];
  };
}
