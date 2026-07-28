# Task: Add the Analyzer Gap Evidence Index

## Goal

Publish source-backed candidate evidence locations and unresolved questions for
each high-demand analyzer gap category.

## Scope

Start with HTTP endpoints, gRPC services, authentication, integration points,
internal dependencies, egress, and services. Include candidate paths, line
ranges, symbols/configuration keys, expected signals, coverage status, and
limitations in JSON and the compact context file.

## Acceptance Criteria

- [x] Schema defines a provenance-preserving `gap_evidence_index`.
- [x] Candidates are deterministic and do not claim proof merely from being
      listed.
- [x] Compact context renders the index in bounded form.
- [x] Go/webhook-controller fixture coverage is present; Python and Rust/web
      candidate coverage remains part of the replay follow-up.
- [ ] Replay measures whether discovery calls and source reads decline.

## Status

Current
