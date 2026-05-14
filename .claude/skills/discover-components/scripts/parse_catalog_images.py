#!/usr/bin/env python3
"""Parse OLM catalog YAML to extract shipped images and match them to repos.

Usage:
    python parse_catalog_images.py <catalog_yaml> <checkouts_dir> [<checkouts_dir2> ...]

    # Find the latest catalog automatically:
    python parse_catalog_images.py --find-catalog <checkouts_dir> [--version rhoai-3.4]

Output: JSON with matched repos, unmatched images, and build variant groups.
"""

import argparse
import json
import os
import re
import sys
from pathlib import Path


KNOWN_MAPPINGS = {
    "dashboard": "odh-dashboard",
    "notebook-controller": "notebooks",
    "kf-notebook-controller": "notebooks",
    "model-controller": "odh-model-controller",
    "deployer": "odh-deployer",
    "mm-rest-proxy": "rest-proxy",
    "trustyai-service": "trustyai-service-operator",
    "ml-pipelines-api-server": "data-science-pipelines",
    "ml-pipelines-api-server-v2": "data-science-pipelines",
    "ml-pipelines-artifact-manager": "data-science-pipelines",
    "ml-pipelines-cache": "data-science-pipelines",
    "ml-pipelines-driver": "data-science-pipelines",
    "ml-pipelines-launcher": "data-science-pipelines",
    "ml-pipelines-persistenceagent": "data-science-pipelines",
    "ml-pipelines-persistenceagent-v2": "data-science-pipelines",
    "ml-pipelines-runtime-generic": "data-science-pipelines",
    "ml-pipelines-scheduledworkflow": "data-science-pipelines",
    "ml-pipelines-scheduledworkflow-v2": "data-science-pipelines",
    "ml-pipelines-viewercontroller": "data-science-pipelines",
    "mlmd-grpc-server": "data-science-pipelines",
    "llm-d-batch-gateway-apiserver": "batch-gateway",
    "llm-d-batch-gateway-gc": "batch-gateway",
    "llm-d-batch-gateway-processor": "batch-gateway",
    "operator": "rhods-operator",
    "operator-bundle": "rhods-operator",
    "rhel8-operator": "rhods-operator",
    "rhel9-operator": "rhods-operator",
    "feature-server": "feast",
    "feast-operator": "feast",
    "workbench-jupyter-datascience": "notebooks-downstream",
    "workbench-jupyter-minimal": "notebooks-downstream",
    "workbench-jupyter-pytorch": "notebooks-downstream",
    "workbench-jupyter-tensorflow": "notebooks-downstream",
    "workbench-jupyter-trustyai": "notebooks-downstream",
    "workbench-codeserver-datascience": "notebooks-downstream",
    "pipeline-runtime-datascience": "notebooks-downstream",
    "pipeline-runtime-minimal": "notebooks-downstream",
    "pipeline-runtime-pytorch": "notebooks-downstream",
    "pipeline-runtime-tensorflow": "notebooks-downstream",
    "training": "notebooks-downstream",
    "th06": "notebooks-downstream",
    "kube-auth-proxy": "kube-rbac-proxy",
    "openvino-servingruntime": "openvino_model_server",
    "openvino-model-server": "openvino_model_server",
}

VARIANT_SUFFIXES = re.compile(
    r"-(cuda|rocm|cpu|gaudi|spyre|nvidia|amd|intel|ibm)"
    r"[\d.]*(-torch[\d.]+)?(-py\d+)?(-llmcompressor)?$"
)

VERSION_SUFFIXES = re.compile(r"-v\d+$")


def find_catalog(checkouts_dirs, version=None):
    """Find the best catalog.yaml in RHOAI-Build-Config."""
    for cdir in checkouts_dirs:
        build_config = Path(cdir) / "RHOAI-Build-Config" / "catalog"
        if not build_config.exists():
            continue

        version_dirs = sorted(
            [d for d in build_config.iterdir() if d.is_dir() and d.name.startswith("rhoai-")],
            key=lambda d: d.name,
        )
        if not version_dirs:
            continue

        if version:
            matches = [d for d in version_dirs if version in d.name]
            target = matches[-1] if matches else version_dirs[-1]
        else:
            non_ea = [d for d in version_dirs if "ea" not in d.name]
            target = non_ea[-1] if non_ea else version_dirs[-1]

        ocp_dirs = sorted(
            [d for d in target.iterdir() if d.is_dir()],
            key=lambda d: d.name,
        )
        if not ocp_dirs:
            continue

        catalog = ocp_dirs[-1] / "rhods-operator" / "catalog.yaml"
        if catalog.exists():
            return str(catalog), target.name

    return None, None


def extract_images(catalog_path):
    """Extract unique image references from relatedImages sections."""
    images = set()
    with open(catalog_path) as f:
        for line in f:
            line = line.strip()
            if line.startswith("- image:"):
                image_ref = line.split("- image:", 1)[1].strip()
                images.add(image_ref)
    return sorted(images)


def image_to_name(image_ref):
    """Extract the short name from a full image reference."""
    name = image_ref.split("/")[-1]
    name = name.split("@")[0]
    name = name.split(":")[0]
    return name


def normalize_image_name(name):
    """Normalize an image name by stripping common prefixes/suffixes."""
    name = re.sub(r"^odh-", "", name)
    name = re.sub(r"-rhel\d+$", "", name)
    return name


def strip_variant(name):
    """Strip hardware/version variant suffixes."""
    name = VERSION_SUFFIXES.sub("", name)
    name = VARIANT_SUFFIXES.sub("", name)
    return name


def find_repo(name, repo_sets):
    """Try to match an image name to a repo using multi-step matching."""
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
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("catalog_yaml", nargs="?", help="Path to catalog.yaml")
    parser.add_argument("checkouts_dirs", nargs="*", help="Checkouts directories to search for repos")
    parser.add_argument("--find-catalog", action="store_true", help="Auto-find the best catalog.yaml")
    parser.add_argument("--version", help="Target RHOAI version (e.g., rhoai-3.4)")
    args = parser.parse_args()

    if args.find_catalog:
        all_dirs = []
        if args.catalog_yaml:
            all_dirs.append(args.catalog_yaml)
        all_dirs.extend(args.checkouts_dirs)
        args.checkouts_dirs = all_dirs
        args.catalog_yaml = None
        catalog_path, catalog_version = find_catalog(args.checkouts_dirs, args.version)
        if not catalog_path:
            print(json.dumps({"error": "No RHOAI-Build-Config catalog found in provided directories"}))
            sys.exit(1)
        print(f"Found catalog: {catalog_path} (version: {catalog_version})", file=sys.stderr)
    else:
        catalog_path = args.catalog_yaml
        catalog_version = None
        if not catalog_path or not os.path.exists(catalog_path):
            print(json.dumps({"error": f"Catalog file not found: {catalog_path}"}))
            sys.exit(1)

    repo_sets = []
    for cdir in args.checkouts_dirs:
        cdir_path = Path(cdir)
        if cdir_path.exists():
            repos = {d.name for d in cdir_path.iterdir() if d.is_dir() and not d.name.startswith(".")}
            repo_sets.append(repos)

    image_refs = extract_images(catalog_path)
    image_names = sorted(set(image_to_name(ref) for ref in image_refs))

    matched = {}
    unmatched = []
    variant_groups = {}

    for raw_name in image_names:
        normalized = normalize_image_name(raw_name)
        base = strip_variant(normalized)

        repo, method = find_repo(normalized, repo_sets)

        if not repo and base != normalized:
            repo, method = find_repo(base, repo_sets)

        if repo:
            if repo not in matched:
                matched[repo] = {
                    "repo": repo,
                    "match_method": method,
                    "image_names": [],
                }
            matched[repo]["image_names"].append(raw_name)

            if base != normalized:
                variant_groups.setdefault(base, []).append(raw_name)
        else:
            unmatched.append(raw_name)
            if base != normalized:
                variant_groups.setdefault(base, []).append(raw_name)

    result = {
        "catalog_path": catalog_path,
        "catalog_version": catalog_version,
        "total_images": len(image_names),
        "matched_repos": len(matched),
        "unmatched_images": len(unmatched),
        "repos": matched,
        "unmatched": unmatched,
        "variant_groups": {k: v for k, v in variant_groups.items() if len(v) > 1},
    }

    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
