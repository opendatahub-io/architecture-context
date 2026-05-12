"""Webhook analysis: collect, overlay, Go handler mapping."""

import json
import re
import shutil
import subprocess
import tempfile
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def _resolve_rg() -> str:
    """Resolve ripgrep binary path once."""
    path = shutil.which("rg")
    if not path:
        raise RuntimeError(
            "ripgrep (rg) is required but not found on PATH"
        )
    return path


_RG_BIN = _resolve_rg()


def _safe_join(root: Path, untrusted: str) -> Path | None:
    """Join root with an untrusted relative path, rejecting traversal."""
    if Path(untrusted).is_absolute():
        return None
    resolved = (root / untrusted).resolve()
    try:
        resolved.relative_to(root.resolve())
    except ValueError:
        return None
    return resolved


@dataclass
class WebhookEntry:
    name: str
    component: str
    type: str
    path: str
    port: int = 0
    failure_policy: str = ""
    side_effects: str = ""
    service_ref: str = ""
    rules: list = field(default_factory=list)
    sources: list = field(default_factory=list)
    overlays: list = field(default_factory=list)
    enable_condition: str = ""
    purpose: str = ""
    data_read: list = field(default_factory=list)
    cross_cutting_concerns: list = field(default_factory=list)
    def to_dict(self) -> dict:
        d = {
            "name": self.name,
            "component": self.component,
            "type": self.type,
            "path": self.path,
        }
        if self.port:
            d["port"] = self.port
        if self.failure_policy:
            d["failure_policy"] = self.failure_policy
        if self.side_effects:
            d["side_effects"] = self.side_effects
        if self.service_ref:
            d["service_ref"] = self.service_ref
        if self.rules:
            d["rules"] = self.rules
        if self.sources:
            d["sources"] = self.sources
        if self.overlays:
            d["overlays"] = self.overlays
        if self.enable_condition:
            d["enable_condition"] = self.enable_condition
        if self.purpose:
            d["purpose"] = self.purpose
        if self.data_read:
            d["data_read"] = self.data_read
        if self.cross_cutting_concerns:
            d["cross_cutting_concerns"] = self.cross_cutting_concerns
        return d


_OPERATOR_COMPONENTS = {"rhods-operator", "opendatahub-operator"}


def _is_prefetched(wh_dict: dict) -> bool:
    """Check if a webhook comes from prefetched-manifests."""
    source = wh_dict.get("source", "")
    if "prefetched-manifests" in source or "prefetched_manifests" in source:
        return True
    for s in wh_dict.get("sources", []):
        f = s.get("file", "")
        if "prefetched-manifests" in f or "prefetched_manifests" in f:
            return True
    return False


def collect_webhooks(
    architecture_dir: str,
    platform_version: str,
) -> list[WebhookEntry]:
    """Read webhooks from all component JSON files in a version directory.

    Prefetched-manifest webhooks on operator components are skipped — those
    belong to the respective component repos, not the operator.
    """
    version_dir = Path(architecture_dir) / platform_version
    if not version_dir.exists():
        return []

    webhooks = []
    skipped = 0
    for json_file in sorted(version_dir.glob("*.json")):
        if json_file.name in ("component-map.json", "build-info.json", "webhooks.json"):
            continue
        try:
            data = json.loads(json_file.read_text())
        except (json.JSONDecodeError, OSError):
            continue

        component = json_file.stem
        raw_webhooks = data.get("webhooks", [])
        if not raw_webhooks:
            continue

        is_operator = component in _OPERATOR_COMPONENTS

        for wh in raw_webhooks:
            if is_operator and _is_prefetched(wh):
                skipped += 1
                continue

            source_file = wh.get("source", "")
            sources = wh.get("sources", [])
            if not sources and source_file:
                sources = [{"type": "webhook_manifest", "file": source_file}]

            entry = WebhookEntry(
                name=wh.get("name", ""),
                component=component,
                type=wh.get("type", ""),
                path=wh.get("path", ""),
                port=wh.get("port", 0),
                failure_policy=wh.get("failure_policy", ""),
                side_effects=wh.get("side_effects", ""),
                service_ref=wh.get("service_ref", ""),
                rules=wh.get("rules", []),
                sources=sources,
            )
            webhooks.append(entry)

    if skipped:
        print(
            f"  Skipped {skipped} prefetched-manifest webhooks"
            " from operator components"
        )

    return webhooks


def discover_webhooks_from_go(
    component_repos: dict[str, Path],
) -> list[WebhookEntry]:
    """Discover webhooks from kubebuilder markers in Go source.

    This catches webhooks that arch-analyzer missed (e.g., operator's own
    webhooks defined in Go code but not in YAML manifests).
    """
    discovered = []
    marker_re = re.compile(
        r'\+kubebuilder:webhook:'
        r'(?P<fields>[^\n]+)'
    )

    for component, repo_path in component_repos.items():
        try:
            result = subprocess.run(
                [_RG_BIN, "-n", r"\+kubebuilder:webhook:", "--glob", "*.go",
                 "--no-heading"],
                cwd=str(repo_path),
                capture_output=True, text=True, timeout=30,
            )
        except (subprocess.TimeoutExpired, FileNotFoundError):
            continue
        if result.returncode != 0:
            continue

        for line in result.stdout.strip().split("\n"):
            if not line:
                continue
            m = marker_re.search(line)
            if not m:
                continue

            fields_str = m.group("fields")
            fields = _parse_marker_fields(fields_str)
            if not fields.get("path"):
                continue

            file_match = re.match(r"^(.+?):(\d+):", line)
            go_file = file_match.group(1) if file_match else ""
            go_line = int(file_match.group(2)) if file_match else 0

            is_mutating = fields.get("mutating", "").lower() == "true"
            wh_type = "mutating" if is_mutating else "validating"

            rules = []
            groups = [g for g in fields.get("groups", "").split(";") if g]
            resources = [r for r in fields.get("resources", "").split(";") if r]
            operations = [v.upper() for v in fields.get("verbs", "").split(";") if v]
            versions = [v for v in fields.get("versions", "").split(";") if v]
            if resources:
                rules.append({
                    "apiGroups": groups,
                    "apiVersions": versions,
                    "resources": resources,
                    "operations": operations,
                })

            sources = [{
                "type": "kubebuilder_marker",
                "file": go_file,
                "repo": repo_path.name,
                "line": go_line,
            }]

            discovered.append(WebhookEntry(
                name=fields.get("name", ""),
                component=component,
                type=wh_type,
                path=fields["path"],
                failure_policy=fields.get("failurePolicy", ""),
                side_effects=fields.get("sideEffects", ""),
                rules=rules,
                sources=sources,
            ))

    return discovered


def _parse_marker_fields(fields_str: str) -> dict[str, str]:
    """Parse kubebuilder marker key=value fields."""
    result = {}
    for part in re.findall(r'(\w+)=([^,]+)', fields_str):
        result[part[0]] = part[1]
    return result


def discover_conversion_webhooks(
    component_repos: dict[str, Path],
) -> list[WebhookEntry]:
    """Discover conversion webhooks from CRD patches (strategy: Webhook)."""
    discovered = []

    for component, repo_path in component_repos.items():
        is_operator = component in _OPERATOR_COMPONENTS

        try:
            result = subprocess.run(
                [_RG_BIN, "-l", "strategy: Webhook", "--glob", "*.yaml",
                 "--glob", "*.yml", "--glob", "!vendor/*",
                 "--glob", "!test/*", "--glob", "!install/*"],
                cwd=str(repo_path),
                capture_output=True, text=True, timeout=30,
            )
        except (subprocess.TimeoutExpired, FileNotFoundError):
            continue
        if result.returncode != 0:
            continue

        seen_crd_names: set[str] = set()
        for file_path in result.stdout.strip().split("\n"):
            if not file_path:
                continue
            full_path = repo_path / file_path
            try:
                import yaml
                content = yaml.safe_load(full_path.read_text())
            except (yaml.YAMLError, OSError):
                continue

            if not isinstance(content, dict):
                continue
            if content.get("kind") != "CustomResourceDefinition":
                continue

            conv = content.get("spec", {}).get("conversion", {})
            if conv.get("strategy") != "Webhook":
                continue

            # Skip prefetched-manifests for operators
            if is_operator and "prefetched-manifests" in file_path:
                continue

            crd_name = content.get("metadata", {}).get("name", "")

            # Skip duplicates (e.g., config/rhoai/ mirrors config/)
            if crd_name in seen_crd_names:
                continue
            seen_crd_names.add(crd_name)
            wh_config = conv.get("webhook", {})
            client_cfg = wh_config.get("clientConfig", {})
            path = client_cfg.get("service", {}).get("path", "/convert")
            versions = wh_config.get("conversionReviewVersions", [])

            resource = crd_name.split(".")[0] if crd_name else ""
            group = ".".join(crd_name.split(".")[1:]) if "." in crd_name else ""

            sources = [{
                "type": "crd_conversion_patch",
                "file": file_path,
                "repo": repo_path.name,
            }]

            go_file = _find_conversion_go_file(repo_path, group, resource)
            if go_file:
                sources.append({
                    "type": "go_handler", "file": go_file, "repo": repo_path.name,
                })

            conv_name = (
                f"conversion.{crd_name}" if crd_name
                else f"conversion.{file_path}"
            )
            discovered.append(WebhookEntry(
                name=conv_name,
                component=component,
                type="conversion",
                path=path,
                rules=[{
                    "apiGroups": [group] if group else [],
                    "apiVersions": versions,
                    "resources": [resource] if resource else [],
                    "operations": ["CONVERT"],
                }],
                sources=sources,
            ))

    return discovered


def _find_conversion_go_file(repo_path: Path, group: str, resource: str) -> str | None:
    """Find the Go conversion implementation file for a CRD."""
    try:
        result = subprocess.run(
            [_RG_BIN, "-l", r"ConvertTo\b|ConvertFrom\b", "--glob", "*.go",
             "--glob", "!vendor/*", "--glob", "!*_test.go"],
            cwd=str(repo_path),
            capture_output=True, text=True, timeout=15,
        )
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return None
    if result.returncode != 0:
        return None

    resource_stem = resource.rstrip("s") if resource else ""
    group_stem = group.split(".")[0] if group else ""
    for f in result.stdout.strip().split("\n"):
        if not f:
            continue
        lower = f.lower()
        resource_match = not resource_stem or resource_stem in lower
        group_match = not group_stem or group_stem in lower
        if resource_match and group_match:
            return f
    return None


def merge_discovered_webhooks(
    existing: list[WebhookEntry],
    discovered: list[WebhookEntry],
) -> list[WebhookEntry]:
    """Merge Go-discovered webhooks into existing list, filling gaps."""
    existing_names = set()
    existing_paths = set()
    for wh in existing:
        existing_names.add((wh.component, wh.name))
        if wh.path:
            existing_paths.add((wh.component, wh.path))

    added = 0
    for wh in discovered:
        if (wh.component, wh.name) in existing_names:
            continue
        if wh.path and (wh.component, wh.path) in existing_paths:
            continue
        existing.append(wh)
        existing_names.add((wh.component, wh.name))
        if wh.path:
            existing_paths.add((wh.component, wh.path))
        added += 1

    return existing


def resolve_overlays(operator_checkout: Path) -> dict[str, list[str]]:
    """Parse kustomize overlays to find which webhook manifests each includes.

    Returns: {overlay_name: [webhook_manifest_relative_paths]}
    """
    overlay_webhooks: dict[str, list[str]] = {}

    config_dir = operator_checkout / "config"
    if not config_dir.exists():
        return overlay_webhooks

    for overlay_dir in sorted(config_dir.iterdir()):
        if not overlay_dir.is_dir():
            continue
        kustomization = overlay_dir / "kustomization.yaml"
        if not kustomization.exists():
            kustomization = overlay_dir / "kustomization.yml"
        if not kustomization.exists():
            continue

        webhook_files = _find_webhook_resources_in_kustomization(
            overlay_dir, config_dir.parent,
        )
        if webhook_files:
            overlay_webhooks[overlay_dir.name] = webhook_files

    prefetched = operator_checkout / "prefetched-manifests"
    if prefetched.exists():
        for component_dir in sorted(prefetched.iterdir()):
            if not component_dir.is_dir():
                continue
            webhook_dir = component_dir / "webhook"
            if not webhook_dir.exists():
                for sub in component_dir.iterdir():
                    if sub.is_dir():
                        webhook_dir = sub / "webhook"
                        if webhook_dir.exists():
                            break
                else:
                    continue

            for manifest in webhook_dir.glob("manifests.yaml*"):
                rel = str(manifest.relative_to(operator_checkout))
                overlay_webhooks.setdefault("prefetched", []).append(rel)

    return overlay_webhooks


def _find_webhook_resources_in_kustomization(
    kust_dir: Path,
    repo_root: Path,
) -> list[str]:
    """Recursively walk kustomization resources to find webhook-related manifests."""
    webhook_files = []

    kust_file = kust_dir / "kustomization.yaml"
    if not kust_file.exists():
        kust_file = kust_dir / "kustomization.yml"
    if not kust_file.exists():
        return webhook_files

    try:
        import yaml
        content = yaml.safe_load(kust_file.read_text())
    except (yaml.YAMLError, OSError):
        return webhook_files

    if not content:
        return webhook_files

    resources = content.get("resources", [])
    for res in resources:
        res_str = str(res)
        res_path = (kust_dir / res_str).resolve()

        try:
            res_path.relative_to(repo_root.resolve())
        except ValueError:
            continue

        if "webhook" in res_str.lower():
            if res_path.is_file():
                try:
                    webhook_files.append(str(res_path.relative_to(repo_root)))
                except ValueError:
                    webhook_files.append(res_str)
            elif res_path.is_dir():
                sub_files = _find_webhook_resources_in_kustomization(
                    res_path, repo_root,
                )
                webhook_files.extend(sub_files)
                for manifest in res_path.glob("*.yaml"):
                    try:
                        webhook_files.append(str(manifest.relative_to(repo_root)))
                    except ValueError:
                        webhook_files.append(str(manifest))

    return webhook_files


def assign_overlays(
    webhooks: list[WebhookEntry],
    overlay_map: dict[str, list[str]],
) -> None:
    """Set .overlays on each webhook based on which overlays include its manifest."""
    for wh in webhooks:
        manifest_sources = [
            s["file"] for s in wh.sources if s.get("type") == "webhook_manifest"
        ]
        if not manifest_sources:
            continue

        for overlay_name, overlay_files in overlay_map.items():
            for msrc in manifest_sources:
                msrc_parts = Path(msrc).parts
                for ofile in overlay_files:
                    ofile_parts = Path(ofile).parts
                    if (msrc_parts == ofile_parts[-len(msrc_parts):]
                            or ofile_parts == msrc_parts[-len(ofile_parts):]):
                        if overlay_name not in wh.overlays:
                            wh.overlays.append(overlay_name)
                        break


def map_go_handlers(
    checkout_base: Path,
    component_repos: dict[str, Path],
) -> dict[tuple[str, str], list[dict]]:
    """Map webhook paths to Go handler files via kubebuilder markers.

    Returns: {(repo_name, webhook_path): [{type, file, repo, line}]}
    """
    handler_map: dict[tuple[str, str], list[dict]] = {}

    for component, repo_path in component_repos.items():
        if not repo_path.exists():
            continue

        try:
            result = subprocess.run(
                [_RG_BIN, "-n", r"\+kubebuilder:webhook:", "--glob", "*.go",
                 "--no-heading"],
                cwd=str(repo_path),
                capture_output=True, text=True, timeout=30,
            )
        except (subprocess.TimeoutExpired, FileNotFoundError):
            continue

        if result.returncode != 0:
            continue

        for line in result.stdout.strip().split("\n"):
            if not line:
                continue
            match = re.match(r"^(.+?):(\d+):.+path=(/[^,]+)", line)
            if match:
                file_path = match.group(1)
                line_num = int(match.group(2))
                webhook_path = match.group(3)
                key = (component, webhook_path)

                handler_map.setdefault(key, []).append({
                    "type": "kubebuilder_marker",
                    "file": file_path,
                    "repo": repo_path.name,
                    "line": line_num,
                })

                go_handler = _find_handler_in_file(repo_path / file_path)
                if go_handler:
                    handler_map[key].append({
                        "type": "go_handler",
                        "file": file_path,
                        "repo": repo_path.name,
                        "line": go_handler,
                    })

    return handler_map


def _find_handler_in_file(go_file: Path) -> int | None:
    """Find the main handler function line in a Go webhook file."""
    if not go_file.exists():
        return None
    try:
        content = go_file.read_text()
    except OSError:
        return None

    handler_re = (
        r"^func\s+\(.*\)\s+"
        r"(Handle|Default|ValidateCreate|ValidateUpdate)\b"
    )
    for i, line in enumerate(content.split("\n"), 1):
        if re.match(handler_re, line):
            return i
    return None


def assign_go_handlers(
    webhooks: list[WebhookEntry],
    handler_map: dict[tuple[str, str], list[dict]],
) -> None:
    """Enrich webhooks with Go handler source information."""
    for wh in webhooks:
        if not wh.path:
            continue
        for h in handler_map.get((wh.component, wh.path), []):
            already = any(
                s.get("file") == h["file"] and s.get("type") == h["type"]
                for s in wh.sources
            )
            if not already:
                wh.sources.append(h)


def extract_go_patterns(
    webhooks: list[WebhookEntry],
    component_repos: dict[str, Path],
) -> None:
    """Extract enable conditions and data dependencies from Go handler files."""
    for wh in webhooks:
        handler_files = [
            s for s in wh.sources if s.get("type") == "go_handler"
        ]
        if not handler_files:
            continue

        for handler in handler_files:
            repo_name = handler.get("repo", "")
            repo_path = component_repos.get(wh.component)
            if not repo_path:
                for _comp, path in component_repos.items():
                    if path.name == repo_name:
                        repo_path = path
                        break
            if not repo_path:
                continue

            go_file = _safe_join(repo_path, handler["file"])
            if not go_file or not go_file.exists():
                continue

            try:
                content = go_file.read_text()
            except OSError:
                continue

            _extract_data_deps(wh, content)
            _extract_enable_conditions(wh, content, repo_path)


def _extract_data_deps(wh: WebhookEntry, content: str) -> None:
    """Extract data dependencies from Go handler code."""
    get_calls = re.findall(
        r'(?:Client|client|Reader|reader)\.\s*(?:Get|List)\s*\([^)]*&(\w+)',
        content,
    )
    for var in get_calls:
        type_match = re.search(
            rf'{var}\s*(?::=|=)\s*&?(\w+(?:\.\w+)*)\s*\{{',
            content,
        )
        if type_match:
            kind = type_match.group(1).split(".")[-1]
            if not any(d.get("kind") == kind for d in wh.data_read):
                wh.data_read.append({"kind": kind, "usage": "read by webhook handler"})

    workload_configs = re.findall(
        r'(?:WorkloadConfig|workloadConfig)\w*\s*=\s*map\[string\]',
        content,
    )
    if workload_configs:
        if "hardware-profiles" not in wh.cross_cutting_concerns:
            wh.cross_cutting_concerns.append("hardware-profiles")


def _extract_enable_conditions(
    wh: WebhookEntry,
    content: str,
    repo_path: Path,
) -> None:
    """Extract enable conditions from webhook registration code."""
    webhook_go = repo_path / "internal" / "webhook" / "webhook.go"
    if not webhook_go.exists():
        return

    try:
        reg_content = webhook_go.read_text()
    except OSError:
        return

    handler_dir = ""
    for s in wh.sources:
        if s.get("type") == "go_handler":
            parts = s["file"].split("/")
            if "webhook" in parts:
                idx = parts.index("webhook")
                if idx + 1 < len(parts):
                    handler_dir = parts[idx + 1]
            break

    if not handler_dir:
        return

    pattern = rf'name:\s*"{handler_dir}".*?disabled:\s*func\(\)\s*bool\s*\{{([^}}]+)\}}'
    match = re.search(pattern, reg_content, re.DOTALL)
    if match:
        condition_body = match.group(1).strip()
        enabled = re.findall(r'IsEnabled\((\w+(?:\.\w+)*)\)', condition_body)
        if enabled:
            components = [
                e.split(".")[-1].replace("ComponentName", "")
                for e in enabled
            ]
            wh.enable_condition = " OR ".join(
                f"{c} component enabled" for c in components
            )


def build_cross_cutting_map(
    webhooks: list[WebhookEntry],
) -> list[dict]:
    """Group webhooks by shared resource types to identify cross-cutting concerns."""
    resource_webhooks: dict[str, list[WebhookEntry]] = {}
    for wh in webhooks:
        for rule in wh.rules:
            resources = rule.get("resources", rule.get("apiGroups", []))
            if isinstance(resources, list):
                for res in resources:
                    resource_webhooks.setdefault(res, []).append(wh)

    path_groups: dict[str, list[WebhookEntry]] = {}
    for wh in webhooks:
        if wh.path:
            path_groups.setdefault(wh.path, []).append(wh)

    concerns = []
    seen_concerns: set[str] = set()

    for path, group in path_groups.items():
        if len(group) <= 1:
            continue

        all_resources = set()
        all_components = set()
        for wh in group:
            all_components.add(wh.component)
            for rule in wh.rules:
                for res in rule.get("resources", []):
                    all_resources.add(res)

        handler_dirs = set()
        for wh in group:
            for s in wh.sources:
                if s.get("type") == "go_handler":
                    parts = s["file"].split("/")
                    if "webhook" in parts:
                        idx = parts.index("webhook")
                        if idx + 1 < len(parts):
                            handler_dirs.add(parts[idx + 1])

        if handler_dirs:
            concern_name = "-".join(handler_dirs)
        else:
            concern_name = path.strip("/").replace("/", "-")
        if concern_name in seen_concerns:
            continue
        seen_concerns.add(concern_name)

        concerns.append({
            "name": concern_name,
            "webhooks": [wh.name for wh in group],
            "affected_types": sorted(all_resources),
            "affected_components": sorted(all_components),
        })

    for wh in webhooks:
        if wh.cross_cutting_concerns:
            for concern_name in wh.cross_cutting_concerns:
                existing = next(
                    (c for c in concerns if c["name"] == concern_name),
                    None,
                )
                if not existing:
                    affected_resources = set()
                    for rule in wh.rules:
                        for res in rule.get("resources", []):
                            affected_resources.add(res)
                    concerns.append({
                        "name": concern_name,
                        "webhooks": [wh.name],
                        "affected_types": sorted(affected_resources),
                        "affected_components": [wh.component],
                    })
                else:
                    if wh.name not in existing["webhooks"]:
                        existing["webhooks"].append(wh.name)
                    if wh.component not in existing["affected_components"]:
                        existing["affected_components"].append(wh.component)
                        existing["affected_components"].sort()
                    new_types = set()
                    for rule in wh.rules:
                        for res in rule.get("resources", []):
                            new_types.add(res)
                    current = set(existing["affected_types"])
                    if new_types - current:
                        existing["affected_types"] = sorted(
                            current | new_types
                        )

    return concerns


def build_webhook_ref_maps(
    webhooks: list[WebhookEntry],
    component_crds: dict[str, set[tuple[str, str]]],
) -> tuple[dict[str, list[dict]], dict[str, list[dict]]]:
    """Find webhooks from other components that intercept each component's types.

    Splits results into two categories:
    - platform_webhooks: from operator components (rhods-operator, opendatahub-operator)
    - external_webhooks: from peer components

    Returns:
        (platform_map, external_map) — each is {component: [{component, webhook}]}
    """
    resource_to_component: dict[tuple[str, str], set[str]] = {}
    for comp, crds in component_crds.items():
        for crd_key in crds:
            resource_to_component.setdefault(crd_key, set()).add(comp)

    platform_map: dict[str, list[dict]] = {}
    external_map: dict[str, list[dict]] = {}

    for wh in webhooks:
        is_platform = wh.component in _OPERATOR_COMPONENTS
        for rule in wh.rules:
            groups = rule.get("apiGroups", []) or [""]
            for res in rule.get("resources", []):
                for group in groups:
                    key = (group, res)
                    owning_components = resource_to_component.get(
                        key, set(),
                    )
                    for owning_comp in owning_components:
                        if owning_comp == wh.component:
                            continue
                        ref = {
                            "component": wh.component,
                            "webhook": wh.name,
                        }
                        target = (
                            platform_map if is_platform else external_map
                        )
                        existing = target.setdefault(owning_comp, [])
                        if ref not in existing:
                            existing.append(ref)

    return platform_map, external_map


def load_component_crds(
    architecture_dir: str,
    platform_version: str,
    webhooks: list[WebhookEntry] | None = None,
) -> dict[str, set[tuple[str, str]]]:
    """Load CRD (group, resource) pairs per component from architecture JSONs.

    Also derives type ownership from component webhooks — if a component
    defines a webhook targeting a resource type, it owns that type.
    """
    version_dir = Path(architecture_dir) / platform_version
    component_crds: dict[str, set[tuple[str, str]]] = {}

    if not version_dir.exists():
        return component_crds

    for json_file in sorted(version_dir.glob("*.json")):
        if json_file.name in ("component-map.json", "build-info.json", "webhooks.json"):
            continue
        try:
            data = json.loads(json_file.read_text())
        except (json.JSONDecodeError, OSError):
            continue

        component = json_file.stem
        crds: set[tuple[str, str]] = set()

        for crd in data.get("crds", []):
            group = crd.get("group", "")
            res = crd.get("resource", "")
            kind = crd.get("kind", "")
            if res:
                crds.add((group, res))
            if kind:
                crds.add((group, kind.lower() + "s"))
                crds.add((group, kind.lower()))

        for api_type in data.get("api_types", []):
            kind = api_type.get("kind", "")
            if kind:
                crds.add(("", kind.lower() + "s"))
                crds.add(("", kind.lower()))

        if crds:
            component_crds[component] = crds

    if webhooks:
        for wh in webhooks:
            if wh.component in _OPERATOR_COMPONENTS:
                continue
            for rule in wh.rules:
                groups = rule.get("apiGroups", []) or [""]
                for res in rule.get("resources", []):
                    for group in groups:
                        component_crds.setdefault(
                            wh.component, set(),
                        ).add((group, res))

    return component_crds



def enrich_component_json(
    json_path: Path,
    webhooks: list[WebhookEntry],
    platform_refs: list[dict],
    external_refs: list[dict],
) -> None:
    """Enrich a component JSON file's webhooks array in-place.

    Adds platform_webhooks (from operator) and external_webhooks (from peers).
    Existing webhook entries are enriched with new fields. Webhooks discovered
    from Go source that are missing from the arch-analyzer output are appended.
    """
    try:
        data = json.loads(json_path.read_text())
    except (json.JSONDecodeError, OSError):
        return

    component = json_path.stem
    component_webhooks = [wh for wh in webhooks if wh.component == component]
    if not component_webhooks and not platform_refs and not external_refs:
        return

    existing_webhooks = data.get("webhooks", [])

    # Remove prefetched-manifest webhooks from operator components
    if component in _OPERATOR_COMPONENTS:
        existing_webhooks = [wh for wh in existing_webhooks if not _is_prefetched(wh)]

    component_wh_map = {wh.name: wh for wh in component_webhooks}
    path_map = {wh.path: wh for wh in component_webhooks if wh.path}

    existing_names = set()
    existing_paths = set()
    for existing in existing_webhooks:
        wh_name = existing.get("name", "")
        wh_path = existing.get("path", "")
        existing_names.add(wh_name)
        if wh_path:
            existing_paths.add(wh_path)

        enriched = component_wh_map.get(wh_name)
        if not enriched:
            enriched = path_map.get(wh_path)
        if not enriched:
            continue

        if enriched.sources:
            existing["sources"] = enriched.sources
            existing.pop("source", None)
        if enriched.overlays:
            existing["overlays"] = enriched.overlays
        if enriched.enable_condition:
            existing["enable_condition"] = enriched.enable_condition
        if enriched.purpose:
            existing["purpose"] = enriched.purpose
        if enriched.data_read:
            existing["data_read"] = enriched.data_read
        if enriched.cross_cutting_concerns:
            existing["cross_cutting_concerns"] = enriched.cross_cutting_concerns

    for wh in component_webhooks:
        if wh.name in existing_names:
            continue
        if wh.path and wh.path in existing_paths:
            continue
        existing_webhooks.append(wh.to_dict())
        existing_names.add(wh.name)
        if wh.path:
            existing_paths.add(wh.path)

    data["webhooks"] = existing_webhooks

    data.pop("external_webhooks", None)
    data.pop("platform_webhooks", None)
    if platform_refs:
        data["platform_webhooks"] = platform_refs
    if external_refs:
        data["external_webhooks"] = external_refs

    data.pop("platform_capabilities", None)

    json_path.write_text(json.dumps(data, indent=2) + "\n")


def enrich_component_markdown(
    md_path: Path,
    webhooks: list[WebhookEntry],
    platform_refs: list[dict],
    external_refs: list[dict],
) -> None:
    """Add or replace Platform Capabilities and Admission Webhooks sections."""
    component = md_path.stem
    comp_webhooks = [wh for wh in webhooks if wh.component == component]
    if not comp_webhooks and not platform_refs and not external_refs:
        return

    try:
        content = md_path.read_text()
    except OSError:
        return

    section = _build_webhook_markdown_section(
        comp_webhooks, platform_refs, external_refs,
    )
    if section:
        content = _insert_or_replace_section(
            content, "## Admission Webhooks", section,
            before=[
                "## Data Flows", "## Integration Points",
                "## Architectural Analysis",
                "## Recent Changes", "## Source References",
            ],
        )

    md_path.write_text(content)


def _insert_or_replace_section(
    content: str,
    heading: str,
    section: str,
    before: list[str],
) -> str:
    """Insert or replace a markdown section."""
    if heading in content:
        start_idx = content.index(heading)
        end_idx = len(content)
        for candidate in before:
            if candidate == heading:
                continue
            pos = content.find(candidate, start_idx + len(heading))
            if pos != -1 and pos < end_idx:
                end_idx = pos
        return content[:start_idx] + section + "\n" + content[end_idx:]

    for candidate in before:
        if candidate in content:
            pos = content.index(candidate)
            return content[:pos] + section + "\n" + content[pos:]

    return content.rstrip() + "\n\n" + section + "\n"



def _md_cell(text: str) -> str:
    """Sanitize text for use in a markdown table cell."""
    return re.sub(r"\s+", " ", text).replace("|", r"\|").strip()


def _build_webhook_markdown_section(
    webhooks: list[WebhookEntry],
    platform_refs: list[dict],
    external_refs: list[dict],
) -> str:
    """Build the Admission Webhooks markdown section."""
    lines = ["## Admission Webhooks", ""]

    if webhooks:
        mutating = [w for w in webhooks if w.type == "mutating"]
        validating = [w for w in webhooks if w.type == "validating"]
        conversion = [w for w in webhooks if w.type == "conversion"]

        lines.append(f"This component defines {len(webhooks)} webhook(s)"
                     f" ({len(mutating)} mutating, {len(validating)} validating"
                     f"{f', {len(conversion)} conversion' if conversion else ''}).")
        lines.append("")

        lines.append("| Name | Type | Target Resources | Purpose |")
        lines.append("|------|------|-----------------|---------|")
        for wh in webhooks:
            resources = []
            for rule in wh.rules:
                resources.extend(rule.get("resources", []))
            res_str = ", ".join(resources) if resources else ""
            purpose = wh.purpose or ""
            name = _md_cell(wh.name)
            wh_type = _md_cell(wh.type)
            res_str = _md_cell(res_str)
            purpose = _md_cell(purpose)
            lines.append(f"| {name} | {wh_type} | {res_str} | {purpose} |")
        lines.append("")

    if platform_refs:
        lines.append("### Platform Webhooks")
        lines.append("")
        lines.append(
            "The following webhooks are defined by the platform"
            " operator and apply to this component's resource types:"
        )
        lines.append("")
        lines.append("| Webhook | Defined By |")
        lines.append("|---------|-----------|")
        for ref in platform_refs:
            wh = _md_cell(ref.get('webhook', ''))
            comp = _md_cell(ref.get('component', ''))
            lines.append(f"| {wh} | {comp} |")
        lines.append("")

    if external_refs:
        lines.append("### External Webhooks")
        lines.append("")
        lines.append(
            "The following webhooks from peer components"
            " intercept this component's resource types:"
        )
        lines.append("")
        lines.append("| Webhook | Defined By |")
        lines.append("|---------|-----------|")
        for ref in external_refs:
            wh = _md_cell(ref.get('webhook', ''))
            comp = _md_cell(ref.get('component', ''))
            lines.append(f"| {wh} | {comp} |")
        lines.append("")

    return "\n".join(lines)


async def run_webhook_agent_analysis(
    webhooks: list[WebhookEntry],
    component_repos: dict[str, Path],
    model: str = "sonnet",
    max_concurrent: int = 5,
) -> None:
    """Spawn Claude agents to analyze Go webhook handler code.

    For each unique handler file, an agent reads the Go source and writes
    a JSON file with purpose, data_read, and hidden_details. Results are
    merged back into the webhook entries.
    """
    from lib.agent_runner import run_agents_concurrently

    handler_groups: dict[tuple[str, str], list[WebhookEntry]] = {}
    for wh in webhooks:
        for s in wh.sources:
            if s.get("type") != "go_handler":
                continue
            repo_name = s.get("repo", "")
            file_path = s.get("file", "")
            if not file_path:
                continue
            repo_path = None
            for _comp, path in component_repos.items():
                if path.name == repo_name:
                    repo_path = path
                    break
            if not repo_path:
                repo_path = component_repos.get(wh.component)
            if not repo_path:
                continue
            full_path = _safe_join(repo_path, file_path)
            if not full_path or not full_path.exists():
                continue

            key = (str(repo_path), file_path)
            handler_groups.setdefault(key, []).append(wh)

    if not handler_groups:
        print("  No Go handler files to analyze")
        return

    log_dir = Path("logs/webhook-analysis")
    log_dir.mkdir(parents=True, exist_ok=True)

    jobs = []
    for (repo_dir, go_file), wh_group in handler_groups.items():
        webhook_names = ", ".join(wh.name for wh in wh_group)
        safe_name = go_file.replace("/", "_").replace(".go", "")
        tmp = tempfile.NamedTemporaryFile(
            delete=False, suffix=".json",
            prefix=f"webhook-analysis-{safe_name}-",
        )
        tmp.close()
        output_file = tmp.name

        full_path = Path(repo_dir) / go_file
        file_lines = 0
        try:
            file_lines = len(full_path.read_text().split("\n"))
        except OSError:
            pass

        if file_lines > 500:
            prompt = _build_large_file_prompt(
                go_file, webhook_names, output_file, full_path,
            )
        else:
            prompt = _build_analysis_prompt(go_file, webhook_names, output_file)

        jobs.append({
            "name": f"webhook:{safe_name}",
            "cwd": repo_dir,
            "prompt": prompt,
            "_output_file": output_file,
            "_webhooks": wh_group,
            "_go_file": go_file,
        })

    print(f"  Analyzing {len(jobs)} unique handler files with {model} agents")
    results = await run_agents_concurrently(
        jobs, log_dir, model, max_concurrent,
    )

    analyzed = 0
    for job, result in zip(jobs, results, strict=True):
        output_file = Path(job["_output_file"])
        try:
            if isinstance(result, Exception):
                continue
            if isinstance(result, dict) and not result.get("success"):
                continue

            analysis = None
            if output_file.exists():
                try:
                    analysis = json.loads(output_file.read_text())
                except (json.JSONDecodeError, OSError):
                    pass

            if analysis is None:
                log_file = log_dir / f"{job['name'].replace('/', '_')}.log"
                analysis = _parse_json_from_log(log_file)

            if not isinstance(analysis, dict):
                continue

            purpose = str(analysis.get("purpose", ""))
            data_read = analysis.get("data_read", [])
            if not isinstance(data_read, list):
                data_read = []
            data_read = [d for d in data_read if isinstance(d, dict)]

            for wh in job["_webhooks"]:
                if not wh.purpose:
                    wh.purpose = purpose
                for dep in data_read:
                    if not any(d.get("kind") == dep.get("kind") for d in wh.data_read):
                        wh.data_read.append(dep)
        finally:
            output_file.unlink(missing_ok=True)

        analyzed += 1

    print(f"  Successfully analyzed {analyzed}/{len(jobs)} handler files")


def _parse_json_from_log(log_file: Path) -> dict | None:
    """Extract JSON analysis from agent log as fallback when file wasn't written."""
    if not log_file.exists():
        return None
    try:
        content = log_file.read_text()
    except OSError:
        return None

    pattern = r'\{[^{}]*"purpose"[^{}]*"data_read"[^{}]*\[.*?\]\s*\}'
    for match in re.finditer(pattern, content, re.DOTALL):
        try:
            return json.loads(match.group(0))
        except json.JSONDecodeError:
            continue

    for match in re.finditer(r"```(?:json)?\s*(\{.*?\})\s*```", content, re.DOTALL):
        try:
            return json.loads(match.group(1))
        except json.JSONDecodeError:
            continue

    return None


def _extraction_instructions() -> str:
    purpose = (
        "One or two sentences. What does this webhook do"
        " and why? Be specific about the business logic."
    )
    data_read = (
        "Kubernetes resources fetched via"
        " client.Get/List/APIReader during webhook"
        " execution. Just kind and group."
    )
    return (
        "Extract:\n\n"
        f"1. **purpose**: {purpose}\n\n"
        f"2. **data_read**: {data_read}\n\n"
        "Write ONLY this JSON — no other files:\n"
        "```json\n"
        "{{\n"
        '  "purpose": "...",\n'
        '  "data_read": [\n'
        '    {{"kind": "...", "group": "..."}}\n'
        "  ]\n"
        "}}\n"
        "```"
    )


def _build_analysis_prompt(
    go_file: str, webhook_names: str, output_file: str,
) -> str:
    instructions = _extraction_instructions()
    return (
        f"Read `{go_file}` and write a JSON file"
        f" to `{output_file}`.\n\n"
        f"This handler implements: {webhook_names}\n\n"
        f"{instructions}"
    )


def _build_large_file_prompt(
    go_file: str,
    webhook_names: str,
    output_file: str,
    full_path: Path,
) -> str:
    """Build prompt for large Go files by extracting key sections inline."""
    try:
        content = full_path.read_text()
    except OSError:
        return _build_analysis_prompt(go_file, webhook_names, output_file)

    lines = content.split("\n")
    key_lines = []

    for i, line in enumerate(lines):
        stripped = line.strip()
        if any(kw in stripped for kw in [
            "type ", "func ", "client.Get", "client.List",
            "Client.Get", "Client.List", "Reader.Get", "APIReader",
            "WorkloadConfig", "Annotation", "const ",
            "var ", "Handle(", "Default(", "Validate",
            "+kubebuilder:webhook:",
        ]):
            start = max(0, i - 1)
            end = min(len(lines), i + 2)
            for j in range(start, end):
                if j not in [kl[0] for kl in key_lines]:
                    key_lines.append((j, lines[j]))

    key_lines.sort(key=lambda x: x[0])
    excerpt = "\n".join(
        f"{num + 1}: {line}" for num, line in key_lines[:200]
    )
    line_count = len(lines)
    instructions = _extraction_instructions()
    read_hint = (
        f"If you need more context, read specific line"
        f" ranges from `{go_file}` using the Read tool."
    )
    return (
        f"Analyze the webhook handler in `{go_file}`"
        f" (large file, {line_count} lines).\n"
        f"Write a JSON file to `{output_file}`.\n\n"
        f"This handler implements: {webhook_names}\n\n"
        f"Key lines extracted from the file:\n"
        f"```go\n{excerpt}\n```\n\n"
        f"{read_hint}\n\n"
        f"{instructions}"
    )


def write_platform_webhooks(
    architecture_dir: str,
    platform_version: str,
    webhooks: list[WebhookEntry],
    cross_cutting: list[dict],
    overlays_analyzed: list[str],
) -> Path:
    """Write the platform-wide webhooks.json."""
    version_dir = Path(architecture_dir) / platform_version
    version_dir.mkdir(parents=True, exist_ok=True)
    output_path = version_dir / "webhooks.json"

    mutating = sum(1 for w in webhooks if w.type == "mutating")
    validating = sum(1 for w in webhooks if w.type == "validating")
    components_with_webhooks = len({w.component for w in webhooks})

    result: dict[str, Any] = {
        "metadata": {
            "platform_version": platform_version,
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "overlays_analyzed": overlays_analyzed,
        },
        "summary": {
            "total": len(webhooks),
            "mutating": mutating,
            "validating": validating,
            "components_with_webhooks": components_with_webhooks,
        },
        "cross_cutting_concerns": cross_cutting,
        "webhooks": [w.to_dict() for w in webhooks],
    }

    output_path.write_text(json.dumps(result, indent=2) + "\n")
    return output_path
