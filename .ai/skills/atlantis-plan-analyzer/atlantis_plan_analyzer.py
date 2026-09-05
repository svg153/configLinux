#!/usr/bin/env python3
"""
Atlantis Plan Extractor & Analyzer

Extracts and merges Atlantis plan comments from GitHub PRs,
then analyzes them to identify resources to create, destroy, import, or replace.

Usage:
    python3 atlantis_plan_analyzer.py --gh-host <ghe-host> --org <ORG> --repo <repo> --pr 2
    python3 atlantis_plan_analyzer.py --plan-file /path/to/plan.txt --analyze
    python3 atlantis_plan_analyzer.py --help
"""

import argparse
import json
import os
import re
import subprocess
import sys
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Optional


@dataclass
class PlanAction:
    """Represents a single resource action in a Terraform plan."""
    action: str  # create, destroy, import, replace, update
    resource_type: str  # e.g., github_repository, module.team_repository
    resource_name: str  # e.g., arch-hld-proxmox
    full_path: str  # Full module path
    change: str = ""  # Optional change description


@dataclass
class PlanSummary:
    """Summary of a Terraform plan."""
    imports: int = 0
    creates: int = 0
    changes: int = 0
    destroys: int = 0
    replaces: int = 0
    actions: list = field(default_factory=list)
    resource_types: dict = field(default_factory=lambda: {"create": {}, "destroy": {}, "import": {}, "replace": {}})
    raw_summary: str = ""


class AtlantisPlanAnalyzer:
    """Extracts and analyzes Atlantis plan comments from GitHub PRs."""

    def __init__(self, gh_host: str, org: str, repo: str, pr: Optional[int] = None, bot_name: Optional[str] = None):
        self.gh_host = gh_host
        self.org = org
        self.repo = repo
        self.pr = pr
        self.bot_name = bot_name or os.environ.get("ATLANTIS_BOT_NAME", "atlantis[bot]")
        self.base_url = f"https://{gh_host}/{org}/{repo}"

    def run_gh_command(self, cmd: list[str]) -> str:
        """Run a gh CLI command and return output."""
        env = os.environ.copy()
        env["GH_HOST"] = self.gh_host
        result = subprocess.run(
            ["gh"] + cmd,
            capture_output=True,
            text=True,
            env=env
        )
        if result.returncode != 0:
            raise RuntimeError(f"gh command failed: {' '.join(cmd)}\n{result.stderr}")
        return result.stdout

    def extract_plan_from_pr(self, days_back: int = 1) -> str:
        """
        Extract Atlantis plan comments from a PR.

        Automatically identifies the latest plan by finding comments from the
        Atlantis bot user within the specified time window, then merges them into a single plan.

        Returns the merged plan text.
        """
        if not self.pr:
            # Find latest PR with Atlantis comments
            self.pr = self._find_latest_pr_with_plan(days_back)

        if not self.pr:
            raise RuntimeError(f"No PR with Atlantis plan found in {self.org}/{self.repo}")

        print(f"Extracting plan from {self.base_url}/pull/{self.pr}")

        # Get all Atlantis bot comments from the PR
        now = datetime.now()
        cutoff = now.replace(hour=0, minute=0, second=0, microsecond=0)

        # Fetch comments with pagination
        comments = self._fetch_pr_comments(self.pr)

        # Filter for Atlantis bot comments
        atlantis_comments = [
            c for c in comments
            if c.get("user", {}).get("login") == self.bot_name
            and c.get("created_at", "") >= cutoff.isoformat()
        ]

        if not atlantis_comments:
            raise RuntimeError(f"No Atlantis bot comments found for PR #{self.pr}")

        # Extract and merge
        output_dir = Path("atlantis-plan-extraction")
        output_dir.mkdir(exist_ok=True)

        complete_file = output_dir / "atlantis-plan-complete.txt"
        summary_file = output_dir / "atlantis-plan-summary.txt"

        with open(complete_file, "w") as f:
            f.write(f"=== Atlantis Plan from {self.base_url}/pull/{self.pr} ===\n")
            f.write(f"Extracted: {datetime.now().isoformat()} ===\n\n")

            for comment in atlantis_comments:
                comment_id = comment["id"]
                body = comment.get("body", "")
                f.write(f"--- Comment {comment_id} ({len(body)} chars) ---\n")
                f.write(body + "\n\n")

            f.write("=== End of extracted plan ===\n")

        print(f"✓ Plan extracted to {complete_file} ({complete_file.stat().st_size / 1024:.0f} KB)")

        # Generate summary
        summary = self.analyze_plan_file(str(complete_file))
        summary.write_summary(str(summary_file))

        print(f"✓ Summary written to {summary_file}")
        return complete_file.read_text()

    def _find_latest_pr_with_plan(self, days_back: int = 1) -> Optional[int]:
        """Find the most recent PR with Atlantis plan comments."""
        # List open PRs
        prs_json = self.run_gh_command([
            "pr", "list", "--state", "open",
            "--json", "number,title,createdAt",
            "--limit", "20"
        ])
        prs = json.loads(prs_json)

        now = datetime.now()
        cutoff = now.replace(hour=0, minute=0, second=0, microsecond=0)

        for pr in prs:
            pr_number = pr["number"]
            created = pr["createdAt"]

            # Check if PR has Atlantis comments
            comments_json = self.run_gh_command([
                "api", f"repos/{self.org}/{self.repo}/issues/{pr_number}/comments"
            ])
            comments = json.loads(comments_json)

            for comment in comments:
                if (comment.get("user", {}).get("login") == self.bot_name
                        and comment.get("created_at", "") >= cutoff.isoformat()):
                    return pr_number

        return None

    def _fetch_pr_comments(self, pr_number: int) -> list:
        """Fetch all comments for a PR with pagination."""
        comments = []
        page = 1

        while True:
            result = self.run_gh_command([
                "api",
                f"repos/{self.org}/{self.repo}/issues/{pr_number}/comments",
                f"--jq=.[],",
                f"--per_page=100"
            ])

            if not result.strip():
                break

            try:
                page_comments = json.loads(f"[{result}]")
                comments.extend(page_comments)

                if len(page_comments) < 100:
                    break
                page += 1
            except json.JSONDecodeError:
                break

        return comments

    def analyze_plan_file(self, plan_file: str) -> PlanSummary:
        """Analyze a Terraform plan file and return a summary."""
        with open(plan_file, "r") as f:
            content = f.read()

        summary = PlanSummary()

        # Extract plan summary line
        for line in content.split("\n"):
            if line.strip().startswith("Plan:"):
                summary.raw_summary = line.strip()

        # Count actions
        summary.imports = content.count("will be imported")
        summary.creates = content.count("will be created")
        summary.changes = content.count("will be updated")
        summary.destroys = content.count("will be destroyed")
        summary.replaces = content.count("must be replaced")

        # Extract resource types
        for action_type in ["create", "destroy", "import", "replace"]:
            pattern = f"will be {action_type.replace('replace', 'replaced')}" if action_type != "import" else f"will be {action_type}"
            lines = [l for l in content.split("\n") if pattern in l]

            for line in lines:
                # Extract resource path
                match = re.search(r'#\s+(module\.[^\s]+)', line)
                if match:
                    resource_path = match.group(1)
                    # Simplify to top-level module
                    top_module = resource_path.split('["')[0].split("[0]")[0]
                    summary.resource_types[action_type][top_module] = \
                        summary.resource_types[action_type].get(top_module, 0) + 1

        return summary

    def get_quick_stats(self, plan_file: str) -> dict:
        """Get quick statistics from a plan file."""
        with open(plan_file, "r") as f:
            content = f.read()

        return {
            "imports": content.count("will be imported"),
            "creates": content.count("will be created"),
            "changes": content.count("will be updated"),
            "destroys": content.count("will be destroyed"),
            "replaces": content.count("must be replaced"),
        }

    def print_summary(self, summary: PlanSummary):
        """Print a formatted summary of the plan."""
        print("\n" + "=" * 60)
        print("ATLANTIS PLAN SUMMARY")
        print("=" * 60)

        if summary.raw_summary:
            print(f"\n📋 Plan: {summary.raw_summary}")
        else:
            print(f"\n📋 Plan: {summary.imports} imports, {summary.creates} creates, "
                  f"{summary.changes} changes, {summary.destroys} destroys, "
                  f"{summary.replaces} replaces")

        print(f"\n📊 Actions:")
        print(f"  ⚡ Imports:  {summary.imports}")
        print(f"  ➕ Creates:  {summary.creates}")
        print(f"  ✏️  Changes:  {summary.changes}")
        print(f"  🗑️  Destroys: {summary.destroys}")
        print(f"  🔄 Replaces: {summary.replaces}")

        print(f"\n📦 Resource Types - Creates:")
        for resource_type, count in sorted(summary.resource_types["create"].items(),
                                            key=lambda x: x[1], reverse=True)[:10]:
            print(f"  {count:4d} {resource_type}")

        print(f"\n📦 Resource Types - Destroys:")
        for resource_type, count in sorted(summary.resource_types["destroy"].items(),
                                            key=lambda x: x[1], reverse=True)[:10]:
            print(f"  {count:4d} {resource_type}")

        print("\n" + "=" * 60)

    def save_summary(self, summary: PlanSummary, output_file: str = "atlantis-plan-extraction/PLAN-ANALYSIS.md"):
        """Save a detailed analysis to a markdown file."""
        output_path = Path(output_file)
        output_path.parent.mkdir(exist_ok=True)

        with open(output_path, "w") as f:
            f.write(f"# Atlantis Plan Analysis - {datetime.now().strftime('%Y-%m-%d')}\n\n")
            f.write(f"## Summary\n\n")
            f.write(f"**Plan:** {summary.raw_summary or f'{summary.imports} imports, {summary.creates} creates, {summary.changes} changes, {summary.destroys} destroys, {summary.replaces} replaces'}\n\n")

            f.write(f"## Actions Breakdown\n\n")
            f.write(f"| Action | Count | Description |\n")
            f.write(f"|--------|-------|-------------|\n")
            f.write(f"| Import | {summary.imports} | Resources to import into state |\n")
            f.write(f"| Add | {summary.creates} | Resources to create |\n")
            f.write(f"| Change | {summary.changes} | Resources to update |\n")
            f.write(f"| Destroy | {summary.destroys} | Resources to destroy |\n")
            f.write(f"| Replace | {summary.replaces} | Resources to recreate |\n\n")

            f.write(f"## Resource Types - Creates ({summary.creates})\n\n")
            for resource_type, count in sorted(summary.resource_types["create"].items(),
                                                key=lambda x: x[1], reverse=True):
                f.write(f"- **{count}** `{resource_type}`\n")

            f.write(f"\n## Resource Types - Destroys ({summary.destroys})\n\n")
            for resource_type, count in sorted(summary.resource_types["destroy"].items(),
                                                key=lambda x: x[1], reverse=True):
                f.write(f"- **{count}** `{resource_type}`\n")


def main():
    parser = argparse.ArgumentParser(
        description="Atlantis Plan Extractor & Analyzer",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Extract plan from PR #2 on GHES
  python3 atlantis_plan_analyzer.py --gh-host <ghe-host> --org <ORG> --repo <repo> --pr 2

  # Analyze an existing plan file
  python3 atlantis_plan_analyzer.py --plan-file atlantis-plan-extraction/atlantis-plan-complete.txt --analyze

  # Find latest plan and analyze
  python3 atlantis_plan_analyzer.py --gh-host <ghe-host> --org <ORG> --repo <repo>

  # Compare with local plan
  python3 atlantis_plan_analyzer.py --plan-file atlantis-plan-extraction/atlantis-plan-complete.txt --compare apps/github-as-code/.terraform-logs/arch-local-plan-20260608_105140.log
        """
    )

    # GitHub/Atlantis options
    parser.add_argument("--gh-host", help="GitHub host (e.g., github.example.com; defaults to the repo remote)")
    parser.add_argument("--org", help="GitHub organization")
    parser.add_argument("--repo", help="GitHub repository")
    parser.add_argument("--pr", type=int, help="PR number (optional, auto-detects if not provided)")
    parser.add_argument("--bot-name", help="Atlantis bot user login (default from $ATLANTIS_BOT_NAME)")

    # File options
    parser.add_argument("--plan-file", help="Path to existing plan file to analyze")
    parser.add_argument("--analyze", action="store_true", help="Analyze the plan file")
    parser.add_argument("--compare", help="Compare with another plan file")
    parser.add_argument("--output", help="Output file for analysis (default: atlantis-plan-extraction/PLAN-ANALYSIS.md)")

    args = parser.parse_args()

    analyzer = None

    # If plan file is provided, analyze it directly
    if args.plan_file:
        if not os.path.exists(args.plan_file):
            print(f"Error: Plan file not found: {args.plan_file}")
            sys.exit(1)

        analyzer = AtlantisPlanAnalyzer("", "", "")
        summary = analyzer.analyze_plan_file(args.plan_file)
        analyzer.print_summary(summary)

        if args.compare:
            if not os.path.exists(args.compare):
                print(f"Error: Comparison file not found: {args.compare}")
                sys.exit(1)

            local_summary = analyzer.analyze_plan_file(args.compare)
            print("\n" + "=" * 60)
            print("COMPARISON: Remote vs Local Plan")
            print("=" * 60)
            print(f"\nRemote Plan: {summary.raw_summary or f'{summary.imports} imports, {summary.creates} creates, {summary.changes} changes, {summary.destroys} destroys, {summary.replaces} replaces'}")
            print(f"Local Plan:  {local_summary.raw_summary or f'{local_summary.imports} imports, {local_summary.creates} creates, {local_summary.changes} changes, {local_summary.destroys} destroys, {local_summary.replaces} replaces'}")

            if (summary.imports == local_summary.imports and
                summary.creates == local_summary.creates and
                summary.changes == local_summary.changes and
                summary.destroys == local_summary.destroys and
                summary.replaces == local_summary.replaces):
                print("\n✅ PLANOS IDÉNTICOS - No hay diferencias")
            else:
                print("\n⚠️ DIFERENCIAS DETECTADAS:")
                if summary.imports != local_summary.imports:
                    print(f"  - Imports: Remote={summary.imports}, Local={local_summary.imports}")
                if summary.creates != local_summary.creates:
                    print(f"  - Creates: Remote={summary.creates}, Local={local_summary.creates}")
                if summary.changes != local_summary.changes:
                    print(f"  - Changes: Remote={summary.changes}, Local={local_summary.changes}")
                if summary.destroys != local_summary.destroys:
                    print(f"  - Destroys: Remote={summary.destroys}, Local={local_summary.destroys}")
                if summary.replaces != local_summary.replaces:
                    print(f"  - Replaces: Remote={summary.replaces}, Local={local_summary.replaces}")
            print("=" * 60)

        if args.analyze or args.output:
            output_file = args.output or "atlantis-plan-extraction/PLAN-ANALYSIS.md"
            analyzer.save_summary(summary, output_file)
            print(f"\n✓ Analysis saved to {output_file}")

        return

    # If GitHub options are provided, extract from PR
    if args.gh_host and args.org and args.repo:
        analyzer = AtlantisPlanAnalyzer(args.gh_host, args.org, args.repo, args.pr, args.bot_name)

        try:
            plan_file = analyzer.extract_plan_from_pr()
            summary = analyzer.analyze_plan_file(plan_file)
            analyzer.print_summary(summary)

            if args.analyze:
                output_file = args.output or "atlantis-plan-extraction/PLAN-ANALYSIS.md"
                analyzer.save_summary(summary, output_file)
                print(f"\n✓ Analysis saved to {output_file}")

        except RuntimeError as e:
            print(f"Error: {e}")
            sys.exit(1)
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
