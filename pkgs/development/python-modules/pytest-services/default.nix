{
  lib,
  stdenv,
  buildPythonPackage,
  fetchFromGitHub,
  psutil,
  pylibmc,
  pytest,
  pytestCheckHook,
  requests,
  setuptools-scm,
  toml,
  mysqlclient,
  zc-lockfile,
}:

buildPythonPackage rec {
  pname = "pytest-services";
  version = "2.2.2";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "pytest-dev";
    repo = "pytest-services";
    tag = "v${version}";
    hash = "sha256-kWgqb7+3/hZKUz7B3PnfxHZq6yU3JUeJ+mruqrMD/NE=";
  };

  build-system = [
    setuptools-scm
    toml
  ];

  buildInputs = [ pytest ];

  dependencies = [
    requests
    psutil
    zc-lockfile
  ];

  nativeCheckInputs = [
    mysqlclient
    pylibmc
    pytestCheckHook
  ];

  pythonImportsCheck = [ "pytest_services" ];

  preCheck = lib.optionalString stdenv.hostPlatform.isDarwin ''
    # Darwin sandboxes share /tmp with other Nix build users.
    cat >> tests/conftest.py <<'PY'

    @pytest.fixture(scope="session")
    def memory_root_dir(tmp_path_factory):
        return str(tmp_path_factory.mktemp("pytest-services"))
    PY
  '';

  disabledTests = [
    # Tests require binaries and additional parts
    "test_memcached"
    "test_mysql"
    "test_xvfb"
  ];

  # Tests use sockets
  __darwinAllowLocalNetworking = true;

  meta = {
    description = "Services plugin for pytest testing framework";
    homepage = "https://github.com/pytest-dev/pytest-services";
    changelog = "https://github.com/pytest-dev/pytest-services/blob/${src.tag}/CHANGES.rst";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ dotlambda ];
  };
}
