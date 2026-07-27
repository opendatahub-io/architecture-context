"""Focused tests for analyzer-assisted targeted synthesis refactoring.

Covers: gap classification, auditable gap reasons, prior-architecture
isolation, sufficient route source-free enforcement, clean-run isolation,
provenance preservation, bounded component validation fixtures, and
end-to-end validation with local MLflow dry-run and OTel/API captures.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from unittest.mock import patch  # noqa: E402

import lib.architecture_routing as routing_mod  # noqa: E402
from lib.agent_runner import _AgentExecutionGuard  # noqa: E402
from lib.architecture_routing import (  # noqa: E402
    NARRATIVE_MIN_PROSE_LENGTH,
    NARRATIVE_SECTIONS,
    SAFETY_CRITICAL_CATEGORIES,
    _narrative_gap_sections,
    classify_gap,
    load_architecture_agent_policy,
)
from lib.mlflow_tracking import (  # noqa: E402
    TrackingConfig,
    preflight,
    track_result,
)


@pytest.fixture()
def _open_allowlist():
    """Mock the synthesis migration allowlist to allow all components."""
    with patch.object(
        routing_mod,
        "load_synthesis_migration_allowlist",
        return_value=frozenset(),
    ):
        yield


# ── Helpers ──


def write_analyzer(
    checkout: Path,
    readiness: str,
    *,
    source_files: list[str] | None = None,
    coverage: dict[str, str] | None = None,
    populate_high_value: bool = False,
    empty_high_value: set[str] | None = None,
    component: str = "test-component",
    category_coverage: dict[str, object] | None = None,
    narrative_prose: dict[str, str] | None = None,
) -> None:
    """Create analyzer fixtures in a checkout directory."""
    checkout.mkdir(parents=True, exist_ok=True)
    files = source_files or []
    for name in files:
        path = checkout / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("source\n")

    empty = empty_high_value or set()
    sources = "\n".join(f"| {path} | 1-10 | Purpose |" for path in files)
    component_row = "| example | Service | Example |"
    authentication = (
        "| /api | GET | Bearer token | middleware | authenticated |"
        if populate_high_value and "authentication" not in empty
        else ""
    )
    integrations = (
        "| database | SQL client | 5432 | PostgreSQL | TLS | persistence |"
        if populate_high_value and "integration_points" not in empty
        else ""
    )
    internal = (
        "| platform-api | HTTP client | platform integration |"
        if populate_high_value and "internal_dependencies" not in empty
        else ""
    )
    prose = narrative_prose or {}
    purpose_section = ""
    if "purpose" in prose:
        purpose_section = f"\n## Purpose\n\n{prose['purpose']}\n"
    data_flows_section = ""
    if "data_flows" in prose:
        data_flows_section = f"\n## Data Flows\n\n{prose['data_flows']}\n"
    arch_analysis_section = ""
    if "architectural_analysis" in prose:
        arch_analysis_section = (
            f"\n## Architectural Analysis\n\n"
            f"{prose['architectural_analysis']}\n"
        )
    md = f"""# Component: {component}
{purpose_section}{data_flows_section}{arch_analysis_section}
## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
{component_row}

## APIs Exposed

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|

## Dependencies

### Internal Platform Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
{internal}

## Security

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
{authentication}

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
{integrations}

## Source References

### Files Analyzed

| File | Lines | Sections Informed |
|------|-------|-------------------|
{sources}
"""
    (checkout / "analyzer_architecture.md").write_text(md)
    data_coverage = {
        "agent_baseline": f"{readiness}: test analyzer facts",
        **(coverage or {}),
    }
    (checkout / "component-architecture.json").write_text(
        json.dumps(
            {
                "component": component,
                "data_coverage": data_coverage,
                "category_coverage": category_coverage or {},
                "authentication": [],
                "integration_points": [],
                "dependencies": {"internal_odh": []},
            }
        )
    )


# ── Gap Classification Tests ──


class TestGapClassification:
    """Gap categories: narrative, safety-critical, or structural."""

    def test_narrative_sections_are_classified_correctly(self):
        for section in NARRATIVE_SECTIONS:
            assert classify_gap(section) == "narrative"

    def test_safety_critical_categories_are_classified_correctly(self):
        for category in SAFETY_CRITICAL_CATEGORIES:
            assert classify_gap(category) == "safety-critical"

    def test_structural_categories_are_classified_correctly(self):
        structural = [
            "architecture_components",
            "integration_points",
            "internal_dependencies",
            "http_endpoints",
            "grpc_services",
            "services",
            "ingress",
            "egress",
            "crds",
            "external_dependencies",
        ]
        for category in structural:
            assert classify_gap(category) == "structural"

    def test_narrative_sections_constant_is_frozen(self):
        assert isinstance(NARRATIVE_SECTIONS, frozenset)

    def test_safety_critical_categories_constant_is_frozen(self):
        assert isinstance(SAFETY_CRITICAL_CATEGORIES, frozenset)

    def test_authentication_is_both_high_value_and_safety_critical(self):
        from lib.architecture_routing import HIGH_VALUE_AGENT_CATEGORIES

        assert "authentication" in HIGH_VALUE_AGENT_CATEGORIES
        assert "authentication" in SAFETY_CRITICAL_CATEGORIES


# ── Auditable Gap Reasons Tests ──


@pytest.mark.usefixtures("_open_allowlist")
class TestAuditableGapReasons:
    """Every gap must have an auditable reason in the policy."""

    def test_sufficient_with_gaps_produces_gap_reasons(self, tmp_path: Path):
        checkout = tmp_path / "sufficient-gaps"
        write_analyzer(
            checkout,
            "sufficient",
            source_files=["src/server.py"],
            coverage={
                "python": "partial: imports unresolved",
                "platform_semantics": "partial: aliases unresolved",
            },
            populate_high_value=False,
            empty_high_value={"authentication"},
        )
        policy = load_architecture_agent_policy(checkout, readiness_routing=True)

        assert policy.route == "synthesis"
        assert "authentication" in policy.gap_categories
        assert len(policy.gap_reasons) == len(policy.gap_categories)
        for reason in policy.gap_reasons:
            assert ":" in reason
            category, detail = reason.split(":", 1)
            assert category in policy.gap_categories
            assert classify_gap(category) in detail

    def test_partial_with_gaps_produces_gap_reasons(self, tmp_path: Path):
        checkout = tmp_path / "partial-gaps"
        write_analyzer(
            checkout, "partial", source_files=["deploy.yaml"],
        )
        policy = load_architecture_agent_policy(checkout, readiness_routing=True)

        assert policy.route == "partial"
        assert len(policy.gap_reasons) == len(policy.gap_categories)
        for reason in policy.gap_reasons:
            category = reason.split(":")[0]
            assert category in policy.gap_categories

    def test_no_gaps_produces_no_gap_reasons(self, tmp_path: Path):
        checkout = tmp_path / "no-gaps"
        write_analyzer(
            checkout,
            "sufficient",
            source_files=["src/main.py"],
            populate_high_value=True,
        )
        policy = load_architecture_agent_policy(checkout, readiness_routing=True)

        assert policy.gap_categories == ()
        assert policy.gap_reasons == ()

    def test_gap_reasons_in_prompt_arguments(self, tmp_path: Path):
        checkout = tmp_path / "prompt-gaps"
        write_analyzer(
            checkout,
            "sufficient",
            source_files=["src/server.py"],
            coverage={
                "python": "partial: imports unresolved",
                "platform_semantics": "partial: aliases unresolved",
            },
            populate_high_value=False,
            empty_high_value={"authentication", "integration_points"},
        )
        policy = load_architecture_agent_policy(checkout, readiness_routing=True)

        args = policy.prompt_arguments()
        assert "--gap-reasons=" in args

    def test_gap_reasons_in_policy_dict(self, tmp_path: Path):
        checkout = tmp_path / "dict-gaps"
        write_analyzer(
            checkout,
            "partial",
            source_files=["deploy.yaml"],
        )
        policy = load_architecture_agent_policy(checkout, readiness_routing=True)
        d = policy.to_dict()

        assert "gap_reasons" in d
        assert isinstance(d["gap_reasons"], tuple)

    def test_gap_reasons_in_guard_telemetry(self, tmp_path: Path):
        checkout = tmp_path / "checkout"
        checkout.mkdir()
        guard = _AgentExecutionGuard(
            {
                "route": "partial",
                "readiness": "partial",
                "gap_categories": ["authentication"],
                "gap_reasons": [
                    "authentication:safety-critical,empty-in-baseline",
                ],
                "file_budget": 4,
                "discovery_tools": ["Glob", "Grep"],
            },
            checkout,
        )

        telemetry = guard.telemetry()
        assert telemetry["gap_reasons"] == [
            "authentication:safety-critical,empty-in-baseline",
        ]


# ── Sufficient Route Source-Free Tests ──


@pytest.mark.usefixtures("_open_allowlist")
class TestSufficientRouteSourceFree:
    """Sufficient routes must never perform source reads or discovery."""

    def test_sufficient_route_has_no_file_budget(self, tmp_path: Path):
        checkout = tmp_path / "sufficient-budget"
        write_analyzer(checkout, "sufficient", source_files=["src/app.py"])
        policy = load_architecture_agent_policy(checkout, readiness_routing=True)

        assert policy.route == "synthesis"
        assert policy.file_budget is None

    def test_sufficient_route_has_no_source_files(self, tmp_path: Path):
        checkout = tmp_path / "sufficient-sources"
        write_analyzer(checkout, "sufficient", source_files=["src/app.py"])
        policy = load_architecture_agent_policy(checkout, readiness_routing=True)

        assert policy.source_files == ()

    def test_sufficient_route_has_no_discovery_tools(self, tmp_path: Path):
        checkout = tmp_path / "sufficient-tools"
        write_analyzer(checkout, "sufficient", source_files=["src/app.py"])
        policy = load_architecture_agent_policy(checkout, readiness_routing=True)

        assert policy.discovery_tools == ()

    @pytest.mark.asyncio
    async def test_sufficient_guard_denies_all_source_reads(self, tmp_path: Path):
        checkout = tmp_path / "checkout"
        checkout.mkdir()
        (checkout / "src").mkdir()
        (checkout / "src" / "main.py").write_text("source\n")
        guard = _AgentExecutionGuard(
            {
                "route": "synthesis",
                "readiness": "sufficient",
                "source_files": [],
                "discovery_tools": [],
            },
            checkout,
        )

        result = await guard.pre_tool_use(
            {"tool_name": "Read", "tool_input": {
                "file_path": str(checkout / "src" / "main.py"),
            }},
            None, {},
        )
        assert result["hookSpecificOutput"]["permissionDecision"] == "deny"
        assert guard.telemetry()["source_files_read"] == []


# ── Prior Architecture Isolation Tests ──


class TestPriorArchitectureIsolation:
    """Prior architecture/*.md files must never be used as synthesis inputs."""

    @pytest.mark.asyncio
    async def test_restricted_guard_denies_prior_architecture_read(
        self, tmp_path: Path,
    ):
        checkout = tmp_path / "checkout"
        checkout.mkdir()
        guard = _AgentExecutionGuard(
            {
                "route": "synthesis",
                "readiness": "sufficient",
                "source_files": [],
                "discovery_tools": [],
            },
            checkout,
        )

        result = await guard.pre_tool_use(
            {"tool_name": "Read", "tool_input": {
                "file_path": "/workspace/architecture/rhoai.next/rhods-operator.md",
            }},
            None, {},
        )
        assert result["hookSpecificOutput"]["permissionDecision"] == "deny"
        reason = result["hookSpecificOutput"]["permissionDecisionReason"]
        assert "comparison-only" in reason

    @pytest.mark.asyncio
    async def test_restricted_guard_denies_prior_architecture_nested(
        self, tmp_path: Path,
    ):
        checkout = tmp_path / "checkout"
        checkout.mkdir()
        guard = _AgentExecutionGuard(
            {
                "route": "partial",
                "readiness": "partial",
                "gap_categories": ["authentication"],
                "file_budget": 4,
                "discovery_tools": ["Glob", "Grep"],
            },
            checkout,
        )

        result = await guard.pre_tool_use(
            {"tool_name": "Read", "tool_input": {
                "file_path": str(
                    tmp_path / "architecture" / "rhoai.next" / "dashboard.md"
                ),
            }},
            None, {},
        )
        assert result["hookSpecificOutput"]["permissionDecision"] == "deny"

    def test_prior_architecture_path_detection(self):
        assert _AgentExecutionGuard._is_prior_architecture_path(
            "/workspace/architecture/rhoai.next/rhods-operator.md"
        )
        assert _AgentExecutionGuard._is_prior_architecture_path(
            "architecture/rhoai-3.5/dashboard.md"
        )
        assert not _AgentExecutionGuard._is_prior_architecture_path(
            "/workspace/checkouts/org/repo/GENERATED_ARCHITECTURE.md"
        )
        assert not _AgentExecutionGuard._is_prior_architecture_path(
            "/workspace/architecture"
        )
        assert not _AgentExecutionGuard._is_prior_architecture_path(
            "architecture/component-map.json"
        )

    @pytest.mark.asyncio
    async def test_legacy_guard_does_not_block_architecture_reads(
        self, tmp_path: Path,
    ):
        """Legacy route agents are unrestricted — not subject to isolation."""
        checkout = tmp_path / "checkout"
        checkout.mkdir()
        guard = _AgentExecutionGuard({"route": "legacy"}, checkout)

        result = await guard.pre_tool_use(
            {"tool_name": "Read", "tool_input": {
                "file_path": "/workspace/architecture/rhoai.next/dashboard.md",
            }},
            None, {},
        )
        assert result == {}


# ── Clean-Run Isolation Tests ──


@pytest.mark.usefixtures("_open_allowlist")
class TestCleanRunIsolation:
    """Clean-run isolation: prior generated docs must not leak into synthesis."""

    def test_sufficient_policy_is_always_analyzer_assisted(self, tmp_path: Path):
        checkout = tmp_path / "clean-analyzer-assisted"
        write_analyzer(
            checkout,
            "sufficient",
            coverage={
                "source": "partial: dynamic expressions unresolved",
                "platform_semantics": "partial: aliases unresolved",
            },
            populate_high_value=True,
            component="agents-operator",
        )
        policy = load_architecture_agent_policy(checkout, readiness_routing=True)

        assert policy.route == "synthesis"
        assert policy.output_preseeded is True

    def test_synthesis_route_is_output_preseeded(self, tmp_path: Path):
        checkout = tmp_path / "clean-synthesis"
        write_analyzer(checkout, "sufficient", source_files=["src/app.py"])
        policy = load_architecture_agent_policy(checkout, readiness_routing=True)

        assert policy.route == "synthesis"
        assert policy.output_preseeded is True

    def test_partial_route_is_output_preseeded(self, tmp_path: Path):
        checkout = tmp_path / "clean-partial"
        write_analyzer(checkout, "partial", source_files=["deploy.yaml"])
        policy = load_architecture_agent_policy(checkout, readiness_routing=True)

        assert policy.route == "partial"
        assert policy.output_preseeded is True

    def test_legacy_route_is_not_output_preseeded(self, tmp_path: Path):
        checkout = tmp_path / "clean-legacy"
        write_analyzer(checkout, "insufficient")
        policy = load_architecture_agent_policy(checkout, readiness_routing=True)

        assert policy.route == "legacy"
        assert policy.output_preseeded is False


# ── Provenance Preservation Tests ──


@pytest.mark.usefixtures("_open_allowlist")
class TestProvenancePreservation:
    """Analyzer-owned facts, provenance, and explicit unknowns must survive."""

    def test_policy_preserves_readiness_detail(self, tmp_path: Path):
        checkout = tmp_path / "provenance"
        write_analyzer(checkout, "sufficient", source_files=["src/main.py"])
        policy = load_architecture_agent_policy(checkout, readiness_routing=True)

        assert "test analyzer facts" in policy.readiness_detail

    def test_policy_preserves_route_reason(self, tmp_path: Path):
        checkout = tmp_path / "reason"
        write_analyzer(checkout, "partial", source_files=["deploy.yaml"])
        policy = load_architecture_agent_policy(checkout, readiness_routing=True)

        assert policy.reason != ""
        assert "bounded discovery" in policy.reason or "declared gap" in policy.reason

    def test_evidence_gated_property_correct(self, tmp_path: Path):
        checkout = tmp_path / "evidence"
        write_analyzer(checkout, "sufficient", source_files=["src/app.py"])
        policy = load_architecture_agent_policy(checkout, readiness_routing=True)

        assert policy.evidence_gated is True


# ── Narrative Gap Partial Route Tests ──


@pytest.mark.usefixtures("_open_allowlist")
class TestNarrativeGapPartialRoute:
    """Partial routes with narrative gaps nominate sections and permit bounded reads."""

    def test_partial_route_nominates_narrative_gaps(self, tmp_path: Path):
        """Partial baseline missing Purpose/DataFlows nominates narrative gaps."""
        checkout = tmp_path / "narrative-gaps"
        write_analyzer(
            checkout, "partial",
            source_files=["src/main.py"],
            coverage={"source": "partial: imports unresolved"},
        )
        policy = load_architecture_agent_policy(checkout, readiness_routing=True)

        assert policy.route == "partial"
        narrative_in_gaps = [
            g for g in policy.gap_categories if g in NARRATIVE_SECTIONS
        ]
        assert len(narrative_in_gaps) > 0, (
            f"expected narrative gaps to be nominated, got {policy.gap_categories}"
        )

    def test_partial_narrative_gap_reasons_include_classification(
        self, tmp_path: Path,
    ):
        """Gap reasons for narrative gaps include 'narrative' classification."""
        checkout = tmp_path / "narrative-reasons"
        write_analyzer(
            checkout, "partial",
            source_files=["src/main.py"],
            coverage={"source": "partial: imports unresolved"},
        )
        policy = load_architecture_agent_policy(checkout, readiness_routing=True)

        narrative_reasons = [
            r for r in policy.gap_reasons
            if r.split(":")[0] in NARRATIVE_SECTIONS
        ]
        assert len(narrative_reasons) > 0
        for reason in narrative_reasons:
            assert "narrative" in reason
            assert "thin-narrative" in reason

    def test_partial_narrative_gap_reasons_count_matches(self, tmp_path: Path):
        """Every gap category has exactly one matching gap reason."""
        checkout = tmp_path / "narrative-count"
        write_analyzer(
            checkout, "partial",
            source_files=["src/main.py"],
            coverage={"source": "partial: imports unresolved"},
        )
        policy = load_architecture_agent_policy(checkout, readiness_routing=True)
        assert len(policy.gap_reasons) == len(policy.gap_categories)

    @pytest.mark.asyncio
    async def test_partial_narrative_gap_allows_targeted_reads(
        self, tmp_path: Path,
    ):
        """Partial guard allows source reads within file budget for narrative gaps."""
        checkout = tmp_path / "narrative-reads"
        write_analyzer(
            checkout, "partial",
            source_files=["src/main.py"],
            coverage={"source": "partial: imports unresolved"},
        )
        policy = load_architecture_agent_policy(checkout, readiness_routing=True)
        guard = _AgentExecutionGuard(policy.to_dict(), checkout)

        result = await guard.pre_tool_use(
            {"tool_name": "Read", "tool_input": {
                "file_path": str(checkout / "src" / "main.py"),
            }},
            None, {},
        )
        assert result == {} or (
            result.get("hookSpecificOutput", {}).get("permissionDecision")
            == "allow"
        )
        assert guard.source_reads == ["src/main.py"]
        assert guard.telemetry()["source_file_count"] == 1

    @pytest.mark.asyncio
    async def test_partial_narrative_gap_records_only_declared_reads(
        self, tmp_path: Path,
    ):
        """Partial guard records only declared reads."""
        checkout = tmp_path / "narrative-declared"
        write_analyzer(
            checkout, "partial",
            source_files=["src/main.py", "src/util.py"],
            coverage={"source": "partial: imports unresolved"},
        )
        policy = load_architecture_agent_policy(checkout, readiness_routing=True)
        guard = _AgentExecutionGuard(policy.to_dict(), checkout)

        for src_file in ["src/main.py", "src/util.py"]:
            await guard.pre_tool_use(
                {"tool_name": "Read", "tool_input": {
                    "file_path": str(checkout / src_file),
                }},
                None, {},
            )

        telemetry = guard.telemetry()
        assert set(telemetry["source_files_read"]) == {"src/main.py", "src/util.py"}
        assert telemetry["source_file_count"] == 2

    @pytest.mark.asyncio
    async def test_partial_narrative_gap_denies_over_budget(
        self, tmp_path: Path,
    ):
        """Partial guard denies reads exceeding file budget."""
        checkout = tmp_path / "narrative-budget"
        extra_files = [f"src/f{i}.py" for i in range(12)]
        write_analyzer(
            checkout, "partial",
            source_files=extra_files,
            coverage={"source": "partial: imports unresolved"},
        )
        policy = load_architecture_agent_policy(checkout, readiness_routing=True)
        guard = _AgentExecutionGuard(policy.to_dict(), checkout)
        budget = policy.file_budget

        for i in range(budget):
            await guard.pre_tool_use(
                {"tool_name": "Read", "tool_input": {
                    "file_path": str(checkout / f"src/f{i}.py"),
                }},
                None, {},
            )

        result = await guard.pre_tool_use(
            {"tool_name": "Read", "tool_input": {
                "file_path": str(checkout / f"src/f{budget}.py"),
            }},
            None, {},
        )
        assert result["hookSpecificOutput"]["permissionDecision"] == "deny"
        assert "budget" in result["hookSpecificOutput"]["permissionDecisionReason"]

    def test_populated_narrative_sections_not_nominated(self, tmp_path: Path):
        """Baseline with substantial prose in narrative sections omits those gaps."""
        checkout = tmp_path / "populated-narrative"
        long_prose = "x" * (NARRATIVE_MIN_PROSE_LENGTH + 10)
        write_analyzer(
            checkout, "partial",
            source_files=["src/main.py"],
            coverage={"source": "partial: imports unresolved"},
            narrative_prose={
                "purpose": long_prose,
                "data_flows": long_prose,
                "architectural_analysis": long_prose,
            },
        )
        policy = load_architecture_agent_policy(checkout, readiness_routing=True)
        narrative_in_gaps = [
            g for g in policy.gap_categories if g in NARRATIVE_SECTIONS
        ]
        assert len(narrative_in_gaps) == 0, (
            f"populated narrative sections should not be nominated: {narrative_in_gaps}"
        )

    def test_narrative_gap_detection_function(self, tmp_path: Path):
        """_narrative_gap_sections correctly detects missing prose."""
        checkout = tmp_path / "detection"
        write_analyzer(checkout, "partial", source_files=["src/main.py"])
        md_path = checkout / "analyzer_architecture.md"

        gaps = _narrative_gap_sections(md_path)
        assert "purpose" in gaps
        assert "data_flows" in gaps
        assert "architectural_analysis" in gaps

    def test_narrative_gap_detection_with_prose(self, tmp_path: Path):
        """_narrative_gap_sections detects only missing sections."""
        checkout = tmp_path / "detection-prose"
        long_prose = "x" * (NARRATIVE_MIN_PROSE_LENGTH + 10)
        write_analyzer(
            checkout, "partial",
            source_files=["src/main.py"],
            narrative_prose={"purpose": long_prose},
        )
        md_path = checkout / "analyzer_architecture.md"

        gaps = _narrative_gap_sections(md_path)
        assert "purpose" not in gaps
        assert "data_flows" in gaps
        assert "architectural_analysis" in gaps


@pytest.mark.usefixtures("_open_allowlist")
class TestNarrativeGapSufficientDenial:
    """Sufficient routes must exclude narrative gaps and deny source reads."""

    def test_sufficient_route_excludes_narrative_gaps(self, tmp_path: Path):
        """Sufficient routes do not nominate narrative gaps."""
        checkout = tmp_path / "no-narrative"
        write_analyzer(
            checkout, "sufficient",
            source_files=["src/app.py"],
            populate_high_value=True,
        )
        policy = load_architecture_agent_policy(checkout, readiness_routing=True)

        assert policy.route == "synthesis"
        narrative_in_gaps = [
            g for g in policy.gap_categories if g in NARRATIVE_SECTIONS
        ]
        assert len(narrative_in_gaps) == 0

    @pytest.mark.asyncio
    async def test_sufficient_guard_denies_reads_for_narrative_content(
        self, tmp_path: Path,
    ):
        """Sufficient/synthesis guard denies source reads even for narrative gaps."""
        checkout = tmp_path / "denied-narrative"
        checkout.mkdir()
        (checkout / "src").mkdir()
        (checkout / "src" / "main.py").write_text("source\n")
        guard = _AgentExecutionGuard(
            {
                "route": "synthesis",
                "readiness": "sufficient",
                "source_files": [],
                "discovery_tools": [],
            },
            checkout,
        )

        result = await guard.pre_tool_use(
            {"tool_name": "Read", "tool_input": {
                "file_path": str(checkout / "src" / "main.py"),
            }},
            None, {},
        )
        assert result["hookSpecificOutput"]["permissionDecision"] == "deny"
        assert guard.telemetry()["source_files_read"] == []

    def test_sufficient_no_file_budget_for_narrative(self, tmp_path: Path):
        """Sufficient route has no file budget even when narrative is thin."""
        checkout = tmp_path / "no-budget-narrative"
        write_analyzer(
            checkout, "sufficient",
            source_files=["src/app.py"],
            populate_high_value=True,
        )
        policy = load_architecture_agent_policy(checkout, readiness_routing=True)

        assert policy.route == "synthesis"
        assert policy.file_budget is None
        assert policy.discovery_tools == ()


# ── Bounded Component Validation Fixtures ──


@pytest.mark.usefixtures("_open_allowlist")
class TestBoundedComponentFixtures:
    """Fixtures for bounded rhods-operator/dashboard validation."""

    def test_rhods_operator_sufficient_fixture(self, tmp_path: Path):
        """rhods-operator with sufficient readiness routes to synthesis."""
        checkout = tmp_path / "rhods-operator"
        write_analyzer(
            checkout,
            "sufficient",
            source_files=[
                "internal/controller/services/gateway/gateway.go",
                "internal/controller/services/dashboard/dashboard.go",
            ],
            coverage={
                "source": "partial: dynamic Go expressions unresolved",
                "platform_semantics": "partial: literal semantics only",
            },
            populate_high_value=True,
            empty_high_value={"authentication"},
            component="rhods-operator",
        )

        policy = load_architecture_agent_policy(checkout, readiness_routing=True)

        assert policy.readiness == "sufficient"
        assert policy.route == "synthesis"
        assert policy.output_preseeded is True
        assert policy.file_budget is None
        assert policy.discovery_tools == ()
        assert policy.source_files == ()

    def test_dashboard_partial_fixture(self, tmp_path: Path):
        """dashboard with partial readiness routes to partial with budget."""
        checkout = tmp_path / "odh-dashboard"
        write_analyzer(
            checkout,
            "partial",
            source_files=[
                "frontend/src/app.tsx",
                "backend/src/server.ts",
            ],
            coverage={
                "web_workspace": "partial: React imports unresolved",
                "source": "partial: dynamic TypeScript expressions unresolved",
            },
            component="odh-dashboard",
        )

        policy = load_architecture_agent_policy(checkout, readiness_routing=True)

        assert policy.readiness == "partial"
        assert policy.route == "partial"
        assert policy.output_preseeded is True
        assert policy.file_budget is not None
        assert policy.file_budget > 0
        assert "Glob" in policy.discovery_tools
        assert "Grep" in policy.discovery_tools
        assert len(policy.gap_categories) > 0
        assert len(policy.gap_reasons) == len(policy.gap_categories)

    def test_rhods_operator_synthesis_telemetry(self, tmp_path: Path):
        """Verify telemetry structure for a synthesis route fixture."""
        checkout = tmp_path / "telemetry-fixture"
        checkout.mkdir()
        (checkout / "analyzer_architecture.md").write_text("# baseline\n")
        (checkout / "GENERATED_ARCHITECTURE.md").write_text("# output\n")
        (checkout / "component-architecture.json").write_text("{}\n")

        guard = _AgentExecutionGuard(
            {
                "route": "synthesis",
                "readiness": "sufficient",
                "source_files": [],
                "discovery_tools": [],
                "output_preseeded": True,
                "component": "rhods-operator",
                "gap_categories": ["authentication"],
                "gap_reasons": [
                    "authentication:safety-critical,empty-in-baseline,partial-coverage",
                ],
            },
            checkout,
        )

        telemetry = guard.telemetry()
        assert telemetry["source_file_count"] == 0
        assert telemetry["source_files_read"] == []
        assert telemetry["denied_tool_calls"] == 0
        assert telemetry["gap_reasons"] == [
            "authentication:safety-critical,empty-in-baseline,partial-coverage",
        ]

    def test_dashboard_partial_telemetry(self, tmp_path: Path):
        """Verify telemetry structure for a partial route fixture."""
        checkout = tmp_path / "telemetry-partial"
        checkout.mkdir()
        (checkout / "analyzer_architecture.md").write_text("# baseline\n")
        (checkout / "GENERATED_ARCHITECTURE.md").write_text("# output\n")
        (checkout / "component-architecture.json").write_text("{}\n")

        guard = _AgentExecutionGuard(
            {
                "route": "partial",
                "readiness": "partial",
                "gap_categories": [
                    "architecture_components",
                    "authentication",
                    "http_endpoints",
                ],
                "gap_reasons": [
                    "architecture_components:structural,empty-in-baseline,partial-coverage",
                    "authentication:safety-critical,empty-in-baseline",
                    "http_endpoints:structural,partial-coverage",
                ],
                "source_files": ["frontend/src/app.tsx"],
                "file_budget": 6,
                "discovery_tools": ["Glob", "Grep"],
            },
            checkout,
        )

        telemetry = guard.telemetry()
        assert telemetry["source_file_count"] == 0
        assert len(telemetry["gap_reasons"]) == 3


# ── Bounded Component Validation with Local MLflow ──


def _make_validation_result(
    component: str,
    route: str,
    telemetry_data: dict,
    *,
    gap_reasons: list[str] | None = None,
) -> dict:
    """Build a minimal valid result record for MLflow tracking validation."""
    return {
        "experiment_id": "targeted-synthesis-validation",
        "condition_id": f"{route}-route",
        "question_id": f"validate-{component}",
        "model": "dry-run",
        "runner_version": "test-0.1.0",
        "timestamp": "2026-07-26T00:00:00Z",
        "schema_version": "1.0.0",
        "provenance": {
            "architecture_context_sha": "test-sha-0000",
            "corpus_version": "test",
        },
        "response": {"success": True},
        "telemetry": {
            "duration_seconds": 0.0,
            "input_tokens": 0,
            "output_tokens": 0,
            "total_cost_usd": 0.0,
            "num_turns": 0,
            "tool_calls": telemetry_data.get("tool_calls_by_name", {}),
        },
        "context_metrics": telemetry_data.get("context_metrics", {}),
        "validation": {
            "component": component,
            "route": route,
            "source_reads": telemetry_data.get("source_files_read", []),
            "source_file_count": telemetry_data.get("source_file_count", 0),
            "denied_tool_calls": telemetry_data.get("denied_tool_calls", 0),
            "gap_reasons": gap_reasons or [],
        },
    }


def _write_redacted_otel_capture(capture_dir: Path, component: str) -> Path:
    """Write a redacted OTel-style capture for a component validation."""
    spans = [
        {
            "traceId": "redacted-trace-id",
            "spanId": f"redacted-{component}-span",
            "operationName": f"validate-{component}",
            "startTime": "2026-07-26T00:00:00Z",
            "duration": 0,
            "tags": {
                "component": component,
                "route": "dry-run",
                "redacted": True,
            },
            "logs": [],
        },
    ]
    otel_path = capture_dir / f"{component}-otel.json"
    otel_path.write_text(json.dumps({"spans": spans}, indent=2))
    return otel_path


def _write_redacted_api_capture(capture_dir: Path, component: str) -> Path:
    """Write a redacted API capture for a component validation."""
    api_record = {
        "component": component,
        "api_calls": [],
        "redacted": True,
        "note": "No external API calls made during dry-run validation",
    }
    api_path = capture_dir / f"{component}-api.json"
    api_path.write_text(json.dumps(api_record, indent=2))
    return api_path


@pytest.mark.usefixtures("_open_allowlist")
class TestBoundedComponentValidation:
    """End-to-end bounded validation for rhods-operator and dashboard.

    Exercises: policy → guard → telemetry → MLflow dry-run → OTel/API
    capture artifacts under tmp/ paths. Does not require external MLflow,
    OTel collector, or human labels.
    """

    def test_rhods_operator_full_validation_pipeline(self, tmp_path: Path):
        """rhods-operator: sufficient → synthesis → zero source reads."""
        checkout = tmp_path / "rhods-operator"
        write_analyzer(
            checkout,
            "sufficient",
            source_files=[
                "internal/controller/services/gateway/gateway.go",
                "internal/controller/services/dashboard/dashboard.go",
            ],
            coverage={
                "source": "partial: dynamic Go expressions unresolved",
                "platform_semantics": "partial: literal semantics only",
            },
            populate_high_value=True,
            empty_high_value={"authentication"},
            component="rhods-operator",
        )

        policy = load_architecture_agent_policy(checkout, readiness_routing=True)
        assert policy.route == "synthesis"

        guard = _AgentExecutionGuard(policy.to_dict(), checkout)
        telemetry = guard.telemetry()
        assert telemetry["source_file_count"] == 0
        assert telemetry["denied_tool_calls"] == 0

        config = TrackingConfig(dry_run=True)
        result = _make_validation_result(
            "rhods-operator", "synthesis", telemetry,
            gap_reasons=list(policy.gap_reasons),
        )
        tracking = track_result(result, config)

        assert tracking.success is True
        assert tracking.dry_run is True
        assert "tracking_contract_version" in tracking.tags_logged
        assert tracking.tags_logged["condition_id"] == "synthesis-route"

    def test_dashboard_full_validation_pipeline(self, tmp_path: Path):
        """dashboard: partial → bounded discovery with file budget."""
        checkout = tmp_path / "odh-dashboard"
        write_analyzer(
            checkout,
            "partial",
            source_files=[
                "frontend/src/app.tsx",
                "backend/src/server.ts",
            ],
            coverage={
                "web_workspace": "partial: React imports unresolved",
                "source": "partial: dynamic TypeScript expressions unresolved",
            },
            component="odh-dashboard",
        )

        policy = load_architecture_agent_policy(checkout, readiness_routing=True)
        assert policy.route == "partial"
        assert policy.file_budget is not None

        guard = _AgentExecutionGuard(policy.to_dict(), checkout)
        telemetry = guard.telemetry()
        assert telemetry["source_file_count"] == 0

        config = TrackingConfig(dry_run=True)
        result = _make_validation_result(
            "odh-dashboard", "partial", telemetry,
            gap_reasons=list(policy.gap_reasons),
        )
        tracking = track_result(result, config)

        assert tracking.success is True
        assert tracking.dry_run is True
        assert len(policy.gap_reasons) == len(policy.gap_categories)

    def test_mlflow_preflight_dry_run(self):
        """MLflow preflight in dry-run mode reports correctly."""
        config = TrackingConfig(
            runs_dir="/tmp/test-mlflow-runs",
            experiment_name="targeted-synthesis-validation",
            dry_run=True,
        )
        result = preflight(config)

        assert result.configured is True
        assert result.mode == "local"
        assert result.experiment_name == "targeted-synthesis-validation"
        assert result.dry_run is True

    def test_mlflow_dry_run_captures_tags_and_metrics(self, tmp_path: Path):
        """Dry-run tracking produces tag/metric structure without SDK."""
        checkout = tmp_path / "track-test"
        write_analyzer(checkout, "sufficient", source_files=["src/app.py"])
        policy = load_architecture_agent_policy(checkout, readiness_routing=True)
        guard = _AgentExecutionGuard(policy.to_dict(), checkout)
        telemetry = guard.telemetry()

        config = TrackingConfig(dry_run=True)
        result_record = _make_validation_result(
            "test-component", "synthesis", telemetry,
        )
        tracking = track_result(result_record, config)

        assert tracking.success is True
        assert "experiment_id" in tracking.tags_logged
        assert "condition_id" in tracking.tags_logged
        assert "question_id" in tracking.tags_logged
        assert "provenance.architecture_context_sha" in tracking.tags_logged

    def test_otel_capture_artifact_structure(self, tmp_path: Path):
        """Redacted OTel capture is valid JSON under tmp/ path."""
        capture_dir = tmp_path / "otel-capture"
        capture_dir.mkdir()

        otel_path = _write_redacted_otel_capture(capture_dir, "rhods-operator")
        assert otel_path.exists()

        data = json.loads(otel_path.read_text())
        assert "spans" in data
        assert len(data["spans"]) == 1
        assert data["spans"][0]["tags"]["redacted"] is True
        assert data["spans"][0]["tags"]["component"] == "rhods-operator"

    def test_api_capture_artifact_structure(self, tmp_path: Path):
        """Redacted API capture is valid JSON under tmp/ path."""
        capture_dir = tmp_path / "api-capture"
        capture_dir.mkdir()

        api_path = _write_redacted_api_capture(capture_dir, "odh-dashboard")
        assert api_path.exists()

        data = json.loads(api_path.read_text())
        assert data["redacted"] is True
        assert data["component"] == "odh-dashboard"
        assert data["api_calls"] == []

    def test_validation_summary_artifact(self, tmp_path: Path):
        """Full validation summary covers both components."""
        summary_dir = tmp_path / "validation-summary"
        summary_dir.mkdir()

        components = []
        for name, readiness, route_kwargs in [
            (
                "rhods-operator",
                "sufficient",
                {
                    "source_files": ["gateway.go", "dashboard.go"],
                    "coverage": {
                        "source": "partial: dynamic Go unresolved",
                        "platform_semantics": "partial: literal only",
                    },
                    "populate_high_value": True,
                    "empty_high_value": {"authentication"},
                },
            ),
            (
                "odh-dashboard",
                "partial",
                {
                    "source_files": ["app.tsx", "server.ts"],
                    "coverage": {
                        "web_workspace": "partial: React imports unresolved",
                        "source": "partial: TypeScript unresolved",
                    },
                },
            ),
        ]:
            checkout = tmp_path / name
            write_analyzer(checkout, readiness, component=name, **route_kwargs)
            policy = load_architecture_agent_policy(
                checkout, readiness_routing=True,
            )
            guard = _AgentExecutionGuard(policy.to_dict(), checkout)
            telemetry = guard.telemetry()

            _write_redacted_otel_capture(summary_dir, name)
            _write_redacted_api_capture(summary_dir, name)

            components.append({
                "component": name,
                "readiness": policy.readiness,
                "route": policy.route,
                "source_reads": telemetry["source_file_count"],
                "denied_calls": telemetry["denied_tool_calls"],
                "gap_count": len(policy.gap_categories),
                "gap_reasons": list(policy.gap_reasons),
                "file_budget": policy.file_budget,
                "evidence_gated": policy.evidence_gated,
                "output_preseeded": policy.output_preseeded,
            })

        summary = {
            "validation": "bounded-component-validation",
            "mlflow_mode": "dry-run",
            "otel_mode": "redacted-capture",
            "api_mode": "redacted-capture",
            "components": components,
            "limitations": [
                "MLflow SDK not installed; dry-run mode only",
                "No external OTel collector; redacted captures only",
                "No external API calls; redacted placeholders only",
                "Existing feedback is directional evidence only",
            ],
        }
        summary_path = summary_dir / "validation-summary.json"
        summary_path.write_text(json.dumps(summary, indent=2))

        data = json.loads(summary_path.read_text())
        assert len(data["components"]) == 2
        op = data["components"][0]
        assert op["component"] == "rhods-operator"
        assert op["route"] == "synthesis"
        assert op["source_reads"] == 0
        db = data["components"][1]
        assert db["component"] == "odh-dashboard"
        assert db["route"] == "partial"
        assert db["file_budget"] is not None
        assert db["file_budget"] > 0

    @pytest.mark.asyncio
    async def test_synthesis_guard_denies_source_reads(self, tmp_path: Path):
        """Synthesis guard blocks source reads (zero budget)."""
        checkout = tmp_path / "guard-deny"
        write_analyzer(
            checkout,
            "sufficient",
            source_files=["src/main.go"],
            populate_high_value=True,
            component="rhods-operator",
        )
        policy = load_architecture_agent_policy(checkout, readiness_routing=True)
        guard = _AgentExecutionGuard(policy.to_dict(), checkout)

        result = await guard.pre_tool_use(
            {"tool_name": "Read", "tool_input": {
                "file_path": str(checkout / "src" / "main.go"),
            }},
            None, {},
        )
        assert result["hookSpecificOutput"]["permissionDecision"] == "deny"

    @pytest.mark.asyncio
    async def test_partial_guard_allows_budgeted_reads(self, tmp_path: Path):
        """Partial guard allows reads within file budget."""
        checkout = tmp_path / "guard-allow"
        write_analyzer(
            checkout,
            "partial",
            source_files=["frontend/src/app.tsx", "backend/src/server.ts"],
            component="odh-dashboard",
        )
        policy = load_architecture_agent_policy(checkout, readiness_routing=True)
        guard = _AgentExecutionGuard(policy.to_dict(), checkout)

        result = await guard.pre_tool_use(
            {"tool_name": "Read", "tool_input": {
                "file_path": str(checkout / "frontend" / "src" / "app.tsx"),
            }},
            None, {},
        )
        assert result == {} or (
            result.get("hookSpecificOutput", {}).get("permissionDecision")
            == "allow"
        )
        assert guard.source_reads == ["frontend/src/app.tsx"]
