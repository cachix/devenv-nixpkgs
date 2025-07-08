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
**Status**: ❌ Some tests failing

**Nixpkgs revision**: [`3c15587533b3`](https://github.com/NixOS/nixpkgs/commit/3c15587533b37ec03503dc0b807e63b74a21c1c1)

**Test run**: [View detailed results](https://github.com/cachix/devenv-nixpkgs/actions/runs/16121139596)

**Last updated**: 2025-07-08 17:23:13 UTC

### Platform Results

| Platform | CLI Tests | Examples | Status |
|----------|-----------|----------|--------|
| Linux ARM64 | ⏳ | - | ⏳ |
| Linux X64 | ⏳ | - | ⏳ |
| macOS ARM64 | ⏳ | - | ⏳ |
| macOS X64 (13) | ⏳ | - | ⏳ |

### Summary

- **Total test jobs**: 262
- **Successful**: 240 ✅
- **Failed**: 22 ❌
- **Success rate**: 91%

<!-- TEST_RESULTS_END -->
## Bumping nixpkgs

```
git fetch nixpkgs
git checkout nixpkgs/nixpkgs-unstable -B bump-rolling
git push origin bump-rolling -f
```

Then trigger a new test run on the [CI](https://github.com/cachix/devenv-nixpkgs/actions/workflows/devenv.yml).
