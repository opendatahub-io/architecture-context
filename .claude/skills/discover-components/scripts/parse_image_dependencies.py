#!/usr/bin/env python3
"""Parse Python dependencies from container image build repos.

Usage:
    python parse_image_dependencies.py <image_repo> <checkouts_dir> ...

Scans pyproject.toml and requirements*.txt files in an image-building repo
(e.g. notebooks), extracts Python package names, and matches them against
repos in the checkouts directories.

Output: JSON with matched repos, unmatched packages, and metadata.
"""

import json
import re
import sys
from pathlib import Path

KNOWN_MAPPINGS = {
    "codeflare-sdk": "codeflare-sdk",
    "kfp": "data-science-pipelines",
    "kfp-server-api": "data-science-pipelines",
    "mlflow": "mlflow",
    "ray": "kuberay",
}

SKIP_DIRS = {".git", "node_modules", "__pycache__", ".tox", ".venv"}

VERSION_RE = re.compile(r"[><=!~]")
EXTRAS_RE = re.compile(r"\[.*?\]")


def find_repo(name, repo_sets):
    """Try to match a package name to a repo."""
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


def normalize_package_name(raw):
    """Normalize a Python package name to its canonical form."""
    name = raw.strip().lower()
    name = EXTRAS_RE.sub("", name)
    name = name.replace("_", "-")
    return name


def extract_package_name(line):
    """Extract the package name from a dependency line.

    Handles formats like:
        package-name
        package-name>=1.0
        package-name==1.2.3
        package-name[extra1,extra2]>=1.0
        package-name; platform_machine != 's390x'
        package-name==1.0 ; env_marker \\ --hash=sha256:...
    """
    line = line.strip()
    if not line or line.startswith("#") or line.startswith("-"):
        return None

    semi_pos = line.find(";")
    if semi_pos > 0:
        line = line[:semi_pos]

    match = VERSION_RE.search(line)
    if match:
        line = line[:match.start()]

    line = line.strip()
    if not line:
        return None

    return normalize_package_name(line)


def parse_requirements_txt(filepath):
    """Extract package names from a requirements.txt file."""
    packages = set()
    try:
        for line in filepath.read_text().splitlines():
            line = line.split("\\")[0].strip()
            name = extract_package_name(line)
            if name:
                packages.add(name)
    except (OSError, UnicodeDecodeError):
        pass
    return packages


def parse_pyproject_toml(filepath):
    """Extract package names from a pyproject.toml dependencies list."""
    packages = set()
    try:
        content = filepath.read_text()
    except (OSError, UnicodeDecodeError):
        return packages

    in_deps = False
    for line in content.splitlines():
        stripped = line.strip()

        if stripped in (
            "dependencies = [",
            "override-dependencies = [",
        ):
            in_deps = True
            continue

        if in_deps:
            if stripped == "]":
                in_deps = False
                continue

            match = re.search(r'"([^"]+)"', stripped)
            if match:
                name = extract_package_name(match.group(1))
                if name:
                    packages.add(name)

    return packages


def find_dependency_files(repo_path):
    """Find all pyproject.toml and requirements*.txt in the repo."""
    pyprojects = []
    requirements = []

    for path in repo_path.rglob("*"):
        if any(part in SKIP_DIRS for part in path.parts):
            continue
        if path.name == "pyproject.toml":
            pyprojects.append(path)
        elif path.name.startswith("requirements") and path.suffix == ".txt":
            requirements.append(path)

    return sorted(pyprojects), sorted(requirements)


def main():
    if len(sys.argv) < 3:
        print(
            f"Usage: {sys.argv[0]} <image_repo> <checkouts_dir>"
            f" [<checkouts_dir2> ...]",
            file=sys.stderr,
        )
        sys.exit(1)

    image_repo = Path(sys.argv[1])
    checkouts_dirs = sys.argv[2:]

    if not image_repo.is_dir():
        print(json.dumps({"error": f"Not a directory: {image_repo}"}))
        sys.exit(1)

    repo_sets = []
    for cdir in checkouts_dirs:
        cdir_path = Path(cdir)
        if cdir_path.exists():
            repos = {
                d.name
                for d in cdir_path.iterdir()
                if d.is_dir() and not d.name.startswith(".")
            }
            repo_sets.append(repos)

    pyprojects, req_files = find_dependency_files(image_repo)
    all_files = pyprojects + req_files

    package_sources = {}

    for pp in pyprojects:
        rel = str(pp.relative_to(image_repo))
        for pkg in parse_pyproject_toml(pp):
            package_sources.setdefault(pkg, set()).add(rel)

    for rf in req_files:
        rel = str(rf.relative_to(image_repo))
        for pkg in parse_requirements_txt(rf):
            package_sources.setdefault(pkg, set()).add(rel)

    matched = {}
    unmatched = []

    for pkg in sorted(package_sources):
        repo, method = find_repo(pkg, repo_sets)
        if repo:
            if repo not in matched:
                matched[repo] = {
                    "repo": repo,
                    "match_method": method,
                    "packages": [],
                    "found_in": set(),
                }
            matched[repo]["packages"].append(pkg)
            matched[repo]["found_in"].update(package_sources[pkg])
        else:
            unmatched.append(pkg)

    for repo_info in matched.values():
        repo_info["found_in"] = sorted(repo_info["found_in"])

    result = {
        "image_repo": str(image_repo),
        "files_scanned": len(all_files),
        "total_packages": len(package_sources),
        "matched_repos": len(matched),
        "unmatched_packages": len(unmatched),
        "repos": matched,
        "unmatched": unmatched,
    }

    print(json.dumps(result, indent=2, default=list))


if __name__ == "__main__":
    main()
