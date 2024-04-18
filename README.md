# devenv-nixpkgs

Battle-tested [nixpkgs](https://github.com/NixOS/nixpkgs) using [devenv](https://devenv.sh/)'s extensive testing infrastructure.

Currently, the only supported release is [rolling](https://github.com/cachix/devenv-nixpkgs/tree/rolling).

Rolling is based upon [nixpkgs-unstable](https://github.com/NixOS/nixpkgs/tree/nixpkgs-unstable)
plus a few patches that [devenv](https://github.com/cachix/devenv) needs which have not yet reached upstream:

- python3Packages.deepdiff: disable tests
- dnspython: disable tests
- openldap: tests fail on darwin
- [fix meiliesearch on darwin](285676e87ad9f0ca23d8714a6ab61e7e027020c6)

You can check the latest [tests here](https://github.com/cachix/devenv-nixpkgs/actions).

## Bumping nixpkgs

```
git fetch nixpkgs
git checkout nixpkgs/nixpkgs-unstable -B bump-rolling
git push origin bump-rolling -f
```

Then trigger a new test run on the [CI](https://github.com/cachix/devenv-nixpkgs/actions/workflows/devenv.yml).
