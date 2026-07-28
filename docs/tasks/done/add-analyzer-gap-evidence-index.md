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
- [x] Go/webhook-controller fixture coverage and Python/web replay coverage are
      present.
- [x] Replay measured source reads and discovery-tool usage; the sanitized
      results and standalone-runner limitation are recorded in the replay note.

## Status

Done — 2026-07-27
