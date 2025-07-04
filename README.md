# devenv-nixpkgs

Battle-tested [nixpkgs](https://github.com/NixOS/nixpkgs) using [devenv](https://devenv.sh/)'s extensive testing infrastructure.

Currently, the only supported release is [rolling](https://github.com/cachix/devenv-nixpkgs/tree/rolling).

Rolling is based upon [nixpkgs-unstable](https://github.com/NixOS/nixpkgs/tree/nixpkgs-unstable)
plus a few patches that [devenv](https://github.com/cachix/devenv) needs which have not yet reached upstream:

All patches have been upstreamed to nixpkgs!

You can check the latest [tests here](https://github.com/cachix/devenv-nixpkgs/actions).

## Test Results

Latest test results from devenv's comprehensive test suite:

<!-- TEST_RESULTS_START -->
**Status**: 🔄 Testing in progress...

**Nixpkgs revision**: [Latest](https://github.com/NixOS/nixpkgs/commit/HEAD)

**Test run**: [View latest results](https://github.com/cachix/devenv-nixpkgs/actions/workflows/devenv.yml)

**Last updated**: Never

### Platform Results

| Platform | CLI Tests | Examples | Status |
|----------|-----------|----------|--------|
| Linux ARM64 | - | - | ⏳ |
| Linux X64 | - | - | ⏳ |
| macOS ARM64 | - | - | ⏳ |
| macOS X64 (13) | - | - | ⏳ |

### Summary

- **Total test jobs**: 0
- **Successful**: 0 ✅
- **Failed**: 0 ❌
- **Success rate**: 0%

<!-- TEST_RESULTS_END -->

## Bumping nixpkgs

```
git fetch nixpkgs
git checkout nixpkgs/nixpkgs-unstable -B bump-rolling
git push origin bump-rolling -f
```

Then trigger a new test run on the [CI](https://github.com/cachix/devenv-nixpkgs/actions/workflows/devenv.yml).
