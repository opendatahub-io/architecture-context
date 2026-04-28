#!/usr/bin/env python3
"""Validate a component-map.json file against the expected schema."""

import json
import sys
from pathlib import Path


VALID_TYPES = {
    "operator", "controller", "service", "ui",
    "installer", "asset", "shared_library", "api_specification",
}

VALID_TIERS = {
    "core_platform", "optional_platform", "payload_component", "ecosystem",
}

VALID_DISCOVERY_METHODS = {"breadcrumb"}

VALID_DISCOVERED_VIA = {
    "operator_operand", "operator_bundle",
    "container_image", "dependency", "installer", "dsc_spec",
}

VALID_CONFIDENCE = {"high", "medium", "low", "disputed"}

REQUIRED_METADATA_FIELDS = {
    "platform": str,
    "discovery_method": str,
    "discovered_at": str,
    "total_repos_scanned": int,
    "components_discovered": int,
    "components_excluded": int,
}

REQUIRED_COMPONENT_FIELDS = {
    "key": str,
    "repo_org": str,
    "repo_name": str,
    "repo_url": str,
    "checkout_path": str,
    "has_architecture": bool,
    "type": str,
    "shipped": bool,
    "architecturally_significant": bool,
}


def validate(path: str) -> list[str]:
    """Return a list of validation errors (empty = valid)."""
    errors = []
    filepath = Path(path)

    if not filepath.exists():
        return [f"File not found: {path}"]

    try:
        data = json.loads(filepath.read_text())
    except json.JSONDecodeError as e:
        return [f"Invalid JSON: {e}"]

    if not isinstance(data, dict):
        return ["Root must be a JSON object"]

    # --- metadata ---
    metadata = data.get("metadata")
    if not isinstance(metadata, dict):
        errors.append("Missing or invalid 'metadata' object")
    else:
        for field, expected_type in REQUIRED_METADATA_FIELDS.items():
            val = metadata.get(field)
            if val is None:
                errors.append(f"metadata: missing required field '{field}'")
            elif not isinstance(val, expected_type):
                errors.append(f"metadata.{field}: expected {expected_type.__name__}, got {type(val).__name__}")

        dm = metadata.get("discovery_method")
        if dm and dm not in VALID_DISCOVERY_METHODS:
            errors.append(f"metadata.discovery_method: '{dm}' not in {VALID_DISCOVERY_METHODS}")

        discovered = metadata.get("components_discovered", 0)
        excluded = metadata.get("components_excluded", 0)
        actual_components = len(data.get("components", {}))
        actual_excluded = len(data.get("excluded", {}))

        if isinstance(discovered, int) and discovered != actual_components:
            errors.append(
                f"metadata.components_discovered ({discovered}) != "
                f"actual component count ({actual_components})"
            )
        if isinstance(excluded, int) and excluded != actual_excluded:
            errors.append(
                f"metadata.components_excluded ({excluded}) != "
                f"actual excluded count ({actual_excluded})"
            )

    # --- components ---
    components = data.get("components")
    if not isinstance(components, dict):
        errors.append("Missing or invalid 'components' object")
    else:
        for key, comp in components.items():
            prefix = f"components.{key}"

            if not isinstance(comp, dict):
                errors.append(f"{prefix}: expected object, got {type(comp).__name__}")
                continue

            for field, expected_type in REQUIRED_COMPONENT_FIELDS.items():
                val = comp.get(field)
                if val is None:
                    errors.append(f"{prefix}: missing required field '{field}'")
                elif not isinstance(val, expected_type):
                    errors.append(f"{prefix}.{field}: expected {expected_type.__name__}, got {type(val).__name__}")

            if comp.get("key") and comp["key"] != key:
                errors.append(f"{prefix}.key: value '{comp['key']}' doesn't match dict key '{key}'")

            ctype = comp.get("type")
            if ctype and ctype not in VALID_TYPES:
                errors.append(f"{prefix}.type: '{ctype}' not in {VALID_TYPES}")

            tier = comp.get("tier")
            if tier and tier not in VALID_TIERS:
                errors.append(f"{prefix}.tier: '{tier}' not in {VALID_TIERS}")

            dv = comp.get("discovered_via")
            if dv and dv not in VALID_DISCOVERED_VIA:
                errors.append(f"{prefix}.discovered_via: '{dv}' not in {VALID_DISCOVERED_VIA}")

            conf = comp.get("confidence")
            if conf and conf not in VALID_CONFIDENCE:
                errors.append(f"{prefix}.confidence: '{conf}' not in {VALID_CONFIDENCE}")

            repo_url = comp.get("repo_url")
            if repo_url and not repo_url.startswith("https://"):
                errors.append(f"{prefix}.repo_url: expected https:// URL, got '{repo_url}'")

            rb = comp.get("referenced_by")
            if rb is not None and not isinstance(rb, list):
                errors.append(f"{prefix}.referenced_by: expected list, got {type(rb).__name__}")

            consumers = comp.get("consumers")
            if consumers is not None and not isinstance(consumers, list):
                errors.append(f"{prefix}.consumers: expected list, got {type(consumers).__name__}")

            cc = comp.get("consumer_count")
            if cc is not None:
                if not isinstance(cc, int):
                    errors.append(f"{prefix}.consumer_count: expected int, got {type(cc).__name__}")
                elif consumers is not None and isinstance(consumers, list) and cc != len(consumers):
                    errors.append(
                        f"{prefix}.consumer_count ({cc}) != len(consumers) ({len(consumers)})"
                    )

    # --- dependency_graph (optional) ---
    dg = data.get("dependency_graph")
    if dg is not None:
        if not isinstance(dg, dict):
            errors.append("dependency_graph: expected object")
        else:
            for repo, deps in dg.items():
                if not isinstance(deps, list):
                    errors.append(f"dependency_graph.{repo}: expected list, got {type(deps).__name__}")

    # --- excluded (optional) ---
    excluded = data.get("excluded")
    if excluded is not None:
        if not isinstance(excluded, dict):
            errors.append("excluded: expected object")

    return errors


def main():
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <component-map.json>")
        sys.exit(2)

    errors = validate(sys.argv[1])

    if errors:
        print(f"VALIDATION FAILED — {len(errors)} error(s):\n")
        for e in errors:
            print(f"  - {e}")
        sys.exit(1)
    else:
        print("VALIDATION PASSED")
        sys.exit(0)


if __name__ == "__main__":
    main()
