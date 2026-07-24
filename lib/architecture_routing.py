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

READINESS_LEVELS = frozenset({"sufficient", "partial", "insufficient"})
PARTIAL_CATEGORY_LIMIT = 6
SUFFICIENT_CATEGORY_LIMIT = 4
SUFFICIENT_FILE_LIMIT = 4
PARTIAL_FILE_LIMIT = 10

HIGH_VALUE_AGENT_CATEGORIES = (
    "architecture_components",
    "authentication",
    "integration_points",
    "internal_dependencies",
)

COMPLETE_EMPTY_CATEGORY_CONTRACTS = {
    "authentication": "authentication/v1",
    "integration_points": "integration-points/v1",
    "internal_dependencies": "internal-platform-dependencies/v1",
}

ANALYZER_ONLY_APPROVALS_PATH = Path(__file__).with_name(
    "analyzer_only_approvals.json"
)
CORRECTION_ADJUDICATIONS_PATH = Path(__file__).with_name(
    "analyzer_correction_adjudications.json"
)


def load_analyzer_only_approvals(
    path: str | Path = ANALYZER_ONLY_APPROVALS_PATH,
) -> frozenset[str]:
    """Load components whose analyzer-only route passed corpus adjudication."""

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
    source_files: tuple[str, ...] = ()
    file_budget: int | None = None
    discovery_tools: tuple[str, ...] = ()
    reason: str = ""
    output_preseeded: bool = False

    @property
    def evidence_gated(self) -> bool:
        return self.route == "evidence-gated"

    @property
    def analyzer_only(self) -> bool:
        return self.route == "analyzer-only"

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
        return " ".join(arguments)


def load_architecture_agent_policy(
    checkout: str | Path,
    *,
    readiness_routing: bool,
) -> ArchitectureAgentPolicy:
    """Load analyzer readiness and derive a bounded agent policy."""

    root = Path(checkout)
    if not readiness_routing:
        return ArchitectureAgentPolicy(
            readiness="legacy",
            readiness_detail="readiness routing disabled",
            route="legacy",
            discovery_tools=("Bash", "Glob", "Grep", "Task"),
            reason="operator selected legacy component generation",
        )

    json_path = root / "component-architecture.json"
    markdown_path = root / "ANALYZER_ARCHITECTURE.md"
    analyzer: dict[str, object] = {}
    try:
        analyzer = json.loads(json_path.read_text())
        detail = str(
            analyzer.get("data_coverage", {}).get("agent_baseline", "")
        ).strip()
    except (OSError, json.JSONDecodeError, AttributeError):
        detail = ""
    readiness = detail.split(":", 1)[0].strip().casefold()
    if readiness not in READINESS_LEVELS or not markdown_path.is_file():
        return ArchitectureAgentPolicy(
            readiness="unknown",
            readiness_detail=detail or "analyzer baseline unavailable",
            route="legacy",
            discovery_tools=("Bash", "Glob", "Grep", "Task"),
            reason="analyzer readiness cannot support constrained generation",
        )
    if readiness == "insufficient":
        return ArchitectureAgentPolicy(
            readiness=readiness,
            readiness_detail=detail,
            route="legacy",
            discovery_tools=("Bash", "Glob", "Grep", "Task"),
            reason="analyzer explicitly requires legacy repository discovery",
        )

    source_files, empty_categories = _baseline_inventory(markdown_path)
    coverage_gaps = set(_coverage_gap_categories(analyzer))
    complete_empty = set(_complete_empty_categories(analyzer, empty_categories))
    component = str(analyzer.get("component") or root.name)
    source_audited_map = load_source_audited_empty_categories()
    source_audited = source_audited_map.get(component, frozenset())
    explained = complete_empty | (source_audited & empty_categories)
    if readiness == "sufficient":
        selected_sources = source_files[:SUFFICIENT_FILE_LIMIT]
        gaps = tuple(
            category
            for category in HIGH_VALUE_AGENT_CATEGORIES
            if category in empty_categories
            and category in coverage_gaps
            and category not in explained
        )[:SUFFICIENT_CATEGORY_LIMIT]
        eligible, eligibility_reason = analyzer_only_eligibility(
            readiness,
            analyzer,
            empty_categories,
            source_audited=source_audited,
        )
        approved = component in load_analyzer_only_approvals()
        if eligible and approved:
            return ArchitectureAgentPolicy(
                readiness=readiness,
                readiness_detail=detail,
                route="analyzer-only",
                reason=eligibility_reason,
                output_preseeded=True,
            )
        return ArchitectureAgentPolicy(
            readiness=readiness,
            readiness_detail=detail,
            route="evidence-gated",
            gap_categories=gaps,
            source_files=selected_sources,
            file_budget=len(selected_sources),
            reason=(
                "analyzer has enough runtime evidence; bounded correction is limited "
                "to empty high-value categories and analyzer-referenced files"
                if gaps
                else (
                    "analyzer-only candidate is awaiting corpus approval; agent is "
                    "synthesis-only and may read only analyzer-referenced files"
                    if eligible
                    else (
                        "analyzer has enough runtime evidence; agent is "
                        "synthesis-only and may read only analyzer-referenced files"
                    )
                )
            ),
            output_preseeded=True,
        )

    nominated = coverage_gaps | empty_categories
    gaps = tuple(
        category
        for category in _CATEGORY_VALUE_PRIORITY
        if category in nominated
    )[:PARTIAL_CATEGORY_LIMIT]
    file_budget = min(PARTIAL_FILE_LIMIT, max(4, len(gaps) + 2))
    return ArchitectureAgentPolicy(
        readiness=readiness,
        readiness_detail=detail,
        route="evidence-gated",
        gap_categories=gaps,
        source_files=source_files[:file_budget],
        file_budget=file_budget,
        discovery_tools=("Glob", "Grep"),
        reason=(
            "analyzer is partial; bounded discovery is limited to empty structured "
            "categories and a finite source-file budget"
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


def _coverage_gap_categories(analyzer: dict[str, object]) -> tuple[str, ...]:
    coverage = analyzer.get("data_coverage", {})
    if not isinstance(coverage, dict):
        return ()
    categories: list[str] = []
    for coverage_name, hints in _COVERAGE_CATEGORY_HINTS.items():
        value = str(coverage.get(coverage_name, "")).strip().casefold()
        if value.startswith("partial:"):
            categories.extend(hints)
    return tuple(dict.fromkeys(categories))


def _baseline_inventory(markdown_path: Path) -> tuple[tuple[str, ...], set[str]]:
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
    return tuple(source_files), empty
