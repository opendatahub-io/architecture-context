"""Tests for the bounded synthesis insight artifact contract."""

import json
import sys
from pathlib import Path

import pytest

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from lib.architecture_merge import (  # noqa: E402
    CONDITIONAL_H2_SECTIONS,
    NON_AUTHORITATIVE_SECTIONS,
    SYNTHESIS_SECTIONS,
    merge_architecture_documents,
)
from lib.insights import (  # noqa: E402
    APPLICABILITY_NORMALIZATION,
    APPLICABILITY_VALUES,
    CONFIDENCE_VALUES,
    INSIGHT_CATEGORIES,
    INSIGHT_JSON_SCHEMA,
    MAX_CLAIM_CHARS,
    MAX_INSIGHTS_PER_ARTIFACT,
    MAX_REASONING_CHARS,
    MAX_TOKEN_BUDGET,
    PROVENANCE_KINDS,
    SCHEMA_VERSION,
    VALIDATION_STATUSES,
    Insight,
    InsightArtifact,
    ProvenanceReference,
    load_insight_artifact,
    validate_insight_artifact,
)

FIXTURES = PROJECT_ROOT / "tests" / "fixtures" / "insights"


def _ref(
    kind: str = "analyzer-fact",
    location: str = "Architecture Components table",
    excerpt: str = "",
) -> ProvenanceReference:
    return ProvenanceReference(kind=kind, location=location, excerpt=excerpt)


def _insight(
    *,
    id: str = "test-001",
    claim: str = "Test claim.",
    category: str = "pattern",
    provenance: tuple[ProvenanceReference, ...] | None = None,
    reasoning: str = "Test reasoning.",
    applicability: str = "component",
    confidence: str = "high",
    unknowns: tuple[str, ...] = (),
    counterevidence: tuple[str, ...] = (),
    suggested_validation: str = "",
    validation_status: str = "pending",
) -> Insight:
    return Insight(
        id=id,
        claim=claim,
        category=category,
        provenance=provenance if provenance is not None else (_ref(),),
        reasoning=reasoning,
        applicability=applicability,
        confidence=confidence,
        unknowns=unknowns,
        counterevidence=counterevidence,
        suggested_validation=suggested_validation,
        validation_status=validation_status,
    )


def _artifact(insights: list[Insight] | None = None) -> InsightArtifact:
    return InsightArtifact(
        schema_version=SCHEMA_VERSION,
        component="test-component",
        platform="rhoai",
        version="rhoai.next",
        insights=insights if insights is not None else [_insight()],
    )


# ── Model validation ──


class TestProvenanceReference:
    def test_valid_reference(self):
        ref = _ref()
        assert ref.validate() == []

    def test_invalid_kind(self):
        ref = _ref(kind="assumption")
        errors = ref.validate()
        assert any("provenance kind" in e for e in errors)

    def test_empty_location(self):
        ref = _ref(location="")
        errors = ref.validate()
        assert any("location" in e for e in errors)

    def test_whitespace_only_location(self):
        ref = _ref(location="   ")
        errors = ref.validate()
        assert any("location" in e for e in errors)


class TestInsight:
    def test_valid_insight(self):
        assert _insight().validate() == []

    def test_empty_id(self):
        errors = _insight(id="").validate()
        assert any("id" in e for e in errors)

    def test_empty_claim(self):
        errors = _insight(claim="").validate()
        assert any("claim" in e for e in errors)

    def test_claim_too_long(self):
        errors = _insight(claim="x" * (MAX_CLAIM_CHARS + 1)).validate()
        assert any("claim exceeds" in e for e in errors)

    def test_reasoning_too_long(self):
        errors = _insight(reasoning="x" * (MAX_REASONING_CHARS + 1)).validate()
        assert any("reasoning exceeds" in e for e in errors)

    @pytest.mark.parametrize("category", sorted(INSIGHT_CATEGORIES))
    def test_valid_categories(self, category: str):
        assert _insight(category=category).validate() == []

    def test_invalid_category(self):
        errors = _insight(category="opinion").validate()
        assert any("category" in e for e in errors)

    def test_empty_provenance(self):
        errors = _insight(provenance=()).validate()
        assert any("provenance" in e for e in errors)

    def test_invalid_provenance_propagated(self):
        bad_ref = _ref(kind="guess")
        errors = _insight(provenance=(bad_ref,)).validate()
        assert any("provenance[0]" in e for e in errors)

    @pytest.mark.parametrize("confidence", sorted(CONFIDENCE_VALUES))
    def test_valid_confidence(self, confidence: str):
        assert _insight(confidence=confidence).validate() == []

    def test_invalid_confidence(self):
        errors = _insight(confidence="very-high").validate()
        assert any("confidence" in e for e in errors)

    def test_invalid_applicability(self):
        errors = _insight(applicability="galaxy-wide").validate()
        assert any("applicability" in e for e in errors)

    def test_cross_component_applicability_is_valid(self):
        assert not _insight(
            category="cross-component implication",
            applicability="cross-component",
        ).validate()

    def test_invalid_validation_status(self):
        errors = _insight(validation_status="approved").validate()
        assert any("validation_status" in e for e in errors)

    @pytest.mark.parametrize("status", sorted(VALIDATION_STATUSES))
    def test_all_valid_validation_statuses(self, status: str):
        assert _insight(validation_status=status).validate() == []

    def test_unknown_status_accepted(self):
        insight = _insight(validation_status="unknown")
        assert insight.validate() == []
        assert insight.validation_status == "unknown"

    def test_not_extracted_status_accepted(self):
        insight = _insight(validation_status="not-extracted")
        assert insight.validate() == []
        assert insight.validation_status == "not-extracted"

    def test_all_valid_provenance_kinds(self):
        for kind in sorted(PROVENANCE_KINDS):
            ref = _ref(kind=kind)
            assert ref.validate() == [], f"kind {kind!r} should be valid"

    @pytest.mark.parametrize("applicability", sorted(APPLICABILITY_VALUES))
    def test_valid_applicability_values(self, applicability: str):
        assert _insight(applicability=applicability).validate() == []

    def test_cross_component_implication_applicability_normalized(self):
        errors = _insight(applicability="cross-component implication").validate()
        assert errors == [], (
            "'cross-component implication' should normalize to 'cross-component'"
        )

    def test_unrelated_invalid_applicability_still_fails(self):
        errors = _insight(applicability="universe-wide").validate()
        assert any("applicability" in e for e in errors)


# ── Applicability normalization ──


class TestApplicabilityNormalization:
    def test_normalization_map_targets_are_valid(self):
        for target in APPLICABILITY_NORMALIZATION.values():
            assert target in APPLICABILITY_VALUES, (
                f"normalization target {target!r} is not a valid applicability"
            )

    def test_cross_component_implication_normalizes(self):
        assert (
            APPLICABILITY_NORMALIZATION["cross-component implication"]
            == "cross-component"
        )

    def test_valid_values_not_in_normalization_map(self):
        for val in APPLICABILITY_VALUES:
            assert val not in APPLICABILITY_NORMALIZATION, (
                f"valid value {val!r} should not appear as a normalization key"
            )


# ── Artifact-level validation ──


class TestInsightArtifact:
    def test_valid_artifact(self):
        assert _artifact().validate() == []

    def test_wrong_schema_version(self):
        artifact = _artifact()
        artifact.schema_version = 999
        errors = artifact.validate()
        assert any("schema_version" in e for e in errors)

    def test_empty_component(self):
        artifact = _artifact()
        artifact.component = ""
        errors = artifact.validate()
        assert any("component" in e for e in errors)

    def test_empty_platform(self):
        artifact = _artifact()
        artifact.platform = ""
        errors = artifact.validate()
        assert any("platform" in e for e in errors)

    def test_too_many_insights(self):
        insights = [
            _insight(id=f"test-{i:03d}")
            for i in range(MAX_INSIGHTS_PER_ARTIFACT + 1)
        ]
        artifact = _artifact(insights)
        errors = artifact.validate()
        assert any("exceeds maximum" in e for e in errors)

    def test_duplicate_ids_rejected(self):
        insights = [_insight(id="dup"), _insight(id="dup")]
        errors = _artifact(insights).validate()
        assert any("duplicate id" in e for e in errors)

    def test_empty_insights_valid(self):
        assert _artifact([]).validate() == []


# ── Token metadata validation ──


class TestTokenMetadata:
    def test_valid_token_metadata(self):
        artifact = _artifact()
        artifact.token_budget = 50000
        artifact.token_count = 12345
        assert artifact.validate() == []

    def test_omitted_token_metadata_valid(self):
        artifact = _artifact()
        assert artifact.token_budget is None
        assert artifact.token_count is None
        assert artifact.validate() == []

    def test_token_budget_only_valid(self):
        artifact = _artifact()
        artifact.token_budget = 50000
        assert artifact.validate() == []

    def test_token_count_only_valid(self):
        artifact = _artifact()
        artifact.token_count = 5000
        assert artifact.validate() == []

    def test_token_count_zero_valid(self):
        artifact = _artifact()
        artifact.token_budget = 50000
        artifact.token_count = 0
        assert artifact.validate() == []

    def test_token_budget_zero_invalid(self):
        artifact = _artifact()
        artifact.token_budget = 0
        errors = artifact.validate()
        assert any("token_budget must be a positive integer" in e for e in errors)

    def test_token_budget_negative_invalid(self):
        artifact = _artifact()
        artifact.token_budget = -100
        errors = artifact.validate()
        assert any("token_budget must be a positive integer" in e for e in errors)

    def test_token_count_negative_invalid(self):
        artifact = _artifact()
        artifact.token_count = -1
        errors = artifact.validate()
        assert any("token_count must be a non-negative integer" in e for e in errors)

    def test_token_count_exceeds_budget_invalid(self):
        artifact = _artifact()
        artifact.token_budget = 10000
        artifact.token_count = 50000
        errors = artifact.validate()
        assert any("token_count 50000 exceeds token_budget 10000" in e for e in errors)

    def test_token_budget_exceeds_max_invalid(self):
        artifact = _artifact()
        artifact.token_budget = MAX_TOKEN_BUDGET + 1
        errors = artifact.validate()
        assert any("exceeds maximum" in e for e in errors)

    def test_to_dict_includes_token_metadata(self):
        artifact = _artifact()
        artifact.token_budget = 50000
        artifact.token_count = 12345
        d = artifact.to_dict()
        assert d["token_budget"] == 50000
        assert d["token_count"] == 12345

    def test_to_dict_omits_none_token_metadata(self):
        artifact = _artifact()
        d = artifact.to_dict()
        assert "token_budget" not in d
        assert "token_count" not in d

    def test_round_trip_with_token_metadata(self):
        artifact = _artifact()
        artifact.token_budget = 50000
        artifact.token_count = 12345
        json_str = artifact.to_json()
        reloaded = json.loads(json_str)
        assert reloaded["token_budget"] == 50000
        assert reloaded["token_count"] == 12345
        assert validate_insight_artifact(reloaded) == []


# ── Deterministic ordering ──


class TestDeterministicOrdering:
    def test_sorted_by_category_then_confidence_then_id(self):
        insights = [
            _insight(id="z", category="risk", confidence="low"),
            _insight(id="a", category="pattern", confidence="high"),
            _insight(id="b", category="pattern", confidence="medium"),
            _insight(id="c", category="trade-off", confidence="high"),
        ]
        artifact = _artifact(insights)
        sorted_ids = [i.id for i in artifact.sorted_insights()]
        assert sorted_ids == ["a", "b", "c", "z"]

    def test_round_trip_determinism(self):
        insights = [
            _insight(id="b", category="risk", confidence="medium"),
            _insight(id="a", category="pattern", confidence="high"),
        ]
        artifact = _artifact(insights)
        json1 = artifact.to_json()
        json2 = artifact.to_json()
        assert json1 == json2

    def test_to_dict_sorts_insights(self):
        insights = [
            _insight(id="b", category="risk", confidence="low"),
            _insight(id="a", category="pattern", confidence="high"),
        ]
        artifact = _artifact(insights)
        d = artifact.to_dict()
        assert d["insights"][0]["id"] == "a"
        assert d["insights"][1]["id"] == "b"


# ── JSON schema validation ──


class TestJsonSchemaValidation:
    def test_schema_available(self):
        assert INSIGHT_JSON_SCHEMA["$schema"] is not None
        assert INSIGHT_JSON_SCHEMA["properties"]["schema_version"]["const"] == 1

    def test_jsonschema_validates_valid_fixture(self):
        jsonschema = pytest.importorskip("jsonschema")
        data = json.loads((FIXTURES / "valid_artifact.json").read_text())
        jsonschema.validate(data, INSIGHT_JSON_SCHEMA)

    def test_jsonschema_rejects_invalid_category(self):
        jsonschema = pytest.importorskip("jsonschema")
        data = json.loads((FIXTURES / "invalid_category.json").read_text())
        with pytest.raises(jsonschema.ValidationError):
            jsonschema.validate(data, INSIGHT_JSON_SCHEMA)

    def test_jsonschema_rejects_empty_provenance(self):
        jsonschema = pytest.importorskip("jsonschema")
        data = json.loads((FIXTURES / "invalid_no_provenance.json").read_text())
        with pytest.raises(jsonschema.ValidationError):
            jsonschema.validate(data, INSIGHT_JSON_SCHEMA)

    def test_jsonschema_rejects_bad_provenance_kind(self):
        jsonschema = pytest.importorskip("jsonschema")
        data = json.loads(
            (FIXTURES / "invalid_bad_provenance_kind.json").read_text()
        )
        with pytest.raises(jsonschema.ValidationError):
            jsonschema.validate(data, INSIGHT_JSON_SCHEMA)

    def test_jsonschema_rejects_bad_confidence(self):
        jsonschema = pytest.importorskip("jsonschema")
        data = json.loads(
            (FIXTURES / "invalid_bad_confidence.json").read_text()
        )
        with pytest.raises(jsonschema.ValidationError):
            jsonschema.validate(data, INSIGHT_JSON_SCHEMA)

    def test_jsonschema_validates_token_metadata(self):
        jsonschema = pytest.importorskip("jsonschema")
        data = json.loads(
            (FIXTURES / "valid_with_token_metadata.json").read_text()
        )
        jsonschema.validate(data, INSIGHT_JSON_SCHEMA)

    def test_jsonschema_validates_unknown_status(self):
        jsonschema = pytest.importorskip("jsonschema")
        data = json.loads(
            (FIXTURES / "valid_unknown_status.json").read_text()
        )
        jsonschema.validate(data, INSIGHT_JSON_SCHEMA)

    def test_jsonschema_validates_not_extracted_status(self):
        jsonschema = pytest.importorskip("jsonschema")
        data = json.loads(
            (FIXTURES / "valid_not_extracted_status.json").read_text()
        )
        jsonschema.validate(data, INSIGHT_JSON_SCHEMA)

    def test_jsonschema_rejects_invalid_validation_status(self):
        jsonschema = pytest.importorskip("jsonschema")
        data = json.loads(
            (FIXTURES / "invalid_validation_status.json").read_text()
        )
        with pytest.raises(jsonschema.ValidationError):
            jsonschema.validate(data, INSIGHT_JSON_SCHEMA)

    def test_jsonschema_rejects_zero_token_budget(self):
        jsonschema = pytest.importorskip("jsonschema")
        data = json.loads(
            (FIXTURES / "invalid_token_budget_zero.json").read_text()
        )
        with pytest.raises(jsonschema.ValidationError):
            jsonschema.validate(data, INSIGHT_JSON_SCHEMA)


# ── Raw dict validator ──


class TestValidateInsightArtifact:
    def test_valid_fixture(self):
        data = json.loads((FIXTURES / "valid_artifact.json").read_text())
        assert validate_insight_artifact(data) == []

    def test_valid_with_unknowns(self):
        data = json.loads((FIXTURES / "valid_with_unknowns.json").read_text())
        assert validate_insight_artifact(data) == []

    def test_invalid_category(self):
        data = json.loads((FIXTURES / "invalid_category.json").read_text())
        errors = validate_insight_artifact(data)
        assert any("category" in e for e in errors)

    def test_invalid_no_provenance(self):
        data = json.loads((FIXTURES / "invalid_no_provenance.json").read_text())
        errors = validate_insight_artifact(data)
        assert any("provenance" in e for e in errors)

    def test_invalid_bad_provenance_kind(self):
        data = json.loads(
            (FIXTURES / "invalid_bad_provenance_kind.json").read_text()
        )
        errors = validate_insight_artifact(data)
        assert any("kind" in e for e in errors)

    def test_invalid_bad_confidence(self):
        data = json.loads(
            (FIXTURES / "invalid_bad_confidence.json").read_text()
        )
        errors = validate_insight_artifact(data)
        assert any("confidence" in e for e in errors)
        assert any("applicability" in e for e in errors)

    def test_not_a_dict(self):
        errors = validate_insight_artifact("not a dict")
        assert errors == ["artifact must be a JSON object"]

    def test_missing_required_fields(self):
        errors = validate_insight_artifact({"schema_version": 1})
        assert any("component" in e for e in errors)
        assert any("platform" in e for e in errors)
        assert any("version" in e for e in errors)
        assert any("insights" in e for e in errors)

    def test_cross_component_implication_applicability_normalized(self):
        data = json.loads((FIXTURES / "valid_artifact.json").read_text())
        data["insights"][0]["applicability"] = "cross-component implication"
        errors = validate_insight_artifact(data)
        assert not any("applicability" in e for e in errors), (
            "'cross-component implication' must be normalized, not rejected"
        )
        assert data["insights"][0]["applicability"] == "cross-component"

    def test_unrelated_invalid_applicability_still_rejected(self):
        data = json.loads((FIXTURES / "valid_artifact.json").read_text())
        data["insights"][0]["applicability"] = "galaxy-wide"
        errors = validate_insight_artifact(data)
        assert any("applicability" in e for e in errors)


# ── File loading ──


class TestLoadInsightArtifact:
    def test_load_valid(self):
        artifact, errors = load_insight_artifact(
            FIXTURES / "valid_artifact.json"
        )
        assert errors == []
        assert artifact is not None
        assert artifact.component == "model-controller"
        assert len(artifact.insights) == 3

    def test_load_invalid_returns_errors(self):
        artifact, errors = load_insight_artifact(
            FIXTURES / "invalid_category.json"
        )
        assert artifact is None
        assert len(errors) > 0

    def test_load_missing_file(self):
        artifact, errors = load_insight_artifact(
            FIXTURES / "nonexistent.json"
        )
        assert artifact is None
        assert any("failed to load" in e for e in errors)

    def test_round_trip(self):
        artifact, _ = load_insight_artifact(FIXTURES / "valid_artifact.json")
        assert artifact is not None
        json_str = artifact.to_json()
        reloaded = json.loads(json_str)
        errors = validate_insight_artifact(reloaded)
        assert errors == []

    def test_load_normalizes_cross_component_implication(self):
        artifact, errors = load_insight_artifact(
            FIXTURES / "valid_cross_component_implication_normalized.json"
        )
        assert errors == []
        assert artifact is not None
        cross_insight = next(
            i for i in artifact.insights if i.id == "lmeh-cross-001"
        )
        assert cross_insight.applicability == "cross-component"
        assert cross_insight.category == "cross-component implication"


# ── Merge layer: insights must NOT be promoted ──


def _doc_with_insights(
    rows: list[tuple[str, str, str]],
    *,
    insights_section: str = "",
) -> str:
    table_rows = "\n".join(
        f"| {name} | {kind} | {purpose} |"
        for name, kind, purpose in rows
    )
    return f"""# Component: Example

## Metadata

- **Repository**: example/example
- **Version**: abc123
- **Distribution**: rhoai
- **Languages**: Python
- **Deployment Type**: Service
- **Generated By**: arch-analyzer

## Purpose

Analyzer purpose.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
{table_rows}

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|

### Internal Platform Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|

## Data Flows

Analyzer flows.

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|

## Architectural Analysis

Analyzer analysis.

{insights_section}## Recent Changes

| Version | Date | Changes |
|---------|------|---------|

## Source References

### Files Analyzed

| File | Lines | Sections Informed |
|------|-------|-------------------|
| app.py | 1-20 | Purpose |

### Grep/Search Results Used

| Search Pattern | Files Matched | Sections Informed |
|----------------|---------------|-------------------|

### Summary

- **Total files referenced**: 1
- **Analyzer coverage (agent_baseline)**: sufficient
"""


class TestMergeDoesNotPromoteInsights:
    def test_insights_section_not_merged(self):
        analyzer = _doc_with_insights([("api", "Service", "API")])
        candidate = _doc_with_insights(
            [("api", "Service", "API")],
            insights_section=(
                "## Insights\n\n"
                "This is agent analysis that must not appear in output.\n\n"
            ),
        )

        result = merge_architecture_documents(analyzer, candidate)

        assert "## Insights" not in result.text
        assert "must not appear" not in result.text

    def test_agent_insights_section_not_merged(self):
        analyzer = _doc_with_insights([("api", "Service", "API")])
        candidate = _doc_with_insights(
            [("api", "Service", "API")],
            insights_section=(
                "## Agent Insights\n\n"
                "Non-authoritative analysis.\n\n"
            ),
        )

        result = merge_architecture_documents(analyzer, candidate)

        assert "## Agent Insights" not in result.text

    def test_synthesis_insights_section_not_merged(self):
        analyzer = _doc_with_insights([("api", "Service", "API")])
        candidate = _doc_with_insights(
            [("api", "Service", "API")],
            insights_section=(
                "## Synthesis Insights\n\n"
                "Bounded synthesis output.\n\n"
            ),
        )

        result = merge_architecture_documents(analyzer, candidate)

        assert "## Synthesis Insights" not in result.text

    def test_insights_not_in_synthesis_sections(self):
        for name in NON_AUTHORITATIVE_SECTIONS:
            assert name not in SYNTHESIS_SECTIONS, (
                f"{name!r} must not be in SYNTHESIS_SECTIONS"
            )

    def test_insights_not_in_conditional_sections(self):
        for name in NON_AUTHORITATIVE_SECTIONS:
            assert name not in CONDITIONAL_H2_SECTIONS, (
                f"{name!r} must not be in CONDITIONAL_H2_SECTIONS"
            )

    def test_analyzer_rows_preserved_with_insights_in_candidate(self):
        analyzer = _doc_with_insights(
            [("api", "Service", "API"), ("worker", "Service", "Jobs")]
        )
        candidate = _doc_with_insights(
            [("api", "Service", "API"), ("worker", "Service", "Jobs")],
            insights_section=(
                "## Insights\n\nInsight content.\n\n"
            ),
        )

        result = merge_architecture_documents(analyzer, candidate)

        assert "| api | Service | API |" in result.text
        assert "| worker | Service | Jobs |" in result.text
        assert "## Insights" not in result.text
