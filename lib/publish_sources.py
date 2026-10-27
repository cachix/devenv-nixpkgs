"""Build and publish a patched nixpkgs snapshot, or check the current pin."""

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
        env = dict(
            os.environ,
            GIT_AUTHOR_NAME="devenv-nixpkgs",
            GIT_AUTHOR_EMAIL="noreply@cachix.org",
            GIT_COMMITTER_NAME="devenv-nixpkgs",
            GIT_COMMITTER_EMAIL="noreply@cachix.org",
            GIT_AUTHOR_DATE="2000-01-01T00:00:00Z",
            GIT_COMMITTER_DATE="2000-01-01T00:00:00Z",
        )
        revision = run(
            *git,
            "commit-tree",
            tree,
            "-m",
            "Patched nixpkgs source (" + nar_hash + ")",
            env=env,
        )
        run(*git, "push", remote, revision + ":refs/heads/patched/" + tree)
    owner, repo = repository.split("/")
    return {"type": "github", "owner": owner, "repo": repo, "rev": revision, "narHash": nar_hash}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--publish", action="store_true", help="Push the snapshot and update sources.json"
    )
    parser.add_argument(
        "--repository", default=os.environ.get("GITHUB_REPOSITORY", "cachix/devenv-nixpkgs")
    )
    args = parser.parse_args()
    system = run("nix", "eval", "--impure", "--raw", "--expr", "builtins.currentSystem", cwd=ROOT)
    result = json.loads(
        run(
            # Avoid flake installable prefix probing, which forces legacyPackages
            # before the initial snapshot exists.
            "nix",
            "build",
            "--impure",
            "--json",
            "--no-link",
            "--expr",
            '(builtins.getFlake (toString ./.)).packages."' + system + '".source',
            cwd=ROOT,
        )
    )
    source = Path(result[0]["outputs"]["out"])
    nar_hash = run("nix", "hash", "path", "--type", "sha256", "--sri", str(source))
    manifest = ROOT / "sources.json"
    if args.publish:
        snapshot = publish_snapshot(
            source, nar_hash, args.repository, "https://github.com/" + args.repository + ".git"
        )
        manifest.write_text(json.dumps(snapshot, indent=2) + "\n")
    elif json.loads(manifest.read_text())["narHash"] != nar_hash:
        raise SystemExit("Stale source snapshot; run with --publish")


if __name__ == "__main__":
    main()
