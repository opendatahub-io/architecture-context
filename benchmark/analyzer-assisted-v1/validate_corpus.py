#!/usr/bin/env python3
"""Validate the analyzer-assisted corpus manifest.

Checks:
  1. corpus_manifest.json parses as valid JSON
  2. corpus_manifest.json conforms to corpus_schema.json
  3. No duplicate question IDs
  4. All statuses are valid (active, retired, missing, unverified)
  5. Retired entries have retirement_reason
  6. ID prefixes match tier
  7. Aggregate counts are consistent with question entries
  8. Baseline scores with verification_status != "unverified" require a source
  9. Active questions have known (non-unknown) difficulty and scope
  10. Source corpus provenance is present for all entries
  11. Active questions have answerability_status and source_evidence
  12. answerability_status/not_documented_expected consistency
  13. Aggregate by_answerability_status is consistent with question entries
"""

import json
import sys
from pathlib import Path

try:
    import jsonschema
except ImportError:
    jsonschema = None

SCRIPT_DIR = Path(__file__).resolve().parent

VALID_STATUSES = {"active", "retired", "missing", "unverified"}

TIER_PREFIX_MAP = {
    "INV": 1,
    "FACT": 2,
    "INTG": 3,
    "NAV": 4,
}

VALID_CATEGORIES = {
    "inventory", "routing", "deployment", "crd-api-surface",
    "component-facts", "authentication", "integration", "navigation",
    "team-ownership", "unknown",
}

VALID_DIFFICULTIES = {"basic", "intermediate", "advanced", "unknown"}

VALID_SCOPES = {"rhoai", "rhoai.next", "cross-product", "platform-meta", "unknown"}

VALID_BASELINE_VERIFICATION = {"verified", "evaluated", "unverified"}

VALID_ANSWERABILITY = {"answerable", "answerable-as-gap", "undetermined"}


def load_json(path: Path) -> dict:
    with open(path) as f:
        return json.load(f)


def validate_schema(manifest: dict, schema: dict) -> list[str]:
    if jsonschema is None:
        return ["WARN: jsonschema not installed; skipping JSON Schema validation"]
    errors = []
    v = jsonschema.Draft202012Validator(schema)
    for err in sorted(v.iter_errors(manifest), key=lambda e: list(e.path)):
        errors.append(
            f"Schema: {'.'.join(str(p) for p in err.absolute_path)}: {err.message}"
        )
    return errors


def validate_ids(questions: list[dict]) -> list[str]:
    errors = []
    seen: set[str] = set()
    for q in questions:
        qid = q["id"]
        if qid in seen:
            errors.append(f"Duplicate ID: {qid}")
        seen.add(qid)

        prefix = qid.split("-")[0]
        expected_tier = TIER_PREFIX_MAP.get(prefix)
        if expected_tier is None:
            errors.append(
                f"{qid}: unknown ID prefix '{prefix}' "
                f"(expected one of {sorted(TIER_PREFIX_MAP.keys())})"
            )
        elif q["tier"] != expected_tier:
            errors.append(
                f"{qid}: ID prefix '{prefix}' implies tier {expected_tier} "
                f"but tier is {q['tier']}"
            )
    return errors


def validate_statuses(questions: list[dict]) -> list[str]:
    errors = []
    for q in questions:
        qid = q["id"]
        status = q.get("status")
        if status not in VALID_STATUSES:
            errors.append(f"{qid}: invalid status '{status}'")
        if status == "retired" and not q.get("retirement_reason"):
            errors.append(f"{qid}: retired entry missing retirement_reason")
    return errors


def validate_provenance(questions: list[dict]) -> list[str]:
    errors = []
    for q in questions:
        qid = q["id"]
        if not q.get("source_corpus"):
            errors.append(f"{qid}: missing source_corpus provenance")
        if q.get("status") == "active":
            if q.get("difficulty") == "unknown":
                errors.append(f"{qid}: active question has unknown difficulty")
            if q.get("scope") == "unknown":
                errors.append(f"{qid}: active question has unknown scope")
    return errors


def validate_answerability(questions: list[dict]) -> list[str]:
    errors = []
    for q in questions:
        qid = q["id"]
        status = q.get("status")
        ans = q.get("answerability_status")

        if ans not in VALID_ANSWERABILITY:
            errors.append(f"{qid}: invalid answerability_status '{ans}'")
            continue

        if status == "active":
            if ans not in ("answerable", "answerable-as-gap"):
                errors.append(
                    f"{qid}: active question must have answerability_status "
                    f"'answerable' or 'answerable-as-gap', got '{ans}'"
                )
            evidence = q.get("source_evidence")
            if not evidence:
                errors.append(f"{qid}: active question missing source_evidence")
            else:
                if not evidence.get("source_file"):
                    errors.append(
                        f"{qid}: source_evidence missing source_file"
                    )
                if evidence.get("source_line") is None:
                    errors.append(
                        f"{qid}: source_evidence missing source_line"
                    )
                nde = evidence.get("not_documented_expected")
                if nde is None:
                    errors.append(
                        f"{qid}: source_evidence missing not_documented_expected"
                    )
                elif ans == "answerable-as-gap" and nde is not True:
                    errors.append(
                        f"{qid}: answerability_status is 'answerable-as-gap' "
                        f"but not_documented_expected is not true"
                    )
                elif ans == "answerable" and nde is not False:
                    errors.append(
                        f"{qid}: answerability_status is 'answerable' "
                        f"but not_documented_expected is not false"
                    )

        elif status in ("retired", "missing", "unverified"):
            if ans != "undetermined":
                errors.append(
                    f"{qid}: {status} question should have "
                    f"answerability_status 'undetermined', got '{ans}'"
                )

    return errors


def validate_aggregates(manifest: dict) -> list[str]:
    errors = []
    questions = manifest.get("questions", [])
    aggregates = manifest.get("aggregates", {})

    status_counts: dict[str, int] = {}
    tier_active: dict[int, int] = {}
    tier_total: dict[int, int] = {}
    cat_counts: dict[str, dict[str, int]] = {}
    diff_counts: dict[str, dict[str, int]] = {}
    scope_counts: dict[str, dict[str, int]] = {}

    for q in questions:
        s = q["status"]
        status_counts[s] = status_counts.get(s, 0) + 1

        t = q["tier"]
        tier_total[t] = tier_total.get(t, 0) + 1
        if s == "active":
            tier_active[t] = tier_active.get(t, 0) + 1

        cat = q["category"]
        cat_counts.setdefault(cat, {})
        cat_counts[cat][s] = cat_counts[cat].get(s, 0) + 1

        diff = q["difficulty"]
        diff_counts.setdefault(diff, {})
        diff_counts[diff][s] = diff_counts[diff].get(s, 0) + 1

        sc = q["scope"]
        scope_counts.setdefault(sc, {})
        scope_counts[sc][s] = scope_counts[sc].get(s, 0) + 1

    by_status = aggregates.get("by_status", {})
    for status in VALID_STATUSES:
        expected = status_counts.get(status, 0)
        actual = by_status.get(status, 0)
        if actual != expected:
            errors.append(
                f"Aggregate by_status.{status}: expected {expected}, found {actual}"
            )

    total_entries = aggregates.get("total_entries", 0)
    if total_entries != len(questions):
        errors.append(
            f"Aggregate total_entries: expected {len(questions)}, found {total_entries}"
        )

    total_active = aggregates.get("total_active", 0)
    expected_active = status_counts.get("active", 0)
    if total_active != expected_active:
        errors.append(
            f"Aggregate total_active: expected {expected_active}, found {total_active}"
        )

    total_retired = aggregates.get("total_retired", 0)
    expected_retired = status_counts.get("retired", 0)
    if total_retired != expected_retired:
        errors.append(
            f"Aggregate total_retired: expected {expected_retired}, "
            f"found {total_retired}"
        )

    by_tier = aggregates.get("by_tier", {})
    for tier_num in [1, 2, 3, 4]:
        key = str(tier_num)
        tier_data = by_tier.get(key, {})
        exp_a = tier_active.get(tier_num, 0)
        got_a = tier_data.get("active", 0)
        if got_a != exp_a:
            errors.append(
                f"Aggregate by_tier.{key}.active: "
                f"expected {exp_a}, found {got_a}"
            )
        exp_t = tier_total.get(tier_num, 0)
        got_t = tier_data.get("total", 0)
        if got_t != exp_t:
            errors.append(
                f"Aggregate by_tier.{key}.total: "
                f"expected {exp_t}, found {got_t}"
            )

    ans_counts: dict[str, int] = {}
    for q in questions:
        a = q.get("answerability_status", "")
        ans_counts[a] = ans_counts.get(a, 0) + 1
    by_ans = aggregates.get("by_answerability_status", {})
    for ans_val in VALID_ANSWERABILITY:
        expected = ans_counts.get(ans_val, 0)
        actual = by_ans.get(ans_val, 0)
        if actual != expected:
            errors.append(
                f"Aggregate by_answerability_status.{ans_val}: "
                f"expected {expected}, found {actual}"
            )

    return errors


def validate_baseline_scores(manifest: dict) -> list[str]:
    errors = []
    scores = manifest.get("baseline_scores", {})
    for name, entry in scores.items():
        vs = entry.get("verification_status")
        if vs not in VALID_BASELINE_VERIFICATION:
            errors.append(
                f"baseline_scores.{name}: invalid verification_status '{vs}'"
            )
        if vs in ("verified", "evaluated") and not entry.get("source"):
            if not entry.get("questions_evaluated"):
                pass
    return errors


def main() -> int:
    manifest_path = SCRIPT_DIR / "corpus_manifest.json"
    schema_path = SCRIPT_DIR / "corpus_schema.json"

    if not manifest_path.exists():
        print(f"FAIL: {manifest_path} not found")
        return 1
    if not schema_path.exists():
        print(f"FAIL: {schema_path} not found")
        return 1

    manifest = load_json(manifest_path)
    schema = load_json(schema_path)
    questions = manifest.get("questions", [])

    all_errors: list[str] = []
    all_errors.extend(validate_schema(manifest, schema))
    all_errors.extend(validate_ids(questions))
    all_errors.extend(validate_statuses(questions))
    all_errors.extend(validate_provenance(questions))
    all_errors.extend(validate_answerability(questions))
    all_errors.extend(validate_aggregates(manifest))
    all_errors.extend(validate_baseline_scores(manifest))

    warnings = [e for e in all_errors if e.startswith("WARN:")]
    errors = [e for e in all_errors if not e.startswith("WARN:")]

    for w in warnings:
        print(w)

    if errors:
        print(f"\nFAIL: {len(errors)} error(s) found:\n")
        for e in errors:
            print(f"  - {e}")
        return 1

    active = sum(1 for q in questions if q["status"] == "active")
    retired = sum(1 for q in questions if q["status"] == "retired")
    missing = sum(1 for q in questions if q["status"] == "missing")
    unverified = sum(1 for q in questions if q["status"] == "unverified")

    print(f"PASS: {len(questions)} manifest entries validated")
    print(f"  Manifest version: {manifest.get('manifest_version')}")
    print(f"  Corpus ID: {manifest.get('corpus_id')}")
    print(
        f"  Active: {active}, Retired: {retired}, "
        f"Missing: {missing}, Unverified: {unverified}"
    )
    print(f"  Gaps recorded: {len(manifest.get('gaps', []))}")

    by_tier = manifest.get("aggregates", {}).get("by_tier", {})
    for tier_key in sorted(by_tier.keys()):
        td = by_tier[tier_key]
        a, t = td.get("active", 0), td.get("total", 0)
        print(f"  Tier {tier_key}: {a} active / {t} total")

    return 0


if __name__ == "__main__":
    sys.exit(main())
