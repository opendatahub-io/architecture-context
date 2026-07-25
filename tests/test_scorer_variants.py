"""Focused tests for deterministic scorer changes.

Tests normalize() markdown stripping, evidence-backed corpus variants,
source-citation regression detection in generate_report.py, and
negative controls.
"""

import json
import sys
from pathlib import Path

import pytest

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT / "benchmark" / "consumer-v1"))

from generate_report import generate_report  # noqa: E402
from score_results import (  # noqa: E402
    check_exact_match,
    check_source_citation,
    normalize,
    score_response,
)


class TestNormalize:
    """Tests for markdown-stripping normalize()."""

    def test_strips_bold_markers(self):
        assert "hello world" == normalize("**hello** world")

    def test_strips_italic_markers(self):
        assert "hello world" == normalize("*hello* world")

    def test_strips_inline_code(self):
        assert "run pytest" == normalize("run `pytest`")

    def test_strips_nested_bold_italic(self):
        assert "important" == normalize("***important***")

    def test_preserves_non_markdown_text(self):
        assert "92 components analyzed" == normalize("92 components analyzed")

    def test_lowercases(self):
        assert "hello world" == normalize("Hello World")

    def test_collapses_whitespace(self):
        assert "a b c" == normalize("a   b\n\nc")

    def test_strips_combined_markdown(self):
        text = "**Operator** (`multi-controller`) + *Python* SDK"
        result = normalize(text)
        assert "operator (multi-controller) + python sdk" == result


class TestExactMatchWithVariants:
    """Tests for evidence-backed variant additions.

    Each test verifies that a new variant matches the actual phrasing
    found in existing raw results, and that it correctly identifies
    the source-backed answer.
    """

    def _question(self, expected, variants):
        return {
            "expected_answer": expected,
            "acceptable_variants": variants,
        }

    def test_inv003_standalone_variant_matches(self):
        q = self._question(
            "No. InstructLab is not a standalone RHOAI component.",
            ["InstructLab is not a standalone RHOAI component"],
        )
        response = (
            "**InstructLab is not a standalone RHOAI component** "
            "and does not have its own architecture document."
        )
        result = check_exact_match(response, q)
        assert result["passed"]
        assert result["variant_matches"] == [
            "InstructLab is not a standalone RHOAI component"
        ]

    def test_inv003_standalone_variant_rejects_affirming_response(self):
        q = self._question(
            "No. InstructLab is not a standalone RHOAI component.",
            ["InstructLab is not a standalone RHOAI component"],
        )
        response = "Yes, InstructLab is a RHOAI component with its own doc."
        result = check_exact_match(response, q)
        assert not result["passed"]

    def test_inv004_model_registry_component_variant(self):
        q = self._question(
            "Yes. model-registry is documented.",
            ["model registry component"],
        )
        response = (
            "Yes, **RHOAI includes a comprehensive model registry "
            "component**, along with a model registry operator."
        )
        result = check_exact_match(response, q)
        assert result["passed"]
        assert result["variant_matches"] == ["model registry component"]

    def test_inv004_model_registry_negative_control(self):
        q = self._question(
            "Yes. model-registry is documented.",
            ["model registry component"],
        )
        response = "No, model-registry is not listed as a RHOAI component."
        result = check_exact_match(response, q)
        assert not result["passed"]

    def test_inv005_codeflare_inventory_variant(self):
        q = self._question(
            "Yes. CodeFlare SDK is listed.",
            ["CodeFlare SDK is in the RHOAI component inventory"],
        )
        response = (
            "Yes, **CodeFlare SDK is in the RHOAI component inventory.** "
            "It is explicitly listed."
        )
        result = check_exact_match(response, q)
        assert result["passed"]

    def test_inv006_sdg_hub_not_documented_variant(self):
        q = self._question(
            "No. SDG Hub does not have its own architecture document.",
            ["SDG Hub is not documented as a standalone RHOAI component"],
        )
        response = (
            "Based on the documents, **SDG Hub is not documented as a "
            "standalone RHOAI component** with its own architecture document."
        )
        result = check_exact_match(response, q)
        assert result["passed"]

    def test_fact001_no_trailing_period_variant(self):
        q = self._question(
            "Operator (multi-controller) + Python SDK + Sidecar utilities.",
            ["Operator (multi-controller) + Python SDK + Sidecar utilities"],
        )
        response = (
            "From kserve.md, line 9:\n\n"
            "> **Deployment Type**: Operator (multi-controller) + "
            "Python SDK + Sidecar utilities\n\n"
            "KServe is deployed as a multi-controller operator."
        )
        result = check_exact_match(response, q)
        assert result["passed"]

    def test_fact001_expected_with_period_does_not_match_without(self):
        q = self._question(
            "Operator (multi-controller) + Python SDK + Sidecar utilities.",
            [],
        )
        response = (
            "Deployment Type: Operator (multi-controller) + "
            "Python SDK + Sidecar utilities\n"
            "KServe is deployed as a multi-controller operator."
        )
        result = check_exact_match(response, q)
        assert not result["expected_match"]

    def test_fact004_no_crds_by_this_component_variant(self):
        q = self._question(
            "No. model-registry does not define CRDs.",
            ["No CRDs are defined by this component"],
        )
        response = (
            "The `model-registry` component explicitly does **not** "
            "define any CRDs.\n_No CRDs are defined by this component._"
        )
        result = check_exact_match(response, q)
        assert result["passed"]

    def test_fact004_negative_when_crds_are_claimed(self):
        q = self._question(
            "No. model-registry does not define CRDs.",
            ["No CRDs are defined by this component"],
        )
        response = (
            "Yes, model-registry defines its own CRDs — "
            "specifically through the model-registry-operator."
        )
        result = check_exact_match(response, q)
        assert not result["passed"]

    def test_fact010_short_4_crds_variant(self):
        q = self._question(
            "KubeRay defines 4 CRDs.",
            ["4 CRDs"],
        )
        response = "KubeRay defines **4 CRDs**, documented in kuberay.md."
        result = check_exact_match(response, q)
        assert result["passed"]

    def test_fact010_4_custom_resource_definitions_variant(self):
        q = self._question(
            "KubeRay defines 4 CRDs.",
            ["4 custom resource definitions"],
        )
        response = (
            "KubeRay defines **4 custom resource definitions (CRDs)**:"
        )
        result = check_exact_match(response, q)
        assert result["passed"]

    def test_intg009_rustls_without_no_prefix(self):
        q = self._question(
            "No. fms-guardrails-orchestrator uses rustls.",
            ["rustls with ring is not FIPS-validated"],
        )
        response = (
            "**rustls with ring** is not FIPS-validated — "
            "ring is a pure-Rust/asm crypto library."
        )
        result = check_exact_match(response, q)
        assert result["passed"]

    def test_nav004_no_components_subdirectory_variant(self):
        q = self._question(
            "No. There is no components/ subdirectory.",
            ["no components/ subdirectory"],
        )
        response = (
            "**No, there is no components/ subdirectory** "
            "anywhere in this architecture tree."
        )
        result = check_exact_match(response, q)
        assert result["passed"]


class TestMarkdownDoesNotRegress:
    """Verify that markdown stripping does not break previously passing matches."""

    def test_plain_text_still_matches(self):
        q = {"expected_answer": "92 components", "acceptable_variants": ["92"]}
        response = "The platform analyzes 92 components."
        result = check_exact_match(response, q)
        assert result["passed"]

    def test_numeric_variant_still_matches(self):
        q = {"expected_answer": "474 total.", "acceptable_variants": ["474"]}
        response = "There are 474 container images shipped."
        result = check_exact_match(response, q)
        assert result["passed"]

    def test_case_insensitive_still_works(self):
        q = {
            "expected_answer": "TypeScript and Go.",
            "acceptable_variants": ["TypeScript, Go"],
        }
        response = "The languages are TypeScript, Go."
        result = check_exact_match(response, q)
        assert result["passed"]


class TestSourceCitationRegressionDetection:
    """Verify generate_report.py detects source_citation regressions."""

    def _make_scored(self, results):
        return {
            "corpus_version": "test",
            "architecture_context_version": "test",
            "model": "test",
            "model_id": "test",
            "timestamp": "test",
            "git_sha": "test",
            "seed": 0,
            "tree_a_path": "a",
            "tree_b_path": "b",
            "total_questions": len(results),
            "aggregates": {
                "tree_a": {"overall": {}, "by_tier": {}, "by_consumer": {}, "by_scope": {}},
                "tree_b": {"overall": {}, "by_tier": {}, "by_consumer": {}, "by_scope": {}},
            },
            "efficiency": {
                "tree_a": {},
                "tree_b": {},
            },
            "results": results,
        }

    def _result_with_citation_regression(self):
        return {
            "question_id": "TEST-001",
            "tier": 1,
            "consumer": "test",
            "question": "Test question?",
            "expected_answer": "Test answer.",
            "not_documented_expected": False,
            "tree_a": {
                "success": True,
                "scores": {
                    "exact_match": {"passed": True},
                    "source_citation": {"passed": True},
                    "gap_acknowledgment": {"passed": True, "applicable": False},
                    "score": 1.0,
                },
            },
            "tree_b": {
                "success": True,
                "scores": {
                    "exact_match": {"passed": True},
                    "source_citation": {"passed": False},
                    "gap_acknowledgment": {"passed": True, "applicable": False},
                    "score": 0.5,
                },
            },
        }

    def _result_no_regression(self):
        return {
            "question_id": "TEST-002",
            "tier": 1,
            "consumer": "test",
            "question": "Another question?",
            "expected_answer": "Another answer.",
            "not_documented_expected": False,
            "tree_a": {
                "success": True,
                "scores": {
                    "exact_match": {"passed": True},
                    "source_citation": {"passed": True},
                    "gap_acknowledgment": {"passed": True, "applicable": False},
                    "score": 1.0,
                },
            },
            "tree_b": {
                "success": True,
                "scores": {
                    "exact_match": {"passed": True},
                    "source_citation": {"passed": True},
                    "gap_acknowledgment": {"passed": True, "applicable": False},
                    "score": 1.0,
                },
            },
        }

    def test_detects_source_citation_regression(self, tmp_path):
        scored = self._make_scored([
            self._result_with_citation_regression(),
            self._result_no_regression(),
        ])
        scored_path = tmp_path / "scored-results.json"
        scored_path.write_text(json.dumps(scored))

        report_path = generate_report(scored_path)
        report_text = report_path.read_text()

        assert "source_citation regressed" in report_text
        assert "TEST-001" in report_text

    def test_no_false_regression_when_both_pass(self, tmp_path):
        scored = self._make_scored([self._result_no_regression()])
        scored_path = tmp_path / "scored-results.json"
        scored_path.write_text(json.dumps(scored))

        report_path = generate_report(scored_path)
        report_text = report_path.read_text()

        assert "source_citation regressed" not in report_text
        assert "No regressions detected" in report_text

    def test_no_false_regression_when_both_fail(self, tmp_path):
        result = self._result_with_citation_regression()
        result["tree_a"]["scores"]["source_citation"]["passed"] = False
        scored = self._make_scored([result])
        scored_path = tmp_path / "scored-results.json"
        scored_path.write_text(json.dumps(scored))

        report_path = generate_report(scored_path)
        report_text = report_path.read_text()

        assert "source_citation regressed" not in report_text
