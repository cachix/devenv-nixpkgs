Battle-tested nixpkgs using devenv's extensive testing infrastructure.

Currently the only supported branch is `rolling`, which is based upon [nixpkgs-unstable](https://github.com/NixOS/nixpkgs/tree/nixpkgs-unstable)
plus a few patches that devenv needs which haven't yet reached upstream:

- [fix creation of Python virtualenv](https://github.com/NixOS/nixpkgs/pull/275701)
- [libpsl: split outputs](https://github.com/NixOS/nixpkgs/pull/292260)
