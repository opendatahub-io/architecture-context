# Component Analyzer Migration Completion Audit: 2026-07-18

## Conclusion

The [component analyzer migration](../plans/component-analyzer-migration.md) meets
its stated scope and acceptance gates against current code and the current configured
`rhoai.next` corpus. The migration replaces most per-repository agent discovery with
the project-owned analyzer while retaining bounded synthesis and explicit fallbacks.
`PLATFORM.md` synthesis and diagrams remain outside the scope.

This audit was reopened after readiness enforcement changed because the plan's old
platform measurements were no longer sufficient proof. A fresh forced production
static run and the final live readiness matrix now provide current evidence.

## Requirement Audit

| Plan requirement | Current evidence | Result |
|------------------|------------------|--------|
| Self-contained Go project | `src/arch-analyzer` has its own module, build, tests, command package, extractor packages, normalizer, renderer, and schema package. Production builds it through `lib/fetch.py`. | Pass |
| Stable JSON and Markdown contracts | Compatibility JSON is decoded into project-owned types; the renderer emits the canonical headings, empty tables, explicit unknown values, coverage, and source references. | Pass |
| Command contract | `extract`, `render`, and `extract-schema` are implemented and exposed by `bin/arch-analyzer --help`. `make -C src/arch-analyzer smoke` passes. | Pass |
| Upstream provenance | `src/arch-analyzer/UPSTREAM.md` records repository, commit, review date, and that the implementation is independent. | Pass |
| Extraction/normalization separation | Generic manifest and language extraction lives under extractor packages; ODH/RHOAI aliases and deployed-view adaptation live under `internal/normalize` and `internal/platformfacts`. | Pass |
| MVP fact rendering | `TestRenderFirstMVP` covers metadata, CRDs, workloads/probes, services, ingress, HTTP/gRPC, RBAC, secrets, dependencies, watches, webhooks, egress, integrations, history, escaping, and evidence. | Pass |
| Template compatibility | Current forced outputs pass the existing Markdown validator for 90/90 configured components, including empty-table structure. | Pass |
| Four-component corpus | Current comparison data includes `kueue`, `model-registry-operator`, `odh-dashboard`, and `fms-guardrails-orchestrator`, with per-category retained, missing, conflicting, and additional facts. | Pass |
| Evidence and conflict audit | Exact-revision task reports classify extractor and normalization gaps; the dashboard follow-up source-adjudicates every remaining identity miss and populated-cell conflict. | Pass |
| Version-matched extraction | The manifest, Go, Rust, dashboard, and fidelity task reports record the exact repository revisions used for their measurements. | Pass |
| Performance measurement | The current 90-component static phase is measured independently; the renderer benchmark is 45,880 ns/document. Agent and merge timings are recorded separately in the live pilot. | Pass |
| Production integration | Static analysis writes compatibility JSON, analyzer Markdown, and CRD schemas; component generation consumes readiness and analyzer Markdown by default. | Pass |
| Analyzer fact preservation | The current live matrix preserves 323/323 analyzer identities with zero analyzer-to-final conflicts. | Pass |
| Agent reduction | Sufficient is synthesis-only; partial has category/file budgets; insufficient retains legacy discovery. Hooks enforce these paths in code. | Pass |
| Scope boundary | No migration work moved `PLATFORM.md` synthesis or diagram generation into `arch-analyzer`. | Pass |

## Refreshed Platform Run

The audit ran the current binary with `--force`, 10 workers, rendering, and schema
extraction over all configured repositories:

```bash
uv run main.py static-analysis \
  --platform=rhoai.next \
  --architecture-dir=tmp/architecture-migration-audit-20260718/architecture \
  --max-concurrent=10 \
  --force
```

| Signal | Current result | Gate |
|--------|---------------:|-----:|
| Configured repositories available | 90/90 | 100% |
| Successful extractions | 90/90 | 100% |
| Analyzer Markdown rendered | 90/90 | 100% |
| Structurally valid analyzer documents | 90/90 | 100% |
| CRD schemas | 325 | measured |
| Static wall time, including binary build | 17.25s | <=60s |
| `sufficient` | 63/90 (70.0%) | >=70% |
| `partial` | 19/90 (21.1%) | measured |
| `insufficient` | 8/90 (8.9%) | <=10% |

The eight insufficient repositories remain `must-gather`, `odh-deployer`,
`odh-gitops`, `ogx-distribution`, `rhds-llama-stack-distribution`, `vllm`,
`vllm-rocm`, and `vllm-spyre`. This is the intended explicit fallback set.

The current static fixture comparison retains 1,268/6,161 structured identities
(20.58%) across the matched corpus, with a 16.06% component median. This number is a
diagnostic extraction/normalization measurement, not the plan's replacement quality
gate: legacy fixtures use synthesized names and include facts outside static source
ownership. The plan explicitly makes raw corpus recall a measurement subject to
source adjudication.

## Quality And Runtime Gates

| Gate | Evidence | Result |
|------|----------|--------|
| Replacement candidate >=95% exact adjudicated recall | `odh-dashboard` is 162/166 (97.59%) raw and 162/162 after four source-backed fixture exclusions. | Pass |
| Sufficient output preserves analyzer identities | Dashboard preserves 314/314; the readiness matrix preserves 323/323 across sufficient, partial, and legacy examples. | Pass |
| Zero unexplained analyzer conflicts | Current readiness matrix reports zero. | Pass |
| Same-model treatment within two recall points while materially reducing work | `caikit-nlp` copy/edit treatment is within 1.05 points and is 55.8% faster than control. | Pass |
| Broad sufficient/partial exploration prohibited | `_AgentExecutionGuard` denies Task and Bash, rejects full-checkout Glob, caps Grep and source reads, and prevents full replacement of preseeded output. Focused tests exercise each rule. | Pass |
| Insufficient fallback retained | Live `must-gather` selected legacy discovery, read 32 source files, produced valid Markdown, and skipped deterministic merge. | Pass |

The preseeded sufficient dashboard follow-up further reduced agent time from 339.79
seconds to 146.24 seconds and output tokens from 19,804 to 5,965 while preserving all
analyzer facts.

## Verification

Completion verification includes:

- the full Python suite, including comparator, corpus, merge, routing, phase, CLI,
  distribution, and static-analysis tests;
- both Go project test suites;
- `arch-analyzer` smoke and renderer benchmark;
- Ruff, Go formatting, golangci-lint, and `go vet`;
- overlay, platform, and architecture-document validators;
- shell syntax validation for the corpus harness; and
- `git diff --check`.

The current audit artifacts are under
`tmp/architecture-migration-audit-20260718`. The durable live-agent measurements and
source review are in the
[readiness-routed evidence merge pilot](readiness-routed-evidence-merge-pilot-2026-07-18.md),
[dashboard fidelity audit](arch-analyzer-dashboard-fidelity-audit.md), and the
[initial analyzer-first viability task](../tasks/done/arch-analyzer-platform-ab.md).

## Remaining Work

Further framework extractors, semantic aliases, and conversion of partial or
insufficient repositories are optimizations under the plan's incremental extension
policy, not unfinished migration deliverables. A complete 90-agent rerun is likewise
not a stated completion gate: the plan requires full-platform static validation and
representative same-model agent quality/runtime evidence, both of which are proven.
