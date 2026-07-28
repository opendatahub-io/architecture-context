# Bug: Report Generator Misses Source Citation Regressions

## Summary

`benchmark/consumer-v1/generate_report.py` only flags regressions on
`exact_match` and `gap_acknowledgment` dimensions. It does not check
`source_citation`, so a question where Tree A cites the correct source file
but Tree B does not is silently omitted from the "Flagged Regressions"
section.

## Reproduction

The v1 A/B evaluation (`benchmark/consumer-v1/results/v1-ab/report.md`)
produced two regressions (INV-008, FACT-004), both caused by source citation
failures. The automated "Flagged Regressions" section reported "No regressions
detected" because only `exact_match` and `gap_acknowledgment` are checked.

Relevant code in `generate_report.py`, lines 164-188:

```python
a_exact = a_scores.get("exact_match", {}).get("passed", False)
b_exact = b_scores.get("exact_match", {}).get("passed", False)
a_gap = a_scores.get("gap_acknowledgment", {}).get("passed", False)
b_gap = b_scores.get("gap_acknowledgment", {}).get("passed", False)

issues = []
if a_exact and not b_exact:
    issues.append("exact_match regressed (A:pass -> B:fail)")
if a_gap and not b_gap:
    issues.append("gap_acknowledgment regressed (A:pass -> B:fail)")
```

No check exists for `source_citation`.

## Expected

The regression detection should also check:

```python
a_cite = a_scores.get("source_citation", {}).get("passed", False)
b_cite = b_scores.get("source_citation", {}).get("passed", False)
if a_cite and not b_cite:
    issues.append("source_citation regressed (A:pass -> B:fail)")
```

## Actual

Source citation regressions are invisible in the automated report. They were
only caught by manual review of the per-question detail table.

## Impact

Low — the per-question detail table still shows all individual scores, so
regressions are visible on close inspection. But the "Flagged Regressions"
section is the summary consumers read first, and it gives a false "no
regressions" signal.

## Status

Fixed — 2026-07-25. The source_citation regression check is now present in
`generate_report.py` lines 201-202 and 209-210. Regression test in
`tests/test_scorer_variants.py::TestSourceCitationRegressionDetection`.
