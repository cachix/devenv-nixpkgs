# devenv-nixpkgs

Battle-tested [nixpkgs](https://github.com/NixOS/nixpkgs) using [devenv](https://devenv.sh/)'s extensive testing infrastructure.

Currently, the only supported release is [rolling](https://github.com/cachix/devenv-nixpkgs/tree/rolling).

Rolling is based on [nixpkgs-unstable](https://github.com/NixOS/nixpkgs/tree/nixpkgs-unstable)
plus any patches that improve the integrations and services offered by [devenv](https://github.com/cachix/devenv).

## Patches

View the currently applied patches: <https://github.com/cachix/devenv-nixpkgs/tree/main/patches>

If the directory is empty, then all patches have been upstreamed into nixpkgs.

## Test Results

Latest test results from devenv's comprehensive test suite:

<!-- TEST_RESULTS_START -->
**Status**: ❌ Some tests failing

**Nixpkgs revision**: [`5eda0b8`](https://github.com/NixOS/nixpkgs/commit/5eda0b85f47a3038a93b451e3b9750639b72d605)

**Test run**: [View detailed results](https://github.com/cachix/devenv-nixpkgs/actions/runs/18616231368)

**Last updated**: 2025-10-18 17:35:36 UTC

### Platform Results

| Platform | Tests Failed/Total | Success Rate |
|----------|-------------------|--------------|
| Linux ARM64 | 3/69 | 95.6% |
| Linux X64 | 2/69 | 97.1% |
| macOS ARM64 | 13/69 | 81.1% |
| macOS X64 (13) | 9/68 | 86.7% |

### Summary

- **Total test jobs**: 276
- **Successful**: 249 ✅
- **Failed**: 27 ❌
- **Success rate**: 90%

<!-- TEST_RESULTS_END -->

## Deployment

This repository maintains (semi-)automated weekly updates from [nixpkgs-unstable](https://github.com/NixOS/nixpkgs/tree/nixpkgs-unstable).
The system automatically:

- Fetches the latest nixpkgs-unstable commits
- Applies any patches from the [patches directory](./patches)
- Runs the comprehensive devenv test suite across multiple platforms
- Updates the `bump-rolling` branch weekly every Monday at 9:00 UTC

### Manual Updates

To manually trigger an update outside the weekly schedule:

1. **Add patches** (if needed): Place `.patch` files in the [patches directory](./patches)

2. **Run the sync workflow**:

   ```bash
   gh workflow run "Sync and test rolling"
   ```

   You can also specify custom parameters:

   ```bash
   gh workflow run "Sync and test rolling" \
     -f target-branch=bump-rolling \
     -f upstream-ref=nixpkgs-unstable
   ```

### Release Process

To promote changes from `bump-rolling` to the stable `rolling` branch:

1. **Fetch latest changes**:

   ```bash
   git fetch origin
   ```

2. **Create a timestamped backup** of the current rolling branch:

   ```bash
   git checkout rolling
   git checkout -b rolling-$(date +%Y-%m-%d)
   git push origin rolling-$(date +%Y-%m-%d)
   ```

3. **Reset rolling to bump-rolling** and deploy:

   ```bash
   git checkout rolling
   git reset --hard origin/bump-rolling
   git push origin rolling --force-with-lease
   ```

This ensures that the stable `rolling` branch contains thoroughly tested changes while maintaining historical snapshots of previous releases.
