import importlib.util
from pathlib import Path

import pytest

PROJECT_ROOT = Path(__file__).resolve().parent.parent
BASELINE_ROOT = PROJECT_ROOT / "architecture/rhoai.next.bak"
pytestmark = pytest.mark.skipif(
    not BASELINE_ROOT.is_dir(),
    reason="optional architecture/rhoai.next.bak baseline is not present",
)
VALIDATOR_PATH = (
    PROJECT_ROOT
    / ".claude/skills/repo-to-architecture-summary/scripts/validate_architecture.py"
)
SPEC = importlib.util.spec_from_file_location("validate_architecture", VALIDATOR_PATH)
assert SPEC is not None and SPEC.loader is not None
VALIDATOR = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(VALIDATOR)


def test_validator_rejects_incomplete_crd_identity(tmp_path: Path):
    source = PROJECT_ROOT / "architecture/rhoai.next.bak/rhods-operator.md"
    text = source.read_text()
    valid_row = (
        "| datasciencecluster.opendatahub.io | v1, v2 | DataScienceCluster "
        "| Cluster | Primary CR for enabling/disabling AI/ML components |"
    )
    invalid_row = "|  |  |  |  | Custom resource managed by rhods-operator |"
    assert valid_row in text
    candidate = tmp_path / "GENERATED_ARCHITECTURE.md"
    candidate.write_text(text.replace(valid_row, invalid_row))

    errors, _ = VALIDATOR.validate(str(candidate))

    assert any("Incomplete CRD identity" in error for error in errors)


def test_validator_accepts_complete_crd_identities():
    source = PROJECT_ROOT / "architecture/rhoai.next.bak/rhods-operator.md"

    errors, _ = VALIDATOR.validate(str(source))

    assert not any("CRD identity" in error for error in errors)


def test_validator_rejects_analyzer_internal_architectural_analysis(
    tmp_path: Path,
):
    source = PROJECT_ROOT / "architecture/rhoai.next.bak/rhods-operator.md"
    text = source.read_text()
    marker = (
        "## Architectural Analysis\n\n"
        "- **Analyzer coverage (agent_baseline)**: sufficient\n"
        "- **Category coverage (authentication)**: complete under authentication/v1\n"
    )
    candidate = tmp_path / "GENERATED_ARCHITECTURE.md"
    candidate.write_text(
        text.replace("## Architectural Analysis\n", marker, 1)
    )

    errors, _ = VALIDATOR.validate(str(candidate))

    assert any("Analyzer coverage" in error for error in errors)
    assert any("Category coverage" in error for error in errors)
