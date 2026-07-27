import json
import sys
from pathlib import Path

import pytest

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from lib.agent_runner import _AgentExecutionGuard  # noqa: E402
from lib.architecture_routing import (  # noqa: E402
    _complete_empty_categories,
    _coverage_gap_categories,
    load_analyzer_only_approvals,
    load_architecture_agent_policy,
    load_source_audited_empty_categories,
    load_synthesis_migration_allowlist,
)


def analyzer_markdown(
    source_files: list[str],
    *,
    include_component: bool = True,
    populate_high_value: bool = False,
    empty_high_value: set[str] | None = None,
) -> str:
    empty = empty_high_value or set()
    sources = "\n".join(f"| {path} | 1-10 | Purpose |" for path in source_files)
    component = "| example | Service | Example |" if include_component else ""
    authentication = (
        "| /api | GET | Bearer token | middleware | authenticated |"
        if populate_high_value and "authentication" not in empty else ""
    )
    integrations = (
        "| database | SQL client | 5432 | PostgreSQL | TLS | persistence |"
        if populate_high_value and "integration_points" not in empty else ""
    )
    internal = (
        "| platform-api | HTTP client | platform integration |"
        if populate_high_value and "internal_dependencies" not in empty else ""
    )
    return f"""# Component: example

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
{component}

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


def write_analyzer(
    checkout: Path,
    readiness: str,
    *,
    source_files: list[str] | None = None,
    coverage: dict[str, str] | None = None,
    include_component: bool = True,
    populate_high_value: bool = False,
    empty_high_value: set[str] | None = None,
    category_coverage: dict[str, object] | None = None,
    component: str = "agents-operator",
) -> None:
    checkout.mkdir()
    files = source_files or []
    for name in files:
        path = checkout / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("source\n")
    (checkout / "ANALYZER_ARCHITECTURE.md").write_text(
        analyzer_markdown(
            files,
            include_component=include_component,
            populate_high_value=populate_high_value,
            empty_high_value=empty_high_value,
        )
    )
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


def test_sufficient_policy_routes_to_partial(tmp_path: Path):
    checkout = tmp_path / "sufficient"
    sources = [f"src/file{index}.py" for index in range(6)]
    write_analyzer(checkout, "sufficient", source_files=sources, component="caikit-nlp")

    policy = load_architecture_agent_policy(
        checkout,
        readiness_routing=True,
    )

    assert policy.route == "partial"
    assert policy.readiness == "sufficient"
    assert policy.file_budget is not None
    assert policy.discovery_tools == ("Glob", "Grep")
    assert policy.output_preseeded is True
    assert "--baseline-preseeded" in policy.prompt_arguments()
    assert "--analysis-route=partial" in policy.prompt_arguments()


def test_populated_sufficient_policy_routes_to_partial(
    tmp_path: Path,
):
    checkout = tmp_path / "analyzer-assisted"
    write_analyzer(
        checkout,
        "sufficient",
        coverage={
            "source": "partial: dynamic expressions unresolved",
            "platform_semantics": "partial: aliases unresolved",
        },
        populate_high_value=True,
        component="caikit-nlp",
    )

    policy = load_architecture_agent_policy(checkout, readiness_routing=True)

    assert policy.route == "partial"
    assert policy.evidence_gated is True
    assert policy.file_budget is not None
    assert policy.discovery_tools == ("Glob", "Grep")
    assert policy.output_preseeded is True


def test_unapproved_populated_candidate_routes_to_partial(tmp_path: Path):
    checkout = tmp_path / "candidate"
    write_analyzer(
        checkout,
        "sufficient",
        populate_high_value=True,
        component="not-yet-approved",
    )

    policy = load_architecture_agent_policy(checkout, readiness_routing=True)

    assert policy.route == "partial"
    assert policy.readiness == "sufficient"
    assert policy.output_preseeded is True
    assert policy.discovery_tools == ("Glob", "Grep")


def test_analyzer_only_approval_loader_rejects_invalid_entries(tmp_path: Path):
    path = tmp_path / "approvals.json"
    path.write_text(
        json.dumps({"components": ["approved", "", 3, "approved"]})
    )

    assert load_analyzer_only_approvals(path) == frozenset({"approved"})


def test_sufficient_policy_with_empty_high_value_tables_routes_to_partial(
    tmp_path: Path,
):
    checkout = tmp_path / "not-analyzer-only"
    write_analyzer(
        checkout,
        "sufficient",
        coverage={"source": "complete", "platform_semantics": "complete"},
        populate_high_value=False,
        component="caikit-nlp",
    )

    policy = load_architecture_agent_policy(checkout, readiness_routing=True)

    assert policy.route == "partial"
    assert policy.output_preseeded is True


def complete_coverage(contract: str) -> dict[str, object]:
    return {
        "status": "complete",
        "fact_count": 0,
        "discovery_contract": contract,
        "completed_checks": ["bounded-check"],
        "limitations": [],
        "evidence": ["summary:test coverage"],
    }


def test_contract_complete_empty_auth_and_internal_categories_route_to_partial(
    tmp_path: Path,
):
    checkout = tmp_path / "complete-empty"
    write_analyzer(
        checkout,
        "sufficient",
        coverage={
            "source": "partial: dynamic expressions unresolved",
            "platform_semantics": "partial: aliases unresolved",
        },
        populate_high_value=True,
        empty_high_value={"authentication", "internal_dependencies"},
        category_coverage={
            "authentication": complete_coverage("authentication/v1"),
            "internal_dependencies": complete_coverage(
                "internal-platform-dependencies/v1"
            ),
        },
        component="caikit-nlp",
    )

    policy = load_architecture_agent_policy(checkout, readiness_routing=True)

    assert policy.route == "partial"
    assert policy.output_preseeded is True
    assert "extend-and-improve" in policy.reason


@pytest.mark.parametrize(
    ("override", "expected"),
    [
        ({"discovery_contract": "authentication/v0"}, ()),
        ({"fact_count": 1}, ()),
        ({"completed_checks": []}, ()),
        ({"limitations": ["dynamic middleware unresolved"]}, ()),
        ({"evidence": []}, ()),
        ({"status": "partial"}, ()),
    ],
)
def test_complete_empty_category_rejects_untrusted_claims(override, expected):
    record = complete_coverage("authentication/v1")
    record.update(override)
    analyzer = {
        "authentication": [],
        "category_coverage": {"authentication": record},
    }

    assert _complete_empty_categories(analyzer, {"authentication"}) == expected


def test_complete_empty_category_requires_explicit_limitations_field():
    record = complete_coverage("authentication/v1")
    record.pop("limitations")
    analyzer = {
        "authentication": [],
        "category_coverage": {"authentication": record},
    }

    assert _complete_empty_categories(analyzer, {"authentication"}) == ()


def test_json_without_category_coverage_routes_to_partial(
    tmp_path: Path,
):
    checkout = tmp_path / "legacy-category-coverage"
    write_analyzer(
        checkout,
        "sufficient",
        populate_high_value=True,
        empty_high_value={"authentication"},
        component="caikit-nlp",
    )

    policy = load_architecture_agent_policy(checkout, readiness_routing=True)

    assert policy.route == "partial"
    assert policy.output_preseeded is True


def test_complete_empty_internal_dependency_accepts_json_null_fact_slice():
    analyzer = {
        "dependencies": {"internal_odh": None},
        "category_coverage": {
            "internal_dependencies": complete_coverage(
                "internal-platform-dependencies/v1"
            )
        },
    }

    assert _complete_empty_categories(analyzer, {"internal_dependencies"}) == (
        "internal_dependencies",
    )


def test_complete_empty_integration_points_with_contract():
    analyzer = {
        "integration_points": [],
        "category_coverage": {
            "integration_points": complete_coverage("integration-points/v1")
        },
    }

    assert _complete_empty_categories(analyzer, {"integration_points"}) == (
        "integration_points",
    )


def test_complete_empty_integration_points_rejects_wrong_contract():
    record = complete_coverage("integration-points/v1")
    record["discovery_contract"] = "integration-points/v0"
    analyzer = {
        "integration_points": [],
        "category_coverage": {"integration_points": record},
    }

    assert _complete_empty_categories(analyzer, {"integration_points"}) == ()


def test_complete_empty_integration_points_rejects_nonempty_facts():
    record = complete_coverage("integration-points/v1")
    record["fact_count"] = 1
    analyzer = {
        "integration_points": [{"component": "Redis"}],
        "category_coverage": {"integration_points": record},
    }

    assert _complete_empty_categories(analyzer, {"integration_points"}) == ()


def test_all_three_complete_empty_contracts_route_to_partial(tmp_path: Path):
    checkout = tmp_path / "all-three-complete-empty"
    write_analyzer(
        checkout,
        "sufficient",
        coverage={
            "source": "partial: dynamic expressions unresolved",
            "platform_semantics": "partial: aliases unresolved",
        },
        populate_high_value=True,
        empty_high_value={
            "authentication",
            "integration_points",
            "internal_dependencies",
        },
        category_coverage={
            "authentication": complete_coverage("authentication/v1"),
            "integration_points": complete_coverage("integration-points/v1"),
            "internal_dependencies": complete_coverage(
                "internal-platform-dependencies/v1"
            ),
        },
        component="caikit-nlp",
    )

    policy = load_architecture_agent_policy(checkout, readiness_routing=True)

    assert policy.route == "partial"
    assert policy.output_preseeded is True


def test_partial_policy_derives_category_and_file_budgets(tmp_path: Path):
    checkout = tmp_path / "partial"
    write_analyzer(checkout, "partial", source_files=["deploy.yaml"])

    policy = load_architecture_agent_policy(
        checkout,
        readiness_routing=True,
    )

    assert policy.route == "partial"
    assert "authentication" in policy.gap_categories
    assert "integration_points" in policy.gap_categories
    assert "internal_dependencies" in policy.gap_categories
    assert len(policy.gap_categories) <= 6
    assert policy.file_budget is not None
    assert policy.discovery_tools == ("Glob", "Grep")
    assert "--file-budget=" in policy.prompt_arguments()
    assert "--gap-categories=authentication" in (
        policy.prompt_arguments()
    )


def test_partial_policy_prioritizes_explicit_language_coverage_gaps(
    tmp_path: Path,
):
    checkout = tmp_path / "partial-python"
    write_analyzer(checkout, "partial", source_files=["module.py"])
    analyzer_path = checkout / "component-architecture.json"
    analyzer = json.loads(analyzer_path.read_text())
    analyzer["data_coverage"]["python"] = (
        "partial: imports and call graphs not resolved"
    )
    analyzer_path.write_text(json.dumps(analyzer))

    policy = load_architecture_agent_policy(
        checkout,
        readiness_routing=True,
    )

    assert "architecture_components" in policy.gap_categories
    assert "authentication" in policy.gap_categories
    assert "integration_points" in policy.gap_categories
    assert "internal_dependencies" in policy.gap_categories
    assert len(policy.gap_categories) <= 6


def test_partial_batch_gateway_prioritizes_agent_owned_categories(tmp_path: Path):
    checkout = tmp_path / "batch-gateway"
    write_analyzer(
        checkout,
        "partial",
        source_files=["internal/apiserver/server/server.go"],
        coverage={
            "manifests": "partial: templated Helm YAML skipped",
            "platform_semantics": "partial: semantic aliases only",
            "source": "partial: dynamic routes and watched expressions unresolved",
            "python": "not_applicable",
            "rust": "not_applicable",
            "web_workspace": "not_applicable",
        },
        include_component=False,
    )

    policy = load_architecture_agent_policy(checkout, readiness_routing=True)

    assert "architecture_components" in policy.gap_categories
    assert "authentication" in policy.gap_categories
    assert "integration_points" in policy.gap_categories
    assert "internal_dependencies" in policy.gap_categories
    assert len(policy.gap_categories) <= 6
    assert "rbac_cluster_roles" not in policy.gap_categories
    assert "rbac_role_bindings" not in policy.gap_categories
    assert "secrets" not in policy.gap_categories


def test_sparse_sufficient_policy_routes_to_partial_with_gap_categories(
    tmp_path: Path,
):
    checkout = tmp_path / "sufficient-sparse"
    sources = [f"src/file{index}.go" for index in range(6)]
    write_analyzer(
        checkout,
        "sufficient",
        source_files=sources,
        coverage={
            "source": "partial: dynamic routes unresolved",
            "platform_semantics": "partial: literal semantics only",
        },
        include_component=False,
        component="caikit-nlp",
    )

    policy = load_architecture_agent_policy(checkout, readiness_routing=True)

    assert policy.route == "partial"
    assert "architecture_components" in policy.gap_categories
    assert "authentication" in policy.gap_categories
    assert "integration_points" in policy.gap_categories
    assert "internal_dependencies" in policy.gap_categories
    assert len(policy.gap_categories) <= 6
    assert policy.file_budget is not None
    assert policy.discovery_tools == ("Glob", "Grep")
    assert policy.output_preseeded is True


def test_coverage_hints_match_emitted_source_and_semantic_keys():
    gaps = _coverage_gap_categories(
        {
            "data_coverage": {
                "source": "partial: dynamic Go expressions unresolved",
                "platform_semantics": "partial: semantic aliases only",
                "go": "partial: obsolete key must be ignored",
            }
        }
    )

    assert "architecture_components" in gaps
    assert "authentication" in gaps
    assert "integration_points" in gaps
    assert "internal_dependencies" in gaps
    assert _coverage_gap_categories(
        {"data_coverage": {"go": "partial: dead key"}}
    ) == ()


def test_unknown_readiness_with_valid_artifacts_routes_to_partial(
    tmp_path: Path,
):
    """Valid JSON and Markdown with unrecognized readiness routes to partial."""
    checkout = tmp_path / "unknown"
    write_analyzer(checkout, "unknown")

    policy = load_architecture_agent_policy(
        checkout,
        readiness_routing=True,
    )

    assert policy.route == "partial"
    assert policy.readiness == "unknown"
    assert policy.output_preseeded is True
    assert policy.file_budget is not None
    assert policy.discovery_tools == ("Glob", "Grep")
    assert "Bash" not in policy.discovery_tools
    assert "Task" not in policy.discovery_tools


def test_insufficient_readiness_with_valid_artifacts_routes_to_partial(
    tmp_path: Path,
):
    checkout = tmp_path / "insufficient"
    write_analyzer(checkout, "insufficient", source_files=["deploy.yaml"])

    policy = load_architecture_agent_policy(
        checkout,
        readiness_routing=True,
    )

    assert policy.route == "partial"
    assert policy.readiness == "insufficient"
    assert policy.output_preseeded is True
    assert policy.file_budget is not None
    assert policy.discovery_tools == ("Glob", "Grep")
    assert "Bash" not in policy.discovery_tools
    assert "Task" not in policy.discovery_tools


@pytest.mark.asyncio
async def test_legacy_guard_counts_reads_without_restricting_them(tmp_path: Path):
    checkout = tmp_path / "checkout"
    source = checkout / "src" / "app.py"
    source.parent.mkdir(parents=True)
    source.write_text("print('ok')\n")
    guard = _AgentExecutionGuard({"route": "legacy"}, checkout)

    decision = await guard.pre_tool_use(
        {"tool_name": "Read", "tool_input": {"file_path": str(source)}},
        None,
        {},
    )

    assert decision == {}
    assert guard.telemetry()["read_calls"] == 1
    assert guard.telemetry()["source_files_read"] == ["src/app.py"]


@pytest.mark.asyncio
async def test_sufficient_guard_denies_unlisted_source_and_discovery(tmp_path: Path):
    checkout = tmp_path / "checkout"
    checkout.mkdir()
    allowed = checkout / "allowed.py"
    denied = checkout / "denied.py"
    allowed.write_text("allowed\n")
    denied.write_text("denied\n")
    guard = _AgentExecutionGuard(
        {
            "route": "synthesis",
            "readiness": "sufficient",
            "source_files": [],
            "discovery_tools": [],
        },
        checkout,
    )

    allowed_result = await guard.pre_tool_use(
        {"tool_name": "Read", "tool_input": {"file_path": str(allowed)}},
        None,
        {},
    )
    denied_result = await guard.pre_tool_use(
        {"tool_name": "Read", "tool_input": {"file_path": str(denied)}},
        None,
        {},
    )
    grep_result = await guard.pre_tool_use(
        {"tool_name": "Grep", "tool_input": {"pattern": "route"}},
        None,
        {},
    )

    assert allowed_result["hookSpecificOutput"]["permissionDecision"] == "deny"
    assert denied_result["hookSpecificOutput"]["permissionDecision"] == "deny"
    assert grep_result["hookSpecificOutput"]["permissionDecision"] == "deny"
    assert guard.telemetry()["source_files_read"] == []


@pytest.mark.asyncio
async def test_partial_guard_enforces_file_budget_and_filename_only_grep(
    tmp_path: Path,
):
    checkout = tmp_path / "checkout"
    checkout.mkdir()
    first = checkout / "first.py"
    second = checkout / "second.py"
    first.write_text("first\n")
    second.write_text("second\n")
    guard = _AgentExecutionGuard(
        {
            "route": "partial",
            "readiness": "partial",
            "gap_categories": ["http_endpoints"],
            "source_files": [],
            "file_budget": 1,
            "discovery_tools": ["Glob", "Grep"],
        },
        checkout,
    )

    grep_result = await guard.pre_tool_use(
        {
            "tool_name": "Grep",
            "tool_input": {
                "pattern": "route",
                "path": str(checkout),
                "output_mode": "content",
            },
        },
        None,
        {},
    )
    await guard.pre_tool_use(
        {"tool_name": "Read", "tool_input": {"file_path": str(first)}},
        None,
        {},
    )
    second_result = await guard.pre_tool_use(
        {"tool_name": "Read", "tool_input": {"file_path": str(second)}},
        None,
        {},
    )

    updated = grep_result["hookSpecificOutput"]["updatedInput"]
    assert updated["output_mode"] == "files_with_matches"
    assert updated["head_limit"] == 1
    assert second_result["hookSpecificOutput"]["permissionDecision"] == "deny"
    assert guard.telemetry()["source_file_count"] == 1


@pytest.mark.asyncio
async def test_partial_guard_denies_full_checkout_glob(tmp_path: Path):
    checkout = tmp_path / "checkout"
    checkout.mkdir()
    guard = _AgentExecutionGuard(
        {
            "route": "partial",
            "readiness": "partial",
            "gap_categories": ["architecture_components"],
            "file_budget": 4,
            "discovery_tools": ["Glob", "Grep"],
        },
        checkout,
    )

    result = await guard.pre_tool_use(
        {
            "tool_name": "Glob",
            "tool_input": {"pattern": "*", "path": str(checkout)},
        },
        None,
        {},
    )

    assert result["hookSpecificOutput"]["permissionDecision"] == "deny"


@pytest.mark.asyncio
async def test_partial_guard_denies_nonessential_tools(tmp_path: Path):
    checkout = tmp_path / "checkout"
    checkout.mkdir()
    guard = _AgentExecutionGuard(
        {
            "route": "partial",
            "readiness": "partial",
            "gap_categories": ["architecture_components"],
            "file_budget": 4,
            "discovery_tools": ["Glob", "Grep"],
        },
        checkout,
    )

    result = await guard.pre_tool_use(
        {"tool_name": "TodoWrite", "tool_input": {"todos": []}},
        None,
        {},
    )

    assert result["hookSpecificOutput"]["permissionDecision"] == "deny"


@pytest.mark.asyncio
async def test_synthesis_guard_denies_full_write_to_preseeded_output(tmp_path: Path):
    checkout = tmp_path / "checkout"
    checkout.mkdir()
    output = checkout / "GENERATED_ARCHITECTURE.md"
    output.write_text("baseline\n")
    guard = _AgentExecutionGuard(
        {
            "route": "synthesis",
            "readiness": "sufficient",
            "gap_categories": [],
            "file_budget": 0,
            "discovery_tools": [],
            "output_preseeded": True,
        },
        checkout,
    )

    write_result = await guard.pre_tool_use(
        {
            "tool_name": "Write",
            "tool_input": {"file_path": str(output), "content": "replacement"},
        },
        None,
        {},
    )
    edit_result = await guard.pre_tool_use(
        {
            "tool_name": "Edit",
            "tool_input": {
                "file_path": str(output),
                "old_string": "baseline",
                "new_string": "synthesis",
            },
        },
        None,
        {},
    )

    assert write_result["hookSpecificOutput"]["permissionDecision"] == "deny"
    assert edit_result == {}


@pytest.mark.asyncio
async def test_evidence_gated_guard_allows_insight_artifact_output(tmp_path: Path):
    checkout = tmp_path / "checkout"
    checkout.mkdir()
    guard = _AgentExecutionGuard(
        {"route": "partial", "readiness": "partial"},
        checkout,
    )

    result = await guard.pre_tool_use(
        {
            "tool_name": "Write",
            "tool_input": {
                "file_path": str(checkout / "INSIGHTS_ARTIFACT.json"),
                "content": "{}",
            },
        },
        None,
        {},
    )

    assert result == {}


def test_source_audited_empty_categories_loader(tmp_path: Path):
    path = tmp_path / "adjudications.json"
    path.write_text(
        json.dumps(
            {
                "accepted_analyzer_absences": [],
                "source_audited_empty_categories": [
                    {
                        "component": "example",
                        "category": "authentication",
                        "reason": "No auth code",
                        "evidence": ["Dockerfile:1-10"],
                    },
                    {
                        "component": "example",
                        "category": "internal_dependencies",
                        "reason": "No deps",
                        "evidence": ["go.mod:1-5"],
                    },
                    {
                        "component": "bad",
                        "category": "auth",
                        "reason": "",
                        "evidence": [],
                    },
                ],
            }
        )
    )

    result = load_source_audited_empty_categories(path)

    assert result == {
        "example": frozenset({"authentication", "internal_dependencies"})
    }


def test_source_audited_categories_enable_analyzer_only_eligibility(tmp_path: Path):
    from lib.architecture_routing import analyzer_only_eligibility

    checkout = tmp_path / "source-audited"
    write_analyzer(
        checkout,
        "sufficient",
        coverage={
            "source": "partial: dynamic expressions unresolved",
            "python": "partial: imports unresolved",
            "platform_semantics": "partial: aliases unresolved",
        },
        populate_high_value=True,
        empty_high_value={
            "authentication",
            "integration_points",
            "internal_dependencies",
        },
    )
    analyzer = json.loads((checkout / "component-architecture.json").read_text())

    eligible_without, _ = analyzer_only_eligibility(
        "sufficient",
        analyzer,
        {"authentication", "integration_points", "internal_dependencies"},
    )
    assert not eligible_without

    eligible_with, reason = analyzer_only_eligibility(
        "sufficient",
        analyzer,
        {"authentication", "integration_points", "internal_dependencies"},
        source_audited=frozenset(
            {"authentication", "integration_points", "internal_dependencies"}
        ),
    )
    assert eligible_with
    assert "contract-complete" in reason


def test_source_audited_policy_routes_to_partial(tmp_path: Path):
    """Source-audited sufficient components route to partial like all others."""
    checkout = tmp_path / "audited-routing"
    write_analyzer(
        checkout,
        "sufficient",
        coverage={
            "python": "partial: imports unresolved",
            "platform_semantics": "partial: aliases unresolved",
        },
        populate_high_value=True,
        empty_high_value={
            "authentication",
            "integration_points",
            "internal_dependencies",
        },
        component="caikit-nlp",
    )

    policy = load_architecture_agent_policy(checkout, readiness_routing=True)

    assert policy.route == "partial"
    assert policy.readiness == "sufficient"
    assert policy.output_preseeded is True


# ── Synthesis migration allowlist tests ──


def test_synthesis_migration_allowlist_loader_accepts_valid_entries(tmp_path: Path):
    path = tmp_path / "allowlist.json"
    path.write_text(
        json.dumps({"schema_version": 1, "components": ["kserve", "", 3, "kserve"]})
    )

    assert load_synthesis_migration_allowlist(path) == frozenset({"kserve"})


def test_synthesis_migration_allowlist_loader_returns_empty_on_missing_file(
    tmp_path: Path,
):
    assert load_synthesis_migration_allowlist(tmp_path / "missing.json") == frozenset()


def test_synthesis_migration_allowlist_loader_returns_empty_on_invalid_json(
    tmp_path: Path,
):
    path = tmp_path / "bad.json"
    path.write_text("{not valid json")

    assert load_synthesis_migration_allowlist(path) == frozenset()


def test_sufficient_routes_to_partial_regardless_of_empty_allowlist(tmp_path: Path):
    """Sufficient readiness routes to partial; the allowlist is audit-only."""
    checkout = tmp_path / "sufficient"
    write_analyzer(checkout, "sufficient", source_files=["src/main.py"])

    policy = load_architecture_agent_policy(checkout, readiness_routing=True)

    assert policy.route == "partial"
    assert policy.readiness == "sufficient"
    assert policy.output_preseeded is True


def test_sufficient_unlisted_on_allowlist_still_routes_to_partial(
    tmp_path: Path,
):
    """Sufficient readiness routes to partial even when unlisted on allowlist."""
    checkout = tmp_path / "unlisted"
    write_analyzer(checkout, "sufficient", component="not-on-list")

    policy = load_architecture_agent_policy(checkout, readiness_routing=True)

    assert policy.route == "partial"
    assert policy.readiness == "sufficient"
    assert policy.output_preseeded is True
    assert policy.discovery_tools == ("Glob", "Grep")


def test_sufficient_listed_on_allowlist_still_routes_to_partial(tmp_path: Path):
    """Even components on the allowlist route to partial, not synthesis."""
    checkout = tmp_path / "listed"
    write_analyzer(checkout, "sufficient", component="kserve")

    policy = load_architecture_agent_policy(checkout, readiness_routing=True)

    assert policy.route == "partial"
    assert policy.readiness == "sufficient"
    assert policy.output_preseeded is True


def test_partial_readiness_routes_to_partial_regardless_of_allowlist(tmp_path: Path):
    """Partial readiness routes to partial; allowlist has no routing effect."""
    checkout = tmp_path / "partial-not-gated"
    write_analyzer(checkout, "partial", component="not-on-list")

    policy = load_architecture_agent_policy(checkout, readiness_routing=True)

    assert policy.route == "partial"
    assert policy.readiness == "partial"
    assert policy.output_preseeded is True


def test_sufficient_routes_to_partial_even_when_unlisted(tmp_path: Path):
    """Sufficient readiness routes to partial; allowlist is audit-only."""
    checkout = tmp_path / "synthesis-allowlist-gated"
    write_analyzer(
        checkout,
        "sufficient",
        coverage={
            "source": "partial: dynamic expressions unresolved",
            "platform_semantics": "partial: aliases unresolved",
        },
        populate_high_value=True,
    )

    policy = load_architecture_agent_policy(checkout, readiness_routing=True)

    assert policy.route == "partial"
    assert policy.readiness == "sufficient"
    assert policy.output_preseeded is True


def test_routing_preserves_checkout_path_identity_in_provenance(tmp_path: Path):
    """The checkout path used for routing must be traceable in the policy."""
    checkout = tmp_path / "data" / "checkouts" / "org.next" / "my-component"
    checkout.parent.mkdir(parents=True, exist_ok=True)
    write_analyzer(
        checkout, "partial", component="my-component", source_files=["src/main.py"]
    )

    policy = load_architecture_agent_policy(checkout, readiness_routing=True)

    assert policy.route == "partial"
    policy_dict = policy.to_dict()
    assert policy_dict["readiness"] == "partial"
    assert policy_dict["route"] == "partial"
    assert policy_dict["source_files"] == ("src/main.py",)


# ── Route-specific guard behavior tests ──


@pytest.mark.asyncio
async def test_synthesis_guard_allows_navigation_file_reads(tmp_path: Path):
    """Synthesis agents must be able to read analyzer/output navigation files."""
    checkout = tmp_path / "checkout"
    checkout.mkdir()
    (checkout / "ANALYZER_ARCHITECTURE.md").write_text("# analyzer baseline\n")
    (checkout / "GENERATED_ARCHITECTURE.md").write_text("# preseeded output\n")
    (checkout / "component-architecture.json").write_text("{}\n")
    guard = _AgentExecutionGuard(
        {
            "route": "synthesis",
            "readiness": "sufficient",
            "source_files": [],
            "discovery_tools": [],
        },
        checkout,
    )

    for nav_file in [
        "ANALYZER_ARCHITECTURE.md",
        "GENERATED_ARCHITECTURE.md",
        "component-architecture.json",
    ]:
        path = str(checkout / nav_file)
        result = await guard.pre_tool_use(
            {"tool_name": "Read", "tool_input": {"file_path": path}},
            None,
            {},
        )
        decision = (
            result.get("hookSpecificOutput", {}).get("permissionDecision")
        )
        assert decision != "deny", (
            f"synthesis guard must allow reading {nav_file}"
        )

    assert guard.telemetry()["source_files_read"] == []
    assert guard.telemetry()["read_calls"] == 3


@pytest.mark.asyncio
async def test_synthesis_guard_denies_bash_and_task(tmp_path: Path):
    """Synthesis agents must not run shell commands or spawn sub-agents."""
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

    bash_result = await guard.pre_tool_use(
        {"tool_name": "Bash", "tool_input": {"command": "find . -type f"}},
        None,
        {},
    )
    task_result = await guard.pre_tool_use(
        {"tool_name": "Task", "tool_input": {"prompt": "analyze files"}},
        None,
        {},
    )

    assert bash_result["hookSpecificOutput"]["permissionDecision"] == "deny"
    assert task_result["hookSpecificOutput"]["permissionDecision"] == "deny"
    assert guard.telemetry()["denied_tool_calls"] == 2
    assert guard.telemetry()["denied_tool_calls_by_name"]["Bash"] == 1
    assert guard.telemetry()["denied_tool_calls_by_name"]["Task"] == 1


@pytest.mark.asyncio
async def test_synthesis_guard_denies_all_source_reads(tmp_path: Path):
    """Synthesis agents with no allowed source files must not read any source."""
    checkout = tmp_path / "checkout"
    checkout.mkdir()
    for name in ["src/main.py", "cmd/server.go", "deploy.yaml"]:
        path = checkout / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("source\n")
    guard = _AgentExecutionGuard(
        {
            "route": "synthesis",
            "readiness": "sufficient",
            "source_files": [],
            "discovery_tools": [],
        },
        checkout,
    )

    for source_file in ["src/main.py", "cmd/server.go", "deploy.yaml"]:
        path = str(checkout / source_file)
        result = await guard.pre_tool_use(
            {"tool_name": "Read", "tool_input": {"file_path": path}},
            None,
            {},
        )
        assert result["hookSpecificOutput"]["permissionDecision"] == "deny"

    assert guard.telemetry()["source_files_read"] == []
    assert guard.telemetry()["denied_tool_calls_by_name"]["Read"] == 3


@pytest.mark.asyncio
async def test_synthesis_telemetry_fixture(tmp_path: Path):
    """Fixture: a typical synthesis agent run produces bounded telemetry."""
    checkout = tmp_path / "checkout"
    checkout.mkdir()
    (checkout / "ANALYZER_ARCHITECTURE.md").write_text("# baseline\n")
    (checkout / "GENERATED_ARCHITECTURE.md").write_text("# output\n")
    (checkout / "component-architecture.json").write_text("{}\n")
    (checkout / "src" / "app.py").mkdir(parents=True, exist_ok=True)
    (checkout / "src" / "app.py").rmdir()
    (checkout / "src").rmdir()
    source = checkout / "src" / "app.py"
    source.parent.mkdir(parents=True, exist_ok=True)
    source.write_text("print('hello')\n")

    guard = _AgentExecutionGuard(
        {
            "route": "synthesis",
            "readiness": "sufficient",
            "source_files": [],
            "discovery_tools": [],
            "output_preseeded": True,
        },
        checkout,
    )

    gen_path = str(checkout / "GENERATED_ARCHITECTURE.md")
    json_path = str(checkout / "component-architecture.json")
    await guard.pre_tool_use(
        {"tool_name": "Read", "tool_input": {"file_path": gen_path}},
        None,
        {},
    )
    await guard.pre_tool_use(
        {"tool_name": "Read", "tool_input": {"file_path": json_path}},
        None,
        {},
    )
    await guard.pre_tool_use(
        {"tool_name": "Edit", "tool_input": {
            "file_path": str(checkout / "GENERATED_ARCHITECTURE.md"),
            "old_string": "# output",
            "new_string": "# refined output",
        }},
        None,
        {},
    )
    await guard.pre_tool_use(
        {"tool_name": "Bash", "tool_input": {"command": "ls"}},
        None,
        {},
    )
    await guard.pre_tool_use(
        {"tool_name": "Read", "tool_input": {"file_path": str(source)}},
        None,
        {},
    )
    await guard.pre_tool_use(
        {"tool_name": "Grep", "tool_input": {"pattern": "endpoint"}},
        None,
        {},
    )

    telemetry = guard.telemetry()
    assert telemetry["source_files_read"] == []
    assert telemetry["source_file_count"] == 0
    assert telemetry["denied_tool_calls"] == 3
    denied_names = set(telemetry["denied_tool_calls_by_name"].keys())
    assert denied_names == {"Bash", "Read", "Grep"}
    assert telemetry["read_calls"] == 3
    assert telemetry["tool_calls"] == 6


@pytest.mark.asyncio
async def test_partial_guard_allows_gap_category_discovery(tmp_path: Path):
    """Partial agents may use Glob/Grep within gap category scope."""
    checkout = tmp_path / "checkout"
    checkout.mkdir()
    guard = _AgentExecutionGuard(
        {
            "route": "partial",
            "readiness": "partial",
            "gap_categories": ["authentication", "http_endpoints"],
            "source_files": [],
            "file_budget": 4,
            "discovery_tools": ["Glob", "Grep"],
        },
        checkout,
    )

    grep_result = await guard.pre_tool_use(
        {
            "tool_name": "Grep",
            "tool_input": {"pattern": "auth", "path": str(checkout)},
        },
        None,
        {},
    )
    glob_result = await guard.pre_tool_use(
        {
            "tool_name": "Glob",
            "tool_input": {"pattern": "**/*.go", "path": str(checkout)},
        },
        None,
        {},
    )

    assert grep_result["hookSpecificOutput"]["permissionDecision"] == "allow"
    assert glob_result["hookSpecificOutput"]["permissionDecision"] == "allow"
    assert guard.telemetry()["denied_tool_calls"] == 0


@pytest.mark.asyncio
async def test_partial_guard_denies_bash_and_task(tmp_path: Path):
    """Partial agents must not run shell commands or spawn sub-agents."""
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

    bash_result = await guard.pre_tool_use(
        {"tool_name": "Bash", "tool_input": {"command": "find . -type f"}},
        None,
        {},
    )
    task_result = await guard.pre_tool_use(
        {"tool_name": "Task", "tool_input": {"prompt": "analyze files"}},
        None,
        {},
    )

    assert bash_result["hookSpecificOutput"]["permissionDecision"] == "deny"
    assert task_result["hookSpecificOutput"]["permissionDecision"] == "deny"


@pytest.mark.asyncio
async def test_legacy_guard_allows_all_tools_unrestricted(tmp_path: Path):
    """Legacy agents have no tool restrictions from the guard."""
    checkout = tmp_path / "checkout"
    checkout.mkdir()
    source = checkout / "src" / "main.go"
    source.parent.mkdir(parents=True, exist_ok=True)
    source.write_text("package main\n")
    guard = _AgentExecutionGuard({"route": "legacy"}, checkout)

    bash_result = await guard.pre_tool_use(
        {"tool_name": "Bash", "tool_input": {"command": "find . -type f"}},
        None,
        {},
    )
    read_result = await guard.pre_tool_use(
        {"tool_name": "Read", "tool_input": {"file_path": str(source)}},
        None,
        {},
    )
    grep_result = await guard.pre_tool_use(
        {"tool_name": "Grep", "tool_input": {"pattern": "main"}},
        None,
        {},
    )

    assert bash_result == {}
    assert read_result == {}
    assert grep_result == {}
    assert guard.telemetry()["denied_tool_calls"] == 0
    assert guard.telemetry()["source_files_read"] == ["src/main.go"]
    assert guard.telemetry()["read_calls"] == 1


# ── Route contract prompt tests ──


def test_sufficient_policy_prompt_includes_partial_route_contract(tmp_path: Path):
    """Sufficient readiness prompt arguments declare partial route and gap state."""
    checkout = tmp_path / "sufficient-prompt"
    write_analyzer(checkout, "sufficient", source_files=["src/app.py"],
                   component="caikit-nlp")

    policy = load_architecture_agent_policy(checkout, readiness_routing=True)

    args = policy.prompt_arguments()
    assert "--analysis-route=partial" in args
    assert "--readiness=sufficient" in args
    assert "--baseline-preseeded" in args
    assert "--file-budget=" in args
    assert "--gap-categories=" in args
    assert "Glob" in policy.discovery_tools
    assert "Grep" in policy.discovery_tools
    assert "Bash" not in policy.discovery_tools
    assert "Task" not in policy.discovery_tools


def test_partial_policy_prompt_includes_bounded_discovery(tmp_path: Path):
    """Partial prompt arguments must declare file budget and gap categories."""
    checkout = tmp_path / "partial-prompt"
    write_analyzer(checkout, "partial", source_files=["deploy.yaml"])

    policy = load_architecture_agent_policy(checkout, readiness_routing=True)

    args = policy.prompt_arguments()
    assert "--analysis-route=partial" in args
    assert "--readiness=partial" in args
    assert "--baseline-preseeded" in args
    assert "--file-budget=" in args
    assert "--gap-categories=" in args
    assert "Glob" in policy.discovery_tools
    assert "Grep" in policy.discovery_tools
    assert "Bash" not in policy.discovery_tools
    assert "Task" not in policy.discovery_tools


def test_legacy_policy_prompt_has_no_evidence_gating(tmp_path: Path):
    """Legacy prompt arguments must not include evidence-gated flags."""
    checkout = tmp_path / "legacy-prompt"
    checkout.mkdir()
    (checkout / "ANALYZER_ARCHITECTURE.md").write_text("# baseline\n")

    policy = load_architecture_agent_policy(checkout, readiness_routing=True)

    args = policy.prompt_arguments()
    assert "--analysis-route=legacy" in args
    assert "--baseline-preseeded" not in args
    assert "--gap-categories" not in args
    assert "--file-budget" not in args
    assert "Bash" in policy.discovery_tools
    assert "Task" in policy.discovery_tools


# ── Synthesis gap-category fixture tests ──


def test_sufficient_with_authentication_gap_routes_to_partial(
    tmp_path: Path,
):
    """Sufficient readiness with empty authentication and partial python coverage
    routes to partial with authentication as a gap category."""
    checkout = tmp_path / "auth-gap"
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
        component="caikit-nlp",
    )

    policy = load_architecture_agent_policy(checkout, readiness_routing=True)

    assert policy.route == "partial"
    assert "authentication" in policy.gap_categories
    assert policy.discovery_tools == ("Glob", "Grep")
    assert policy.output_preseeded is True
    assert policy.file_budget is not None


@pytest.mark.asyncio
async def test_synthesis_guard_context_telemetry_records_navigation_reads(
    tmp_path: Path,
):
    """Synthesis guard records navigation reads in context telemetry."""
    checkout = tmp_path / "checkout"
    checkout.mkdir()
    (checkout / "GENERATED_ARCHITECTURE.md").write_text("# baseline\n")
    (checkout / "ANALYZER_ARCHITECTURE.md").write_text("# analyzer\n")
    (checkout / "component-architecture.json").write_text("{}\n")

    guard = _AgentExecutionGuard(
        {
            "route": "synthesis",
            "readiness": "sufficient",
            "source_files": [],
            "discovery_tools": [],
            "output_preseeded": True,
            "component": "test-component",
        },
        checkout,
    )

    for nav in ["GENERATED_ARCHITECTURE.md", "ANALYZER_ARCHITECTURE.md",
                "component-architecture.json"]:
        await guard.pre_tool_use(
            {"tool_name": "Read", "tool_input": {
                "file_path": str(checkout / nav)}},
            None, {},
        )

    telemetry = guard.telemetry()
    metrics = telemetry["context_metrics"]
    assert metrics["navigation_reads"] == 3
    assert metrics["useful_reads"] == 0
    assert telemetry["source_files_read"] == []
    assert telemetry["denied_tool_calls"] == 0


@pytest.mark.asyncio
async def test_synthesis_guard_denies_glob_grep_as_discovery(tmp_path: Path):
    """Synthesis agents with no discovery_tools must be denied Glob and Grep."""
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

    glob_result = await guard.pre_tool_use(
        {"tool_name": "Glob", "tool_input": {"pattern": "**/*.py"}},
        None, {},
    )
    grep_result = await guard.pre_tool_use(
        {"tool_name": "Grep", "tool_input": {"pattern": "auth"}},
        None, {},
    )

    assert glob_result["hookSpecificOutput"]["permissionDecision"] == "deny"
    assert grep_result["hookSpecificOutput"]["permissionDecision"] == "deny"
    denied = guard.telemetry()["denied_tool_calls_by_name"]
    assert denied.get("Glob") == 1
    assert denied.get("Grep") == 1


@pytest.mark.asyncio
async def test_synthesis_guard_allows_edit_on_output_artifacts(tmp_path: Path):
    """Synthesis agents can Edit the preseeded output and write change/insight files."""
    checkout = tmp_path / "checkout"
    checkout.mkdir()
    (checkout / "GENERATED_ARCHITECTURE.md").write_text("# baseline\n")
    guard = _AgentExecutionGuard(
        {
            "route": "synthesis",
            "readiness": "sufficient",
            "source_files": [],
            "discovery_tools": [],
            "output_preseeded": True,
        },
        checkout,
    )

    edit_result = await guard.pre_tool_use(
        {"tool_name": "Edit", "tool_input": {
            "file_path": str(checkout / "GENERATED_ARCHITECTURE.md"),
            "old_string": "# baseline",
            "new_string": "# refined",
        }},
        None, {},
    )
    changes_result = await guard.pre_tool_use(
        {"tool_name": "Write", "tool_input": {
            "file_path": str(checkout / "ARCHITECTURE_CHANGES.md"),
            "content": "# changes",
        }},
        None, {},
    )
    insights_result = await guard.pre_tool_use(
        {"tool_name": "Write", "tool_input": {
            "file_path": str(checkout / "INSIGHTS_ARTIFACT.json"),
            "content": "{}",
        }},
        None, {},
    )

    assert edit_result == {}
    assert changes_result == {}
    assert insights_result == {}
    assert guard.telemetry()["denied_tool_calls"] == 0


# ── Focused routing assertions for rhods-operator allowlist expansion ──
# Evidence: commit d14a7e1f "Validate real analyzer-assisted synthesis"
# Report: docs/notes/real-analyzer-assisted-synthesis-report.md


class TestAllowlistAuditEntries:
    """Verify the synthesis allowlist is retained for audit with expected entries.

    The allowlist no longer affects routing — all valid-artifact components
    route to partial. These tests verify the audit registry content.
    """

    def test_rhods_operator_on_audit_allowlist(self):
        """rhods-operator is present in the audit-only allowlist."""
        allowlist = load_synthesis_migration_allowlist()
        assert "rhods-operator" in allowlist

    def test_audit_allowlist_preserves_prior_entries(self):
        """Audit allowlist still contains caikit-nlp and rhoai-mcp."""
        allowlist = load_synthesis_migration_allowlist()
        assert "caikit-nlp" in allowlist
        assert "rhoai-mcp" in allowlist

    def test_odh_dashboard_on_audit_allowlist(self):
        """odh-dashboard is on the audit-only allowlist."""
        allowlist = load_synthesis_migration_allowlist()
        assert "odh-dashboard" in allowlist

    def test_rhods_operator_routes_to_partial(
        self, tmp_path: Path,
    ):
        """rhods-operator with sufficient readiness routes to partial."""
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
        assert policy.route == "partial"
        assert policy.output_preseeded is True
        assert policy.file_budget is not None
        assert policy.discovery_tools == ("Glob", "Grep")

    def test_odh_dashboard_routes_to_partial(self, tmp_path: Path):
        """odh-dashboard with sufficient readiness routes to partial."""
        checkout = tmp_path / "odh-dashboard"
        write_analyzer(
            checkout,
            "sufficient",
            coverage={
                "source": "partial: dynamic TypeScript expressions unresolved",
                "platform_semantics": "partial: aliases unresolved",
            },
            populate_high_value=True,
            component="odh-dashboard",
        )

        policy = load_architecture_agent_policy(checkout, readiness_routing=True)

        assert policy.readiness == "sufficient"
        assert policy.route == "partial"
        assert policy.output_preseeded is True
        assert policy.file_budget is not None
        assert policy.discovery_tools == ("Glob", "Grep")

    def test_odh_dashboard_not_in_analyzer_only_approvals(self):
        """odh-dashboard is NOT in the analyzer-only approvals registry."""
        approvals = load_analyzer_only_approvals()
        assert "odh-dashboard" not in approvals

    def test_rhods_operator_not_in_analyzer_only_approvals(self):
        """rhods-operator is NOT in the analyzer-only approvals registry."""
        approvals = load_analyzer_only_approvals()
        assert "rhods-operator" not in approvals


# ── Analyzer-backed default partial routing tests ──


def test_missing_analyzer_json_routes_to_legacy(tmp_path: Path):
    """Missing component-architecture.json triggers legacy routing."""
    checkout = tmp_path / "no-json"
    checkout.mkdir()
    (checkout / "ANALYZER_ARCHITECTURE.md").write_text("# baseline\n")

    policy = load_architecture_agent_policy(checkout, readiness_routing=True)

    assert policy.route == "legacy"
    assert policy.readiness == "unknown"


def test_missing_analyzer_markdown_routes_to_legacy(tmp_path: Path):
    """Missing ANALYZER_ARCHITECTURE.md triggers legacy routing."""
    checkout = tmp_path / "no-md"
    checkout.mkdir()
    (checkout / "component-architecture.json").write_text(json.dumps({
        "data_coverage": {"agent_baseline": "sufficient: test"},
    }))

    policy = load_architecture_agent_policy(checkout, readiness_routing=True)

    assert policy.route == "legacy"
    assert policy.readiness == "unknown"


def test_invalid_analyzer_json_routes_to_legacy(tmp_path: Path):
    """Corrupt component-architecture.json triggers legacy routing."""
    checkout = tmp_path / "bad-json"
    checkout.mkdir()
    (checkout / "component-architecture.json").write_text("{not valid json")
    (checkout / "ANALYZER_ARCHITECTURE.md").write_text("# baseline\n")

    policy = load_architecture_agent_policy(checkout, readiness_routing=True)

    assert policy.route == "legacy"
    assert policy.readiness == "unknown"


def test_explicit_legacy_override_via_disabled_routing(tmp_path: Path):
    """readiness_routing=False is an explicit operator override to legacy."""
    checkout = tmp_path / "explicit-legacy"
    write_analyzer(checkout, "sufficient", source_files=["src/main.py"])

    policy = load_architecture_agent_policy(checkout, readiness_routing=False)

    assert policy.route == "legacy"
    assert policy.readiness == "legacy"
    assert "operator selected" in policy.reason


def test_insufficient_readiness_preserves_gap_categories(tmp_path: Path):
    """Insufficient readiness via partial route still computes gap categories."""
    checkout = tmp_path / "insufficient-gaps"
    write_analyzer(
        checkout, "insufficient",
        source_files=["deploy.yaml"],
        coverage={"source": "partial: incomplete analysis"},
    )

    policy = load_architecture_agent_policy(checkout, readiness_routing=True)

    assert policy.route == "partial"
    assert len(policy.gap_categories) > 0
    assert policy.gap_reasons
    assert policy.file_budget is not None


def test_all_valid_readiness_levels_route_to_partial(tmp_path: Path):
    """All valid readiness levels (sufficient/partial/insufficient/unknown)
    route to partial with valid analyzer artifacts."""
    checkout_sufficient = tmp_path / "sufficient"
    write_analyzer(checkout_sufficient, "sufficient", component="comp-a")
    checkout_partial = tmp_path / "partial"
    write_analyzer(checkout_partial, "partial", component="comp-b")
    checkout_insufficient = tmp_path / "insufficient"
    write_analyzer(checkout_insufficient, "insufficient", component="comp-c")
    checkout_unknown = tmp_path / "unknown"
    write_analyzer(checkout_unknown, "unknown", component="comp-d")

    policy_s = load_architecture_agent_policy(
        checkout_sufficient, readiness_routing=True,
    )
    policy_p = load_architecture_agent_policy(
        checkout_partial, readiness_routing=True,
    )
    policy_i = load_architecture_agent_policy(
        checkout_insufficient, readiness_routing=True,
    )
    policy_u = load_architecture_agent_policy(
        checkout_unknown, readiness_routing=True,
    )

    for p in (policy_s, policy_p, policy_i, policy_u):
        assert p.route == "partial"
        assert p.output_preseeded is True
        assert p.discovery_tools == ("Glob", "Grep")
    assert policy_s.readiness == "sufficient"
    assert policy_p.readiness == "partial"
    assert policy_i.readiness == "insufficient"
    assert policy_u.readiness == "unknown"


def test_insufficient_prompt_includes_partial_contract(tmp_path: Path):
    """Insufficient readiness routed to partial includes correct prompt flags."""
    checkout = tmp_path / "insufficient-prompt"
    write_analyzer(checkout, "insufficient", source_files=["src/app.go"])

    policy = load_architecture_agent_policy(checkout, readiness_routing=True)

    args = policy.prompt_arguments()
    assert "--analysis-route=partial" in args
    assert "--readiness=insufficient" in args
    assert "--baseline-preseeded" in args
    assert "--file-budget=" in args
    assert "--gap-categories=" in args
    assert "Bash" not in policy.discovery_tools
    assert "Task" not in policy.discovery_tools
