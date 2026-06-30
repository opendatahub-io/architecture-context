#!/usr/bin/env python3
"""Parse upstream-source-map.yaml and produce structured sync config JSON.

Usage:
    python parse_sync_config.py <upstream-source-map.yaml>

Output: JSON with sync rules and a repo_index for fast org/repo lookups.
"""

import json
import re
import sys
from pathlib import Path

import yaml

GITHUB_URL_RE = re.compile(
    r"https://github\.com/([^/\s\"']+)/([^/\s\"'#\]\)>]+)"
)


def _parse_github_url(url):
    """Extract (org, repo) from a GitHub URL."""
    m = GITHUB_URL_RE.search(url)
    if not m:
        return None, None
    org = m.group(1)
    repo = m.group(2).removesuffix(".git").rstrip("/")
    return org, repo


def _classify_mechanism(entry):
    """Determine sync mechanism from entry fields."""
    automerge = entry.get("automerge", "no").lower()
    manual = entry.get("manual-sync", "no").lower()
    if automerge == "yes":
        return "auto_merge"
    if manual == "yes":
        return "manual"
    return "manual"


def parse_upstream_source_map(path):
    """Parse upstream-source-map.yaml and return structured data."""
    data = yaml.safe_load(Path(path).read_text())
    entries = data.get("git", [])

    sync_rules = []
    repo_index = {}

    for entry in entries:
        src_url = entry.get("src", {}).get("url", "")
        src_branch = entry.get("src", {}).get("branch", "")
        dest_url = entry.get("dest", {}).get("url", "")
        dest_branch = entry.get("dest", {}).get("branch", "main")

        src_org, src_repo = _parse_github_url(src_url)
        dest_org, dest_repo = _parse_github_url(dest_url)

        if not src_org or not dest_org:
            continue

        mechanism = _classify_mechanism(entry)

        ignore_raw = entry.get("ignore-files", "")
        ignore_files = [
            f.strip() for f in ignore_raw.split(",") if f.strip()
        ] if ignore_raw else []

        rule = {
            "name": entry.get("name", ""),
            "automerge": entry.get("automerge", "no").lower() == "yes",
            "manual_sync": entry.get("manual-sync", "no").lower() == "yes",
            "sync_mechanism": mechanism,
            "ignore_files": ignore_files,
            "src_org": src_org,
            "src_repo": src_repo,
            "src_branch": src_branch,
            "dest_org": dest_org,
            "dest_repo": dest_repo,
            "dest_branch": dest_branch,
        }
        sync_rules.append(rule)

        src_key = f"{src_org}/{src_repo}"
        dest_key = f"{dest_org}/{dest_repo}"

        if src_key not in repo_index:
            repo_index[src_key] = {
                "downstream": [],
                "upstream": None,
                "sync_mechanism": None,
                "sync_branch": None,
            }
        if dest_key not in repo_index[src_key]["downstream"]:
            repo_index[src_key]["downstream"].append(dest_key)
        repo_index[src_key]["sync_mechanism"] = mechanism
        repo_index[src_key]["sync_branch"] = src_branch

        if dest_key not in repo_index:
            repo_index[dest_key] = {
                "downstream": [],
                "upstream": None,
                "sync_mechanism": None,
                "sync_branch": None,
            }
        repo_index[dest_key]["upstream"] = src_key
        repo_index[dest_key]["sync_mechanism"] = mechanism
        repo_index[dest_key]["sync_branch"] = src_branch

    auto_count = sum(1 for r in sync_rules if r["automerge"])
    manual_count = sum(1 for r in sync_rules if not r["automerge"])

    return {
        "metadata": {
            "source_file": str(path),
            "total_sync_rules": len(sync_rules),
            "auto_merge_count": auto_count,
            "manual_sync_count": manual_count,
        },
        "sync_rules": sync_rules,
        "repo_index": repo_index,
    }


def main():
    if len(sys.argv) != 2:
        print(
            f"Usage: {sys.argv[0]} <upstream-source-map.yaml>",
            file=sys.stderr,
        )
        sys.exit(1)

    path = sys.argv[1]
    if not Path(path).exists():
        print(f"File not found: {path}", file=sys.stderr)
        sys.exit(1)

    result = parse_upstream_source_map(path)
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
