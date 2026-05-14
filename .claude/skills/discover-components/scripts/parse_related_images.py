#!/usr/bin/env python3
"""Parse RELATED_IMAGE mappings from operator *_support.go files.

Usage:
    python parse_related_images.py <operator_repo> <checkouts_dir> [<checkouts_dir2> ...]

Scans internal/controller/components/*/  for *_support.go files containing
imageParamMap or similar RELATED_IMAGE_* mappings. Outputs JSON with discovered
operands and their repo matches.
"""

import json
import re
import sys
from pathlib import Path


def find_support_files(operator_dir):
    """Find all *_support.go files in the operator's component controllers."""
    operator_path = Path(operator_dir)
    patterns = [
        "internal/controller/components/*/*_support.go",
        "controllers/components/*/*_support.go",
        "pkg/controller/components/*/*_support.go",
    ]
    files = []
    for pattern in patterns:
        files.extend(operator_path.glob(pattern))
    return sorted(files)


def extract_image_keys(filepath):
    """Extract image key -> RELATED_IMAGE_* mappings from a Go file."""
    content = filepath.read_text()

    component = filepath.parent.name

    mappings = []
    pattern = re.compile(r'"([^"]+)"\s*:\s*"(RELATED_IMAGE_[^"]+)"')
    for match in pattern.finditer(content):
        key, env_var = match.groups()
        mappings.append({
            "key": key,
            "env_var": env_var,
            "component": component,
            "source_file": str(filepath),
        })

    return mappings


def normalize_key(key):
    """Normalize an image key to a potential repo name."""
    key = key.lower()
    key = re.sub(r"^(kserve|modelmesh|trustyai|modelregistry)-", "", key)
    key = re.sub(r"-(image|controller-image|operator-image)$", "", key)
    key = key.replace("_", "-")
    return key


KNOWN_MAPPINGS = {
    "ovms": "openvino_model_server",
    "related-image-rh-distribution": "rhds-llama-stack-distribution",
    "related-image-odh-llamastack-operator": "llama-stack-k8s-operator",
}


def find_repo(name, repo_sets):
    """Try to match an image key to a repo."""
    if name in KNOWN_MAPPINGS:
        mapped = KNOWN_MAPPINGS[name]
        for repos in repo_sets:
            if mapped in repos:
                return mapped, "known_mapping"

    for repos in repo_sets:
        if name in repos:
            return name, "direct"

    parts = name.split("-")
    for length in range(len(parts) - 1, 0, -1):
        candidate = "-".join(parts[:length])
        for repos in repo_sets:
            if candidate in repos:
                return candidate, "parent_repo"

    return None, None


def main():
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <operator_repo> <checkouts_dir> [<checkouts_dir2> ...]", file=sys.stderr)
        sys.exit(1)

    operator_dir = sys.argv[1]
    checkouts_dirs = sys.argv[2:]

    support_files = find_support_files(operator_dir)
    if not support_files:
        print(json.dumps({
            "error": f"No *_support.go files found in {operator_dir}",
            "searched_patterns": [
                "internal/controller/components/*/*_support.go",
                "controllers/components/*/*_support.go",
            ],
        }))
        sys.exit(1)

    repo_sets = []
    for cdir in checkouts_dirs:
        cdir_path = Path(cdir)
        if cdir_path.exists():
            repos = {d.name for d in cdir_path.iterdir() if d.is_dir() and not d.name.startswith(".")}
            repo_sets.append(repos)

    all_mappings = []
    for sf in support_files:
        all_mappings.extend(extract_image_keys(sf))

    matched = {}
    unmatched = []
    by_component = {}

    for mapping in all_mappings:
        key = mapping["key"]
        component = mapping["component"]

        by_component.setdefault(component, []).append(key)

        normalized = normalize_key(key)
        repo, method = find_repo(normalized, repo_sets)

        if not repo:
            repo, method = find_repo(key, repo_sets)

        if repo:
            if repo not in matched:
                matched[repo] = {
                    "repo": repo,
                    "match_method": method,
                    "image_keys": [],
                    "components": set(),
                }
            matched[repo]["image_keys"].append(key)
            matched[repo]["components"].add(component)
        else:
            unmatched.append({
                "key": key,
                "env_var": mapping["env_var"],
                "component": component,
                "normalized": normalized,
            })

    for repo_info in matched.values():
        repo_info["components"] = sorted(repo_info["components"])

    result = {
        "operator_dir": operator_dir,
        "support_files_found": len(support_files),
        "total_mappings": len(all_mappings),
        "matched_repos": len(matched),
        "unmatched_keys": len(unmatched),
        "repos": matched,
        "unmatched": unmatched,
        "by_component": {k: sorted(set(v)) for k, v in by_component.items()},
    }

    print(json.dumps(result, indent=2, default=list))


if __name__ == "__main__":
    main()
