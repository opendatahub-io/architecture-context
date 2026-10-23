#!/usr/bin/env python3
"""Deterministically build a component map from platforms.yaml include_components.

Phase-2 equivalent for platforms that declare their component set
explicitly (e.g., 'breadboard'): no operator manifests to parse and no
agent-driven breadcrumb discovery. The component set is known ahead of
time, so the map is built from config + local checkouts only.

Also emits a workflow input file (components.json) consumed by the pi
workflow plugin port (breadboard/var/demos/workflow-engine-poc):
a list of {key, repoDir, promptContext} work items.
"""

import argparse
import json
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO_ROOT))

from lib.component_discovery import write_component_map  # noqa: E402
from lib.fetch import load_platform_config  # noqa: E402
from lib.manifest_parser import ComponentInfo  # noqa: E402


def git_output(repo_dir: Path, *args: str) -> str | None:
    """Run git in a checkout, return stripped stdout or None on failure."""
    try:
        result = subprocess.run(
            ["git", *args],
            cwd=repo_dir,
            capture_output=True,
            text=True,
            timeout=10,
        )
        if result.returncode == 0:
            return result.stdout.strip() or None
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
        pass
    return None


def resolve_checkout(
    checkouts_dir: Path, org: str, repo_name: str, suffix: str | None
) -> Path | None:
    """Find a component checkout following the pipeline's directory layout."""
    org_dir = f"{org}.{suffix}" if suffix else org
    for candidate in [
        checkouts_dir / org_dir / repo_name,
        checkouts_dir / org / repo_name,
    ]:
        if candidate.exists():
            return candidate
    return None


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Build component map + workflow input from platforms.yaml"
    )
    parser.add_argument(
        "--platform", required=True,
        help="Platform identifier from platforms.yaml (e.g., 'breadboard')",
    )
    parser.add_argument(
        "--checkouts-dir", default="checkouts",
        help="Base checkouts directory (default: checkouts)",
    )
    parser.add_argument(
        "--architecture-dir", default="architecture",
        help="Output directory for component-map.json (default: architecture)",
    )
    parser.add_argument(
        "--workflow-input", action="store_true",
        help="Also write architecture/<platform>/components.json"
        " (work items for the pi workflow plugin)",
    )
    parser.add_argument(
        "--config-path", default="platforms.yaml",
        help="Path to platforms.yaml",
    )
    args = parser.parse_args()

    config = load_platform_config(args.platform, args.config_path)
    suffix = config.get("suffix")
    includes = config.get("include_components", [])
    if not includes:
        sys.exit(
            f"Platform '{args.platform}' declares no include_components;"
            " this script only handles explicit component sets"
        )

    checkouts_dir = Path(args.checkouts_dir).resolve()
    if args.workflow_input:
        # Work items carry repo-root-relative repoDir paths (the workflow
        # resolves them against its cwd); an external checkouts dir cannot
        # produce those — reject before writing anything.
        try:
            checkouts_dir.relative_to(REPO_ROOT)
        except ValueError:
            sys.exit(
                f"--checkouts-dir must live under the repo root for "
                f"--workflow-input (got {checkouts_dir}, repo root "
                f"{REPO_ROOT})"
            )
    components: dict[str, ComponentInfo] = {}
    missing: list[str] = []

    for entry in includes:
        key = entry["key"]
        org = entry["repo_org"]
        repo_name = entry.get("repo_name", key)
        checkout = resolve_checkout(checkouts_dir, org, repo_name, suffix)
        if checkout is None:
            missing.append(f"{org}/{repo_name}")
            continue

        ref = git_output(checkout, "rev-parse", "HEAD")
        if ref is None:
            sys.exit(
                f"Component '{key}' checkout has no resolvable HEAD "
                f"({checkout}) — not a valid git checkout; refusing to "
                "pin None as the component ref"
            )
        branch = git_output(checkout, "rev-parse", "--abbrev-ref", "HEAD")
        components[key] = ComponentInfo(
            key=key,
            repo_org=org,
            repo_name=repo_name,
            ref=ref,
            source_folder=".",
            has_architecture=(checkout / "GENERATED_ARCHITECTURE.md").exists(),
            checkout_path=checkout,
            repo_url=f"https://github.com/{org}/{repo_name}",
            checkout_branch=branch,
            tier="payload_component",
            type=entry.get("type"),
            discovered_via="platforms_yaml_include",
            referenced_by=[],
            shipped=True,
            architecturally_significant=True,
            confidence="high",
        )

    if missing:
        sys.exit(
            "Missing checkouts: " + ", ".join(missing)
            + " — run `main.py fetch --platform " + args.platform + "` first"
        )

    org_dirs = sorted({
        f"{c.repo_org}.{suffix}" if suffix else c.repo_org
        for c in components.values()
    })
    metadata = {
        "platform": args.platform,
        "discovery_method": "static_platforms_yaml",
        "entry_point": None,
        "checkouts_dirs": [str(checkouts_dir / d) for d in org_dirs],
        "total_repos_scanned": len(includes),
        "components_discovered": len(components),
        "components_excluded": 0,
    }

    map_file = write_component_map(
        args.platform, components, metadata, args.architecture_dir
    )
    print(f"Wrote {map_file} ({len(components)} components)")

    if args.workflow_input:
        work_items = []
        for entry in includes:
            comp = components[entry["key"]]
            repo_dir = comp.checkout_path.relative_to(REPO_ROOT)
            # Analyzer baseline (phase 2c output) consumed by the generate
            # stage — the skill's ground-truth facts. Emitted only when the
            # host-side analyze phase has produced it.
            analyzer_dir = (
                Path(args.architecture_dir) / args.platform / comp.key / ".analyzer"
            )
            # Recent commits for the doc linter's required "Recent
            # Changes" section — captured at P0 so the renderer emits a
            # deterministic, pinned-to-ref history.
            recent = git_output(
                comp.checkout_path, "log", "--oneline", "-n", "5", f"{comp.ref}"
            )
            item = {
                "key": comp.key,
                "repoDir": str(repo_dir),
                "promptContext": {
                    "repo_url": comp.repo_url,
                    "ref": comp.ref,
                    "checkout_branch": comp.checkout_branch,
                    "type": comp.type,
                    "recent_changes": recent.splitlines() if recent else [],
                },
            }
            if analyzer_dir.is_dir():
                item["analyzerDir"] = str(analyzer_dir)
            work_items.append(item)
        wf_path = Path(args.architecture_dir) / args.platform / "components.json"
        wf_path.parent.mkdir(parents=True, exist_ok=True)
        wf_path.write_text(json.dumps(work_items, indent=2) + "\n")
        print(f"Wrote {wf_path} ({len(work_items)} work items)")


if __name__ == "__main__":
    main()
