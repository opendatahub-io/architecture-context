# Bug: Security Evidence Emits Duplicate TLS Import Rows

## Summary

The generated security evidence for `agents-operator` incorrectly emits many
identical rows for the `crypto/tls` import and places `literal` in the `Status`
column. The resulting table does not represent distinct security controls or
configurations.

## Reproduction

Inspect `architecture/rhoai.next/agents-operator.md` under `### Security
Evidence`. The table contains repeated rows equivalent to:

```text
| tls-config | crypto/tls | TLS configuration import | literal |
```

The same target/detail pair is repeated approximately 20 times.

## Actual

Repeated source observations are promoted to separate security evidence
records. The renderer displays the evidence classification (`literal`) as the
status value, even though it is not a status such as observed, inferred, or
unresolved.

## Expected

Security evidence should be deduplicated by its stable identity (for example,
kind, target, and detail), retain source provenance separately, and render a
meaningful status. Generic imports such as `crypto/tls` should not be emitted
as security evidence unless they are connected to an observed TLS
configuration or enforcement point.

## Impact

Generated architecture documents overstate the amount of security evidence and
make the section difficult to interpret. Consumers may incorrectly conclude
that multiple TLS controls were found when the analyzer observed only repeated
imports.

## Acceptance Criteria

- Repeated identical security evidence observations produce one rendered row.
- Evidence classification and status are represented in distinct fields.
- Generic TLS imports without configuration or enforcement evidence are
  omitted or clearly marked as unresolved/weak evidence.
- Source provenance remains available for retained evidence.
- Regression coverage uses the `agents-operator` shape and verifies the
  rendered table does not contain duplicate rows or `literal` as a status.

## Status

Fixed on 2026-07-28 by
`docs/tasks/done/fix-duplicate-security-evidence-rendering.md`.

The current generated `agents-operator` output already renders one
`tls-config` / `crypto/tls` row with `dependency-signal`. This fix makes that
behavior durable with extractor and renderer regression coverage. The Markdown
Security Evidence table now labels the final column `Signal Type`, avoiding
the previous ambiguity where `literal`/`dependency-signal` appeared under a
runtime-status heading.

Validation passed:

```bash
GOCACHE=/tmp/arch-analyzer-go-cache go test ./internal/gosource ./internal/renderer
GOCACHE=/tmp/arch-analyzer-go-cache go test ./...
```
