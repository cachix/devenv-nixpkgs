"""Build and publish immutable patched nixpkgs trees, or check existing snapshots."""

import argparse
import json
import os
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent


def run(*args, cwd=None, env=None):
    return subprocess.check_output(args, cwd=cwd, env=env, text=True).strip()


def publish_snapshot(source, nar_hash, repository, remote):
    """Publish a Git tree without modifying or copying the read-only store path."""
    with tempfile.TemporaryDirectory(prefix="devenv-nixpkgs-source-") as directory:
        git_dir = Path(directory) / "snapshot.git"
        run("git", "init", "--bare", "--quiet", str(git_dir))
        git = ["git", "--git-dir=" + str(git_dir)]
        run(*git, "config", "core.autocrlf", "false")
        run(*git, "--work-tree=" + str(source), "add", "--force", "--all")
        tree = run(*git, "write-tree")
        env = dict(os.environ)
        env.update(
            {
                "GIT_AUTHOR_NAME": "devenv-nixpkgs",
                "GIT_AUTHOR_EMAIL": "noreply@cachix.org",
                "GIT_COMMITTER_NAME": "devenv-nixpkgs",
                "GIT_COMMITTER_EMAIL": "noreply@cachix.org",
                "GIT_AUTHOR_DATE": "2000-01-01T00:00:00Z",
                "GIT_COMMITTER_DATE": "2000-01-01T00:00:00Z",
            }
        )
        revision = run(
            *git,
            "commit-tree",
            tree,
            "-m",
            "Patched nixpkgs source (" + nar_hash + ")",
            env=env,
        )
        # The NAR hash addresses the complete tree, independent of builder OS.
        branch_hash = run("nix", "hash", "path", "--type", "sha256", "--base32", str(source))
        run(*git, "push", remote, revision + ":refs/heads/patched/" + branch_hash)
    owner, repo = repository.split("/")
    return {"type": "github", "owner": owner, "repo": repo, "rev": revision, "narHash": nar_hash}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--publish", action="store_true", help="Push snapshots and update sources.json"
    )
    parser.add_argument(
        "--repository", default=os.environ.get("GITHUB_REPOSITORY", "cachix/devenv-nixpkgs")
    )
    args = parser.parse_args()
    lock = json.loads((ROOT / "flake.lock").read_text())
    upstream = lock["nodes"]["nixpkgs-src"]["locked"]
    system = run("nix", "eval", "--impure", "--raw", "--expr", "builtins.currentSystem", cwd=ROOT)
    patches_hash = run("nix", "eval", "--impure", "--raw", "--file", "lib/patch-hash.nix", cwd=ROOT)
    manifest = {"nixpkgsRev": upstream["rev"], "patchesHash": patches_hash, "sources": {}}
    previous = json.loads((ROOT / "sources.json").read_text())
    remote = "https://github.com/" + args.repository + ".git"
    for platform in ["linux", "darwin"]:
        result = json.loads(
            run(
                # Select the build output directly. Flake installable prefix
                # probing can force legacyPackages before snapshots exist.
                "nix",
                "build",
                "--impure",
                "--json",
                "--no-link",
                "--expr",
                '(builtins.getFlake (toString ./.)).packages."' + system + '".source-' + platform,
                cwd=ROOT,
            )
        )
        source = Path(result[0]["outputs"]["out"])
        nar_hash = run("nix", "hash", "path", "--type", "sha256", "--sri", str(source))
        if args.publish:
            manifest["sources"][platform] = publish_snapshot(
                source,
                nar_hash,
                args.repository,
                remote,
            )
        else:
            saved = previous.get("sources", {}).get(platform, {})
            if saved.get("narHash") != nar_hash:
                raise SystemExit("Stale " + platform + " snapshot; run with --publish")
            manifest["sources"][platform] = saved
    if args.publish:
        # Only update the manifest after both source trees have been pushed.
        (ROOT / "sources.json").write_text(json.dumps(manifest, indent=2) + "\n")
    elif manifest != previous:
        raise SystemExit("Stale source metadata; run with --publish")


if __name__ == "__main__":
    main()
