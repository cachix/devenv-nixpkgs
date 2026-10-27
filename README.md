# devenv-nixpkgs

Battle-tested [nixpkgs](https://github.com/NixOS/nixpkgs) using [devenv](https://devenv.sh/)'s extensive testing infrastructure.

Currently, the only supported release is [rolling](https://github.com/cachix/devenv-nixpkgs/tree/rolling).

Main tracks [nixpkgs-unstable](https://github.com/NixOS/nixpkgs/tree/nixpkgs-unstable)
plus any patches that improve the integrations and services offered by [devenv](https://github.com/cachix/devenv).
Rolling contains snapshots promoted from main.

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

Source patches are applied when publishing a snapshot, not during package
evaluation. Platform-specific behavior belongs in the patched package definitions,
so every platform uses the same source tree. After changing patches or the upstream lock, publish a new snapshot:

```bash
python3 lib/publish_sources.py --publish
```

This pushes immutable `patched/<content-hash>` branches and updates `sources.json`.
The snapshot omits upstream workflow definitions so CI can publish them with
its existing `contents: write` permission.
For a fork, pass `--repository OWNER/devenv-nixpkgs` so the snapshot is published
to your own repository. Commit `sources.json` together with the patch or lock change.

Check that the published snapshot matches the patches and lock file, then test packages:

```bash
python3 lib/publish_sources.py

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
**Nixpkgs revision**: [`674a202`](https://github.com/NixOS/nixpkgs/commit/674a2028661e550a97400c1cc992b9cca9a668a1)

**Test run**: [View detailed results](https://github.com/cachix/devenv-nixpkgs/actions/runs/40341314331)

**Last updated**: 2026-10-26 19:29:25 UTC

### Platform Results

| Platform | Tests Failed/Total | Success Rate |
|----------|-------------------|--------------|
| aarch64-linux | 2/70 | 97.1% |
| x86_64-linux | 2/71 | 97.1% |
| aarch64-darwin | 4/66 | 93.9% |

### Summary

- **Total test jobs**: 207
- **Successful**: 199 ✅
- **Failed**: 8 ❌
- **Success rate**: 96%

<!-- TEST_RESULTS_END -->

## Deployment

### How It Works

1. `flake.lock` pins the exact nixpkgs-unstable revision
2. Publishing builds one patched source tree using native tools
3. `sources.json` pins its Git revision and NAR hash
4. Flake and non-flake imports fetch this tree without import-from-derivation,
   including when evaluating Darwin packages on Linux
5. CI runs weekly to update, publish, test, and create release PRs

### Branches

- `main`: development branch, receives weekly nixpkgs updates
- `rolling`: stable release, promoted from main via PR

### CI Workflow

Every Monday at 9:00 UTC (or manually triggered):

1. **Update**: `nix flake update` pulls latest nixpkgs-unstable
2. **Publish**: Apply patches and push immutable source snapshots
3. **Push**: Commit updated `flake.lock` and `sources.json` to `main`
4. **Test**: Run devenv test suite across all platforms
5. **Summary**: Update README with test results
6. **Release PR**: Create PR to promote `main` → `rolling`

Changes to patches or the publishing code on `main` also publish and test fresh
snapshots. Pull requests check snapshot integrity and evaluation without IFD.

### Manual Updates

Test locally:

```bash
nix flake update
python3 lib/publish_sources.py --publish
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
