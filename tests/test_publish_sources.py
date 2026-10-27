import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

from lib.publish_sources import publish_snapshot, run


class PublishSnapshotTest(unittest.TestCase):
    def test_source_selection_and_stale_metadata_without_ifd(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "lib").mkdir()
            (root / "patches").mkdir()
            for name in ["source.nix", "patch-hash.nix"]:
                shutil.copy(Path(__file__).resolve().parents[1] / "lib" / name, root / "lib" / name)
            patch = root / "patches" / "default.nix"
            patch.write_text("{}\n")
            lock = {"nodes": {"nixpkgs-src": {"locked": {"rev": "upstream"}}}}
            (root / "flake.lock").write_text(json.dumps(lock))
            patch_hash = run(
                "nix", "eval", "--impure", "--raw", "--file", str(root / "lib/patch-hash.nix")
            )
            manifest = {"nixpkgsRev": "upstream", "patchesHash": patch_hash, "sources": {}}
            for platform in ["linux", "darwin"]:
                source = root / platform
                source.mkdir()
                (source / "platform").write_text(platform)
                manifest["sources"][platform] = {
                    "type": "path",
                    "path": str(source),
                    "narHash": run("nix", "hash", "path", "--type", "sha256", "--sri", str(source)),
                }
            (root / "sources.json").write_text(json.dumps(manifest))

            def evaluate(system):
                expr = (
                    "builtins.readFile ((import "
                    + str(root / "lib/source.nix")
                    + ' { system = "'
                    + system
                    + '"; }) + "/platform")'
                )
                return subprocess.run(
                    [
                        "nix",
                        "eval",
                        "--impure",
                        "--raw",
                        "--expr",
                        expr,
                        "--option",
                        "allow-import-from-derivation",
                        "false",
                        "--option",
                        "builders",
                        "",
                        "--option",
                        "max-jobs",
                        "0",
                        "--option",
                        "substitute",
                        "false",
                    ],
                    text=True,
                    capture_output=True,
                )

            for system, platform in [("x86_64-linux", "linux"), ("aarch64-darwin", "darwin")]:
                result = evaluate(system)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout, platform)
            patch.write_text("{ changed = true; }\n")
            self.assertIn("source snapshots are stale", evaluate("aarch64-darwin").stderr)
            patch.write_text("{}\n")
            lock["nodes"]["nixpkgs-src"]["locked"]["rev"] = "new-upstream"
            (root / "flake.lock").write_text(json.dumps(lock))
            self.assertIn("source snapshots are stale", evaluate("aarch64-darwin").stderr)

    def test_published_tree_preserves_contents_and_is_idempotent(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "source"
            source.mkdir()
            (source / ".gitignore").write_text("ignored\n")
            (source / "ignored").write_text("must still be published\n")
            (source / "default.nix").write_text("{ system }: { inherit system; }\n")
            executable = source / "script"
            executable.write_text("#!/bin/sh\nexit 0\n")
            executable.chmod(0o755)
            (source / "link").symlink_to("default.nix")
            remote = root / "remote.git"
            run("git", "init", "--bare", "--quiet", str(remote))
            nar_hash = run("nix", "hash", "path", "--type", "sha256", "--sri", str(source))
            result = publish_snapshot(source, nar_hash, "test/snapshots", str(remote))
            repeated = publish_snapshot(source, nar_hash, "test/snapshots", str(remote))
            self.assertEqual(result, repeated)

            restored = root / "restored"
            restored.mkdir()
            archive = subprocess.check_output(
                [
                    "git",
                    "--git-dir=" + str(remote),
                    "archive",
                    result["rev"],
                ]
            )
            subprocess.run(["tar", "-x", "-C", str(restored)], input=archive, check=True)
            self.assertEqual(
                nar_hash,
                run("nix", "hash", "path", "--type", "sha256", "--sri", str(restored)),
            )
            self.assertTrue(os.access(restored / "script", os.X_OK))
            self.assertEqual((restored / "ignored").read_text(), "must still be published\n")
            self.assertEqual(os.readlink(restored / "link"), "default.nix")

            # Content changes get a new immutable branch, leaving the old tree available.
            (source / "default.nix").write_text("{ system }: { inherit system; patched = true; }\n")
            changed_hash = run("nix", "hash", "path", "--type", "sha256", "--sri", str(source))
            changed = publish_snapshot(source, changed_hash, "test/snapshots", str(remote))
            self.assertNotEqual(result["rev"], changed["rev"])
            self.assertEqual(
                len(run("git", "--git-dir=" + str(remote), "for-each-ref").splitlines()), 2
            )


if __name__ == "__main__":
    unittest.main()
