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

**Nixpkgs revision**: [`6bceb54`](https://github.com/NixOS/nixpkgs/commit/6bceb54ed394d44525ed12cabe65a325e10d9101)

**Test run**: [View detailed results](https://github.com/cachix/devenv-nixpkgs/actions/runs/16412886099)

**Last updated**: 2025-07-21 12:24:37 UTC

### Platform Results

| Platform | Tests Failed/Total | Success Rate |
|----------|-------------------|--------------|
| Linux ARM64 | 8/65 | 87.6% |
| Linux X64 | 8/65 | 87.6% |
| macOS ARM64 | 9/65 | 86.1% |
| macOS X64 (13) | 9/65 | 86.1% |

### Summary

- **Total test jobs**: 262
- **Successful**: 228 ✅
- **Failed**: 34 ❌
- **Success rate**: 87%

<!-- TEST_RESULTS_END -->
## Bumping nixpkgs

```
git fetch nixpkgs
git checkout nixpkgs/nixpkgs-unstable -B bump-rolling
git push origin bump-rolling -f
```

Then trigger a new test run on the [CI](https://github.com/cachix/devenv-nixpkgs/actions/workflows/devenv.yml).
