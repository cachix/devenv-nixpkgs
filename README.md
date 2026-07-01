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

- **upstream**: Patches from nixpkgs PRs or unreleased fixes
- **local**: Patches not yet submitted upstream

### Adding an Upstream Patch

Download the PR patch and commit it as a local file:

```bash
curl -L https://github.com/NixOS/nixpkgs/pull/12345.patch -o patches/fix-python-darwin.patch
```

Then add it to `patches/default.nix`:

```nix
upstream = [
  ./fix-python-darwin.patch
];
```

> **Note:** Avoid using `fetchpatch` for unmerged PRs — a force-push to the PR branch changes the content at that URL.
> `fetchpatch` is fine for merged commits whose content is immutable (e.g. unreleased fixes not yet in nixpkgs-unstable):
>
> ```nix
> (fetchpatch {
>   name = "fix-python-darwin.patch";
>   url = "https://github.com/NixOS/nixpkgs/commit/abc123.patch";
>   sha256 = "sha256-AAAA...";
> })
> ```

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
**Nixpkgs revision**: [`e1c1b84`](https://github.com/NixOS/nixpkgs/commit/e1c1b84752fb0897897380a3cae9dc7fcab91ca3)

**Test run**: [View detailed results](https://github.com/cachix/devenv-nixpkgs/actions/runs/28366109748)

**Last updated**: 2026-07-01 11:58:23 UTC

### Platform Results

| Platform | Tests Failed/Total | Success Rate |
|----------|-------------------|--------------|
| aarch64-linux | 6/71 | 91.5% |
| x86_64-linux | 2/71 | 97.1% |
| aarch64-darwin | 5/70 | 92.8% |

### Summary

- **Total test jobs**: 213
- **Successful**: 200 ✅
- **Failed**: 13 ❌
- **Success rate**: 93%

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

# Force the tests to run even if nixpkgs is already up to date
gh workflow run "Update and test" -f run_tests=always
```

The `run_tests` input accepts `auto` (default: test only when nixpkgs changed),
`always`, or `never`.

### Release Process

After tests complete, a PR is automatically created to promote `main` → `rolling` with the test results summary.
Merge the PR to release.
