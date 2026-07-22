# ADR-0018: Multi-Tenancy Analysis in Architecture Summaries

## Status

Accepted

## Date

2026-07-22

## Context

The platform comprises dozens of components that each handle tenancy differently — some scope by namespace, some by custom resource, some by user identity, and some have no tenant concept at all. There is no single document that captures what "tenant" means in each component, how isolation is enforced (and by whom — Kubernetes vs application code), or where gaps exist.

Without this information, architects cannot answer basic questions: Can one tenant read another's data? Are network boundaries enforced per tenant? Which components share a data plane? What would it take to standardize tenancy across the platform?

## Decision

Add multi-tenancy analysis as a supplementary analysis step in the `repo-to-architecture-summary` skill, with a corresponding `## Multi-Tenancy` section in the `GENERATED_ARCHITECTURE.md` template.

**Reference doc** (`references/multi-tenancy-analysis.md`): Provides structured grep patterns and guiding questions across six isolation dimensions — authentication/authorization, data storage, network traffic, compute/resources, configuration/secrets, and API scoping. Also covers Kubernetes primitives used, application vs Kubernetes enforcement, shared services, and risk identification.

**Template section** (`## Multi-Tenancy`): Three tables — Tenant Model (what "tenant" means), Isolation Mechanisms (one row per dimension with mechanism, enforcer, and gaps), and Shared Services (shared infrastructure with tenant boundary preservation).

**Skill step** (Step 4b): Runs alongside the primary language-specific analysis. Depth scales by component type — platform operators get full analysis, libraries get a brief note.

The per-component findings are designed to be aggregated into a platform-level comparison table and synthesis by the `aggregate-platform-architecture` skill, producing three layers of output:

1. Per-component tenancy summary (in each `GENERATED_ARCHITECTURE.md`)
2. Cross-component comparison table (in platform aggregation)
3. Synthesis of common patterns, differences, and recommended follow-up questions

## Consequences

Positive:
- Every component's tenancy model is documented with enforcement points and gaps
- Platform-level aggregation can identify inconsistencies (component A uses namespace tenancy, component B uses cluster tenancy)
- Gaps in tenant isolation are surfaced as architectural risks, not discovered during incidents
- The six-dimension framework provides consistent vocabulary across components

Negative:
- Adds analysis time per component (grep patterns + code reading for tenancy signals)
- Multi-tenancy is nuanced — automated analysis may miss implicit tenancy patterns or overstate gaps where the surrounding platform provides isolation
- Components with no tenancy concept still need a documented "N/A" entry, adding minor overhead
