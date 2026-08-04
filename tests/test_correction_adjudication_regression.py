"""Regression assertions for shipped correction adjudications.

Validates that the live ``lib/analyzer_correction_adjudications.json`` file
loads without error, contains structurally valid entries, and that known
correction counts remain stable across changes.  These assertions guard
Step 3's "regression assertions for known corrections and confirmed-correct
patterns from the feedback corpus" requirement.
"""

import json
import sys
from pathlib import Path

import pytest

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from lib.architecture_merge import load_rejected_additions  # noqa: E402
from lib.architecture_routing import (  # noqa: E402
    load_source_audited_empty_categories,
)

ADJUDICATIONS_PATH = PROJECT_ROOT / "lib" / "analyzer_correction_adjudications.json"


@pytest.fixture(scope="module")
def adjudication_data():
    return json.loads(ADJUDICATIONS_PATH.read_text())


class TestShippedAdjudicationsStructure:
    """Validate the shipped adjudications file loads and has valid schema."""

    def test_file_exists(self):
        assert ADJUDICATIONS_PATH.is_file()

    def test_valid_json(self, adjudication_data):
        assert isinstance(adjudication_data, dict)
        assert "accepted_analyzer_absences" in adjudication_data
        assert "source_audited_empty_categories" in adjudication_data

    def test_schema_version(self, adjudication_data):
        assert adjudication_data.get("schema_version") == 1

    def test_accepted_absences_is_list(self, adjudication_data):
        absences = adjudication_data["accepted_analyzer_absences"]
        assert isinstance(absences, list)
        assert len(absences) > 0

    def test_source_audited_is_list(self, adjudication_data):
        audited = adjudication_data["source_audited_empty_categories"]
        assert isinstance(audited, list)
        assert len(audited) > 0


class TestAcceptedAbsenceEntryValidity:
    """Every accepted_analyzer_absence entry has required fields."""

    def test_all_entries_have_required_fields(self, adjudication_data):
        for i, entry in enumerate(adjudication_data["accepted_analyzer_absences"]):
            assert isinstance(entry, dict), f"entry {i} is not a dict"
            assert entry.get("component"), f"entry {i} missing component"
            assert entry.get("category"), f"entry {i} missing category"
            assert entry.get("key"), f"entry {i} missing key"
            assert isinstance(entry["key"], list), f"entry {i} key is not a list"
            assert len(entry["key"]) > 0, f"entry {i} key is empty"
            assert entry.get("reason"), f"entry {i} missing reason"
            assert entry.get("evidence"), f"entry {i} missing evidence"
            assert isinstance(entry["evidence"], list), (
                f"entry {i} evidence is not a list"
            )
            assert len(entry["evidence"]) > 0, f"entry {i} evidence is empty"

    def test_evidence_entries_are_file_line_references(self, adjudication_data):
        for i, entry in enumerate(adjudication_data["accepted_analyzer_absences"]):
            for j, ref in enumerate(entry["evidence"]):
                assert isinstance(ref, str), f"entry {i} evidence[{j}] not a string"
                assert ":" in ref, (
                    f"entry {i} evidence[{j}] ({ref!r}) missing file:line format"
                )


class TestSourceAuditedEntryValidity:
    """Every source_audited_empty_categories entry has required fields."""

    def test_all_entries_have_required_fields(self, adjudication_data):
        for i, entry in enumerate(
            adjudication_data["source_audited_empty_categories"]
        ):
            assert isinstance(entry, dict), f"entry {i} is not a dict"
            assert entry.get("component"), f"entry {i} missing component"
            assert entry.get("category"), f"entry {i} missing category"
            assert entry.get("reason"), f"entry {i} missing reason"
            assert entry.get("evidence"), f"entry {i} missing evidence"
            assert isinstance(entry["evidence"], list), (
                f"entry {i} evidence is not a list"
            )
            assert len(entry["evidence"]) > 0, f"entry {i} evidence is empty"


class TestAdjudicationLoaderIntegration:
    """Loaders produce correct results from the shipped file."""

    def test_load_rejected_additions_returns_nonempty(self, adjudication_data):
        components = {
            e["component"]
            for e in adjudication_data["accepted_analyzer_absences"]
        }
        total = 0
        for component in components:
            rejected = load_rejected_additions(component, path=ADJUDICATIONS_PATH)
            total += len(rejected)
        assert total == len(adjudication_data["accepted_analyzer_absences"])

    def test_load_source_audited_returns_nonempty(self):
        result = load_source_audited_empty_categories(path=ADJUDICATIONS_PATH)
        assert isinstance(result, dict)
        assert len(result) > 0
        for component, categories in result.items():
            assert isinstance(component, str)
            assert isinstance(categories, frozenset)
            assert len(categories) > 0


class TestCorrectionCountRegression:
    """Guard known correction counts against unintentional changes."""

    def test_accepted_absence_count(self, adjudication_data):
        count = len(adjudication_data["accepted_analyzer_absences"])
        assert count >= 68, (
            f"accepted_analyzer_absences count dropped to {count} "
            f"(expected >= 68); removing entries requires explicit review"
        )

    def test_source_audited_count(self, adjudication_data):
        count = len(adjudication_data["source_audited_empty_categories"])
        assert count >= 16, (
            f"source_audited_empty_categories count dropped to {count} "
            f"(expected >= 16); removing entries requires explicit review"
        )

    def test_distinct_components_in_absences(self, adjudication_data):
        components = {
            e["component"]
            for e in adjudication_data["accepted_analyzer_absences"]
        }
        assert len(components) >= 20, (
            f"distinct components in absences dropped to {len(components)} "
            f"(expected >= 20)"
        )

    def test_distinct_components_in_source_audited(self, adjudication_data):
        components = {
            e["component"]
            for e in adjudication_data["source_audited_empty_categories"]
        }
        assert len(components) >= 10, (
            f"distinct source-audited components dropped to {len(components)} "
            f"(expected >= 10)"
        )


class TestKnownCorrectionPatterns:
    """Spot-check that specific known corrections remain present."""

    def test_trustyai_service_operator_auth_absence(self, adjudication_data):
        match = [
            e
            for e in adjudication_data["accepted_analyzer_absences"]
            if e["component"] == "trustyai-service-operator"
            and e["category"] == "authentication"
        ]
        assert len(match) >= 1

    def test_batch_gateway_component_absences(self, adjudication_data):
        match = [
            e
            for e in adjudication_data["accepted_analyzer_absences"]
            if e["component"] == "batch-gateway"
            and e["category"] == "architecture_components"
        ]
        assert len(match) >= 3

    def test_caikit_tgis_serving_source_audited(self, adjudication_data):
        match = [
            e
            for e in adjudication_data["source_audited_empty_categories"]
            if e["component"] == "caikit-tgis-serving"
        ]
        assert len(match) >= 1

    def test_distributed_workloads_source_audited(self, adjudication_data):
        match = [
            e
            for e in adjudication_data["source_audited_empty_categories"]
            if e["component"] == "distributed-workloads"
        ]
        assert len(match) >= 1
