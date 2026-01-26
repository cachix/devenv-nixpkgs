# devenv-nixpkgs

Battle-tested [nixpkgs](https://github.com/NixOS/nixpkgs) using [devenv](https://devenv.sh/)'s extensive testing infrastructure.

Currently, the only supported release is [rolling](https://github.com/cachix/devenv-nixpkgs/tree/rolling).

Rolling is based on [nixpkgs-unstable](https://github.com/NixOS/nixpkgs/tree/nixpkgs-unstable)
plus any patches that improve the integrations and services offered by [devenv](https://github.com/cachix/devenv).

## Usage

In your `devenv.yaml`:

```yaml
inputs:
  nixpkgs:
    url: github:cachix/devenv-nixpkgs/rolling
    flake: false
```

## Patches

Patches are defined in [`patches/default.nix`](./patches/default.nix) with two categories:

- **upstream**: Patches fetched from open nixpkgs PRs via `fetchpatch` (self-tracking)
- **local**: Patches not yet submitted upstream

### Adding an Upstream Patch

For patches with an open nixpkgs PR:

```nix
# patches/default.nix
upstream = [
  (fetchpatch {
    name = "fix-python-darwin.patch";
    url = "https://github.com/NixOS/nixpkgs/pull/12345.patch";
    sha256 = "sha256-AAAA...";
  })
];
```

When the PR is merged, the hash changes and the build fails, signaling removal.

### Adding a Local Patch

For patches not yet submitted upstream:

1. Create your patch in a nixpkgs checkout:
   ```bash
   git format-patch -1 HEAD -o /path/to/devenv-nixpkgs/patches/
   ```

2. Add it to `patches/default.nix`:
   ```nix
   local = [
     ./001-fix-something.patch
   ];
   ```

### Testing Locally

Test patches before pushing:

```bash
# Build a package with patches applied
nix build .#legacyPackages.x86_64-linux.hello

# Or enter a shell
nix develop
```

### Overlays

For package-level fixes that don't require source patches, use [`overlays/default.nix`](./overlays/default.nix):

```nix
[
  (final: prev: {
    somePackage = prev.somePackage.overrideAttrs (old: {
      patches = old.patches or [] ++ [ ./fix.patch ];
    });
  })
]
```

Overlays are more resilient to upstream changes than source patches.

## Test Results

Latest test results from devenv's comprehensive test suite:

<!-- TEST_RESULTS_START -->
**Status**: ❌ Some tests failing

**Nixpkgs revision**: [`7ab75bb`](https://github.com/NixOS/nixpkgs/commit/7ab75bb38dd082a6f0d9ef017616490874d064e3)

**Test run**: [View detailed results](https://github.com/cachix/devenv-nixpkgs/actions/runs/21352211894)

**Last updated**: 2026-01-26 14:06:18 UTC

### Platform Results

| Platform | Tests Failed/Total | Success Rate |
|----------|-------------------|--------------|
| aarch64-linux | 13/70 | 81.4% |
| x86_64-linux | 13/71 | 81.6% |
| aarch64-darwin | 39/71 | 45.0% |
| x86_64-darwin | 33/71 | 53.5% |

### Summary

- **Total test jobs**: 284
- **Successful**: 186 ✅
- **Failed**: 98 ❌
- **Success rate**: 65%

<!-- TEST_RESULTS_END -->

## Deployment

### How It Works

1. `flake.nix` imports nixpkgs-unstable and applies patches at evaluation time
2. `flake.lock` pins the exact nixpkgs revision
3. CI runs weekly to update, test, and create release PRs

### Branches

- `main`: development branch, receives weekly nixpkgs updates
- `rolling`: stable release, promoted from main via PR

### CI Workflow

Every Monday at 9:00 UTC (or manually triggered):

1. **Update**: `nix flake update` pulls latest nixpkgs-unstable
2. **Validate**: Build a test package to verify patches apply
3. **Push**: Commit updated `flake.lock` to `main`
4. **Test**: Run devenv test suite across all platforms
5. **Summary**: Update README with test results
6. **Release PR**: Create PR to promote `main` → `rolling`

### Manual Updates

Test locally:

```bash
nix flake update
nix build .#legacyPackages.x86_64-linux.hello
```

Trigger CI manually:

```bash
gh workflow run "Update and test"
```

### Release Process

After tests pass, a PR is automatically created to promote `main` → `rolling`. Merge the PR to release.
