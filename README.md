# devenv-nixpkgs

Battle-tested [nixpkgs](https://github.com/NixOS/nixpkgs) using [devenv](https://devenv.sh/)'s extensive testing infrastructure.

Currently, the only supported release is [rolling](https://github.com/cachix/devenv-nixpkgs/tree/rolling).

Rolling is based upon [nixpkgs-unstable](https://github.com/NixOS/nixpkgs/tree/nixpkgs-unstable)
plus a few patches that [devenv](https://github.com/cachix/devenv) needs which have not yet reached upstream:

- [ ] [mongodb fails to compile on macOS](https://github.com/NixOS/nixpkgs/issues/346003)
- [ ] poetry fails to work with Python wrapper
- [ ] deno fails to compile until macOS SDK is bumped
- [ ] swift fails to compile until macOS SDK is bumped
- [ ] [bun needs newer macOS SDK](https://github.com/NixOS/nixpkgs/pull/343120#issuecomment-2388096956)

You can check the latest [tests here](https://github.com/cachix/devenv-nixpkgs/actions).

## Bumping nixpkgs

```
git fetch nixpkgs
git checkout nixpkgs/nixpkgs-unstable -B bump-rolling
git push origin bump-rolling -f
```

Then trigger a new test run on the [CI](https://github.com/cachix/devenv-nixpkgs/actions/workflows/devenv.yml).
