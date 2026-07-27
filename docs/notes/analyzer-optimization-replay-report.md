# arch-analyzer Optimization Replay Report

## Scope

This replay validates the new deterministic projections against four sanitized
repositories already committed as analyzer fixtures. It does not rerun the
97-component platform generation because the component checkouts are not
present in this workspace.

The completed 97-component run remains the demand baseline: 97 components,
median zero source-file reads, 193 discovery calls, and repeated reconstruction
of endpoint, service, authentication, integration, and dependency
relationships.

## Fixture results

| Fixture | Cross-references | Coverage findings | Confirmed-empty findings | Evidence records | Evidence categories |
|---|---:|---:|---:|---:|---|
| Go manifest/controller | 1 | 6 | 0 | 5 | authentication, endpoints, integrations, dependencies, services |
| Go operator | 0 | 6 | 1 | 0 | none; no bounded records were available |
| Rust service | 0 | 6 | 2 | 10 | authentication, endpoints, services |
| Web workspace | 0 | 6 | 1 | 7 | endpoints |
| Python service | 0 | 6 | 1 | 0 | none; no bounded records were available |

All four fixtures extracted and rendered successfully. Cross-reference output
contains contributing source paths, and compact evidence records contain both
a bounded claim and source provenance. Empty categories with incomplete
coverage render `not-verified`; complete empty categories render
`confirmed-empty`.

## Validation

- `GOCACHE=/tmp/arch-analyzer-go-cache go test ./...` — passed.
- `.venv/bin/pytest -q tests/test_insights.py` — passed, 84 tests.
- Extract/render replay for all five fixtures — passed.
- JSON parsing and renderer section checks — passed.

## Limitations and follow-up

- A full before/after runtime comparison requires the original component
  checkouts and a fresh 97-component run. No runtime reduction claim is made
  from this fixture replay alone.
- The Python architecture-phase suite currently contains stale expectations
  for the retired synthesis route and checkout-local output files; those
  failures predate this analyzer change and are not used as evidence for the
  analyzer implementation.
- Webhook-heavy and multi-runtime production replays should be rerun when
  checkouts are available.
