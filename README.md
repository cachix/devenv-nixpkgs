Battle-tested [nixpkgs](https://github.com/NixOS/nixpkgs) using [devenv](https://devenv.sh/)'s extensive testing infrastructure.

Currently the only supported release is [rolling](https://github.com/cachix/devenv-nixpkgs/tree/rolling).

Rolling is based upon [nixpkgs-unstable](https://github.com/NixOS/nixpkgs/tree/nixpkgs-unstable)
plus a few patches that [devenv](https://github.com/cachix/devenv) needs which have not yet reached upstream:

- [fix creation of Python virtualenv](https://github.com/NixOS/nixpkgs/pull/275701)
- [libpsl: split outputs](https://github.com/NixOS/nixpkgs/pull/292260)
- [pixman: disable tests on darwin](https://github.com/NixOS/nixpkgs/pull/297660)
- [swift: don't pass -march to swiftc](https://github.com/NixOS/nixpkgs/pull/296082)
