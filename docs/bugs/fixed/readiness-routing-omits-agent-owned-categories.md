# Bug: Readiness Routing Omits Agent-Owned Structured Categories

## Summary

The partial readiness policy can spend its entire six-category budget on manifest
coverage gaps before considering empty high-value categories such as architecture
components, authentication, integration points, and internal dependencies.

## Evidence

The full production-routing run `rhoai-next-20260718T173838Z` completed successfully
but reduced exact structured fixture recall from 35.66% to 24.82%.

For `batch-gateway`, the analyzer document had empty tables for architecture
components, authentication, integration points, internal dependencies, services,
ingress, egress, RBAC, and secrets. Because manifest coverage was partial,
`lib/architecture_routing.py` selected only:

```text
services, ingress, egress, rbac_cluster_roles, rbac_role_bindings, secrets
```

The bounded agent filled valid facts in those categories but was not assigned the
other empty categories. The final document has detailed synthesis prose but empty
architecture component, authentication, integration, and internal dependency
tables. Its fixture match fell from 27/51 to 1/51.

## Cause

`_coverage_gap_categories()` emits categories in coverage-surface order, while
`load_architecture_agent_policy()` concatenates that sequence ahead of empty-table
priority and truncates it to `PARTIAL_CATEGORY_LIMIT`.

The analyzer reports Go coverage under the `source` key, but
`_COVERAGE_CATEGORY_HINTS` contains a `go` key that never appears in analyzer output.
It also does not map the always-partial `platform_semantics` surface. As a result,
manifest gaps can dominate the policy even when source and semantic synthesis tables
are empty.

## Expected

Partial routing should prioritize high-value missing architecture information across
all incomplete coverage surfaces. The finite category and source-file budgets must
remain explicit, and every applied structured change must remain evidence-gated.

## Impact

High. Analyzer preservation and runtime gates pass, but bounded agents can omit
architecturally important facts that the previous full agent found.

## Related

- [Readiness-routed corpus comparison](../../notes/rhoai-next-readiness-routed-corpus-comparison-2026-07-18.md)
- [Improve readiness-routed synthesis coverage](../../tasks/done/improve-readiness-routed-synthesis-coverage.md)
- [Bounded routing matrix](../../notes/readiness-routing-coverage-matrix-2026-07-18.md)

## Resolution

Fixed on 2026-07-18.

Partial gap candidates from coverage surfaces and empty tables now pass through one
architecture-value priority before the six-category limit is applied. Coverage hints
use analyzer-emitted `source`, `platform_semantics`, language, manifest, template,
Kustomize, Go module, and Go CRD keys; the dead `go` key was removed.

Sparse sufficient baselines may receive up to four high-value categories, but only
through their existing four analyzer-referenced source files. Broad discovery,
source budgets, and evidence-gated merges remain enforced.

The same-revision Opus matrix recovered 16 source-backed high-value facts, kept the
dashboard control unchanged, preserved 390/390 analyzer identities, produced zero
conflicts, and passed the synthesis/structure quality gate for all three documents.
