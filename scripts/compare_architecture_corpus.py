#!/usr/bin/env python3
"""Prepare, snapshot, and compare an analyzer-first architecture corpus run."""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
import time
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from statistics import median
from typing import Any

import yaml

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from lib.architecture_baseline import (  # noqa: E402
    NON_ARCHITECTURE_CATEGORIES,
    REQUIRED_H2_SECTIONS,
    SYNTHESIS_SECTIONS,
    compare_component_documents,
    parse_component_markdown,
)
from lib.component_discovery import (  # noqa: E402
    apply_platform_overrides,
    read_component_map,
)

SKIP_DOCUMENTS = frozenset({"PLATFORM.md", "README.md"})
READINESS_LEVELS = frozenset({"sufficient", "partial", "insufficient"})
VERSION_RE = re.compile(r"^- \*\*Version\*\*:\s*(.+?)\s*$", re.MULTILINE)
VERSION_SHA_RE = re.compile(r"(?:-g|@)([0-9a-f]{7,40})\b", re.IGNORECASE)
FAILED_RE = re.compile(r"^Failed:\s*(\d+)\s*$", re.MULTILINE)
SYNTHESIS_WORD_RE = re.compile(r"\b[\w][\w'-]*\b")
DETAILED_SYNTHESIS_WORD_MINIMUM = 80
ANALYZER_ONLY_SYNTHESIS_WORD_MINIMUM = 200
HIGH_VALUE_STRUCTURED_CATEGORIES = (
    "architecture_components",
    "authentication",
    "integration_points",
    "internal_dependencies",
)


def utc_now() -> str:
    """Return an RFC 3339-compatible UTC timestamp."""
    return datetime.now(timezone.utc).isoformat()


def _write_json(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")
    temporary.replace(path)


def _read_json(path: str | Path) -> dict[str, Any]:
    return json.loads(Path(path).read_text())


def load_merge_artifacts(directory: str | Path) -> dict[str, Any]:
    """Collect merge adjudications and agent telemetry from a log directory."""

    root = Path(directory)
    accepted_conflicts = []
    accepted_deletions = []
    merges = {}
    runs = {}
    errors = []
    if not root.is_dir():
        return {
            "accepted_conflicts": [],
            "accepted_deletions": [],
            "merges": {},
            "runs": {},
            "errors": [f"merge report directory not found: {root}"],
        }
    for path in sorted(root.glob("*.merge.json")):
        try:
            data = _read_json(path)
        except (OSError, json.JSONDecodeError) as error:
            errors.append(f"{path.name}: {error}")
            continue
        component = path.name.removesuffix(".merge.json")
        entries = data.get("accepted_conflicts", [])
        if not isinstance(entries, list):
            errors.append(f"{path.name}: accepted_conflicts must be a list")
            entries = []
        accepted_conflicts.extend(entries)
        deletions = data.get("accepted_deletions")
        if deletions is None:
            # Older merge reports retain enough decision data to reconstruct these.
            deletions = [
                {
                    "component": component,
                    "category": decision.get("category"),
                    "key": decision.get("key"),
                    "reason": decision.get("reason"),
                    "evidence": decision.get("evidence"),
                }
                for decision in data.get("decisions", [])
                if isinstance(decision, dict)
                and decision.get("status") == "applied"
                and decision.get("action") == "delete"
            ]
        if not isinstance(deletions, list):
            errors.append(f"{path.name}: accepted_deletions must be a list")
            deletions = []
        accepted_deletions.extend(deletions)
        merges[component] = {
            "counts": data.get("counts", {}),
            "parse_errors": data.get("parse_errors", []),
            "accepted_conflicts": len(entries),
            "accepted_deletions": len(deletions),
        }
    for path in sorted(root.glob("*.run.json")):
        try:
            data = _read_json(path)
        except (OSError, json.JSONDecodeError) as error:
            errors.append(f"{path.name}: {error}")
            continue
        component = str(data.get("component") or path.name.removesuffix(".run.json"))
        runs[component] = data
    return {
        "accepted_conflicts": accepted_conflicts,
        "accepted_deletions": accepted_deletions,
        "merges": merges,
        "runs": runs,
        "errors": errors,
    }


def _combined_adjudications(
    manual: dict[str, Any] | None,
    merge_artifacts: dict[str, Any] | None,
) -> dict[str, Any]:
    accepted = []
    deleted = []
    for source in (manual or {}, merge_artifacts or {}):
        entries = source.get("accepted_conflicts", [])
        if isinstance(entries, list):
            accepted.extend(entries)
        entries = source.get("accepted_deletions", [])
        if isinstance(entries, list):
            deleted.extend(entries)
    return {
        "schema_version": 1,
        "accepted_conflicts": accepted,
        "accepted_deletions": deleted,
    }


def paths_overlap(left: str | Path, right: str | Path) -> bool:
    """Return whether either resolved path contains the other."""
    left_path = Path(left).resolve()
    right_path = Path(right).resolve()
    return (
        left_path == right_path
        or left_path in right_path.parents
        or right_path in left_path.parents
    )


def _git_value(checkout: Path, *args: str) -> str:
    try:
        result = subprocess.run(
            ["git", *args],
            cwd=checkout,
            capture_output=True,
            text=True,
            timeout=15,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired):
        return ""
    return result.stdout.strip() if result.returncode == 0 else ""


def _repository_revision(checkout: Path) -> dict[str, Any]:
    if not checkout.is_dir():
        return {"available": False, "checkout_path": str(checkout)}
    commit = _git_value(checkout, "rev-parse", "HEAD")
    if not commit:
        return {
            "available": True,
            "checkout_path": str(checkout),
            "git_repository": False,
        }
    dirty = bool(_git_value(checkout, "status", "--porcelain"))
    return {
        "available": True,
        "checkout_path": str(checkout),
        "git_repository": True,
        "commit_sha": commit,
        "branch": _git_value(checkout, "rev-parse", "--abbrev-ref", "HEAD"),
        "remote_url": _git_value(checkout, "remote", "get-url", "origin"),
        "dirty": dirty,
    }


def initialize_run(
    *,
    repo_root: str | Path,
    source_architecture_dir: str | Path,
    platform: str,
    platforms_file: str | Path,
    baseline_dir: str | Path,
    run_dir: str | Path,
    model: str,
    workers: int,
    prior_wall_seconds: float,
    component_names: tuple[str, ...] = (),
) -> dict[str, Any]:
    """Create a fresh run tree and capture configuration and revisions."""
    root = Path(repo_root).resolve()
    source_architecture = Path(source_architecture_dir).resolve()
    baseline = Path(baseline_dir).resolve()
    destination = Path(run_dir).resolve()
    candidate = destination / "architecture" / platform
    analyzer = destination / "analyzer" / platform
    source_map = source_architecture / platform / "component-map.json"
    platform_config_path = Path(platforms_file).resolve()

    if destination.exists():
        raise ValueError(f"Run directory already exists: {destination}")
    if not baseline.is_dir():
        raise ValueError(f"Baseline directory not found: {baseline}")
    if not source_map.is_file():
        raise ValueError(f"Component map not found: {source_map}")
    if paths_overlap(baseline, candidate):
        raise ValueError(
            "Baseline and candidate directories overlap: "
            f"{baseline} and {candidate}"
        )
    if workers <= 0:
        raise ValueError("Worker count must be greater than zero")

    platform_data = yaml.safe_load(platform_config_path.read_text()) or {}
    platform_config = platform_data.get(platform)
    if not isinstance(platform_config, dict):
        raise ValueError(f"Platform {platform!r} not found in {platform_config_path}")

    destination.mkdir(parents=True)
    candidate.mkdir(parents=True)
    analyzer.mkdir(parents=True)
    (destination / "logs").mkdir()
    (destination / "reports").mkdir()
    adjudications_path = destination / "preservation-adjudications.json"
    _write_json(
        adjudications_path,
        {"schema_version": 1, "accepted_conflicts": []},
    )

    components = read_component_map(
        platform, architecture_dir=str(source_architecture),
    )
    if components is None:
        raise ValueError(f"Unable to read component map: {source_map}")
    components = apply_platform_overrides(
        components,
        platform_config,
        checkouts_base=str(root / "checkouts"),
    )
    if component_names:
        requested = set(component_names)
        missing = sorted(requested - set(components))
        if missing:
            raise ValueError(
                "Components not found after platform overrides: "
                + ", ".join(missing)
            )
        components = {
            key: component
            for key, component in components.items()
            if key in requested
        }

    component_map = _read_json(source_map)
    raw_components = component_map.get("components", {})
    if not isinstance(raw_components, dict):
        raise ValueError(f"Invalid component map: {source_map}")
    component_map["components"] = {
        key: raw_components[key]
        for key in sorted(components)
        if key in raw_components
    }
    metadata = component_map.get("metadata")
    if isinstance(metadata, dict):
        metadata["components_selected"] = len(components)
        metadata["selected_components"] = sorted(components)
    _write_json(candidate / "component-map.json", component_map)

    repositories: dict[str, Any] = {}
    for key, component in sorted(components.items()):
        checkout = component.checkout_path
        if checkout is None:
            revision = {"available": False, "checkout_path": None}
        else:
            if not checkout.is_absolute():
                checkout = root / checkout
            revision = _repository_revision(checkout.resolve())
        revision.update(
            {
                "repo_org": component.repo_org,
                "repo_name": component.repo_name,
                "requested_ref": component.ref,
            }
        )
        repositories[key] = revision

    started_epoch = time.time()
    manifest = {
        "schema_version": 1,
        "status": "initialized",
        "platform": platform,
        "model": model,
        "workers": workers,
        "components": sorted(components),
        "prior_wall_seconds": prior_wall_seconds,
        "started_at": datetime.fromtimestamp(
            started_epoch, timezone.utc,
        ).isoformat(),
        "started_epoch": started_epoch,
        "paths": {
            "repo_root": str(root),
            "source_architecture_dir": str(source_architecture),
            "baseline_dir": str(baseline),
            "candidate_dir": str(candidate),
            "analyzer_dir": str(analyzer),
            "run_dir": str(destination),
            "reports_dir": str(destination / "reports"),
            "logs_dir": str(destination / "logs"),
            "component_map": str(candidate / "component-map.json"),
            "platforms_file": str(platform_config_path),
            "preservation_adjudications": str(adjudications_path),
        },
        "platform_config": platform_config,
        "repositories": repositories,
        "phases": {},
    }
    _write_json(destination / "run.json", manifest)
    return manifest


def record_phase(
    manifest_path: str | Path,
    *,
    phase: str,
    started_at: str,
    ended_at: str,
    started_epoch: float,
    ended_epoch: float,
    wall_seconds: float,
    exit_code: int,
    command: str,
    log_path: str,
) -> dict[str, Any]:
    """Add one measured pipeline phase to a run manifest."""
    path = Path(manifest_path)
    manifest = _read_json(path)
    log = Path(log_path)
    failures = None
    if log.is_file():
        matches = FAILED_RE.findall(log.read_text(errors="replace"))
        if matches:
            failures = int(matches[-1])
    manifest.setdefault("phases", {})[phase] = {
        "started_at": started_at,
        "ended_at": ended_at,
        "started_epoch": started_epoch,
        "ended_epoch": ended_epoch,
        "wall_seconds": wall_seconds,
        "exit_code": exit_code,
        "reported_failures": failures,
        "command": command,
        "log_path": str(log.resolve()),
    }
    manifest["status"] = "failed" if exit_code else f"{phase}_complete"
    _write_json(path, manifest)
    return manifest


def snapshot_analyzers(manifest_path: str | Path) -> dict[str, Any]:
    """Copy analyzer Markdown and JSON into the run tree.

    Current static-analysis output lives in the candidate architecture tree.
    The checkout-root fallback keeps this helper compatible with older runs.
    """
    path = Path(manifest_path)
    manifest = _read_json(path)
    analyzer_dir = Path(manifest["paths"]["analyzer_dir"])
    candidate_dir_value = manifest["paths"].get("candidate_dir")
    candidate_dir = Path(candidate_dir_value) if candidate_dir_value else None
    analyzer_dir.mkdir(parents=True, exist_ok=True)
    copied: list[str] = []
    missing: dict[str, list[str]] = {}

    for component, repository in sorted(manifest["repositories"].items()):
        checkout_value = repository.get("checkout_path")
        if not repository.get("available"):
            continue

        source_roots: list[Path] = []
        if candidate_dir is not None:
            source_roots.append(candidate_dir / component / ".analyzer")
        if checkout_value:
            source_roots.append(Path(checkout_value))

        source_pair = next(
            (
                (
                    root / "analyzer_architecture.md",
                    root / "component-architecture.json",
                )
                for root in source_roots
                if (root / "analyzer_architecture.md").is_file()
                and (root / "component-architecture.json").is_file()
            ),
            None,
        )
        if source_pair is None:
            reference_root = source_roots[0] if source_roots else Path()
            missing[component] = [
                name
                for name in ("analyzer_architecture.md", "component-architecture.json")
                if not (reference_root / name).is_file()
            ]
            continue
        markdown, analyzer_json = source_pair
        shutil.copy2(markdown, analyzer_dir / f"{component}.md")
        shutil.copy2(analyzer_json, analyzer_dir / f"{component}.json")
        copied.append(component)

    snapshot = {
        "expected": sum(
            bool(repository.get("available"))
            for repository in manifest["repositories"].values()
        ),
        "copied": len(copied),
        "components": copied,
        "missing": missing,
        "captured_at": utc_now(),
    }
    manifest["analyzer_snapshot"] = snapshot
    manifest["status"] = (
        "analyzer_snapshot_failed" if missing else "analyzer_snapshot_complete"
    )
    _write_json(path, manifest)
    snapshot_path = (
        Path(manifest["paths"]["reports_dir"]) / "analyzer-snapshot.json"
    )
    _write_json(snapshot_path, snapshot)
    return snapshot


def _discover_documents(directory: Path) -> dict[str, Path]:
    if not directory.is_dir():
        return {}
    return {
        path.stem: path
        for path in sorted(directory.glob("*.md"))
        if path.name not in SKIP_DOCUMENTS
    }


def _component_summary(report) -> dict[str, Any]:
    return {
        "baseline": report.baseline,
        "candidate": report.candidate,
        "baseline_rows": report.baseline_rows,
        "matched_rows": report.matched_rows,
        "row_recall": report.row_recall,
        "structured_baseline_rows": report.structured_baseline_rows,
        "structured_matched_rows": report.structured_matched_rows,
        "structured_row_recall": report.structured_row_recall,
        "conflict_count": report.conflict_count,
        "missing_required_sections": report.missing_required_sections,
        "missing_synthesis_sections": report.missing_synthesis_sections,
        "categories": [category for category in report.to_dict()["categories"]],
    }


def _aggregate_comparisons(
    baseline_documents: dict[str, Path],
    candidate_documents: dict[str, Path],
    *,
    threshold: float,
) -> dict[str, Any]:
    baseline_names = set(baseline_documents)
    candidate_names = set(candidate_documents)
    matched_names = sorted(baseline_names & candidate_names)
    component_reports: dict[str, Any] = {}
    category_totals: dict[str, dict[str, int]] = defaultdict(
        lambda: {
            "baseline_rows": 0,
            "candidate_rows": 0,
            "matched_rows": 0,
            "conflicts": 0,
        }
    )
    recalls: list[float] = []
    baseline_rows = matched_rows = 0
    structured_baseline = structured_matched = 0
    conflicts = 0

    for component in matched_names:
        report = compare_component_documents(
            parse_component_markdown(baseline_documents[component]),
            parse_component_markdown(candidate_documents[component]),
        )
        summary = _component_summary(report)
        component_reports[component] = summary
        recalls.append(report.structured_row_recall)
        baseline_rows += report.baseline_rows
        matched_rows += report.matched_rows
        structured_baseline += report.structured_baseline_rows
        structured_matched += report.structured_matched_rows
        conflicts += report.conflict_count
        for category in report.categories:
            aggregate = category_totals[category.category]
            aggregate["baseline_rows"] += category.baseline_rows
            aggregate["candidate_rows"] += category.candidate_rows
            aggregate["matched_rows"] += category.matched_rows
            aggregate["conflicts"] += len(category.conflicts)

    categories = {}
    for name, values in sorted(category_totals.items()):
        denominator = values["baseline_rows"]
        categories[name] = {
            **values,
            "row_recall": values["matched_rows"] / denominator if denominator else 1.0,
        }

    separate = {
        name: categories.get(
            name,
            {
                "baseline_rows": 0,
                "candidate_rows": 0,
                "matched_rows": 0,
                "conflicts": 0,
                "row_recall": 1.0,
            },
        )
        for name in sorted(NON_ARCHITECTURE_CATEGORIES)
    }
    return {
        "baseline_document_count": len(baseline_names),
        "candidate_document_count": len(candidate_names),
        "matched_document_count": len(matched_names),
        "missing_documents": sorted(baseline_names - candidate_names),
        "extra_documents": sorted(candidate_names - baseline_names),
        "baseline_rows": baseline_rows,
        "matched_rows": matched_rows,
        "row_recall": matched_rows / baseline_rows if baseline_rows else 1.0,
        "structured_baseline_rows": structured_baseline,
        "structured_matched_rows": structured_matched,
        "structured_row_recall": (
            structured_matched / structured_baseline
            if structured_baseline else 1.0
        ),
        "median_component_structured_recall": median(recalls) if recalls else 0.0,
        "component_threshold": threshold,
        "components_below_threshold": [
            name
            for name, report in component_reports.items()
            if report["structured_row_recall"] < threshold
        ],
        "conflict_count": conflicts,
        "categories": categories,
        "non_architecture_categories": separate,
        "components": component_reports,
    }


def _validate_document(path: Path) -> list[str]:
    document = parse_component_markdown(path)
    h2_sections = set(document.h2_sections)
    headings = {title.casefold() for _, title in document.headings}
    errors = [
        f"missing required section: ## {section}"
        for section in REQUIRED_H2_SECTIONS
        if section not in h2_sections
    ]
    errors.extend(
        f"missing synthesis section: {section}"
        for section in SYNTHESIS_SECTIONS
        if section.casefold() not in headings
    )

    for table in document.tables:
        if table.section.casefold() != "custom resource definitions (crds)":
            continue
        for row_index, row in enumerate(table.rows, start=1):
            if not any(cell.strip() for cell in row):
                continue
            required = [
                row[index].strip() if index < len(row) else ""
                for index in range(4)
            ]
            if not all(required):
                errors.append(
                    "incomplete CRD identity in row "
                    f"{row_index}: group, version, kind, and scope are required"
                )
    return errors


def _synthesis_structure_quality(
    documents: dict[str, Path],
    runs: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """Detect detailed prose that is inconsistent with sparse core tables."""

    components = {}
    failed = []
    synthesis_sections = {section.casefold() for section in SYNTHESIS_SECTIONS}
    for component, path in sorted(documents.items()):
        document = parse_component_markdown(path)
        synthesis = "\n".join(
            text
            for section, text in document.section_text.items()
            if section and section[-1].casefold() in synthesis_sections
        )
        word_count = len(SYNTHESIS_WORD_RE.findall(synthesis))
        self_comparison = compare_component_documents(document, document)
        row_counts = {
            category.category: category.candidate_rows
            for category in self_comparison.categories
        }
        empty = [
            category
            for category in HIGH_VALUE_STRUCTURED_CATEGORIES
            if row_counts.get(category, 0) == 0
        ]
        unexpectedly_sparse = (
            word_count >= DETAILED_SYNTHESIS_WORD_MINIMUM
            and "architecture_components" in empty
            and len(empty) >= 3
        )
        route = str(
            (runs or {}).get(component, {}).get("routing", {}).get("route", "")
        )
        analyzer_only = route == "analyzer-only"
        pending_placeholder = (
            "pending constrained synthesis" in synthesis.casefold()
        )
        analyzer_only_too_short = (
            analyzer_only
            and word_count < ANALYZER_ONLY_SYNTHESIS_WORD_MINIMUM
        )
        failure_reasons = []
        if unexpectedly_sparse:
            failure_reasons.append("detailed synthesis has sparse high-value tables")
        if analyzer_only and pending_placeholder:
            failure_reasons.append(
                "analyzer-only synthesis contains a pending placeholder"
            )
        if analyzer_only_too_short:
            failure_reasons.append(
                "analyzer-only synthesis is below the minimum word count"
            )
        components[component] = {
            "synthesis_word_count": word_count,
            "empty_high_value_categories": empty,
            "route": route or "unknown",
            "failure_reasons": failure_reasons,
            "passed": not failure_reasons,
        }
        if failure_reasons:
            failed.append(component)
    return {
        "minimum_synthesis_words": DETAILED_SYNTHESIS_WORD_MINIMUM,
        "analyzer_only_minimum_synthesis_words": (
            ANALYZER_ONLY_SYNTHESIS_WORD_MINIMUM
        ),
        "components": components,
        "failed_components": failed,
        "passed": bool(documents) and not failed,
    }


def _load_analyzer_metadata(analyzer_dir: Path, component: str) -> dict[str, Any]:
    path = analyzer_dir / f"{component}.json"
    if not path.is_file():
        return {
            "readiness": "unknown",
            "readiness_detail": "analyzer JSON missing",
            "commit_sha": "",
        }
    try:
        data = _read_json(path)
    except (OSError, json.JSONDecodeError) as error:
        return {
            "readiness": "unknown",
            "readiness_detail": f"invalid analyzer JSON: {error}",
            "commit_sha": "",
        }
    coverage = data.get("data_coverage", {}).get("agent_baseline", "")
    readiness = coverage.split(":", 1)[0].strip().casefold()
    if readiness not in READINESS_LEVELS:
        readiness = "unknown"
    return {
        "readiness": readiness,
        "readiness_detail": coverage,
        "commit_sha": str(data.get("commit_sha", "")),
    }


def _baseline_version(path: Path | None) -> tuple[str, str]:
    if path is None or not path.is_file():
        return "", ""
    match = VERSION_RE.search(path.read_text(errors="replace"))
    version = match.group(1) if match else ""
    sha_match = VERSION_SHA_RE.search(version)
    return version, sha_match.group(1) if sha_match else ""


def _revision_status(baseline_sha: str, current_sha: str) -> str:
    if not baseline_sha or not current_sha:
        return "unknown"
    return (
        "same"
        if current_sha.casefold().startswith(baseline_sha.casefold())
        else "different"
    )


def compare_corpus(
    baseline_dir: str | Path,
    candidate_dir: str | Path,
    analyzer_dir: str | Path,
    *,
    component_threshold: float = 0.95,
    run_manifest: dict[str, Any] | None = None,
    preservation_adjudications: dict[str, Any] | None = None,
    merge_artifacts: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """Compare fixture fidelity, analyzer preservation, and document validity."""
    baseline_path = Path(baseline_dir).resolve()
    candidate_path = Path(candidate_dir).resolve()
    analyzer_path = Path(analyzer_dir).resolve()
    if paths_overlap(baseline_path, candidate_path):
        raise ValueError(
            "Baseline and candidate directories overlap: "
            f"{baseline_path} and {candidate_path}"
        )
    if not 0.0 <= component_threshold <= 1.0:
        raise ValueError("Component threshold must be between 0 and 1")

    baseline_documents = _discover_documents(baseline_path)
    candidate_documents = _discover_documents(candidate_path)
    analyzer_documents = _discover_documents(analyzer_path)
    fixture = _aggregate_comparisons(
        baseline_documents,
        candidate_documents,
        threshold=component_threshold,
    )

    preservation = _aggregate_comparisons(
        analyzer_documents,
        candidate_documents,
        threshold=1.0,
    )
    adjudication = _adjudicate_preservation_conflicts(
        preservation,
        _combined_adjudications(preservation_adjudications, merge_artifacts),
    )
    preservation["accepted_conflicts"] = adjudication["accepted"]
    preservation["accepted_deletions"] = adjudication["accepted_deletions"]
    preservation["unexplained_conflicts"] = adjudication["unexplained"]
    preservation["unexplained_missing_rows"] = adjudication[
        "unexplained_missing_rows"
    ]
    preservation["invalid_adjudications"] = adjudication["invalid"]
    preservation["merge_adjudications"] = list(
        (merge_artifacts or {}).get("accepted_conflicts", [])
    )
    unexplained_components = {
        conflict["component"] for conflict in adjudication["unexplained"]
    }
    unexplained_components.update(
        deletion["component"]
        for deletion in adjudication["unexplained_missing_rows"]
    )
    preservation_failures = [
        name
        for name, component in preservation["components"].items()
        if name in unexplained_components
    ]
    preservation["failed_components"] = preservation_failures
    preservation["passed"] = not (
        preservation["missing_documents"]
        or preservation["extra_documents"]
        or preservation_failures
        or adjudication["invalid"]
        or not analyzer_documents
        or not candidate_documents
    )

    structural_errors = {
        component: errors
        for component, path in candidate_documents.items()
        if (errors := _validate_document(path))
    }
    structural = {
        "validated_documents": len(candidate_documents),
        "failed_documents": sorted(structural_errors),
        "errors": structural_errors,
        "passed": bool(candidate_documents) and not structural_errors,
    }
    generation_runs = (merge_artifacts or {}).get("runs", {})
    synthesis_quality = _synthesis_structure_quality(
        candidate_documents,
        generation_runs,
    )

    readiness_components = {}
    readiness_counts: Counter[str] = Counter()
    revisions = {}
    for component in sorted(set(candidate_documents) | set(analyzer_documents)):
        metadata = _load_analyzer_metadata(analyzer_path, component)
        readiness_components[component] = {
            "status": metadata["readiness"],
            "detail": metadata["readiness_detail"],
        }
        readiness_counts[metadata["readiness"]] += 1
        version, baseline_sha = _baseline_version(baseline_documents.get(component))
        current_sha = metadata["commit_sha"]
        if not current_sha and run_manifest:
            current_sha = str(
                run_manifest.get("repositories", {})
                .get(component, {})
                .get("commit_sha", "")
            )
        revisions[component] = {
            "baseline_version": version,
            "baseline_commit_sha": baseline_sha,
            "analyzed_commit_sha": current_sha,
            "status": _revision_status(baseline_sha, current_sha),
        }

    timing = _timing_summary(run_manifest or {})
    agent_execution = _agent_execution_summary(generation_runs)
    gate_errors = []
    if not preservation["passed"]:
        gate_errors.append("analyzer-to-generated preservation failed")
    if not structural["passed"]:
        gate_errors.append("generated document structural validation failed")
    if not synthesis_quality["passed"]:
        gate_errors.append("generated document synthesis/structure quality failed")
    snapshot = (run_manifest or {}).get("analyzer_snapshot", {})
    if snapshot.get("missing"):
        gate_errors.append("one or more analyzer snapshots were missing")

    return {
        "schema_version": 1,
        "generated_at": utc_now(),
        "paths": {
            "baseline_dir": str(baseline_path),
            "candidate_dir": str(candidate_path),
            "analyzer_dir": str(analyzer_path),
        },
        "fixture_comparison": fixture,
        "analyzer_preservation": preservation,
        "structural_validation": structural,
        "synthesis_structure_quality": synthesis_quality,
        "readiness": {
            "counts": dict(sorted(readiness_counts.items())),
            "components": readiness_components,
        },
        "revisions": revisions,
        "timing": timing,
        "agent_execution": agent_execution,
        "merge_audit": {
            "components": (merge_artifacts or {}).get("merges", {}),
            "errors": (merge_artifacts or {}).get("errors", []),
        },
        "gates": {"passed": not gate_errors, "errors": gate_errors},
    }


def _adjudicate_preservation_conflicts(
    preservation: dict[str, Any], adjudications: dict[str, Any],
) -> dict[str, list[dict[str, Any]]]:
    accepted_entries: dict[tuple[Any, ...], dict[str, Any]] = {}
    accepted_deletion_entries: dict[tuple[Any, ...], dict[str, Any]] = {}
    invalid = []
    raw_entries = adjudications.get("accepted_conflicts", [])
    if not isinstance(raw_entries, list):
        raw_entries = []
        invalid.append({"error": "accepted_conflicts must be a list"})
    for index, entry in enumerate(raw_entries):
        if not isinstance(entry, dict):
            invalid.append({"index": index, "error": "entry must be an object"})
            continue
        evidence = entry.get("evidence")
        has_evidence = (
            isinstance(evidence, str) and bool(evidence.strip())
        ) or (
            isinstance(evidence, list)
            and bool(evidence)
            and all(isinstance(item, str) and item.strip() for item in evidence)
        )
        required = ("component", "category", "key", "column", "analyzer", "generated")
        if (
            not all(entry.get(field) for field in required)
            or not isinstance(entry.get("key"), list)
            or not str(entry.get("reason", "")).strip()
            or not has_evidence
        ):
            invalid.append(
                {
                    "index": index,
                    "error": "entry requires identity, reason, and source evidence",
                }
            )
            continue
        accepted_entries[
            (
                entry["component"],
                entry["category"],
                tuple(entry["key"]),
                entry["column"],
                entry["analyzer"],
                entry["generated"],
            )
        ] = entry

    raw_deletions = adjudications.get("accepted_deletions", [])
    if not isinstance(raw_deletions, list):
        raw_deletions = []
        invalid.append({"error": "accepted_deletions must be a list"})
    for index, entry in enumerate(raw_deletions):
        if not isinstance(entry, dict):
            invalid.append(
                {"deletion_index": index, "error": "entry must be an object"}
            )
            continue
        evidence = entry.get("evidence")
        has_evidence = (
            isinstance(evidence, str) and bool(evidence.strip())
        ) or (
            isinstance(evidence, list)
            and bool(evidence)
            and all(isinstance(item, str) and item.strip() for item in evidence)
        )
        if (
            not all(entry.get(field) for field in ("component", "category", "key"))
            or not isinstance(entry.get("key"), list)
            or not str(entry.get("reason", "")).strip()
            or not has_evidence
        ):
            invalid.append(
                {
                    "deletion_index": index,
                    "error": "entry requires identity, reason, and source evidence",
                }
            )
            continue
        accepted_deletion_entries[
            (entry["component"], entry["category"], tuple(entry["key"]))
        ] = entry

    accepted = []
    accepted_deletions = []
    unexplained = []
    unexplained_missing_rows = []
    for component, report in preservation["components"].items():
        for category in report["categories"]:
            for conflict in category["conflicts"]:
                identity = (
                    component,
                    conflict["category"],
                    tuple(conflict["key"]),
                    conflict["column"],
                    conflict["baseline"],
                    conflict["candidate"],
                )
                detail = {"component": component, **conflict}
                entry = accepted_entries.get(identity)
                if entry:
                    accepted.append(
                        {
                            **detail,
                            "reason": entry["reason"],
                            "evidence": entry["evidence"],
                        }
                    )
                else:
                    unexplained.append(detail)
            if category["category"] in NON_ARCHITECTURE_CATEGORIES:
                continue
            for key in category["missing_keys"]:
                identity = (component, category["category"], tuple(key))
                detail = {
                    "component": component,
                    "category": category["category"],
                    "key": list(key),
                }
                entry = accepted_deletion_entries.get(identity)
                if entry:
                    accepted_deletions.append(
                        {
                            **detail,
                            "reason": entry["reason"],
                            "evidence": entry["evidence"],
                        }
                    )
                else:
                    unexplained_missing_rows.append(detail)
    return {
        "accepted": accepted,
        "accepted_deletions": accepted_deletions,
        "unexplained": unexplained,
        "unexplained_missing_rows": unexplained_missing_rows,
        "invalid": invalid,
    }


def _timing_summary(run_manifest: dict[str, Any]) -> dict[str, Any]:
    phases = run_manifest.get("phases", {})
    starts = [
        phase["started_epoch"]
        for phase in phases.values()
        if isinstance(phase.get("started_epoch"), (int, float))
    ]
    ends = [
        phase["ended_epoch"]
        for phase in phases.values()
        if isinstance(phase.get("ended_epoch"), (int, float))
    ]
    workflow_seconds = max(ends) - min(starts) if starts and ends else None
    prior = run_manifest.get("prior_wall_seconds")
    change = None
    reduction = None
    if workflow_seconds is not None and isinstance(prior, (int, float)) and prior:
        change = workflow_seconds - prior
        reduction = (prior - workflow_seconds) / prior
    return {
        "phases": {
            name: {
                "wall_seconds": phase.get("wall_seconds"),
                "exit_code": phase.get("exit_code"),
                "reported_failures": phase.get("reported_failures"),
                "started_at": phase.get("started_at"),
                "ended_at": phase.get("ended_at"),
                "log_path": phase.get("log_path"),
            }
            for name, phase in sorted(phases.items())
        },
        "static_analysis_seconds": phases.get("static_analysis", {}).get(
            "wall_seconds"
        ),
        "bounded_agent_seconds": phases.get("component_generation", {}).get(
            "wall_seconds"
        ),
        "collection_seconds": phases.get("collection", {}).get("wall_seconds"),
        "workflow_wall_seconds": workflow_seconds,
        "prior_wall_seconds": prior,
        "wall_seconds_change": change,
        "wall_time_reduction": reduction,
    }


def _agent_execution_summary(runs: dict[str, Any]) -> dict[str, Any]:
    components = {}
    totals: Counter[str] = Counter()
    total_cost = 0.0
    total_duration = 0.0
    route_counts: Counter[str] = Counter()
    for component, run in sorted(runs.items()):
        telemetry = run.get("telemetry", {})
        usage = telemetry.get("usage", {})
        merge = run.get("merge") or {}
        summary = {
            "success": bool(run.get("success")),
            "readiness": run.get("routing", {}).get("readiness", "unknown"),
            "route": run.get("routing", {}).get("route", "unknown"),
            "duration_seconds": run.get("duration_seconds"),
            "merge_seconds": merge.get("duration_seconds"),
            "tool_calls": telemetry.get("tool_calls", 0),
            "read_calls": telemetry.get("read_calls", 0),
            "source_file_count": telemetry.get("source_file_count", 0),
            "input_tokens": usage.get("input_tokens", 0),
            "output_tokens": usage.get("output_tokens", 0),
            "cache_read_input_tokens": usage.get("cache_read_input_tokens", 0),
            "cache_creation_input_tokens": usage.get(
                "cache_creation_input_tokens", 0
            ),
            "cost_usd": telemetry.get("total_cost_usd"),
            "denied_tool_calls": telemetry.get("denied_tool_calls", 0),
        }
        components[component] = summary
        route_counts[str(summary["route"])] += 1
        for key in (
            "tool_calls",
            "read_calls",
            "source_file_count",
            "input_tokens",
            "output_tokens",
            "cache_read_input_tokens",
            "cache_creation_input_tokens",
            "denied_tool_calls",
        ):
            totals[key] += int(summary[key] or 0)
        if isinstance(summary["cost_usd"], (int, float)):
            total_cost += summary["cost_usd"]
        if isinstance(summary["duration_seconds"], (int, float)):
            total_duration += summary["duration_seconds"]
    return {
        "component_count": len(components),
        "agent_invocation_count": len(components)
        - route_counts.get("analyzer-only", 0),
        "analyzer_only_count": route_counts.get("analyzer-only", 0),
        "route_counts": dict(sorted(route_counts.items())),
        "successful_components": sum(
            component["success"] for component in components.values()
        ),
        "duration_seconds": total_duration,
        "cost_usd": total_cost,
        **dict(totals),
        "components": components,
    }


def format_corpus_report(report: dict[str, Any]) -> str:
    """Render a concise Markdown corpus report."""
    fixture = report["fixture_comparison"]
    preservation = report["analyzer_preservation"]
    structural = report["structural_validation"]
    synthesis_quality = report["synthesis_structure_quality"]
    timing = report["timing"]
    execution = report.get("agent_execution", {})
    quality_passed = len(synthesis_quality["components"]) - len(
        synthesis_quality["failed_components"]
    )
    lines = [
        "# Architecture Corpus Comparison",
        "",
        "## Summary",
        "",
        "| Measure | Result |",
        "|---------|-------:|",
        (
            "| Structured fixture recall | "
            f"{fixture['structured_matched_rows']}/"
            f"{fixture['structured_baseline_rows']} "
            f"({fixture['structured_row_recall']:.2%}) |"
        ),
        (
            "| Median component structured recall | "
            f"{fixture['median_component_structured_recall']:.2%} |"
        ),
        (
            "| Fixture populated-cell conflicts | "
            f"{fixture['conflict_count']} |"
        ),
        (
            "| Components below fixture threshold | "
            f"{len(fixture['components_below_threshold'])} |"
        ),
        (
            "| Analyzer identities retained unchanged | "
            f"{preservation['structured_matched_rows']}/"
            f"{preservation['structured_baseline_rows']} "
            f"({preservation['structured_row_recall']:.2%}) |"
        ),
        (
            "| Analyzer-to-final conflicts | "
            f"{preservation['conflict_count']} |"
        ),
        (
            "| Accepted analyzer-to-final conflicts | "
            f"{len(preservation['accepted_conflicts'])} |"
        ),
        (
            "| Accepted analyzer row corrections | "
            f"{len(preservation['accepted_deletions'])} |"
        ),
        (
            "| Unexplained analyzer-to-final conflicts | "
            f"{len(preservation['unexplained_conflicts'])} |"
        ),
        (
            "| Unexplained missing analyzer rows | "
            f"{len(preservation['unexplained_missing_rows'])} |"
        ),
        (
            "| Structurally valid documents | "
            f"{structural['validated_documents'] - len(structural['failed_documents'])}"
            "/"
            f"{structural['validated_documents']} |"
        ),
        (
            "| Synthesis/structure quality | "
            f"{quality_passed}/{len(synthesis_quality['components'])} |"
        ),
        f"| Required gates | {'PASS' if report['gates']['passed'] else 'FAIL'} |",
        "",
        "## Documents",
        "",
        (
            f"Baseline: {fixture['baseline_document_count']}; candidate: "
            f"{fixture['candidate_document_count']}; matched: "
            f"{fixture['matched_document_count']}."
        ),
        "",
    ]
    if fixture["missing_documents"]:
        lines.append("Missing candidates: " + ", ".join(fixture["missing_documents"]))
        lines.append("")
    if fixture["extra_documents"]:
        lines.append("Additional candidates: " + ", ".join(fixture["extra_documents"]))
        lines.append("")
    if synthesis_quality["failed_components"]:
        lines.extend(
            [
                "## Sparse High-Value Structure",
                "",
                "Detailed synthesis is paired with unexpectedly empty high-value "
                "tables in: "
                + ", ".join(synthesis_quality["failed_components"]),
                "",
            ]
        )
    if fixture["components_below_threshold"]:
        lines.extend(
            [
                "## Components Below Threshold",
                "",
                ", ".join(fixture["components_below_threshold"]),
                "",
            ]
        )

    lines.extend(
        [
            "## Category Recall",
            "",
            "| Category | Matched | Baseline | Recall | Conflicts |",
            "|----------|--------:|---------:|-------:|----------:|",
        ]
    )
    for name, category in fixture["categories"].items():
        if name in NON_ARCHITECTURE_CATEGORIES:
            continue
        lines.append(
            f"| {name} | {category['matched_rows']} | "
            f"{category['baseline_rows']} | {category['row_recall']:.2%} | "
            f"{category['conflicts']} |"
        )

    lines.extend(
        [
            "",
            "## History And Source Inventory",
            "",
            "These evidence inventories are excluded from structured "
            "architecture recall.",
            "",
            "| Category | Matched | Baseline | Recall | Conflicts |",
            "|----------|--------:|---------:|-------:|----------:|",
        ]
    )
    for name, category in fixture["non_architecture_categories"].items():
        lines.append(
            f"| {name} | {category['matched_rows']} | "
            f"{category['baseline_rows']} | {category['row_recall']:.2%} | "
            f"{category['conflicts']} |"
        )

    lines.extend(
        [
            "",
            "## Readiness",
            "",
            "| Status | Components |",
            "|--------|-----------:|",
        ]
    )
    for status, count in report["readiness"]["counts"].items():
        lines.append(f"| {status} | {count} |")

    if execution.get("component_count"):
        lines.extend(
            [
                "",
                "## Agent Execution",
                "",
                (
                    f"Agent invocations: {execution['agent_invocation_count']}; "
                    f"analyzer-only documents: {execution['analyzer_only_count']}."
                ),
                "",
                "| Component | Readiness | Route | Agent | Merge | Tools | Reads | "
                "Source files | Output tokens | Cost USD |",
                "|-----------|-----------|-------|------:|------:|------:|------:|"
                "-------------:|--------------:|---------:|",
            ]
        )
        for component, metrics in execution["components"].items():
            cost = metrics["cost_usd"]
            cost_text = f"{cost:.4f}" if isinstance(cost, (int, float)) else "n/a"
            lines.append(
                f"| {component} | {metrics['readiness']} | {metrics['route']} | "
                f"{_format_seconds(metrics['duration_seconds'])} | "
                f"{_format_seconds(metrics['merge_seconds'])} | "
                f"{metrics['tool_calls']} | {metrics['read_calls']} | "
                f"{metrics['source_file_count']} | {metrics['output_tokens']} | "
                f"{cost_text} |"
            )

    revision_counts = Counter(
        revision["status"] for revision in report["revisions"].values()
    )
    lines.extend(
        [
            "",
            "## Revision Comparison",
            "",
            "| Status | Components |",
            "|--------|-----------:|",
        ]
    )
    for status, count in sorted(revision_counts.items()):
        lines.append(f"| {status} | {count} |")
    drifted = [
        component
        for component, revision in report["revisions"].items()
        if revision["status"] == "different"
    ]
    if drifted:
        lines.extend(["", "Different source revisions: " + ", ".join(drifted)])

    lines.extend(
        [
            "",
            "## Timing",
            "",
            "| Phase | Wall time | Failures |",
            "|-------|----------:|---------:|",
        ]
    )
    for name, phase in timing["phases"].items():
        failures = phase["reported_failures"]
        lines.append(
            f"| {name} | {_format_seconds(phase['wall_seconds'])} | "
            f"{failures if failures is not None else 'not reported'} |"
        )
    if timing["workflow_wall_seconds"] is not None:
        lines.extend(
            [
                "",
                (
                    "Workflow wall time: "
                    f"{_format_seconds(timing['workflow_wall_seconds'])}; prior "
                    f"reference: {_format_seconds(timing['prior_wall_seconds'])}."
                ),
            ]
        )
        if timing["wall_time_reduction"] is not None:
            lines.append(
                "Wall-time reduction from prior reference: "
                f"{timing['wall_time_reduction']:.2%}."
            )

    if report["gates"]["errors"]:
        lines.extend(["", "## Gate Failures", ""])
        lines.extend(f"- {error}" for error in report["gates"]["errors"])
    lines.append("")
    return "\n".join(lines)


def _format_seconds(value: Any) -> str:
    if not isinstance(value, (int, float)):
        return "not measured"
    return f"{value:.2f}s"


def write_corpus_reports(
    report: dict[str, Any], json_path: str | Path, markdown_path: str | Path,
) -> None:
    _write_json(Path(json_path), report)
    markdown = Path(markdown_path)
    markdown.parent.mkdir(parents=True, exist_ok=True)
    markdown.write_text(format_corpus_report(report))


def _add_init_arguments(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--repo-root", default=str(PROJECT_ROOT))
    parser.add_argument("--source-architecture-dir", required=True)
    parser.add_argument("--platform", default="rhoai.next")
    parser.add_argument("--platforms-file", required=True)
    parser.add_argument("--baseline", required=True)
    parser.add_argument("--run-dir", required=True)
    parser.add_argument("--model", default="opus")
    parser.add_argument("--workers", type=int, default=10)
    parser.add_argument("--prior-wall-seconds", type=float, default=3600.0)
    parser.add_argument(
        "--components",
        help="Optional comma-separated component keys for a bounded matrix run",
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    init_parser = subparsers.add_parser("init-run")
    _add_init_arguments(init_parser)

    phase_parser = subparsers.add_parser("record-phase")
    phase_parser.add_argument("--run-manifest", required=True)
    phase_parser.add_argument("--phase", required=True)
    phase_parser.add_argument("--started-at", required=True)
    phase_parser.add_argument("--ended-at", required=True)
    phase_parser.add_argument("--started-epoch", type=float, required=True)
    phase_parser.add_argument("--ended-epoch", type=float, required=True)
    phase_parser.add_argument("--wall-seconds", type=float, required=True)
    phase_parser.add_argument("--exit-code", type=int, required=True)
    phase_parser.add_argument("--phase-command", required=True)
    phase_parser.add_argument("--log", required=True)

    snapshot_parser = subparsers.add_parser("snapshot-analyzers")
    snapshot_parser.add_argument("--run-manifest", required=True)

    compare_parser = subparsers.add_parser("compare")
    compare_parser.add_argument("--baseline", required=True)
    compare_parser.add_argument("--candidate", required=True)
    compare_parser.add_argument("--analyzer", required=True)
    compare_parser.add_argument("--run-manifest")
    compare_parser.add_argument("--preservation-adjudications")
    compare_parser.add_argument("--merge-report-dir")
    compare_parser.add_argument("--component-threshold", type=float, default=0.95)
    compare_parser.add_argument("--output-json", required=True)
    compare_parser.add_argument("--output-markdown", required=True)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        if args.command == "init-run":
            initialize_run(
                repo_root=args.repo_root,
                source_architecture_dir=args.source_architecture_dir,
                platform=args.platform,
                platforms_file=args.platforms_file,
                baseline_dir=args.baseline,
                run_dir=args.run_dir,
                model=args.model,
                workers=args.workers,
                prior_wall_seconds=args.prior_wall_seconds,
                component_names=tuple(
                    component.strip()
                    for component in (args.components or "").split(",")
                    if component.strip()
                ),
            )
            print(Path(args.run_dir).resolve() / "run.json")
            return 0
        if args.command == "record-phase":
            record_phase(
                args.run_manifest,
                phase=args.phase,
                started_at=args.started_at,
                ended_at=args.ended_at,
                started_epoch=args.started_epoch,
                ended_epoch=args.ended_epoch,
                wall_seconds=args.wall_seconds,
                exit_code=args.exit_code,
                command=args.phase_command,
                log_path=args.log,
            )
            return 0
        if args.command == "snapshot-analyzers":
            snapshot = snapshot_analyzers(args.run_manifest)
            print(json.dumps(snapshot, indent=2))
            return 1 if snapshot["missing"] else 0

        manifest = _read_json(args.run_manifest) if args.run_manifest else None
        adjudications = (
            _read_json(args.preservation_adjudications)
            if args.preservation_adjudications else None
        )
        merge_artifacts = (
            load_merge_artifacts(args.merge_report_dir)
            if args.merge_report_dir else None
        )
        report = compare_corpus(
            args.baseline,
            args.candidate,
            args.analyzer,
            component_threshold=args.component_threshold,
            run_manifest=manifest,
            preservation_adjudications=adjudications,
            merge_artifacts=merge_artifacts,
        )
        write_corpus_reports(report, args.output_json, args.output_markdown)
        if args.run_manifest:
            manifest_path = Path(args.run_manifest)
            manifest = _read_json(manifest_path)
            manifest["comparison"] = {
                "completed_at": report["generated_at"],
                "output_json": str(Path(args.output_json).resolve()),
                "output_markdown": str(Path(args.output_markdown).resolve()),
                "gates": report["gates"],
            }
            manifest["status"] = (
                "complete" if report["gates"]["passed"] else "validation_failed"
            )
            _write_json(manifest_path, manifest)
        print(format_corpus_report(report), end="")
        return 0 if report["gates"]["passed"] else 1
    except (OSError, ValueError, json.JSONDecodeError, yaml.YAMLError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
