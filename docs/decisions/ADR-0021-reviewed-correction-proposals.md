# ADR-0021: Separate Reviewed Correction Proposals from Authoritative Overlays

## Status

Accepted

## Date

2026-07-24

## Context

Architecture corrections may originate in staff review, imported feedback, or
existing human-authored overlays. Applying those corrections automatically
would allow unverified text to become authoritative architecture context and
would make provenance, supersession, and review state difficult to audit.

The project already uses overlays to supplement or supersede generated facts,
so the correction workflow needs an explicit pre-application state rather than
creating a second implicit authority path.

## Decision

Represent proposed corrections as versioned, validated artifacts that remain
separate from active authoritative overlays until reviewed and explicitly
applied.

Each proposal carries component scope, correction category, claim and
replacement content, provenance, author, affected releases, creation and
verification dates, review status, and supersession metadata. Proposal
generation, validation, frequency reporting, review, and authoritative overlay
application are separate operations.

Proposals are never automatically applied. Unsupported correction categories,
missing provenance, invalid dates, duplicate identities, and invalid lifecycle
states fail validation rather than being normalized into an accepted fact.

## Consequences

Positive:

- Human feedback can be harvested and analyzed without changing authoritative
  architecture output.
- Every applied correction has an auditable provenance and lifecycle.
- Superseded and pending proposals remain available for review and reporting.
- Existing overlay behavior remains compatible while gaining a safer intake
  path.

Negative:

- Corrections require an explicit review and application step.
- The project maintains proposal schemas and lifecycle validation in addition
  to overlay validation.
- Pending proposals can leave known issues visible until a reviewer acts.

## Related Records

- [Architecture context static migration note](../notes/architecture-context-static-migration.md)
- [Architecture context static migration plan](../plans/architecture-context-static-migration.md)
- [Architecture context overlays](ADR-0005-architecture-context-overlays.md)
