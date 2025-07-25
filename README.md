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

**Nixpkgs revision**: [`655c5f3`](https://github.com/NixOS/nixpkgs/commit/655c5f3465b8b8338c50d1e8b64a9e1aed5adbdc)

**Test run**: [View detailed results](https://github.com/cachix/devenv-nixpkgs/actions/runs/16429697490)

**Last updated**: 2025-07-22 07:21:11 UTC

### Platform Results

| Platform | Tests Failed/Total | Success Rate |
|----------|-------------------|--------------|
| Linux ARM64 | 7/65 | 89.2% |
| Linux X64 | 6/65 | 90.7% |
| macOS ARM64 | 7/65 | 89.2% |
| macOS X64 (13) | 8/65 | 87.6% |

### Summary

- **Total test jobs**: 262
- **Successful**: 234 ✅
- **Failed**: 28 ❌
- **Success rate**: 89%

<!-- TEST_RESULTS_END -->


## Bumping nixpkgs

```
git fetch nixpkgs
git checkout nixpkgs/nixpkgs-unstable -B bump-rolling
git push origin bump-rolling -f
```

Then trigger a new test run on the [CI](https://github.com/cachix/devenv-nixpkgs/actions/workflows/devenv.yml).
