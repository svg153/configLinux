#!/usr/bin/env python3
"""
Team Hierarchy Viewer — queries GitHub / GHES API directly and generates
a Markdown file with tables and Mermaid diagrams of team hierarchies.

Supports:
  - Single organization (--org)
  - Entire enterprise (--enterprise) — fetches all orgs and combines output

Works with GitHub.com and GitHub Enterprise Server (GHES).
Requires: gh CLI authenticated against the target instance.
"""
import argparse
import json
import subprocess
import sys
import os
from pathlib import Path
from collections import defaultdict


def run_gh(args: list[str], gh_host: str | None = None) -> dict | list | None:
    """Run a gh CLI command and return parsed JSON."""
    env = os.environ.copy()
    if gh_host:
        env["GH_HOST"] = gh_host
    cmd = ["gh"] + args
    result = subprocess.run(cmd, capture_output=True, text=True, env=env)
    if result.returncode != 0:
        return None
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError:
        return None


def fetch_teams(gh_host: str | None, org: str) -> list[dict]:
    """Fetch all teams for an org via the REST API (paginated)."""
    data = run_gh(["api", f"orgs/{org}/teams", "--paginate"], gh_host)
    return data if isinstance(data, list) else []


def fetch_enterprise_orgs(gh_host: str | None, enterprise: str) -> list[str]:
    """Fetch all organizations belonging to an enterprise.

    Tries the enterprise management API first. If unavailable (e.g. GHES < 3.12),
    falls back to listing all user orgs.
    """
    data = run_gh(
        ["api", f"enterprises/{enterprise}/organizations", "--paginate"],
        gh_host,
    )
    if isinstance(data, list) and len(data) > 0:
        return [o["login"] for o in data]

    # Fallback: enterprise management API not available, use user orgs
    print(
        f"  Note: enterprise API not available, listing all user orgs instead",
        file=sys.stderr,
    )
    return fetch_user_orgs(gh_host)


def fetch_user_orgs(gh_host: str | None) -> list[str]:
    """Fetch all organizations the authenticated user belongs to."""
    data = run_gh(["api", "/user/orgs", "--paginate"], gh_host)
    if isinstance(data, list):
        return [o["login"] for o in data]
    return []


def build_hierarchy(teams: list[dict]) -> dict:
    """
    Build a structured hierarchy from the flat team list.

    Returns:
        {
            "roots": [team_dict, ...],
            "children": { parent_slug: [team_dict, ...], ... },
            "all": { slug: team_dict, ... },
        }
    """
    all_teams = {}
    children_map = defaultdict(list)

    for t in teams:
        slug = t["slug"]
        info = {
            "slug": slug,
            "name": t.get("name", slug),
            "description": t.get("description", ""),
            "privacy": t.get("privacy", "closed"),
            "member_count": t.get("members_count", 0),
            "parent": None,
        }
        parent = t.get("parent")
        if parent:
            info["parent"] = parent["slug"]
            children_map[parent["slug"]].append(info)
        all_teams[slug] = info

    roots = [info for info in all_teams.values() if info["parent"] is None]

    return {"roots": roots, "children": dict(children_map), "all": all_teams}


def team_url(base_url: str, org: str, slug: str) -> str:
    return f"{base_url}/{org}/teams/{slug}"


def slug_to_mermaid_id(slug: str) -> str:
    return slug.replace("-", "_").replace(".", "_").replace(" ", "_")


# ---------------------------------------------------------------------------
# Renderers
# ---------------------------------------------------------------------------

def render_summary(title: str, orgs_data: dict) -> str:
    """Render summary table across one or more orgs."""
    total_teams = sum(len(h["all"]) for h in orgs_data.values())
    total_roots = sum(len(h["roots"]) for h in orgs_data.values())
    total_nested = total_teams - total_roots
    total_members = sum(
        sum(t["member_count"] for t in h["all"].values())
        for h in orgs_data.values()
    )

    lines = [
        f"## {title} — Summary\n",
        "| Metric | Count |",
        "|--------|-------|",
        f"| Organizations | {len(orgs_data)} |",
        f"| Total teams | {total_teams} |",
        f"| Root teams | {total_roots} |",
        f"| Nested teams | {total_nested} |",
        f"| Total members | {total_members} |",
        "",
    ]
    return "\n".join(lines)


def render_org_table(org: str, hierarchy: dict, base_url: str) -> str:
    lines = [
        f"## {org} — Team Table\n",
        "| Team | Description | Privacy | Members | Parent | Link |",
        "|------|-------------|---------|---------|--------|------|",
    ]

    def team_row(info: dict, indent: str = "") -> str:
        link = f"[↗]({team_url(base_url, org, info['slug'])})"
        parent = info["parent"] or "-"
        desc = (info["description"] or "-")[:60]
        name_display = (
            f"**{info['name']}**" if not info["parent"] else f"↳ {info['name']}"
        )
        return (
            f"| {indent}{name_display} | {desc} | {info['privacy']} "
            f"| {info['member_count']} | {parent} | {link} |"
        )

    for root in sorted(hierarchy["roots"], key=lambda x: x["slug"]):
        lines.append(team_row(root))
        for child in sorted(
            hierarchy["children"].get(root["slug"], []), key=lambda x: x["slug"]
        ):
            lines.append(team_row(child, "  "))

    lines.append("")
    return "\n".join(lines)


def render_org_mermaid(org: str, hierarchy: dict, base_url: str) -> str:
    safe_org = slug_to_mermaid_id(org)
    lines = [
        f"## {org} — Hierarchy Diagram\n",
        "```mermaid",
        "graph TD",
        f"    subgraph {safe_org}[{org}]",
    ]

    clicks = []

    for root in sorted(hierarchy["roots"], key=lambda x: x["slug"]):
        rid = slug_to_mermaid_id(root["slug"])
        lines.append(f'        {rid}["{root["name"]}"]')
        clicks.append((rid, team_url(base_url, org, root["slug"])))

        for child in sorted(
            hierarchy["children"].get(root["slug"], []), key=lambda x: x["slug"]
        ):
            cid = slug_to_mermaid_id(child["slug"])
            lines.append(f'        {rid} --> {cid}["{child["name"]}"]')
            clicks.append((cid, team_url(base_url, org, child["slug"])))

    lines.append("    end")
    lines.append("")

    for node_id, url in clicks:
        lines.append(f'    click {node_id} "{url}"')

    lines.append("```")
    lines.append("")
    return "\n".join(lines)


def render_combined_mermaid(orgs_data: dict, base_url: str) -> str:
    """Render a single Mermaid diagram with subgraphs per org."""
    lines = [
        "## Enterprise — Hierarchy Diagram\n",
        "```mermaid",
        "graph TD",
    ]
    clicks = []

    for org in sorted(orgs_data.keys()):
        hierarchy = orgs_data[org]
        safe_org = slug_to_mermaid_id(org)
        lines.append(f"    subgraph {safe_org}[{org}]")

        for root in sorted(hierarchy["roots"], key=lambda x: x["slug"]):
            rid = slug_to_mermaid_id(root["slug"])
            # Prefix with org to avoid ID collisions across orgs
            prefixed_rid = f"{safe_org}_{rid}"
            lines.append(f'        {prefixed_rid}["{root["name"]}"]')
            clicks.append((prefixed_rid, team_url(base_url, org, root["slug"])))

            for child in sorted(
                hierarchy["children"].get(root["slug"], []),
                key=lambda x: x["slug"],
            ):
                cid = slug_to_mermaid_id(child["slug"])
                prefixed_cid = f"{safe_org}_{cid}"
                lines.append(
                    f'        {prefixed_rid} --> {prefixed_cid}["{child["name"]}"]'
                )
                clicks.append(
                    (prefixed_cid, team_url(base_url, org, child["slug"]))
                )

        lines.append("    end")
        lines.append("")

    for node_id, url in clicks:
        lines.append(f'    click {node_id} "{url}"')

    lines.append("```")
    lines.append("")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Generate team hierarchy Markdown from GitHub / GHES API"
    )

    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument(
        "--org",
        help="Single GitHub organization login",
    )
    mode.add_argument(
        "--enterprise",
        help="Enterprise slug — fetches all orgs in the enterprise",
    )

    parser.add_argument(
        "--ghes-url",
        default=None,
        help="GHES base URL (e.g. https://<ghes-url>). Omit for github.com",
    )
    parser.add_argument(
        "--output",
        default=None,
        help="Output file path (default: stdout)",
    )
    parser.add_argument(
        "--format",
        choices=["table", "mermaid", "both"],
        default="both",
        help="Output format (default: both)",
    )
    args = parser.parse_args()

    # Determine base URL and gh_host
    if args.ghes_url:
        base_url = args.ghes_url.rstrip("/")
        gh_host = base_url.replace("https://", "").replace("http://", "")
    else:
        base_url = "https://github.com"
        gh_host = None

    # Resolve org list
    if args.enterprise:
        print(
            f"Fetching organizations for enterprise '{args.enterprise}'...",
            file=sys.stderr,
        )
        orgs = fetch_enterprise_orgs(gh_host, args.enterprise)
        if not orgs:
            print(
                f"ERROR: No orgs found or API error for enterprise '{args.enterprise}'",
                file=sys.stderr,
            )
            sys.exit(1)
        print(f"Found {len(orgs)} organizations: {', '.join(orgs)}", file=sys.stderr)
        title = f"Enterprise {args.enterprise}"
    else:
        orgs = [args.org]
        title = args.org

    # Fetch teams for each org
    orgs_data = {}
    for org in orgs:
        print(f"  Fetching teams for '{org}'...", file=sys.stderr)
        teams = fetch_teams(gh_host, org)
        if teams:
            orgs_data[org] = build_hierarchy(teams)
            print(f"    → {len(teams)} teams", file=sys.stderr)
        else:
            print(f"    → no teams or API error, skipping", file=sys.stderr)

    if not orgs_data:
        print("ERROR: No team data fetched for any organization", file=sys.stderr)
        sys.exit(1)

    # Build output
    parts = [f"# Team Hierarchy — {title}\n"]

    if args.format in ("table", "both"):
        parts.append(render_summary(title, orgs_data))
        for org in sorted(orgs_data.keys()):
            parts.append(render_org_table(org, orgs_data[org], base_url))

    if args.format in ("mermaid", "both"):
        if len(orgs_data) == 1:
            org = list(orgs_data.keys())[0]
            parts.append(render_org_mermaid(org, orgs_data[org], base_url))
        else:
            parts.append(render_combined_mermaid(orgs_data, base_url))

    output = "\n".join(parts)

    if args.output:
        Path(args.output).write_text(output)
        print(f"Written to {args.output}", file=sys.stderr)
    else:
        print(output)


if __name__ == "__main__":
    main()
