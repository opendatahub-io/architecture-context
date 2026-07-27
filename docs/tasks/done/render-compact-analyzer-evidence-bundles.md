# Task: Render Compact Analyzer Evidence Bundles

## Goal

Provide bounded, section-oriented evidence slices for synthesis while keeping
the full analyzer JSON authoritative.

## Scope

Cover endpoints, services, authentication, dependencies, integrations, and
runtime/build metadata. Include source paths and line/range provenance where
available.

## Acceptance Criteria

- [x] Bundles are deterministic and derived only from analyzer facts.
- [x] Bundles are smaller and section-specific rather than duplicate full JSON.
- [x] Existing synthesis routing exposes them through the supplied analyzer
      JSON/Markdown directory without granting broader source access.
      access.
- [x] Fixture replay validates deterministic output, provenance, and bounded
      records; full runtime measurement remains a follow-up requiring checkouts.
      preservation against the completed-run baseline.

## Status

Implementation complete; full runtime comparison remains pending checkout
availability.
