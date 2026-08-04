# ADR-0020: Versioned Context Contract with Explicit Uncertainty States

## Status

Accepted

## Date

2026-07-24

## Context

Architecture consumers need to distinguish confirmed facts from values that
were not extracted, could not be validated, are stale, or do not apply. A
plain optional field or an empty string collapses those meanings and invites
downstream agents and tools to fill the gap with inference. The contract also
needs to carry provenance, freshness, scope, deployment topology, dependency
status, maturity, confidence, and behavioral evidence without breaking older
analyzer fixtures.

## Decision

Represent this metadata in an optional, versioned `context_contract` envelope
within the machine-readable component architecture document.

The contract:

- preserves backward compatibility when absent;
- carries provenance, applicability and freshness, confidence, maturity,
  scope/deployment topology, dependency or upstream status, and behavioral
  evidence metadata;
- uses explicit states such as `unknown`, `not-extracted`, and
  `needs-validation` rather than fabricating values; and
- is a schema and evidence carrier only. The analyzer must not populate
  contract values through unsupported inference.

Renderers and consumers must preserve the distinction between an omitted
field, an explicit unknown, and an extraction that was not attempted.

## Consequences

Positive:

- Consumers can make safe decisions about confidence, freshness, and evidence
  without guessing what an empty value means.
- New metadata can be added without invalidating existing fixtures or changing
  output when the contract is absent.
- Provenance and limitations remain attached to the fact context.

Negative:

- Schemas, validators, renderers, and consumers must evolve together.
- Documents become more explicit and may expose more unresolved states.
- Producers must choose the correct uncertainty state instead of relying on
  omission as a universal fallback.

## Related Records

- [Architecture context static migration note](../notes/architecture-context-static-migration.md)
- [Architecture context static migration plan](../plans/architecture-context-static-migration.md)
