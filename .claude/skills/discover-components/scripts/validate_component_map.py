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
    "container_image", "image_dependency", "dependency", "installer", "dsc_spec",
    "sync_config",
}

VALID_CONFIDENCE = {"high", "medium", "low", "disputed"}

VALID_UPSTREAM_DETECTION = {"github_api", "sync_workflow", "known_mapping", "name_prefix", "sync_config"}
VALID_DOWNSTREAM_DETECTION = {"cross_org_match", "sync_config"}
VALID_SYNC_MECHANISMS = {
    "sync_workflow", "rebase_workflow", "auto_merge", "manual",
}

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

    # --- provenance (optional, added by harness post-processing) ---
    provenance = data.get("provenance")
    if provenance is not None:
        if not isinstance(provenance, dict):
            errors.append("provenance: expected object")
        else:
            prov_meta = provenance.get("metadata")
            if not isinstance(prov_meta, dict):
                errors.append("provenance.metadata: missing or not an object")
            else:
                for field in ("total_repos", "repos_with_upstream", "repos_with_downstream"):
                    val = prov_meta.get(field)
                    if val is not None and not isinstance(val, int):
                        errors.append(
                            f"provenance.metadata.{field}: expected int,"
                            f" got {type(val).__name__}"
                        )
                ga = prov_meta.get("generated_at")
                if ga is not None and not isinstance(ga, str):
                    errors.append(
                        "provenance.metadata.generated_at:"
                        " expected string"
                    )
                cd = prov_meta.get("checkouts_dirs")
                if cd is not None:
                    if not isinstance(cd, list):
                        errors.append(
                            "provenance.metadata.checkouts_dirs:"
                            " expected list"
                        )
                    elif not all(isinstance(d, str) for d in cd):
                        errors.append(
                            "provenance.metadata.checkouts_dirs:"
                            " all items must be strings"
                        )
                api = prov_meta.get("github_api_available")
                if api is not None and not isinstance(api, bool):
                    errors.append(
                        "provenance.metadata.github_api_available:"
                        " expected bool"
                    )

            prov_repos = provenance.get("repos")
            if not isinstance(prov_repos, dict):
                errors.append("provenance.repos: missing or not an object")
            else:
                for repo_key, repo_data in prov_repos.items():
                    prefix = f"provenance.repos.{repo_key}"
                    if not isinstance(repo_data, dict):
                        errors.append(f"{prefix}: expected object")
                        continue

                    for field in ("org", "repo"):
                        if not isinstance(repo_data.get(field), str):
                            errors.append(f"{prefix}.{field}: expected string")

                    if not isinstance(repo_data.get("is_fork"), bool):
                        errors.append(f"{prefix}.is_fork: expected bool")

                    us = repo_data.get("upstream")
                    if us is not None and not isinstance(us, str):
                        errors.append(
                            f"{prefix}.upstream: expected"
                            " string or null"
                        )

                    ud = repo_data.get("upstream_detection")
                    if ud is not None and ud not in VALID_UPSTREAM_DETECTION:
                        errors.append(
                            f"{prefix}.upstream_detection: '{ud}'"
                            f" not in {VALID_UPSTREAM_DETECTION}"
                        )

                    dd = repo_data.get("downstream_detection")
                    if dd is not None and dd not in VALID_DOWNSTREAM_DETECTION:
                        errors.append(
                            f"{prefix}.downstream_detection: '{dd}'"
                            f" not in {VALID_DOWNSTREAM_DETECTION}"
                        )

                    sm = repo_data.get("sync_mechanism")
                    if sm is not None and sm not in VALID_SYNC_MECHANISMS:
                        errors.append(
                            f"{prefix}.sync_mechanism: '{sm}'"
                            f" not in {VALID_SYNC_MECHANISMS}"
                        )

                    ds = repo_data.get("downstream")
                    if not isinstance(ds, list):
                        errors.append(
                            f"{prefix}.downstream: expected list"
                        )
                    elif not all(isinstance(d, str) for d in ds):
                        errors.append(
                            f"{prefix}.downstream: all items"
                            " must be strings"
                        )

                    sw = repo_data.get("sync_workflows")
                    if not isinstance(sw, list):
                        errors.append(
                            f"{prefix}.sync_workflows:"
                            " expected list"
                        )
                    elif not all(isinstance(w, str) for w in sw):
                        errors.append(
                            f"{prefix}.sync_workflows: all"
                            " items must be strings"
                        )

                if isinstance(prov_meta, dict):
                    total = prov_meta.get("total_repos")
                    actual = len(prov_repos)
                    if isinstance(total, int) and total != actual:
                        errors.append(
                            f"provenance.metadata.total_repos ({total})"
                            f" != actual repo count ({actual})"
                        )

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
