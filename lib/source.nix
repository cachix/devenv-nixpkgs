{
  system,
  nixpkgsRev ? null,
}:
let
  lock = builtins.fromJSON (builtins.readFile ../flake.lock);
  snapshots = builtins.fromJSON (builtins.readFile ../sources.json);
  platform = if builtins.match ".*-darwin" system != null then "darwin" else "linux";
in
if
  (snapshots.nixpkgsRev or null) != lock.nodes.nixpkgs-src.locked.rev
  || (nixpkgsRev != null && snapshots.nixpkgsRev != nixpkgsRev)
  || (snapshots.patchesHash or null) != import ./patch-hash.nix
then
  throw "devenv-nixpkgs: source snapshots are stale; run python3 lib/publish_sources.py --publish"
else
  builtins.fetchTree snapshots.sources.${platform}
