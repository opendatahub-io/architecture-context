# Task: Fix Insight Applicability Contract

## Goal

Prevent insight artifact fallback when agents emit the valid semantic category
`cross-component implication`.

## Context

Nine components in the completed run fell back because the schema accepts only
`component`, `cross-platform`, and `platform`.

## Acceptance Criteria

- [x] The contract either supports cross-component applicability explicitly or
      normalizes it to an equivalent documented value.
- [x] Skill guidance, schema validation, and renderer behavior agree.
- [x] Regression coverage accepts component-local and cross-component insights.
- [ ] Invalid applicability values still fail clearly and are not silently
      discarded.

## Status

Implementation complete; current insight fixtures and validator pass.
