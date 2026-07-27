# Task: Add arch-analyzer Coverage and Complete-Empty Findings

## Goal

Represent category coverage explicitly and emit complete-empty findings where
the analyzer can prove absence, while preserving `unknown` for incomplete
scans.

## Acceptance Criteria

- [x] Output distinguishes observed, confirmed-empty, and not-verified
      findings while retaining complete/partial analyzer coverage.
- [x] Reliable empty categories render explicit findings, including gRPC,
      ingress, and CRD cases where applicable.
- [x] Partial extraction never renders absence as a fact.
- [x] Schema, renderer, and validation tests cover positive, empty, and partial
      cases.

## Status

Implementation complete; production-corpus replay remains pending checkout
availability.
