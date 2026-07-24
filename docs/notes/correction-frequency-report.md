# Correction Frequency Report

`arch-query proposals report` reads a proposal set, validates it, and emits
report contract `v1` as JSON or deterministic text. It preserves proposal-set
identity and counts superseded proposals separately, while active component,
category, status, and release counts exclude superseded records.

The report is descriptive rather than prescriptive: it does not infer review
priority, apply proposals, harvest new corrections, or mutate generated
architecture output. Invalid or missing proposal sets fail before counting.
