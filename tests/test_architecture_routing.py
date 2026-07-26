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


def test_sufficient_policy_is_synthesis_only_and_caps_known_sources(tmp_path: Path):
    checkout = tmp_path / "sufficient"
    sources = [f"src/file{index}.py" for index in range(6)]
    write_analyzer(checkout, "sufficient", source_files=sources)

    policy = load_architecture_agent_policy(
        checkout,
        readiness_routing=True,
    )

    assert policy.route == "synthesis"
    assert policy.readiness == "sufficient"
    assert policy.gap_categories == ()
    assert policy.source_files == ()
    assert policy.file_budget is None
    assert policy.discovery_tools == ()
    assert "--gap-categories=none" in policy.prompt_arguments()
    assert "--allowed-source-files" not in policy.prompt_arguments()
    assert policy.output_preseeded is True
    assert "--baseline-preseeded" in policy.prompt_arguments()


def test_populated_sufficient_policy_uses_analyzer_only_route(tmp_path: Path):
    checkout = tmp_path / "analyzer-only"
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

    assert policy.route == "analyzer-only"
    assert policy.analyzer_only is True
    assert policy.evidence_gated is False
    assert policy.gap_categories == ()
    assert policy.source_files == ()
    assert policy.file_budget is None
    assert policy.output_preseeded is True


def test_unapproved_populated_candidate_keeps_agent(tmp_path: Path):
    checkout = tmp_path / "candidate"
    write_analyzer(
        checkout,
        "sufficient",
        populate_high_value=True,
        component="not-yet-approved",
    )

    policy = load_architecture_agent_policy(checkout, readiness_routing=True)

    assert policy.route == "synthesis"
    assert policy.gap_categories == ()
    assert "awaiting corpus approval" in policy.reason


def test_analyzer_only_approval_loader_rejects_invalid_entries(tmp_path: Path):
    path = tmp_path / "approvals.json"
    path.write_text(
        json.dumps({"components": ["approved", "", 3, "approved"]})
    )

    assert load_analyzer_only_approvals(path) == frozenset({"approved"})


def test_sufficient_policy_with_any_empty_high_value_table_keeps_agent(
    tmp_path: Path,
):
    checkout = tmp_path / "not-analyzer-only"
    write_analyzer(
        checkout,
        "sufficient",
        coverage={"source": "complete", "platform_semantics": "complete"},
        populate_high_value=False,
    )

    policy = load_architecture_agent_policy(checkout, readiness_routing=True)

    assert policy.route == "synthesis"


def complete_coverage(contract: str) -> dict[str, object]:
    return {
        "status": "complete",
        "fact_count": 0,
        "discovery_contract": contract,
        "completed_checks": ["bounded-check"],
        "limitations": [],
        "evidence": ["summary:test coverage"],
    }


def test_contract_complete_empty_auth_and_internal_categories_allow_analyzer_only(
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
    )

    policy = load_architecture_agent_policy(checkout, readiness_routing=True)

    assert policy.route == "analyzer-only"
    assert "contract-complete empty" in policy.reason


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


def test_legacy_json_without_category_coverage_keeps_empty_category_ineligible(
    tmp_path: Path,
):
    checkout = tmp_path / "legacy-category-coverage"
    write_analyzer(
        checkout,
        "sufficient",
        populate_high_value=True,
        empty_high_value={"authentication"},
    )

    policy = load_architecture_agent_policy(checkout, readiness_routing=True)

    assert policy.route == "synthesis"


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


def test_all_three_complete_empty_contracts_allow_analyzer_only(tmp_path: Path):
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
    )

    policy = load_architecture_agent_policy(checkout, readiness_routing=True)

    assert policy.route == "analyzer-only"


def test_partial_policy_derives_category_and_file_budgets(tmp_path: Path):
    checkout = tmp_path / "partial"
    write_analyzer(checkout, "partial", source_files=["deploy.yaml"])

    policy = load_architecture_agent_policy(
        checkout,
        readiness_routing=True,
    )

    assert policy.route == "partial"
    assert policy.gap_categories == (
        "authentication",
        "integration_points",
        "internal_dependencies",
        "http_endpoints",
        "grpc_services",
        "services",
    )
    assert policy.file_budget == 8
    assert policy.discovery_tools == ("Glob", "Grep")
    assert "--file-budget=8" in policy.prompt_arguments()
    assert "--gap-categories=authentication,integration_points" in (
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

    assert policy.gap_categories == (
        "architecture_components",
        "authentication",
        "integration_points",
        "internal_dependencies",
        "http_endpoints",
        "grpc_services",
    )


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

    assert policy.gap_categories == (
        "architecture_components",
        "authentication",
        "integration_points",
        "internal_dependencies",
        "http_endpoints",
        "grpc_services",
    )
    assert not {
        "services",
        "ingress",
        "rbac_cluster_roles",
        "rbac_role_bindings",
        "secrets",
    }.intersection(policy.gap_categories)


def test_sparse_sufficient_policy_allows_high_value_corrections_without_discovery(
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
    )

    policy = load_architecture_agent_policy(checkout, readiness_routing=True)

    assert policy.gap_categories == (
        "architecture_components",
        "authentication",
        "integration_points",
        "internal_dependencies",
    )
    assert policy.source_files == ()
    assert policy.file_budget is None
    assert policy.discovery_tools == ()
    assert "--allowed-source-files" not in policy.prompt_arguments()


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


@pytest.mark.parametrize("readiness", ["insufficient", "unknown"])
def test_unusable_analyzer_readiness_keeps_legacy_route(
    tmp_path: Path,
    readiness: str,
):
    checkout = tmp_path / readiness
    write_analyzer(checkout, readiness)

    policy = load_architecture_agent_policy(
        checkout,
        readiness_routing=True,
    )

    assert policy.route == "legacy"
    assert "Task" in policy.discovery_tools


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


def test_source_audited_policy_routes_analyzer_only(tmp_path: Path):
    checkout = tmp_path / "audited-routing"
    adjudications = tmp_path / "adjudications.json"
    adjudications.write_text(
        json.dumps(
            {
                "accepted_analyzer_absences": [],
                "source_audited_empty_categories": [
                    {
                        "component": "caikit-tgis-serving",
                        "category": "authentication",
                        "reason": "No auth",
                        "evidence": ["Dockerfile:1-10"],
                    },
                    {
                        "component": "caikit-tgis-serving",
                        "category": "integration_points",
                        "reason": "No integrations",
                        "evidence": ["Dockerfile:1-10"],
                    },
                    {
                        "component": "caikit-tgis-serving",
                        "category": "internal_dependencies",
                        "reason": "No deps",
                        "evidence": ["Dockerfile:1-10"],
                    },
                ],
            }
        )
    )
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
        component="caikit-tgis-serving",
    )

    from unittest.mock import patch

    import lib.architecture_routing as routing_mod

    with patch.object(
        routing_mod,
        "CORRECTION_ADJUDICATIONS_PATH",
        adjudications,
    ):
        policy = load_architecture_agent_policy(checkout, readiness_routing=True)

    assert policy.route == "analyzer-only"


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


def test_empty_synthesis_allowlist_preserves_synthesis_route(tmp_path: Path):
    from unittest.mock import patch

    import lib.architecture_routing as routing_mod

    checkout = tmp_path / "sufficient"
    write_analyzer(checkout, "sufficient", source_files=["src/main.py"])

    with patch.object(
        routing_mod,
        "load_synthesis_migration_allowlist",
        return_value=frozenset(),
    ):
        policy = load_architecture_agent_policy(checkout, readiness_routing=True)

    assert policy.route == "synthesis"


def test_populated_synthesis_allowlist_gates_unlisted_component_to_legacy(
    tmp_path: Path,
):
    from unittest.mock import patch

    import lib.architecture_routing as routing_mod

    checkout = tmp_path / "unlisted"
    write_analyzer(checkout, "sufficient", component="not-on-list")

    with patch.object(
        routing_mod,
        "load_synthesis_migration_allowlist",
        return_value=frozenset({"kserve"}),
    ):
        policy = load_architecture_agent_policy(checkout, readiness_routing=True)

    assert policy.route == "legacy"
    assert "synthesis migration allowlist" in policy.reason


def test_populated_synthesis_allowlist_allows_listed_component(tmp_path: Path):
    from unittest.mock import patch

    import lib.architecture_routing as routing_mod

    checkout = tmp_path / "listed"
    write_analyzer(checkout, "sufficient", component="kserve")

    with patch.object(
        routing_mod,
        "load_synthesis_migration_allowlist",
        return_value=frozenset({"kserve"}),
    ):
        policy = load_architecture_agent_policy(checkout, readiness_routing=True)

    assert policy.route == "synthesis"


def test_partial_readiness_gated_by_synthesis_allowlist(tmp_path: Path):
    from unittest.mock import patch

    import lib.architecture_routing as routing_mod

    checkout = tmp_path / "partial-gated"
    write_analyzer(checkout, "partial", component="not-on-list")

    with patch.object(
        routing_mod,
        "load_synthesis_migration_allowlist",
        return_value=frozenset({"kserve"}),
    ):
        policy = load_architecture_agent_policy(checkout, readiness_routing=True)

    assert policy.route == "legacy"
    assert "synthesis migration allowlist" in policy.reason


def test_partial_readiness_allowed_by_synthesis_allowlist(tmp_path: Path):
    from unittest.mock import patch

    import lib.architecture_routing as routing_mod

    checkout = tmp_path / "partial-allowed"
    write_analyzer(checkout, "partial", component="kserve")

    with patch.object(
        routing_mod,
        "load_synthesis_migration_allowlist",
        return_value=frozenset({"kserve"}),
    ):
        policy = load_architecture_agent_policy(checkout, readiness_routing=True)

    assert policy.route == "partial"


def test_analyzer_only_route_unaffected_by_synthesis_allowlist(tmp_path: Path):
    from unittest.mock import patch

    import lib.architecture_routing as routing_mod

    checkout = tmp_path / "analyzer-only-unaffected"
    write_analyzer(
        checkout,
        "sufficient",
        coverage={
            "source": "partial: dynamic expressions unresolved",
            "platform_semantics": "partial: aliases unresolved",
        },
        populate_high_value=True,
    )

    with patch.object(
        routing_mod,
        "load_synthesis_migration_allowlist",
        return_value=frozenset({"not-this-one"}),
    ):
        policy = load_architecture_agent_policy(checkout, readiness_routing=True)

    assert policy.route == "analyzer-only"
