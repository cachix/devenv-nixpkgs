import os
import subprocess
import tempfile
import unittest
from pathlib import Path

from lib.publish_sources import publish_snapshot, run


class PublishSnapshotTest(unittest.TestCase):
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
