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

**Nixpkgs revision**: [`8e00acc`](https://github.com/NixOS/nixpkgs/commit/8e00acc65b9926ac35f7d90b0502ebf54d39e51a)

**Test run**: [View detailed results](https://github.com/cachix/devenv-nixpkgs/actions/runs/20427307148)

**Last updated**: 2025-12-22 22:41:25 UTC

### Platform Results

| Platform | Tests Failed/Total | Success Rate |
|----------|-------------------|--------------|
| aarch64-linux | 14/71 | 80.2% |
| x86_64-linux | 16/70 | 77.1% |
| aarch64-darwin | 17/71 | 76.0% |
| x86_64-darwin | 19/70 | 72.8% |

### Summary

- **Total test jobs**: 283
- **Successful**: 217 ✅
- **Failed**: 66 ❌
- **Success rate**: 76%

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

2. **Reset rolling to bump-rolling** and deploy:

   ```bash
   git checkout rolling
   git reset --hard origin/bump-rolling
   git push origin rolling --force-with-lease
   ```

3. **Create a timestamped backup** of the released rolling branch:

   This will safe-guard the release from garbage-collection when `rolling` is bumped again.

   ```bash
   git checkout -b rolling-$(date +%Y-%m-%d)
   git push origin rolling-$(date +%Y-%m-%d)
   ```

This ensures that the stable `rolling` branch contains thoroughly tested changes while maintaining historical snapshots of previous releases.
