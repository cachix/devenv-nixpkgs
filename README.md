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

**Nixpkgs revision**: [`f9a58c2`](https://github.com/NixOS/nixpkgs/commit/f9a58c292a040b1d851e0153fbc328cc7d4a1b81)

**Test run**: [View detailed results](https://github.com/cachix/devenv-nixpkgs/actions/runs/16262743507)

**Last updated**: 2025-07-14 18:07:05 UTC

### Platform Results

| Platform | Tests Failed/Total | Success Rate |
|----------|-------------------|--------------|
| Linux ARM64 | 2/65 | 96.9% |
| Linux X64 | 2/65 | 96.9% |
| macOS ARM64 | 6/65 | 90.7% |
| macOS X64 (13) | 5/65 | 92.3% |

### Summary

- **Total test jobs**: 262
- **Successful**: 247 ✅
- **Failed**: 15 ❌
- **Success rate**: 94%

<!-- TEST_RESULTS_END -->## Bumping nixpkgs

```
git fetch nixpkgs
git checkout nixpkgs/nixpkgs-unstable -B bump-rolling
git push origin bump-rolling -f
```

Then trigger a new test run on the [CI](https://github.com/cachix/devenv-nixpkgs/actions/workflows/devenv.yml).
