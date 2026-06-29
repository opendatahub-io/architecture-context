#!/usr/bin/env python3
"""Validate platforms.yaml schema and safety constraints."""

import sys
from pathlib import Path

import yaml

PLATFORMS_FILE = Path(__file__).resolve().parent.parent / "platforms.yaml"

KNOWN_KEYS = {
    "suffix",
    "branch",
    "version",
    "orgs",
    "extra_orgs",
    "extra_repos",
    "exclude_repos",
    "exclude_components",
    "include_components",
    "component_overrides",
    "post_checkout",
    "sync_config",
}


def _check_str(value, label, errors):
    if not isinstance(value, str):
        errors.append(f"'{label}' must be a string, got {type(value).__name__}")


def _check_list_of_str(value, label, errors):
    if not isinstance(value, list):
        errors.append(
            f"'{label}' must be a list, got {type(value).__name__}"
        )
        return
    for i, item in enumerate(value):
        if not isinstance(item, str):
            errors.append(
                f"'{label}[{i}]' must be a string,"
                f" got {type(item).__name__}"
            )


def _check_exclude_patterns(patterns, label, errors):
    if not isinstance(patterns, list):
        errors.append(
            f"'{label}' must be a list of glob patterns,"
            f" got {type(patterns).__name__}"
        )
        return
    for i, p in enumerate(patterns):
        if not isinstance(p, str):
            errors.append(
                f"'{label}[{i}]' must be a string,"
                f" got {type(p).__name__}"
            )
        elif ".." in p:
            errors.append(
                f"'{label}[{i}]': pattern contains '..'"
                " (path traversal)"
            )
        elif p.startswith("/"):
            errors.append(
                f"'{label}[{i}]': pattern is an absolute path"
            )


def _check_extra_orgs(value, errors):
    if not isinstance(value, list):
        errors.append(
            f"'extra_orgs' must be a list,"
            f" got {type(value).__name__}"
        )
        return
    for i, entry in enumerate(value):
        if isinstance(entry, str):
            continue
        if not isinstance(entry, dict):
            errors.append(
                f"'extra_orgs[{i}]' must be a string or dict,"
                f" got {type(entry).__name__}"
            )
            continue
        if "org" not in entry:
            errors.append(f"'extra_orgs[{i}]': missing required 'org'")
        elif not isinstance(entry["org"], str):
            errors.append(f"'extra_orgs[{i}].org' must be a string")
        for k in ("branch", "suffix"):
            if k in entry and not isinstance(entry[k], str):
                errors.append(
                    f"'extra_orgs[{i}].{k}' must be a string"
                )


def _check_extra_repos(value, errors):
    if not isinstance(value, list):
        errors.append(
            f"'extra_repos' must be a list,"
            f" got {type(value).__name__}"
        )
        return
    allowed = {"org", "repo", "branch", "suffix", "exclude_files", "protocol"}
    for i, entry in enumerate(value):
        if not isinstance(entry, dict):
            errors.append(
                f"'extra_repos[{i}]' must be a dict,"
                f" got {type(entry).__name__}"
            )
            continue
        unknown = set(entry.keys()) - allowed
        if unknown:
            errors.append(
                f"'extra_repos[{i}]': unrecognized keys:"
                f" {', '.join(sorted(unknown))}"
            )
        for req in ("org", "repo"):
            if req not in entry:
                errors.append(
                    f"'extra_repos[{i}]': missing required '{req}'"
                )
            elif not isinstance(entry[req], str):
                errors.append(
                    f"'extra_repos[{i}].{req}' must be a string"
                )
        for opt in ("branch", "suffix"):
            if opt in entry and not isinstance(entry[opt], str):
                errors.append(
                    f"'extra_repos[{i}].{opt}' must be a string"
                )
        if "protocol" in entry:
            proto = entry["protocol"]
            if proto not in ("https", "ssh"):
                errors.append(
                    f"'extra_repos[{i}].protocol' must be"
                    f" 'https' or 'ssh', got '{proto}'"
                )
        if "exclude_files" in entry:
            _check_exclude_patterns(
                entry["exclude_files"],
                f"extra_repos[{i}].exclude_files",
                errors,
            )


def _check_include_components(value, errors):
    if not isinstance(value, list):
        errors.append(
            f"'include_components' must be a list,"
            f" got {type(value).__name__}"
        )
        return
    for i, entry in enumerate(value):
        if not isinstance(entry, dict):
            errors.append(
                f"'include_components[{i}]' must be a dict,"
                f" got {type(entry).__name__}"
            )
            continue
        for req in ("key", "repo_org", "repo_name", "type"):
            if req not in entry:
                errors.append(
                    f"'include_components[{i}]':"
                    f" missing required '{req}'"
                )
            elif not isinstance(entry[req], str):
                errors.append(
                    f"'include_components[{i}].{req}'"
                    " must be a string"
                )


def _check_post_checkout(value, errors):
    if not isinstance(value, list):
        errors.append(
            f"'post_checkout' must be a list,"
            f" got {type(value).__name__}"
        )
        return
    for i, entry in enumerate(value):
        if not isinstance(entry, dict):
            errors.append(
                f"'post_checkout[{i}]' must be a dict,"
                f" got {type(entry).__name__}"
            )
            continue
        if "repo" not in entry:
            errors.append(
                f"'post_checkout[{i}]': missing required 'repo'"
            )
        elif not isinstance(entry["repo"], str):
            errors.append(
                f"'post_checkout[{i}].repo' must be a string"
            )
        if "exclude_files" not in entry:
            errors.append(
                f"'post_checkout[{i}]':"
                " missing required 'exclude_files'"
            )
        else:
            _check_exclude_patterns(
                entry["exclude_files"],
                f"post_checkout[{i}].exclude_files",
                errors,
            )


def _check_sync_config(value, errors):
    if not isinstance(value, dict):
        errors.append(
            f"'sync_config' must be a dict,"
            f" got {type(value).__name__}"
        )
        return
    allowed = {"org", "repo", "branch", "protocol", "upstream_map"}
    unknown = set(value.keys()) - allowed
    if unknown:
        errors.append(
            f"'sync_config': unrecognized keys:"
            f" {', '.join(sorted(unknown))}"
        )
    for req in ("org", "repo", "upstream_map"):
        if req not in value:
            errors.append(f"'sync_config': missing required '{req}'")
        elif not isinstance(value[req], str):
            errors.append(f"'sync_config.{req}' must be a string")
    for opt in ("branch",):
        if opt in value and not isinstance(value[opt], str):
            errors.append(f"'sync_config.{opt}' must be a string")
    if "protocol" in value:
        proto = value["protocol"]
        if proto not in ("https", "ssh"):
            errors.append(
                f"'sync_config.protocol' must be"
                f" 'https' or 'ssh', got '{proto}'"
            )
    um = value.get("upstream_map", "")
    if isinstance(um, str):
        if ".." in um:
            errors.append(
                "'sync_config.upstream_map' contains '..'"
                " (path traversal)"
            )
        elif um.startswith("/"):
            errors.append(
                "'sync_config.upstream_map' is an absolute path"
            )


def validate_platform(name: str, config: dict) -> list[str]:
    errors: list[str] = []

    if not isinstance(config, dict):
        errors.append("platform value must be a mapping")
        return errors

    unknown = set(config.keys()) - KNOWN_KEYS
    if unknown:
        errors.append(
            f"unrecognized keys: {', '.join(sorted(unknown))}"
        )

    for key in ("suffix", "branch", "version"):
        if key in config:
            _check_str(config[key], key, errors)

    for key in ("orgs", "exclude_repos", "exclude_components"):
        if key in config:
            _check_list_of_str(config[key], key, errors)

    if "extra_orgs" in config:
        _check_extra_orgs(config["extra_orgs"], errors)

    if "extra_repos" in config:
        _check_extra_repos(config["extra_repos"], errors)

    if "include_components" in config:
        _check_include_components(config["include_components"], errors)

    if "component_overrides" in config:
        co = config["component_overrides"]
        if not isinstance(co, dict):
            errors.append(
                "'component_overrides' must be a mapping,"
                f" got {type(co).__name__}"
            )
        else:
            for k, v in co.items():
                if not isinstance(v, dict):
                    errors.append(
                        f"'component_overrides.{k}'"
                        " must be a mapping"
                    )

    if "post_checkout" in config:
        _check_post_checkout(config["post_checkout"], errors)

    if "sync_config" in config:
        _check_sync_config(config["sync_config"], errors)

    return errors


def main() -> int:
    if not PLATFORMS_FILE.exists():
        print(f"platforms.yaml not found: {PLATFORMS_FILE}")
        return 1

    try:
        with open(PLATFORMS_FILE, encoding="utf-8") as f:
            data = yaml.safe_load(f)
    except yaml.YAMLError as e:
        print(f"invalid YAML in {PLATFORMS_FILE}: {e}")
        return 1

    if not isinstance(data, dict):
        print("platforms.yaml root must be a YAML mapping")
        return 1

    total_errors = 0
    platforms = sorted(
        k for k in data if not k.startswith("_")
    )

    for name in platforms:
        errors = validate_platform(name, data[name])
        if errors:
            print(f"{name}:")
            for e in errors:
                print(f"  - {e}")
            total_errors += len(errors)

    if total_errors:
        print(
            f"\n{total_errors} error(s) in"
            f" {len(platforms)} platform(s)"
        )
        return 1

    print(
        f"All {len(platforms)} platform(s) passed validation."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
