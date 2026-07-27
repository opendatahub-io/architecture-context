import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from lib.cli import parse_args  # noqa: E402


def test_generate_architecture_defaults_to_evidence_gated_merge(monkeypatch):
    monkeypatch.setattr(
        sys,
        "argv",
        ["main.py", "generate-architecture", "--platform", "rhoai.next"],
    )

    args = parse_args()

    assert args.evidence_gated_merge is True


def test_generate_architecture_allows_legacy_merge_opt_out(monkeypatch):
    monkeypatch.setattr(
        sys,
        "argv",
        [
            "main.py",
            "generate-architecture",
            "--platform",
            "rhoai.next",
            "--no-evidence-gated-merge",
        ],
    )

    args = parse_args()

    assert args.evidence_gated_merge is False


def test_all_defaults_to_evidence_gated_merge(monkeypatch):
    monkeypatch.setattr(
        sys,
        "argv",
        ["main.py", "all", "--platform", "rhoai.next"],
    )

    args = parse_args()

    assert args.evidence_gated_merge is True


def test_all_allows_legacy_merge_opt_out(monkeypatch):
    monkeypatch.setattr(
        sys,
        "argv",
        [
            "main.py",
            "all",
            "--platform",
            "rhoai.next",
            "--no-evidence-gated-merge",
        ],
    )

    args = parse_args()

    assert args.evidence_gated_merge is False
