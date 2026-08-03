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
    assert "one bounded search plan" in skill
    assert "Do not repeat equivalent searches" in skill
    assert "stop discovery for that gap" in skill
    assert "not an invitation to continue searching" in skill
    assert "not permission to stop early" not in skill
    assert "not permission to repeat" in skill
    assert "| add | architecture_components |" in skill
    assert "do not copy the candidate row contents" in skill
    assert "row-key migration" in skill
    assert "Never emit an `update` whose candidate value changes a key column" in skill
    assert "requires a delete for the former key" in skill
    assert "an add\nfor the latter key" in skill
    assert "Do not emit bare pipe-separated lines" in skill
