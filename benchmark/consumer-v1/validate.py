#!/usr/bin/env python3
"""Validate the consumer benchmark corpus against its JSON schema.

Checks:
  1. corpus.json parses as valid JSON
  2. corpus.json conforms to schema.json
  3. No duplicate question IDs
  4. Every question has a non-empty source_file and source_line
  5. source_file paths exist on disk (relative to repo root)
  6. ID prefixes match tier (INV=1, FACT=2, INTG=3, NAV=4)
  7. Exactly 10 questions per tier
  8. Minimum 40 questions total
"""

import json
import os
import sys
from pathlib import Path

try:
    import jsonschema
except ImportError:
    jsonschema = None

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent.parent

TIER_PREFIX_MAP = {
    "INV": 1,
    "FACT": 2,
    "INTG": 3,
    "NAV": 4,
}

EXPECTED_PER_TIER = 10

VALID_SCOPES = {"architecture", "architecture+overlays", "full-repo"}


def load_json(path: Path) -> dict:
    with open(path) as f:
        return json.load(f)


def validate_schema(corpus: dict, schema: dict) -> list[str]:
    if jsonschema is None:
        return ["WARN: jsonschema not installed; skipping JSON Schema validation (pip install jsonschema)"]
    errors = []
    v = jsonschema.Draft202012Validator(schema)
    for err in sorted(v.iter_errors(corpus), key=lambda e: list(e.path)):
        errors.append(f"Schema: {'.'.join(str(p) for p in err.absolute_path)}: {err.message}")
    return errors


def validate_ids(questions: list[dict]) -> list[str]:
    errors = []
    seen = set()
    for q in questions:
        qid = q["id"]
        if qid in seen:
            errors.append(f"Duplicate ID: {qid}")
        seen.add(qid)

        prefix = qid.split("-")[0]
        expected_tier = TIER_PREFIX_MAP.get(prefix)
        if expected_tier is None:
            errors.append(f"{qid}: unknown ID prefix '{prefix}' (expected one of {list(TIER_PREFIX_MAP.keys())})")
        elif q["tier"] != expected_tier:
            errors.append(f"{qid}: ID prefix '{prefix}' implies tier {expected_tier} but tier is {q['tier']}")
    return errors


def validate_tier_counts(questions: list[dict]) -> list[str]:
    errors = []
    counts = {}
    for q in questions:
        counts[q["tier"]] = counts.get(q["tier"], 0) + 1
    for tier in [1, 2, 3, 4]:
        count = counts.get(tier, 0)
        if count != EXPECTED_PER_TIER:
            errors.append(f"Tier {tier}: expected {EXPECTED_PER_TIER} questions, found {count}")
    total = len(questions)
    if total < 40:
        errors.append(f"Total questions: expected >= 40, found {total}")
    return errors


def validate_sources(questions: list[dict]) -> list[str]:
    errors = []
    for q in questions:
        qid = q["id"]
        src = q.get("source_file", "")
        if not src:
            errors.append(f"{qid}: missing source_file")
            continue

        src_path = REPO_ROOT / src
        if not src_path.exists():
            if src_path.is_symlink():
                pass
            else:
                errors.append(f"{qid}: source_file not found: {src}")

        line = q.get("source_line")
        if line is None or (isinstance(line, str) and not line.strip()):
            errors.append(f"{qid}: missing source_line")
    return errors


def validate_scopes(questions: list[dict]) -> list[str]:
    errors = []
    for q in questions:
        qid = q["id"]
        scope = q.get("required_scope")
        if scope is None:
            errors.append(f"{qid}: missing required_scope")
        elif scope not in VALID_SCOPES:
            errors.append(
                f"{qid}: invalid required_scope '{scope}' "
                f"(expected one of {sorted(VALID_SCOPES)})"
            )
    return errors


def validate_fields(questions: list[dict]) -> list[str]:
    errors = []
    required = [
        "id", "tier", "consumer", "question", "expected_answer",
        "acceptable_variants", "source_file", "source_line",
        "scope", "not_documented_expected", "required_scope",
    ]
    for q in questions:
        qid = q.get("id", "<no-id>")
        for field in required:
            if field not in q:
                errors.append(f"{qid}: missing required field '{field}'")
    return errors


def main() -> int:
    corpus_path = SCRIPT_DIR / "corpus.json"
    schema_path = SCRIPT_DIR / "schema.json"

    if not corpus_path.exists():
        print(f"FAIL: {corpus_path} not found")
        return 1
    if not schema_path.exists():
        print(f"FAIL: {schema_path} not found")
        return 1

    corpus = load_json(corpus_path)
    schema = load_json(schema_path)
    questions = corpus.get("questions", [])

    all_errors = []
    all_errors.extend(validate_schema(corpus, schema))
    all_errors.extend(validate_fields(questions))
    all_errors.extend(validate_ids(questions))
    all_errors.extend(validate_tier_counts(questions))
    all_errors.extend(validate_sources(questions))
    all_errors.extend(validate_scopes(questions))

    warnings = [e for e in all_errors if e.startswith("WARN:")]
    errors = [e for e in all_errors if not e.startswith("WARN:")]

    for w in warnings:
        print(w)

    if errors:
        print(f"\nFAIL: {len(errors)} error(s) found:\n")
        for e in errors:
            print(f"  - {e}")
        return 1

    tier_names = {1: "Inventory", 2: "Component Facts", 3: "Cross-Component Integration", 4: "Navigation/Structure"}
    not_doc = sum(1 for q in questions if q.get("not_documented_expected"))
    print(f"PASS: {len(questions)} questions validated")
    print(f"  Corpus version: {corpus.get('corpus_version')}")
    print(f"  Architecture context: {corpus.get('architecture_context_version', '')[:12]}...")
    for tier in [1, 2, 3, 4]:
        count = sum(1 for q in questions if q["tier"] == tier)
        print(f"  Tier {tier} ({tier_names[tier]}): {count} questions")
    print(f"  'Not documented' expected: {not_doc} questions")
    scope_counts: dict[str, int] = {}
    for q in questions:
        s = q.get("required_scope", "unknown")
        scope_counts[s] = scope_counts.get(s, 0) + 1
    for scope in sorted(scope_counts):
        print(f"  Scope '{scope}': {scope_counts[scope]} questions")
    return 0


if __name__ == "__main__":
    sys.exit(main())
