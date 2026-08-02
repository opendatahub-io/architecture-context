from pathlib import Path

SKILL_PATH = (
    Path(__file__).resolve().parent.parent
    / ".claude/skills/repo-to-architecture-summary/SKILL.md"
)


def test_change_output_contract_is_explicit_in_summary_skill():
    skill = SKILL_PATH.read_text()

    assert (
        "Action | Category | Row Key | Column | Analyzer Value | Candidate Value | "
        "Reason | Evidence"
    ) in skill
    assert "literal value `<empty>` in both value columns" in skill
    assert "numeric repository-relative" in skill
    assert "bare file paths, directory paths, and glob patterns are invalid" in skill
    assert "comma-separated evidence item" in skill
    assert "Do not replace" in skill
    assert "prose change summary" in skill
    assert "never `metadata`" in skill
    assert "`endpoint :: methods`" in skill
    assert "`component :: interaction_type`" in skill
    assert "at most one change record" in skill
    assert "Tracking Server API :: All" in skill
    assert "mechanism is a cell value" in skill
    assert "| add | architecture_components |" in skill
    assert "do not copy the candidate row contents" in skill
    assert "Do not emit bare pipe-separated lines" in skill
