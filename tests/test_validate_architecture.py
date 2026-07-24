import importlib.util
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
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
