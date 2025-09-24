#!/usr/bin/env python3
"""
Robust script to fetch upstream nixpkgs and apply patches.
Replicates the functionality of .github/workflows/fetch-and-patch.yml
"""

import shutil
import sys
import tempfile
from pathlib import Path
from typing import Optional

import click
import git
from git import Repo, Remote, GitCommandError
from rich.console import Console
from rich.logging import RichHandler
from rich.progress import Progress, SpinnerColumn, TextColumn
from rich.panel import Panel
from rich.text import Text
import logging


class PatcherError(Exception):
    """Custom exception for Patcher-related errors."""

    pass


class Patcher:
    def __init__(
        self,
        repo_path: Path = Path("."),
        upstream_ref: str = "nixpkgs-unstable",
        target_branch: str = "bump-rolling",
        remote_name: str = "upstream",
        remote_url: str = "https://github.com/NixOS/nixpkgs.git",
        patch_dir: Path = Path("patches"),
        refetch: bool = True,
        git_user_name: str = "Patcher Script",
        git_user_email: str = "sander@cachix.org",
        console: Optional[Console] = None,
    ):
        self.repo_path = repo_path
        self.upstream_ref = upstream_ref
        self.target_branch = target_branch
        self.remote_name = remote_name
        self.remote_url = remote_url
        self.patch_dir = patch_dir
        self.refetch = refetch
        self.git_user_name = git_user_name
        self.git_user_email = git_user_email
        self.console = console or Console()

        # Initialize repository
        try:
            self.repo = Repo(repo_path)
        except git.InvalidGitRepositoryError:
            raise PatcherError(f"Not a valid git repository: {repo_path}")

        # Set up logging with rich
        logging.basicConfig(
            level=logging.INFO,
            format="%(message)s",
            datefmt="[%X]",
            handlers=[RichHandler(console=self.console, rich_tracebacks=True)],
        )
        self.logger = logging.getLogger(__name__)

    def configure_git(self) -> None:
        """Configure git user name and email."""
        with self.repo.config_writer() as git_config:
            git_config.set_value("user", "name", self.git_user_name)
            git_config.set_value("user", "email", self.git_user_email)

        self.console.print(
            f"✅ Configured Git user: {self.git_user_name} <{self.git_user_email}>"
        )

    def setup_upstream_remote(self) -> Remote:
        """Add upstream remote if it doesn't exist, or update it if it does."""
        try:
            remote = self.repo.remote(self.remote_name)
            if remote.url != self.remote_url:
                self.console.print(
                    f"🔄 Updating remote '{self.remote_name}' URL to {self.remote_url}"
                )
                remote.set_url(self.remote_url)
            else:
                self.console.print(
                    f"✅ Remote '{self.remote_name}' already configured correctly"
                )
        except ValueError:
            self.console.print(
                f"➕ Adding remote '{self.remote_name}': {self.remote_url}"
            )
            remote = self.repo.create_remote(self.remote_name, self.remote_url)

        return remote

    def fetch_upstream(self, remote: Remote) -> None:
        """Fetch from upstream remote."""
        if not self.refetch:
            self.console.print("⏭️  Skipping fetch (refetch disabled)")
            return

        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=self.console,
        ) as progress:
            task = progress.add_task(f"Fetching from {self.remote_name}...", total=None)
            try:
                remote.fetch()
                progress.update(task, description=f"✅ Fetched from {self.remote_name}")
            except GitCommandError as e:
                raise PatcherError(f"Failed to fetch from {self.remote_name}: {e}")

    def create_fresh_branch(self) -> None:
        """Create a fresh branch from upstream ref."""
        try:
            upstream_commit = self.repo.commit(
                f"{self.remote_name}/{self.upstream_ref}"
            )
        except git.BadName:
            raise PatcherError(
                f"Invalid upstream ref: {self.remote_name}/{self.upstream_ref}"
            )

        self.console.print(
            f"📍 Using upstream nixpkgs commit: {upstream_commit.hexsha}"
        )

        # Check if branch already exists and delete it
        if self.target_branch in self.repo.heads:
            self.console.print(f"🗑️  Deleting existing branch '{self.target_branch}'")
            self.repo.delete_head(self.target_branch, force=True)

        # Create fresh branch
        new_branch = self.repo.create_head(self.target_branch, upstream_commit)
        new_branch.checkout()

        self.console.print(
            f"🌿 Created fresh branch '{self.target_branch}' from {self.remote_name}/{self.upstream_ref}"
        )

    def remove_github_workflows(self) -> None:
        """Remove .github directory and commit the change."""
        github_dir = self.repo_path / ".github"

        if not github_dir.exists():
            self.console.print("ℹ️  .github directory not found, skipping removal")
            return

        self.console.print("🗂️  Removing .github directory")
        shutil.rmtree(github_dir)

        # Stage all changes and commit
        self.repo.git.add("-A")
        self.repo.index.commit("ci: remove nixpkgs workflows")

        self.console.print("✅ Committed removal of .github directory")

    def copy_patches_to_temp(self) -> Optional[Path]:
        """Copy patches to temporary directory before switching branches."""
        if not self.patch_dir.exists():
            self.console.print(f"⚠️  Patch directory '{self.patch_dir}' does not exist")
            return None

        patch_files = sorted(self.patch_dir.glob("*.patch"))
        if not patch_files:
            self.console.print(f"ℹ️  No patch files found in '{self.patch_dir}'")
            return None

        self.console.print(
            f"📋 Copying {len(patch_files)} patch files to temporary directory"
        )
        temp_dir = Path(tempfile.mkdtemp())
        temp_patch_dir = temp_dir / "patches"
        shutil.copytree(self.patch_dir, temp_patch_dir)

        return temp_patch_dir

    def apply_patches_from_temp(self, temp_patch_dir: Path) -> None:
        """Apply patches from temporary directory."""
        patch_files = sorted(temp_patch_dir.glob("*.patch"))
        self.console.print(f"🔧 Applying {len(patch_files)} patch files")

        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=self.console,
        ) as progress:
            for patch_file in patch_files:
                task = progress.add_task(f"Applying {patch_file.name}...", total=None)

                try:
                    self.repo.git.am("--reject", str(patch_file))
                    progress.update(task, description=f"✅ Applied {patch_file.name}")
                except GitCommandError as e:
                    progress.update(
                        task, description=f"❌ Failed to apply {patch_file.name}"
                    )
                    raise PatcherError(f"Failed to apply patch {patch_file}: {e}")

    def push_branch(self, force: bool = True) -> None:
        """Push the target branch to origin."""
        try:
            origin = self.repo.remote("origin")
        except ValueError:
            raise PatcherError("No 'origin' remote found")

        push_args = [self.target_branch]
        if force:
            push_args.insert(0, "--force")

        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=self.console,
        ) as progress:
            task = progress.add_task(
                f"Pushing branch '{self.target_branch}' to origin...", total=None
            )

            try:
                origin.push(*push_args)
                progress.update(
                    task, description=f"✅ Pushed '{self.target_branch}' to origin"
                )
            except GitCommandError as e:
                progress.update(
                    task, description=f"❌ Failed to push '{self.target_branch}'"
                )
                raise PatcherError(f"Failed to push branch: {e}")

    def run(self, push: bool = True) -> None:
        """Execute the complete fetch and patch workflow."""
        temp_patch_dir = None
        try:
            self.console.print(
                Panel.fit("🚀 Starting Patcher Workflow", style="bold blue")
            )

            self.configure_git()
            remote = self.setup_upstream_remote()
            self.fetch_upstream(remote)

            # Copy patches BEFORE switching branches
            temp_patch_dir = self.copy_patches_to_temp()

            self.create_fresh_branch()
            self.remove_github_workflows()

            # Apply patches from temp directory
            if temp_patch_dir:
                self.apply_patches_from_temp(temp_patch_dir)

            if push:
                self.push_branch()

            self.console.print(
                Panel.fit(
                    "✅ Patcher workflow completed successfully!", style="bold green"
                )
            )

        except PatcherError as e:
            self.console.print(Panel.fit(f"❌ Workflow failed: {e}", style="bold red"))
            sys.exit(1)
        except Exception as e:
            self.console.print(Panel.fit(f"💥 Unexpected error: {e}", style="bold red"))
            sys.exit(1)
        finally:
            # Clean up temporary directory
            if temp_patch_dir and temp_patch_dir.parent.exists():
                shutil.rmtree(temp_patch_dir.parent)


@click.command()
@click.option(
    "--upstream-ref",
    default="nixpkgs-unstable",
    help="Upstream nixpkgs ref to sync from",
    show_default=True,
)
@click.option(
    "--target-branch",
    default="bump-rolling",
    help="Target branch to create/update",
    show_default=True,
)
@click.option(
    "--remote-name",
    default="upstream",
    help="Name for the upstream remote",
    show_default=True,
)
@click.option(
    "--remote-url",
    default="https://github.com/NixOS/nixpkgs.git",
    help="URL for the upstream remote",
    show_default=True,
)
@click.option(
    "--patch-dir",
    default="patches",
    type=click.Path(exists=False, path_type=Path),
    help="Directory containing patch files",
    show_default=True,
)
@click.option("--no-refetch", is_flag=True, help="Skip fetching from upstream remote")
@click.option(
    "--git-user-name",
    default="Patcher Script",
    help="Git user name for commits",
    show_default=True,
)
@click.option(
    "--git-user-email",
    default="noreply@example.com",
    help="Git user email for commits",
    show_default=True,
)
@click.option("--no-push", is_flag=True, help="Don't push the branch to origin")
@click.option(
    "--repo-path",
    default=".",
    type=click.Path(exists=True, file_okay=False, dir_okay=True, path_type=Path),
    help="Path to git repository",
    show_default=True,
)
@click.option("-v", "--verbose", is_flag=True, help="Enable verbose logging")
def main(
    upstream_ref: str,
    target_branch: str,
    remote_name: str,
    remote_url: str,
    patch_dir: Path,
    no_refetch: bool,
    git_user_name: str,
    git_user_email: str,
    no_push: bool,
    repo_path: Path,
    verbose: bool,
) -> None:
    """Fetch upstream nixpkgs and apply patches."""

    console = Console()

    if verbose:
        logging.getLogger().setLevel(logging.DEBUG)

    # Show configuration
    config_text = Text()
    config_text.append("Configuration:\n", style="bold")
    config_text.append(f"  Repository: {repo_path.absolute()}\n")
    config_text.append(f"  Upstream ref: {upstream_ref}\n")
    config_text.append(f"  Target branch: {target_branch}\n")
    config_text.append(f"  Remote: {remote_name} ({remote_url})\n")
    config_text.append(f"  Patch directory: {patch_dir}\n")
    config_text.append(f"  Refetch: {not no_refetch}\n")
    config_text.append(f"  Push: {not no_push}\n")

    console.print(Panel(config_text, title="Patcher Configuration", style="cyan"))

    patcher = Patcher(
        repo_path=repo_path,
        upstream_ref=upstream_ref,
        target_branch=target_branch,
        remote_name=remote_name,
        remote_url=remote_url,
        patch_dir=patch_dir,
        refetch=not no_refetch,
        git_user_name=git_user_name,
        git_user_email=git_user_email,
        console=console,
    )

    patcher.run(push=not no_push)


if __name__ == "__main__":
    main()
