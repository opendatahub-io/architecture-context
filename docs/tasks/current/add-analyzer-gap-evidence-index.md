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

- [ ] Schema defines a provenance-preserving `gap_evidence_index`.
- [ ] Candidates are deterministic and do not claim proof merely from being
      listed.
- [ ] Compact context renders the index in bounded form.
- [ ] Fixtures cover Go, Python, Rust/web, and webhook/controller cases.
- [ ] Replay measures whether discovery calls and source reads decline.

## Status

Current
