# ADR-0011: rhoai.next as Rolling-Target Platform Key

## Status

Accepted

## Date

2026-04-29

## Context

The pipeline generates architecture docs into versioned directories (`architecture/rhoai-3.4/`, `architecture/rhoai-3.5-ea.1/`, etc.). During active development, the "latest unreleased version" changes frequently as EA milestones and GA releases are cut. Agents and consumers needed a stable reference to "whatever is current" without hardcoding a version that would become stale.

## Decision

Introduce `rhoai.next` as a rolling platform key in `platforms.yaml` that always tracks the latest unreleased RHOAI version. Architecture output goes to `architecture/rhoai.next/`.

When a version goes GA (e.g., 3.4), the architecture symlinks are updated:
- `architecture/rhoai-3.4` symlink points to the GA-frozen directory
- `rhoai.next` continues tracking the next version (e.g., 3.5)

This provides a stable reference for consumers while preserving version-specific snapshots.

## Consequences

Positive:
- Agents and scripts can always reference `rhoai.next` for the latest architecture context
- Version-specific directories are frozen at release, providing historical snapshots
- No directory renames needed when versions change

Negative:
- Symlink management adds a manual step at GA time
- Consumers must understand that `rhoai.next` content changes between runs
