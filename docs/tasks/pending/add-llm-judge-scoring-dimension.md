# Task: Add LLM-as-Judge Scoring Dimension

## Goal

Extend the consumer-v1 scorer with an optional semantic-equivalence dimension
that runs alongside deterministic exact-match, citation, and gap checks.

## Preconditions and authorization

- Do not start implementation or model calls until the user authorizes the
  expected model, question count, estimated cost, and duration.
- Prepare an offline fixture/protocol first; no paid or full-corpus evaluation
  is part of task setup.

## Scope

- Define a versioned judge-result schema with prompt/model provenance,
  per-question classification, confidence, rationale, and explicit abstention.
- Keep deterministic scores unchanged and make the judge opt-in.
- Add tests for semantic match, mismatch, abstention, malformed output, and
  disagreement with deterministic checks.
- Define a manually classified calibration set and an acceptance calculation
  for the 90% agreement target before running it.

## Non-goals

- Do not replace exact-match scoring or modify existing raw/scored artifacts.
- Do not claim the 90% target without an authorized run and human-labeled
  reference set.
