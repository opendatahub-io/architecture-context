#!/usr/bin/env python3
"""Map upstream/midstream/downstream relationships for checkout repos.

Usage:
    python parse_repo_provenance.py <checkouts_dir> [<checkouts_dir2> ...]

Queries the GitHub API (requires GITHUB_TOKEN) for fork metadata, scans
for sync workflows, and detects cross-org downstream links when multiple
checkouts directories are provided.

Output: JSON with per-repo provenance info (upstream, downstream, sync).
"""

import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

GITHUB_URL_RE = re.compile(
    r"https://github\.com/([^/\s\"']+)/([^/\s\"'#\]\)>]+)"
)

SYNC_WORKFLOW_PATTERNS = {"sync", "rebase", "upstream"}

SKIP_ORGS = {"actions", "docker", "golang", "google", "kubernetes"}

# Org hierarchy for downstream directionality.
# Downstream links only flow from lower rank to higher rank.
# Repos in unranked orgs can have downstream links to any ranked org.
ORG_RANK = {
    "opendatahub-io": 1,       # midstream
    "red-hat-data-services": 2, # downstream
}

# Repos where midstream/downstream uses a different name than upstream.
# Format: "upstream-org/upstream-repo" -> "downstream-org/downstream-repo"
KNOWN_NAME_ALIASES = {
    "llm-d/llm-d-workload-variant-autoscaler": [
        "opendatahub-io/workload-variant-autoscaler",
        "red-hat-data-services/workload-variant-autoscaler",
    ],
    # Rename in progress: llm-d-inference-scheduler → llm-d-router
    "llm-d/llm-d-inference-scheduler": [
        "opendatahub-io/llm-d-router",
        "red-hat-data-services/llm-d-router",
    ],
}

# Repos superseded by a rename. When both old and new appear in a
# downstream list, the old entry is dropped.
SUPERSEDED_REPOS = {
    "red-hat-data-services/llm-d-inference-scheduler": "red-hat-data-services/llm-d-router",
    "llm-d/llm-d-inference-scheduler": "llm-d/llm-d-router",
}

# Well-known upstream mappings for repos where API/workflow detection fails.
# Format: downstream_repo_name -> upstream_org/repo
KNOWN_UPSTREAMS = {
    "agents-operator": "kagenti/kagenti-operator",
    "argo-workflows": "argoproj/argo-workflows",
    "batch-gateway": "llm-d-incubation/batch-gateway",
    "llm-d-async": "llm-d-incubation/llm-d-async",
    "caikit": "caikit/caikit",
    "feast": "feast-dev/feast",
    "gateway-api-inference-extension": "kubernetes-sigs/gateway-api-inference-extension",
    "kserve": "kserve/kserve",
    "kubeflow": "kubeflow/kubeflow",
    "kuberay": "ray-project/kuberay",
    "kueue": "kubernetes-sigs/kueue",
    "MLServer": "SeldonIO/MLServer",
    "ml-metadata": "google/ml-metadata",
    "mlflow": "mlflow/mlflow",
    "NeMo-Guardrails": "NVIDIA/NeMo-Guardrails",
    "openvino_model_server": "openvinotoolkit/model_server",
    "spark-operator": "kubeflow/spark-operator",
    "training-operator": "kubeflow/training-operator",
    "vllm": "vllm-project/vllm",
    "vllm-gaudi": "vllm-project/vllm",
}

# Repos where the downstream has a different name than the upstream/midstream.
# Format: "org/repo" -> ["downstream-org/downstream-repo", ...]
KNOWN_DOWNSTREAMS = {
    "opendatahub-io/opendatahub-operator": [
        "red-hat-data-services/rhods-operator",
    ],
}


def _github_get(org, repo, token):
    """Query GitHub API for repo metadata. Returns dict or None."""
    url = f"https://api.github.com/repos/{org}/{repo}"
    req = urllib.request.Request(url)
    req.add_header("Authorization", f"token {token}")
    req.add_header("Accept", "application/vnd.github+json")
    req.add_header("User-Agent", "parse-repo-provenance")
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        if e.code == 403:
            raise
        return None
    except (urllib.error.URLError, TimeoutError):
        return None


def detect_sync_workflows(repo_path):
    """Find sync/rebase/upstream workflows and classify the mechanism."""
    workflows_dir = repo_path / ".github" / "workflows"
    if not workflows_dir.is_dir():
        return [], None

    sync_files = []
    for wf in sorted(workflows_dir.iterdir()):
        if not wf.is_file():
            continue
        if not wf.suffix.lower() in (".yml", ".yaml"):
            continue
        name_lower = wf.name.lower()
        if any(p in name_lower for p in SYNC_WORKFLOW_PATTERNS):
            if "label" in name_lower or "lint" in name_lower:
                continue
            sync_files.append(wf.name)

    if not sync_files:
        return [], None

    mechanism = "sync_workflow"
    for f in sync_files:
        fl = f.lower()
        if "rebase" in fl:
            mechanism = "rebase_workflow"
            break
        if "auto-merge" in fl or "auto_merge" in fl:
            mechanism = "auto_merge"
            break

    return sync_files, mechanism


def extract_upstream_from_workflows(repo_path, sync_files):
    """Try to extract upstream org/repo from workflow file contents."""
    workflows_dir = repo_path / ".github" / "workflows"
    for wf_name in sync_files:
        wf_path = workflows_dir / wf_name
        try:
            content = wf_path.read_text(errors="replace")
        except OSError:
            continue

        for match in GITHUB_URL_RE.finditer(content):
            org, repo = match.group(1), match.group(2)
            repo = repo.removesuffix(".git").rstrip("/")
            if org.startswith("$") or repo.startswith("$"):
                continue
            if org.lower() in SKIP_ORGS:
                continue
            repo_parent = repo_path.parent.name.split(".")[0]
            if org.lower() == repo_parent.lower():
                continue
            return f"{org}/{repo}"
    return None


def parse_org_from_dir(dir_name):
    """Extract org name from checkout dir name like 'opendatahub-io.head'."""
    return dir_name.split(".")[0]


def collect_repos(checkouts_dirs):
    """Build {org: {repo_name: repo_path}} from checkouts directories."""
    org_repos = {}
    for cdir in checkouts_dirs:
        cdir_path = Path(cdir)
        if not cdir_path.is_dir():
            continue
        org = parse_org_from_dir(cdir_path.name)
        if org not in org_repos:
            org_repos[org] = {}
        for d in sorted(cdir_path.iterdir()):
            if d.is_dir() and not d.name.startswith("."):
                org_repos[org][d.name] = d
    return org_repos


def find_downstream(org, repo_name, org_repos):
    """Find same-named repos in other orgs that are downstream.

    Uses ORG_RANK to enforce directionality: downstream links only flow
    from lower-ranked (or unranked) orgs to higher-ranked orgs.
    e.g., upstream(unranked) -> opendatahub-io(1) -> red-hat-data-services(2)
    """
    my_rank = ORG_RANK.get(org, 0)
    downstream = []
    for other_org, repos in org_repos.items():
        if other_org == org:
            continue
        other_rank = ORG_RANK.get(other_org, 0)
        if other_rank <= my_rank:
            continue
        if repo_name in repos:
            downstream.append(f"{other_org}/{repo_name}")
    return sorted(downstream)


def main():
    if len(sys.argv) < 2:
        print(
            f"Usage: {sys.argv[0]} <checkouts_dir> [<checkouts_dir2> ...]",
            file=sys.stderr,
        )
        sys.exit(1)

    checkouts_dirs = sys.argv[1:]
    token = os.environ.get("GITHUB_TOKEN", "")
    api_available = bool(token)

    if not api_available:
        print(
            "WARNING: GITHUB_TOKEN not set. Skipping GitHub API calls;"
            " upstream detection will rely on sync workflows and"
            " cross-org matching only.",
            file=sys.stderr,
        )

    org_repos = collect_repos(checkouts_dirs)

    all_repos = []
    for org, repos in org_repos.items():
        for repo_name, repo_path in repos.items():
            all_repos.append((org, repo_name, repo_path))

    results = {}
    api_stopped = False
    total = len(all_repos)

    for i, (org, repo_name, repo_path) in enumerate(all_repos):
        key = f"{org}/{repo_name}"

        is_fork = False
        upstream = None
        upstream_detection = None

        if api_available and not api_stopped:
            if i > 0:
                time.sleep(0.1)
            try:
                data = _github_get(org, repo_name, token)
                if data:
                    is_fork = data.get("fork", False)
                    parent = data.get("parent", {})
                    source = data.get("source", {})
                    if parent and parent.get("full_name"):
                        upstream = parent["full_name"]
                        upstream_detection = "github_api"
                    elif source and source.get("full_name"):
                        upstream = source["full_name"]
                        upstream_detection = "github_api"
            except urllib.error.HTTPError:
                print(
                    f"WARNING: Rate limited at repo {i + 1}/{total}."
                    " Stopping API calls.",
                    file=sys.stderr,
                )
                api_stopped = True

        sync_files, sync_mechanism = detect_sync_workflows(repo_path)

        if not upstream and sync_files:
            wf_upstream = extract_upstream_from_workflows(
                repo_path, sync_files
            )
            if wf_upstream:
                upstream = wf_upstream
                upstream_detection = "sync_workflow"
                is_fork = True

        if not upstream and repo_name in KNOWN_UPSTREAMS:
            upstream = KNOWN_UPSTREAMS[repo_name]
            upstream_detection = "known_mapping"
            is_fork = True

        # Detect upstream by name prefix: if repo name starts with
        # another org's name and that org has the repo, it's likely
        # the upstream origin (e.g., llm-d-router belongs to llm-d)
        if not upstream:
            for other_org, other_repos in org_repos.items():
                if other_org == org:
                    continue
                if repo_name.startswith(other_org + "-") and repo_name in other_repos:
                    upstream = f"{other_org}/{repo_name}"
                    upstream_detection = "name_prefix"
                    is_fork = True
                    break

        # Reverse alias lookup: if this repo appears as a downstream
        # in KNOWN_NAME_ALIASES, set the alias source as upstream.
        # Runs after name_prefix so the current name takes priority
        # over old/renamed names.
        if not upstream:
            for alias_src, alias_dests in KNOWN_NAME_ALIASES.items():
                if key in alias_dests:
                    upstream = alias_src
                    upstream_detection = "known_mapping"
                    is_fork = True
                    break

        downstream = find_downstream(org, repo_name, org_repos)
        if key in KNOWN_DOWNSTREAMS:
            for kd in KNOWN_DOWNSTREAMS[key]:
                if kd not in downstream:
                    downstream.append(kd)
            downstream.sort()
        if key in KNOWN_NAME_ALIASES:
            for alias in KNOWN_NAME_ALIASES[key]:
                if alias not in downstream:
                    downstream.append(alias)
            downstream.sort()
        if downstream and upstream:
            upstream_org = upstream.split("/")[0]
            downstream = [
                d for d in downstream
                if d.split("/")[0] != upstream_org
            ]
        ds_set = set(downstream)
        downstream = [
            d for d in downstream
            if d not in SUPERSEDED_REPOS or SUPERSEDED_REPOS[d] not in ds_set
        ]
        downstream_detection = "cross_org_match" if downstream else None

        if upstream and not sync_mechanism:
            sync_mechanism = "manual"

        results[key] = {
            "org": org,
            "repo": repo_name,
            "is_fork": is_fork,
            "upstream": upstream,
            "upstream_detection": upstream_detection,
            "downstream": downstream,
            "downstream_detection": downstream_detection,
            "sync_mechanism": sync_mechanism,
            "sync_workflows": sync_files,
        }

        if (i + 1) % 25 == 0:
            print(
                f"Progress: {i + 1}/{total} repos processed",
                file=sys.stderr,
            )

    repos_with_upstream = sum(
        1 for r in results.values() if r["upstream"]
    )
    repos_with_downstream = sum(
        1 for r in results.values() if r["downstream"]
    )

    output = {
        "metadata": {
            "generated_at": None,
            "checkouts_dirs": checkouts_dirs,
            "github_api_available": api_available and not api_stopped,
            "total_repos": len(results),
            "repos_with_upstream": repos_with_upstream,
            "repos_with_downstream": repos_with_downstream,
        },
        "repos": results,
    }

    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()
