{
  lib,
  stdenv,
  buildPythonPackage,
  fetchFromGitHub,

  # build-system
  poetry-core,

  # dependencies
  httpx,
  orjson,
  pydantic,
  requests,
  requests-toolbelt,

  # tests
  anthropic,
  dataclasses-json,
  fastapi,
  freezegun,
  instructor,
  pytest-asyncio,
  pytestCheckHook,
  uvicorn,
  attr,
}:

buildPythonPackage rec {
  pname = "langsmith";
  version = "0.2.11";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "langchain-ai";
    repo = "langsmith-sdk";
    tag = "v${version}";
    hash = "sha256-fhmPbA2SyyBJDPS1XCv2mIUsFqWRt6wvNFg8i1QQf9s=";
  };

  sourceRoot = "${src.name}/python";

  pythonRelaxDeps = [ "orjson" ];

  build-system = [ poetry-core ];

  dependencies = [
    httpx
    orjson
    pydantic
    requests
    requests-toolbelt
  ];

  nativeCheckInputs = [
    anthropic
    dataclasses-json
    fastapi
    freezegun
    instructor
    pytest-asyncio
    pytestCheckHook
    uvicorn
  ] ++ lib.optionals stdenv.hostPlatform.isLinux [ attr ];

  disabledTests = [
    # These tests require network access
    "integration_tests"
    # due to circular import
    "test_as_runnable"
    "test_as_runnable_batch"
    "test_as_runnable_async"
    "test_as_runnable_async_batch"
    # Test requires git repo
    "test_git_info"
    # Tests require OpenAI API key
    "test_chat_async_api"
    "test_chat_sync_api"
    "test_completions_async_api"
    "test_completions_sync_api"
  ];

  disabledTestPaths = [
    # due to circular import
    "tests/integration_tests/test_client.py"
    "tests/integration_tests/test_prompts.py"
    "tests/unit_tests/evaluation/test_runner.py"
    "tests/unit_tests/test_client.py"
    # Tests require a Langsmith API key
    "tests/evaluation/test_evaluation.py"
    "tests/external/test_instructor_evals.py"
  ];

  pythonImportsCheck = [ "langsmith" ];

  __darwinAllowLocalNetworking = true;

  meta = {
    description = "Client library to connect to the LangSmith LLM Tracing and Evaluation Platform";
    homepage = "https://github.com/langchain-ai/langsmith-sdk";
    changelog = "https://github.com/langchain-ai/langsmith-sdk/releases/tag/${src.tag}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ natsukium ];
    mainProgram = "langsmith";
  };
}
