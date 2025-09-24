# devenv-nixpkgs

Battle-tested [nixpkgs](https://github.com/NixOS/nixpkgs) using [devenv](https://devenv.sh/)'s extensive testing infrastructure.

Currently, the only supported release is [rolling](https://github.com/cachix/devenv-nixpkgs/tree/rolling).

Rolling is based on [nixpkgs-unstable](https://github.com/NixOS/nixpkgs/tree/nixpkgs-unstable)
plus any patches that improve the integrations and services offered by [devenv](https://github.com/cachix/devenv).

## Patches

View the currently applied patches: https://github.com/cachix/devenv-nixpkgs/tree/main/patches

If the directory is empty, then all patches have been upstreamed into nixpkgs.

## Test Results

Latest test results from devenv's comprehensive test suite:

<!-- TEST_RESULTS_START -->
**Status**: ❌ Some tests failing

**Nixpkgs revision**: [`207a4cb`](https://github.com/NixOS/nixpkgs/commit/207a4cb0e1253c7658c6736becc6eb9cace1f25f)

**Test run**: [View detailed results](https://github.com/cachix/devenv-nixpkgs/actions/runs/17910388640)

**Last updated**: 2025-09-24 22:16:15 UTC

### Platform Results

| Platform | Tests Failed/Total | Success Rate |
|----------|-------------------|--------------|
| Linux ARM64 | 0/0 | 0.0% |
| Linux X64 | 0/0 | 0.0% |
| macOS ARM64 | 0/0 | 0.0% |
| macOS X64 (13) | 0/0 | 0.0% |

### Summary

- **Total test jobs**: 262
- **Successful**: 246 ✅
- **Failed**: 16 ❌
- **Success rate**: 93%

<!-- TEST_RESULTS_END -->




## Bumping nixpkgs

```
git fetch nixpkgs
git checkout nixpkgs/nixpkgs-unstable -B bump-rolling
git push origin bump-rolling -f
```

Then trigger a new test run on the [CI](https://github.com/cachix/devenv-nixpkgs/actions/workflows/devenv.yml).
