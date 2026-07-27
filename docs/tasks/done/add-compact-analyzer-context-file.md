# Task: Add a Compact Analyzer Context File

## Goal

Generate a bounded analyzer context projection that agents read before the full
JSON, avoiding tool failures and unnecessary context consumption on large
components.

## Context

The completed run had 22 components attempt full analyzer JSON reads larger than
the 25,000-token Read limit. The projection contains coverage findings,
cross-references, and section-oriented synthesis evidence with provenance.

## Acceptance Criteria

- [x] Static-analysis rendering emits a compact context file beside the
      analyzer Markdown and JSON.
- [x] The skill directs agents to read the compact file first and only inspect
      the full JSON for exact facts not present in the projection.
- [x] The compact file has deterministic size/content and preserves provenance.
- [x] Regression tests cover generation, navigation permissions, and rendering.

## Status

Implemented; next full run should measure reduction in oversized JSON reads.
