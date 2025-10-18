#!/usr/bin/env python3
"""
Script to update README.md with test results from GitHub Actions workflow runs.
Replaces the functionality of the bash script in .github/workflows/update-test-summary.yml
"""

import os
import re
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import click
from github import Github
from rich.console import Console
from rich.logging import RichHandler
from rich.panel import Panel
from rich.progress import Progress, SpinnerColumn, TextColumn
from rich.text import Text
import logging


class TestResultsError(Exception):
    """Custom exception for test results updater errors."""
    pass


class TestResultsUpdater:
    def __init__(
        self,
        github_token: str,
        repo_name: str,
        readme_path: Path = Path("README.md"),
        template_path: Path = Path(".github/templates/test-results.md"),
        console: Optional[Console] = None,
    ):
        self.github = Github(github_token)
        self.repo_name = repo_name
        self.readme_path = readme_path
        self.template_path = template_path
        self.console = console or Console()

        # Set up logging with rich
        logging.basicConfig(
            level=logging.INFO,
            format="%(message)s",
            datefmt="[%X]",
            handlers=[RichHandler(console=self.console, rich_tracebacks=True)],
        )
        self.logger = logging.getLogger(__name__)

        try:
            self.repo = self.github.get_repo(repo_name)
        except Exception as e:
            raise TestResultsError(f"Failed to access repository {repo_name}: {e}")

    def get_nixpkgs_commit(self) -> Tuple[str, str]:
        """Get nixpkgs commit hash from bump-rolling branch."""
        try:
            ref = self.repo.get_git_ref("heads/bump-rolling")
            commit_sha = ref.object.sha
            return commit_sha, commit_sha[:7]
        except Exception as e:
            raise TestResultsError(f"Failed to get nixpkgs commit from bump-rolling: {e}")

    def get_workflow_jobs(self, run_id: str) -> List[Dict]:
        """Get jobs from a workflow run."""
        try:
            run = self.repo.get_workflow_run(int(run_id))
            jobs = []
            for job in run.jobs():
                jobs.append({
                    'name': job.name,
                    'conclusion': job.conclusion,
                    'status': job.status
                })
            return jobs
        except Exception as e:
            raise TestResultsError(f"Failed to get jobs for run {run_id}: {e}")

    def analyze_jobs(self, jobs: List[Dict]) -> Dict[str, int]:
        """Analyze job results and calculate platform-specific statistics."""
        stats = {
            'total_jobs': len(jobs),
            'successful_jobs': 0,
            'failed_jobs': 0,
            'linux_arm64_total': 0,
            'linux_arm64_failed': 0,
            'linux_x64_total': 0,
            'linux_x64_failed': 0,
            'macos_arm64_total': 0,
            'macos_arm64_failed': 0,
            'macos_x64_total': 0,
            'macos_x64_failed': 0,
        }

        for job in jobs:
            name = job['name']
            conclusion = job['conclusion']

            # Overall stats
            if conclusion == 'success':
                stats['successful_jobs'] += 1
            elif conclusion == 'failure':
                stats['failed_jobs'] += 1

            # Platform-specific stats (only for test jobs)
            if 'run-tests /' in name:
                # Linux ARM64
                if 'linux' in name and 'ARM64' in name:
                    stats['linux_arm64_total'] += 1
                    if conclusion == 'failure':
                        stats['linux_arm64_failed'] += 1

                # Linux X64
                elif 'linux' in name and 'X64' in name:
                    stats['linux_x64_total'] += 1
                    if conclusion == 'failure':
                        stats['linux_x64_failed'] += 1

                # macOS ARM64
                elif 'macOS' in name and 'ARM64' in name:
                    stats['macos_arm64_total'] += 1
                    if conclusion == 'failure':
                        stats['macos_arm64_failed'] += 1

                # macOS X64 (macos-15-intel)
                elif 'macos-15-intel' in name:
                    stats['macos_x64_total'] += 1
                    if conclusion == 'failure':
                        stats['macos_x64_failed'] += 1

        return stats

    def calculate_success_rates(self, stats: Dict[str, int]) -> Dict[str, str]:
        """Calculate success rates for each platform."""
        rates = {}

        platforms = [
            ('linux_arm64', 'linux_arm64_total', 'linux_arm64_failed'),
            ('linux_x64', 'linux_x64_total', 'linux_x64_failed'),
            ('macos_arm64', 'macos_arm64_total', 'macos_arm64_failed'),
            ('macos_x64', 'macos_x64_total', 'macos_x64_failed'),
        ]

        for platform, total_key, failed_key in platforms:
            total = stats[total_key]
            failed = stats[failed_key]

            if total > 0:
                success_rate = ((total - failed) * 1000) // total
                rates[f'{platform}_success_rate'] = f"{success_rate // 10}.{success_rate % 10}"
            else:
                rates[f'{platform}_success_rate'] = "0.0"

        return rates

    def generate_test_results_content(
        self,
        run_id: str,
        run_url: str,
        stats: Dict[str, int],
        rates: Dict[str, str],
        nixpkgs_commit: str,
        nixpkgs_short: str
    ) -> str:
        """Generate test results content from template."""
        if not self.template_path.exists():
            raise TestResultsError(f"Template file not found: {self.template_path}")

        template_content = self.template_path.read_text()

        # Determine overall status
        if stats['failed_jobs'] == 0:
            status = "✅ All tests passing"
        else:
            status = "❌ Some tests failing"

        # Calculate overall success rate
        if stats['total_jobs'] > 0:
            success_rate = (stats['successful_jobs'] * 100) // stats['total_jobs']
        else:
            success_rate = 0

        # Get current timestamp
        timestamp = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC")

        # Create platform count strings
        linux_arm64_count = f"{stats['linux_arm64_failed']}/{stats['linux_arm64_total']}"
        linux_x64_count = f"{stats['linux_x64_failed']}/{stats['linux_x64_total']}"
        macos_arm64_count = f"{stats['macos_arm64_failed']}/{stats['macos_arm64_total']}"
        macos_x64_count = f"{stats['macos_x64_failed']}/{stats['macos_x64_total']}"

        # Replace template variables
        replacements = {
            '{{STATUS}}': status,
            '{{NIXPKGS_COMMIT}}': nixpkgs_commit,
            '{{NIXPKGS_SHORT}}': nixpkgs_short,
            '{{RUN_URL}}': run_url,
            '{{TIMESTAMP}}': timestamp,
            '{{TOTAL_JOBS}}': str(stats['total_jobs']),
            '{{SUCCESSFUL_JOBS}}': str(stats['successful_jobs']),
            '{{FAILED_JOBS}}': str(stats['failed_jobs']),
            '{{SUCCESS_RATE}}': str(success_rate),
            '{{LINUX_ARM64_COUNT}}': linux_arm64_count,
            '{{LINUX_X64_COUNT}}': linux_x64_count,
            '{{MACOS_ARM64_COUNT}}': macos_arm64_count,
            '{{MACOS_X64_COUNT}}': macos_x64_count,
            '{{LINUX_ARM64_SUCCESS_RATE}}': rates['linux_arm64_success_rate'],
            '{{LINUX_X64_SUCCESS_RATE}}': rates['linux_x64_success_rate'],
            '{{MACOS_ARM64_SUCCESS_RATE}}': rates['macos_arm64_success_rate'],
            '{{MACOS_X64_SUCCESS_RATE}}': rates['macos_x64_success_rate'],
        }

        content = template_content
        for placeholder, value in replacements.items():
            content = content.replace(placeholder, value)

        return content

    def update_readme(self, test_results_content: str) -> None:
        """Update README.md with new test results."""
        if not self.readme_path.exists():
            raise TestResultsError(f"README file not found: {self.readme_path}")

        readme_content = self.readme_path.read_text()

        # Find and replace the test results section
        pattern = r'<!-- TEST_RESULTS_START -->.*?<!-- TEST_RESULTS_END -->'
        replacement = test_results_content.strip()

        if not re.search(pattern, readme_content, re.DOTALL):
            raise TestResultsError("Test results section markers not found in README")

        updated_content = re.sub(pattern, replacement, readme_content, flags=re.DOTALL)
        self.readme_path.write_text(updated_content)

        self.console.print("✅ Updated README.md with new test results")

    def run(self, run_id: str, run_url: Optional[str] = None) -> None:
        """Execute the complete test results update workflow."""
        try:
            self.console.print(
                Panel.fit("🚀 Starting Test Results Update", style="bold blue")
            )

            # Get nixpkgs commit info
            with Progress(
                SpinnerColumn(),
                TextColumn("[progress.description]{task.description}"),
                console=self.console,
            ) as progress:
                task = progress.add_task("Getting nixpkgs commit info...", total=None)
                nixpkgs_commit, nixpkgs_short = self.get_nixpkgs_commit()
                progress.update(task, description=f"✅ Got nixpkgs commit {nixpkgs_short}")

            # Get workflow jobs
            with Progress(
                SpinnerColumn(),
                TextColumn("[progress.description]{task.description}"),
                console=self.console,
            ) as progress:
                task = progress.add_task(f"Fetching jobs for run {run_id}...", total=None)
                jobs = self.get_workflow_jobs(run_id)
                progress.update(task, description=f"✅ Fetched {len(jobs)} jobs")

            # Analyze results
            stats = self.analyze_jobs(jobs)
            rates = self.calculate_success_rates(stats)

            # Generate run URL if not provided
            if not run_url:
                run_url = f"https://github.com/{self.repo_name}/actions/runs/{run_id}"

            # Generate test results content
            test_results_content = self.generate_test_results_content(
                run_id, run_url, stats, rates, nixpkgs_commit, nixpkgs_short
            )

            # Update README
            self.update_readme(test_results_content)

            # Show summary
            summary_text = Text()
            summary_text.append("Update Summary:\n", style="bold")
            summary_text.append(f"  Run ID: {run_id}\n")
            summary_text.append(f"  Total jobs: {stats['total_jobs']}\n")
            summary_text.append(f"  Successful: {stats['successful_jobs']} ✅\n")
            summary_text.append(f"  Failed: {stats['failed_jobs']} ❌\n")
            summary_text.append(f"  Nixpkgs: {nixpkgs_short}\n")

            self.console.print(Panel(summary_text, title="Results", style="green"))

            self.console.print(
                Panel.fit("✅ Test results update completed successfully!", style="bold green")
            )

        except TestResultsError as e:
            self.console.print(Panel.fit(f"❌ Update failed: {e}", style="bold red"))
            sys.exit(1)
        except Exception as e:
            self.console.print(Panel.fit(f"💥 Unexpected error: {e}", style="bold red"))
            sys.exit(1)


@click.command()
@click.option(
    "--run-id",
    required=True,
    help="GitHub Actions workflow run ID to process",
)
@click.option(
    "--run-url",
    help="Custom URL for the workflow run (optional)",
)
@click.option(
    "--repo",
    default="cachix/devenv-nixpkgs",
    help="GitHub repository (owner/name)",
    show_default=True,
)
@click.option(
    "--readme-path",
    default="README.md",
    type=click.Path(path_type=Path),
    help="Path to README.md file",
    show_default=True,
)
@click.option(
    "--template-path",
    default=".github/templates/test-results.md",
    type=click.Path(path_type=Path),
    help="Path to test results template",
    show_default=True,
)
@click.option("-v", "--verbose", is_flag=True, help="Enable verbose logging")
def main(
    run_id: str,
    run_url: Optional[str],
    repo: str,
    readme_path: Path,
    template_path: Path,
    verbose: bool,
) -> None:
    """Update README.md with test results from a GitHub Actions workflow run."""

    console = Console()

    if verbose:
        logging.getLogger().setLevel(logging.DEBUG)

    # Get GitHub token from environment
    github_token = os.getenv("GH_TOKEN") or os.getenv("GITHUB_TOKEN")
    if not github_token:
        console.print("❌ GitHub token not found. Set GH_TOKEN or GITHUB_TOKEN environment variable.", style="bold red")
        sys.exit(1)

    # Show configuration
    config_text = Text()
    config_text.append("Configuration:\n", style="bold")
    config_text.append(f"  Repository: {repo}\n")
    config_text.append(f"  Run ID: {run_id}\n")
    config_text.append(f"  Run URL: {run_url or 'auto-generated'}\n")
    config_text.append(f"  README path: {readme_path}\n")
    config_text.append(f"  Template path: {template_path}\n")

    console.print(Panel(config_text, title="Test Results Updater Configuration", style="cyan"))

    updater = TestResultsUpdater(
        github_token=github_token,
        repo_name=repo,
        readme_path=readme_path,
        template_path=template_path,
        console=console,
    )

    updater.run(run_id, run_url)


if __name__ == "__main__":
    main()