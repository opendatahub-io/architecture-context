import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from lib.cli import parse_args, resolve_script_path  # noqa: E402
from lib.manifest_parser import (  # noqa: E402
    parse_manifests_config,
    process_manifest_script,
)


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


def test_pipeline_accepts_repeated_phases_components_and_repos(monkeypatch):
    monkeypatch.setattr(
        sys,
        "argv",
        [
            "main.py",
            "pipeline",
            "--platform",
            "rhoai.next",
            "--phase",
            "static-analysis",
            "--phase",
            "generate-architecture",
            "--component",
            "models-as-a-service",
            "--component",
            "eval-hub",
            "--repo",
            "red-hat-data-services/llm-d-inference-scheduler",
            "--max-concurrent",
            "2",
            "--force",
        ],
    )

    args = parse_args()

    assert args.command == "pipeline"
    assert args.phase == ["static-analysis", "generate-architecture"]
    assert args.component == ["models-as-a-service", "eval-hub"]
    assert args.repo == ["red-hat-data-services/llm-d-inference-scheduler"]
    assert args.max_concurrent == 2
    assert args.force is True
    assert args.evidence_gated_merge is True


def test_pipeline_allows_evidence_gated_merge_opt_out(monkeypatch):
    monkeypatch.setattr(
        sys,
        "argv",
        [
            "main.py",
            "pipeline",
            "--platform",
            "rhoai.next",
            "--phase",
            "generate-architecture",
            "--no-evidence-gated-merge",
        ],
    )

    args = parse_args()

    assert args.evidence_gated_merge is False


def test_parse_manifests_config_extracts_components(tmp_path: Path):
    config = tmp_path / "manifests-config.yaml"
    config.write_text("""\
components:
  kserve:
    odh:
      repo: opendatahub-io/kserve
      ref: release-v0.17@abc123
      sourcePath: config
    rhoai:
      repo: red-hat-data-services/kserve
      ref: rhoai-3.5@def456
      sourcePath: kserve-module/config
ccmCharts:
  cert-manager-operator:
    rhoai:
      repo: red-hat-data-services/odh-gitops
      ref: rhoai-3.5@aaa111
      sourcePath: charts/dependencies/cert-manager-operator
""")
    components = parse_manifests_config(config, "rhoai")
    assert "kserve" in components
    assert components["kserve"].repo_org == "red-hat-data-services"
    assert components["kserve"].repo_name == "kserve"
    assert components["kserve"].ref == "rhoai-3.5@def456"
    assert components["kserve"].source_folder == "kserve-module/config"
    assert "cert-manager-operator" in components
    assert len(components) == 2


def test_parse_manifests_config_filters_by_platform(tmp_path: Path):
    config = tmp_path / "manifests-config.yaml"
    config.write_text("""\
components:
  kserve:
    odh:
      repo: opendatahub-io/kserve
      ref: main@abc123
      sourcePath: config
""")
    components = parse_manifests_config(config, "rhoai")
    assert len(components) == 0


def test_process_manifest_script_dispatches_to_yaml(tmp_path: Path):
    config = tmp_path / "manifests-config.yaml"
    checkout = tmp_path / "kserve"
    checkout.mkdir()
    config.write_text("""\
components:
  kserve:
    rhoai:
      repo: test-org/kserve
      ref: main@abc123
      sourcePath: config
""")
    components = process_manifest_script(
        str(config), platform="rhoai", checkouts_dir=str(tmp_path),
    )
    assert "kserve" in components
    assert components["kserve"].checkout_path == checkout


def test_process_manifest_script_dispatches_to_shell(tmp_path: Path):
    script = tmp_path / "get_all_manifests.sh"
    checkout = tmp_path / "kserve"
    checkout.mkdir()
    script.write_text("""\
declare -A RHOAI_COMPONENT_MANIFESTS=(
    ["kserve"]="test-org:kserve:main@abc123:config"
)
""")
    components = process_manifest_script(
        str(script), platform="rhoai", checkouts_dir=str(tmp_path),
    )
    assert "kserve" in components


def test_resolve_script_path_prefers_shell_script(tmp_path: Path):
    operator_dir = tmp_path / "checkouts" / "org.platform" / "rhods-operator"
    operator_dir.mkdir(parents=True)
    (operator_dir / "get_all_manifests.sh").write_text("#!/bin/bash\n")
    (operator_dir / "manifests-config.yaml").write_text("components: {}\n")
    result = resolve_script_path(
        platform="rhoai", org="org", suffix="platform",
        checkouts_dir=str(tmp_path / "checkouts"),
    )
    assert result.endswith("get_all_manifests.sh")


def test_resolve_script_path_falls_back_to_yaml(tmp_path: Path):
    operator_dir = tmp_path / "checkouts" / "org.platform" / "rhods-operator"
    operator_dir.mkdir(parents=True)
    (operator_dir / "manifests-config.yaml").write_text("components: {}\n")
    result = resolve_script_path(
        platform="rhoai", org="org", suffix="platform",
        checkouts_dir=str(tmp_path / "checkouts"),
    )
    assert result.endswith("manifests-config.yaml")
