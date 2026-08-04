# ADR-0022: Declarative Architecture-Document Section Assembly

## Status

Accepted

## Date

2026-07-31

## Context

The analyzer baseline, agent candidate, and merged architecture document have
different ownership boundaries. Ad hoc text replacement in the Python
pipeline made it possible for a candidate to overwrite analyzer-owned content,
inject unknown sections, or publish an incomplete document. Promotion also
needed to be atomic so a failed assembly could not replace a valid document.

## Decision

Use a standalone `arch-doc` Go module with a declarative section manifest and
three operations:

- `validate` checks document structure, required sections, duplicate or unknown
  headings, and ownership rules;
- `update` replaces only an explicitly owned section and validates the result
  before an atomic write; and
- `assemble` combines the validated analyzer base and permitted candidate
  sections, asserting that analyzer-owned sections remain unchanged.

The architecture phase validates candidate, merged, and final documents and
promotes a result only after successful assembly validation. Generated
sidecars remain separate from the promoted architecture document.

## Consequences

Positive:

- Section ownership is explicit and mechanically enforceable.
- Analyzer-owned facts receive byte-for-byte preservation checks.
- Unknown, duplicate, or incomplete sections fail before promotion.
- Atomic writes reduce the risk of publishing partially assembled documents.
- The assembly contract is independently testable outside the Python
  orchestration flow.

Negative:

- New document sections require manifest, validator, and ownership updates.
- The project maintains a Go assembly tool alongside the Python pipeline.
- Candidate synthesis must conform to the section contract instead of editing
  the whole document freely.

## Related Records

- [Architecture context static migration note](../notes/architecture-context-static-migration.md)
- [Architecture context static migration plan](../plans/architecture-context-static-migration.md)
