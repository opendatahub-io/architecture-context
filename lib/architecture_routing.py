"""Analyzer-readiness routing policy for component architecture agents."""

from __future__ import annotations

import json
from dataclasses import asdict, dataclass
from pathlib import Path

from lib.architecture_baseline import (
    _TABLE_SPECS,
    NON_ARCHITECTURE_CATEGORIES,
    _normalize_section,
    parse_component_markdown,
)

READINESS_LEVELS = frozenset({"sufficient", "partial", "insufficient", "unknown"})
PARTIAL_CATEGORY_LIMIT = 6
PARTIAL_FILE_LIMIT = 10

HIGH_VALUE_AGENT_CATEGORIES = (
    "architecture_components",
    "authentication",
    "integration_points",
    "internal_dependencies",
)

BROAD_EMPTY_TRANSPORT_CATEGORIES = frozenset({
    "http_endpoints",
    "grpc_services",
    "services",
})

NARRATIVE_SECTIONS = frozenset({
    "purpose",
    "data_flows",
    "architectural_analysis",
})

NARRATIVE_MIN_PROSE_LENGTH = 50

_NARRATIVE_HEADING_MAP = {
    "purpose": "purpose",
    "data_flows": "data flows",
    "architectural_analysis": "architectural analysis",
}

_NARRATIVE_PRIORITY = (
    "purpose",
    "data_flows",
    "architectural_analysis",
)

_PARTIAL_GAP_PRIORITY = (
    *HIGH_VALUE_AGENT_CATEGORIES,
    *_NARRATIVE_PRIORITY,
    "http_endpoints",
    "grpc_services",
    "services",
    "ingress",
    "egress",
    "crds",
    "rbac_cluster_roles",
    "rbac_role_bindings",
    "secrets",
    "external_dependencies",
)

SAFETY_CRITICAL_CATEGORIES = frozenset({
    "authentication",
    "rbac_cluster_roles",
    "rbac_role_bindings",
    "secrets",
})

COMPLETE_EMPTY_CATEGORY_CONTRACTS = {
    "authentication": "authentication/v1",
    "integration_points": "integration-points/v1",
    "internal_dependencies": "internal-platform-dependencies/v1",
}

ACTIONABLE_PARTIAL_LIMITATION_MARKERS = (
    "unaccounted",
    "not accounted",
    "unsupported runtime source",
    "require ",
    "requires ",
)

ANALYZER_ONLY_APPROVALS_PATH = Path(__file__).with_name(
    "analyzer_only_approvals.json"
)
CORRECTION_ADJUDICATIONS_PATH = Path(__file__).with_name(
    "analyzer_correction_adjudications.json"
)
SYNTHESIS_MIGRATION_ALLOWLIST_PATH = Path(__file__).with_name(
    "synthesis_migration_allowlist.json"
)


def load_analyzer_only_approvals(
    path: str | Path = ANALYZER_ONLY_APPROVALS_PATH,
) -> frozenset[str]:
    """Load historical analyzer-only approvals for audit/reporting only.

    Generation routing always invokes analyzer-assisted synthesis or bounded
    partial synthesis; this registry no longer selects an analyzer-only route.
    """

    try:
        payload = json.loads(Path(path).read_text())
    except (OSError, json.JSONDecodeError):
        return frozenset()
    components = payload.get("components", [])
    if not isinstance(components, list):
        return frozenset()
    return frozenset(
        component.strip()
        for component in components
        if isinstance(component, str) and component.strip()
    )

def load_synthesis_migration_allowlist(
    path: str | Path = SYNTHESIS_MIGRATION_ALLOWLIST_PATH,
) -> frozenset[str]:
    """Load the historical synthesis migration allowlist for audit/reporting.

    This registry is no longer used for routing decisions. All valid
    analyzer-backed components route to partial regardless of allowlist
    membership. The allowlist is retained for historical audit and rollout
    reporting only.
    """
    try:
        payload = json.loads(Path(path).read_text())
    except (OSError, json.JSONDecodeError):
        return frozenset()
    components = payload.get("components", [])
    if not isinstance(components, list):
        return frozenset()
    return frozenset(
        component.strip()
        for component in components
        if isinstance(component, str) and component.strip()
    )


def load_source_audited_empty_categories(
    path: str | Path = CORRECTION_ADJUDICATIONS_PATH,
) -> dict[str, frozenset[str]]:
    """Load component→categories whose emptiness was verified by source audit."""

    try:
        payload = json.loads(Path(path).read_text())
    except (OSError, json.JSONDecodeError):
        return {}
    entries = payload.get("source_audited_empty_categories", [])
    if not isinstance(entries, list):
        return {}
    result: dict[str, set[str]] = {}
    for entry in entries:
        if not isinstance(entry, dict):
            continue
        component = str(entry.get("component") or "").strip()
        category = str(entry.get("category") or "").strip()
        reason = str(entry.get("reason") or "").strip()
        evidence = entry.get("evidence") or []
        if (
            component
            and category
            and reason
            and isinstance(evidence, list)
            and evidence
            and all(isinstance(item, str) and item.strip() for item in evidence)
        ):
            result.setdefault(component, set()).add(category)
    return {comp: frozenset(cats) for comp, cats in result.items()}


_CATEGORY_VALUE_PRIORITY = (
    *HIGH_VALUE_AGENT_CATEGORIES,
    "http_endpoints",
    "grpc_services",
    "services",
    "ingress",
    "egress",
    "crds",
    "rbac_cluster_roles",
    "rbac_role_bindings",
    "secrets",
    "external_dependencies",
)

# These are the coverage keys emitted by arch-analyzer. A partial surface nominates
# categories, but the single value priority above decides which categories fit.
_COVERAGE_CATEGORY_HINTS = {
    "source": (
        "architecture_components",
        "http_endpoints",
        "grpc_services",
        "authentication",
        "egress",
        "integration_points",
        "internal_dependencies",
    ),
    "python": (
        "architecture_components",
        "http_endpoints",
        "grpc_services",
        "authentication",
        "egress",
        "integration_points",
        "internal_dependencies",
    ),
    "rust": (
        "architecture_components",
        "http_endpoints",
        "authentication",
        "egress",
        "integration_points",
        "internal_dependencies",
    ),
    "web_workspace": (
        "architecture_components",
        "http_endpoints",
        "authentication",
        "egress",
        "integration_points",
        "internal_dependencies",
    ),
    "go_crds": ("crds",),
    "go_module_configs": (
        "architecture_components",
        "crds",
        "services",
        "rbac_cluster_roles",
        "rbac_role_bindings",
        "integration_points",
    ),
    "controller_templates": (
        "architecture_components",
        "services",
        "ingress",
        "egress",
        "integration_points",
        "internal_dependencies",
    ),
    "kustomize": (
        "architecture_components",
        "services",
        "ingress",
        "egress",
        "rbac_cluster_roles",
        "rbac_role_bindings",
        "secrets",
        "integration_points",
        "internal_dependencies",
    ),
    "manifests": (
        "architecture_components",
        "services",
        "ingress",
        "egress",
        "rbac_cluster_roles",
        "rbac_role_bindings",
        "secrets",
        "integration_points",
        "internal_dependencies",
    ),
    "platform_semantics": (
        "architecture_components",
        "authentication",
        "integration_points",
        "internal_dependencies",
        "services",
        "ingress",
        "egress",
    ),
}


@dataclass(frozen=True)
class ArchitectureAgentPolicy:
    """One component's code-enforced agent exploration policy."""

    readiness: str
    readiness_detail: str
    route: str
    gap_categories: tuple[str, ...] = ()
    gap_reasons: tuple[str, ...] = ()
    source_files: tuple[str, ...] = ()
    file_budget: int | None = None
    discovery_tools: tuple[str, ...] = ()
    reason: str = ""
    output_preseeded: bool = False

    @property
    def evidence_gated(self) -> bool:
        return self.route in ("synthesis", "partial")

    def to_dict(self) -> dict[str, object]:
        return asdict(self)

    def prompt_arguments(self) -> str:
        """Return explicit skill arguments for this policy."""

        arguments = [
            f"--readiness={self.readiness}",
            f"--analysis-route={self.route}",
        ]
        if self.file_budget is not None:
            arguments.append(f"--file-budget={self.file_budget}")
        if self.gap_categories:
            arguments.append("--gap-categories=" + ",".join(self.gap_categories))
        elif self.evidence_gated:
            arguments.append("--gap-categories=none")
        if self.readiness == "sufficient" and self.source_files:
            arguments.append("--allowed-source-files=" + ",".join(self.source_files))
        if self.output_preseeded:
            arguments.append("--baseline-preseeded")
        if self.gap_reasons:
            arguments.append("--gap-reasons=" + ";".join(self.gap_reasons))
        return " ".join(arguments)


def classify_gap(category: str) -> str:
    """Classify a gap category as narrative, safety-critical, or structural."""
    if category in NARRATIVE_SECTIONS:
        return "narrative"
    if category in SAFETY_CRITICAL_CATEGORIES:
        return "safety-critical"
    return "structural"


def _narrative_gap_sections(markdown_path: Path) -> set[str]:
    """Return narrative sections that are missing or thin in the baseline."""
    document = parse_component_markdown(markdown_path)
    gaps = set()
    for gap_key, normalized_heading in _NARRATIVE_HEADING_MAP.items():
        found = False
        for path_key, text in document.section_text.items():
            if not path_key:
                continue
            if _normalize_section(path_key[-1]) == normalized_heading:
                if len(text.strip()) >= NARRATIVE_MIN_PROSE_LENGTH:
                    found = True
                break
        if not found:
            gaps.add(gap_key)
    return gaps


def _build_gap_reasons(
    gaps: tuple[str, ...],
    empty_categories: set[str],
    coverage_gaps: set[str],
    narrative_gaps: set[str] | None = None,
) -> tuple[str, ...]:
    """Build an auditable reason string for each gap category."""
    reasons: list[str] = []
    narr = narrative_gaps or set()
    for category in gaps:
        parts: list[str] = [classify_gap(category)]
        if category in empty_categories:
            parts.append("empty-in-baseline")
        if category in coverage_gaps:
            parts.append("partial-coverage")
        if category in narr:
            parts.append("thin-narrative")
        reasons.append(f"{category}:{','.join(parts)}")
    return tuple(reasons)


def load_architecture_agent_policy(
    checkout: str | Path,
    *,
    readiness_routing: bool,
    analyzer_root: str | Path | None = None,
) -> ArchitectureAgentPolicy:
    """Load analyzer readiness and derive a bounded agent policy."""

    root = Path(analyzer_root) if analyzer_root is not None else Path(checkout)
    if not readiness_routing:
        return ArchitectureAgentPolicy(
            readiness="legacy",
            readiness_detail="readiness routing disabled",
            route="legacy",
            discovery_tools=("Bash", "Glob", "Grep", "Task"),
            reason="operator selected legacy component generation",
        )

    json_path = root / "component-architecture.json"
    markdown_path = root / "analyzer_architecture.md"
    analyzer: dict[str, object] = {}
    json_valid = False
    try:
        analyzer = json.loads(json_path.read_text())
        detail = str(
            analyzer.get("data_coverage", {}).get("agent_baseline", "")
        ).strip()
        json_valid = True
    except (OSError, json.JSONDecodeError, AttributeError):
        detail = ""
    readiness = detail.split(":", 1)[0].strip().casefold()
    if not json_valid or not markdown_path.is_file():
        return ArchitectureAgentPolicy(
            readiness="unknown",
            readiness_detail=detail or "analyzer baseline unavailable",
            route="legacy",
            discovery_tools=("Bash", "Glob", "Grep", "Task"),
            reason="analyzer readiness cannot support constrained generation",
        )

    if readiness not in {"sufficient", "partial", "insufficient"}:
        readiness = "unknown"

    source_files, empty_categories, baseline_counts = _baseline_inventory_details(
        markdown_path
    )
    coverage_gaps = set(
        _coverage_gap_categories(analyzer, baseline_counts=baseline_counts)
    )

    narrative_gaps = _narrative_gap_sections(markdown_path)
    high_value_empty_categories = {
        category
        for category in empty_categories
        if category in HIGH_VALUE_AGENT_CATEGORIES
    }
    nominated = coverage_gaps | high_value_empty_categories | narrative_gaps
    gaps = tuple(
        category
        for category in _PARTIAL_GAP_PRIORITY
        if category in nominated
    )[:PARTIAL_CATEGORY_LIMIT]
    gap_reasons = _build_gap_reasons(
        gaps, empty_categories, coverage_gaps, narrative_gaps,
    )
    file_budget = min(PARTIAL_FILE_LIMIT, max(4, len(gaps) + 2))
    return ArchitectureAgentPolicy(
        readiness=readiness,
        readiness_detail=detail,
        route="partial",
        gap_categories=gaps,
        gap_reasons=gap_reasons,
        source_files=source_files[:file_budget],
        file_budget=file_budget,
        discovery_tools=("Glob", "Grep"),
        reason=(
            "valid analyzer baseline; bounded extend-and-improve discovery is "
            "limited to declared gap categories with source-read budget guidance"
        ),
        output_preseeded=True,
    )


def analyzer_only_eligibility(
    readiness: str,
    analyzer: dict[str, object],
    empty_categories: set[str],
    *,
    source_audited: frozenset[str] = frozenset(),
) -> tuple[bool, str]:
    """Return whether current analyzer evidence can bypass component agents."""

    if readiness != "sufficient":
        return False, "analyzer readiness is not sufficient"
    empty_high_value = tuple(
        category
        for category in HIGH_VALUE_AGENT_CATEGORIES
        if category in empty_categories
    )
    explained = set(_complete_empty_categories(analyzer, empty_categories))
    explained |= source_audited & empty_categories
    coverage_gaps = set(_coverage_gap_categories(analyzer))
    correction_gaps = tuple(
        category
        for category in HIGH_VALUE_AGENT_CATEGORIES
        if category in empty_categories
        and category in coverage_gaps
        and category not in explained
    )
    if correction_gaps:
        return False, "bounded correction gaps: " + ", ".join(correction_gaps)
    unexplained_empty = tuple(
        category for category in empty_high_value if category not in explained
    )
    if unexplained_empty:
        return False, "empty high-value categories: " + ", ".join(unexplained_empty)
    return (
        True,
        "analyzer has populated or contract-complete empty high-value categories "
        "and nominates no bounded correction gaps",
    )


def _complete_empty_categories(
    analyzer: dict[str, object],
    empty_categories: set[str],
) -> tuple[str, ...]:
    """Return empty categories backed by a recognized complete contract."""

    coverage = analyzer.get("category_coverage", {})
    if not isinstance(coverage, dict):
        return ()
    complete: list[str] = []
    for category, contract in COMPLETE_EMPTY_CATEGORY_CONTRACTS.items():
        if category not in empty_categories:
            continue
        record = coverage.get(category)
        if not isinstance(record, dict):
            continue
        fact_count = record.get("fact_count")
        checks = record.get("completed_checks")
        limitations = record.get("limitations")
        evidence = record.get("evidence")
        if (
            str(record.get("status", "")).casefold() != "complete"
            or record.get("discovery_contract") != contract
            or not isinstance(fact_count, int)
            or isinstance(fact_count, bool)
            or fact_count != 0
            or not isinstance(checks, list)
            or not checks
            or not all(isinstance(check, str) and check.strip() for check in checks)
            or not isinstance(limitations, list)
            or limitations
            or not isinstance(evidence, list)
            or not evidence
            or not all(isinstance(item, str) and item.strip() for item in evidence)
            or _analyzer_fact_count(analyzer, category) != 0
        ):
            continue
        complete.append(category)
    return tuple(complete)


def _analyzer_fact_count(analyzer: dict[str, object], category: str) -> int:
    if category == "authentication":
        facts = analyzer.get("authentication", [])
    elif category == "integration_points":
        facts = analyzer.get("integration_points", [])
    elif category == "internal_dependencies":
        dependencies = analyzer.get("dependencies", {})
        facts = (
            dependencies.get("internal_odh", [])
            if isinstance(dependencies, dict)
            else []
        )
    else:
        return -1
    if facts is None:
        return 0
    return len(facts) if isinstance(facts, list) else -1


def _coverage_gap_categories(
    analyzer: dict[str, object],
    *,
    baseline_counts: dict[str, int] | None = None,
) -> tuple[str, ...]:
    coverage = analyzer.get("data_coverage", {})
    if not isinstance(coverage, dict):
        return ()
    categories: list[str] = []
    for coverage_name, hints in _COVERAGE_CATEGORY_HINTS.items():
        value = str(coverage.get(coverage_name, "")).strip().casefold()
        if value.startswith("partial:"):
            categories.extend(hints)
    # Category-specific extraction contracts override broad language-level
    # hints. A language extractor may be partial in general while a specific
    # surface (for example literal entrypoints) is complete. Conversely, a
    # category contract marked partial must remain visible to the bounded
    # agent route even when broad hints did not nominate it.
    category_coverage = analyzer.get("category_coverage", {})
    if isinstance(category_coverage, dict):
        for category, raw in category_coverage.items():
            if not isinstance(raw, dict):
                continue
            status = str(raw.get("status", "")).strip().lower()
            if status == "complete":
                categories = [item for item in categories if item != category]
            elif status == "partial":
                if (
                    baseline_counts is not None
                    and not _category_partial_coverage_requires_agent_gap(
                        category,
                        raw,
                        baseline_counts.get(category, 0),
                    )
                ):
                    categories = [
                        item for item in categories if item != category
                    ]
                elif category not in categories:
                    categories.append(category)
        category_records = {
            category
            for category, raw in category_coverage.items()
            if isinstance(category, str) and isinstance(raw, dict)
        }
    else:
        category_records = set()
    if baseline_counts is not None:
        categories = [
            category
            for category in categories
            if _broad_coverage_hint_requires_agent_gap(
                category,
                baseline_counts.get(category, 0),
                category_records,
            )
        ]
    return tuple(dict.fromkeys(categories))


def _broad_coverage_hint_requires_agent_gap(
    category: str,
    baseline_row_count: int,
    category_records: set[str],
) -> bool:
    """Return whether a broad analyzer coverage hint should route a category."""

    if category in category_records:
        return True
    if category in HIGH_VALUE_AGENT_CATEGORIES:
        return True
    return category in BROAD_EMPTY_TRANSPORT_CATEGORIES and baseline_row_count <= 0


def _category_partial_coverage_requires_agent_gap(
    category: str,
    record: dict[str, object],
    baseline_row_count: int,
) -> bool:
    """Return whether a partial category is concrete enough to route to agents."""

    if category in SAFETY_CRITICAL_CATEGORIES:
        return True
    if baseline_row_count <= 0:
        return True
    fact_count = record.get("fact_count")
    has_facts = (
        isinstance(fact_count, int)
        and not isinstance(fact_count, bool)
        and fact_count > 0
    )
    evidence = record.get("evidence")
    has_evidence = (
        isinstance(evidence, list)
        and any(isinstance(item, str) and item.strip() for item in evidence)
    )
    if not has_facts and not has_evidence:
        return True
    limitations = record.get("limitations")
    if not isinstance(limitations, list):
        return True
    normalized_limitations = " ".join(
        item.strip().casefold()
        for item in limitations
        if isinstance(item, str) and item.strip()
    )
    if not normalized_limitations:
        return False
    return any(
        marker in normalized_limitations
        for marker in ACTIONABLE_PARTIAL_LIMITATION_MARKERS
    )


def _baseline_inventory_details(
    markdown_path: Path,
) -> tuple[tuple[str, ...], set[str], dict[str, int]]:
    document = parse_component_markdown(markdown_path)
    category_counts = {
        spec.category: 0
        for spec in _TABLE_SPECS
        if spec.category not in NON_ARCHITECTURE_CATEGORIES
    }
    source_files: list[str] = []
    for table in document.tables:
        spec = next(
            (
                candidate
                for candidate in _TABLE_SPECS
                if _normalize_section(table.section) in candidate.sections
            ),
            None,
        )
        if spec is None:
            continue
        if spec.category == "source_files":
            for row in table.rows:
                if not row:
                    continue
                path = row[0].strip()
                candidate = markdown_path.parent / path
                if (
                    path
                    and path not in source_files
                    and not Path(path).is_absolute()
                    and ".." not in Path(path).parts
                    and candidate.is_file()
                ):
                    source_files.append(path)
            continue
        if spec.category in category_counts:
            category_counts[spec.category] += len(table.rows)
    empty = {
        category for category, row_count in category_counts.items() if row_count == 0
    }
    return tuple(source_files), empty, category_counts


def _baseline_category_counts(markdown_path: Path) -> dict[str, int]:
    _, _, category_counts = _baseline_inventory_details(markdown_path)
    return category_counts


def _baseline_inventory(markdown_path: Path) -> tuple[tuple[str, ...], set[str]]:
    source_files, empty, _ = _baseline_inventory_details(markdown_path)
    return tuple(source_files), empty
