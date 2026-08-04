from pathlib import Path

SKILL_PATH = (
    Path(__file__).resolve().parent.parent
    / ".claude/skills/aggregate-platform-architecture/SKILL.md"
)
TEMPLATE_PATH = SKILL_PATH.parent / "references/platform-template.md"


def test_platform_skill_requires_evidence_derived_serving_path_matrix():
    skill = SKILL_PATH.read_text()

    assert "Serving-path completeness pass" in skill
    assert "one row for every distinct path supported by the evidence" in skill
    assert "external-provider or multi-model path" in skill
    assert "Do not substitute one" in skill
    assert "implementation path for another" in skill
    assert "Serving Path Evolution" in skill
    assert "source references" in skill


def test_platform_template_reserves_serving_path_evolution_section():
    template = TEMPLATE_PATH.read_text()

    assert "### Serving Path Evolution" in template
    assert "Evidence Components" in template
    assert "Runtime or Provider Role" in template
