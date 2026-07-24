# Component Analyzer Migration

**Status**: Complete (audited against current production state 2026-07-18)

The first successful full-corpus run confirmed viability but exposed that prompt
instructions do not reliably preserve analyzer-owned facts. Production enforcement
and the initial readiness-routed live matrix are complete. The
[migration completion audit](../tasks/done/audit-component-analyzer-migration-completion.md)
refreshed the platform-scale evidence after those changes and mapped every gate in
this document to current authoritative evidence.

## Scope

Replace as much of `.claude/skills/repo-to-architecture-summary` as practical
with deterministic analysis while preserving component Markdown as the agent-facing
contract. The initial work applies only to per-component documents. `PLATFORM.md`
synthesis and diagrams remain unchanged.

Use `architecture/rhoai.next/*.md` as regression fixtures, not unquestionable
ground truth. A source-backed analyzer finding may add to or correct a fixture.

## Decision

Create a self-contained Go project at `src/arch-analyzer`, following the ownership
and build pattern established by `src/arch-query`.

This project will own:

- The component architecture fact model and JSON contract.
- ODH/RHOAI normalization, including downstream names and kustomize overlays.
- Component Markdown rendering.
- Source evidence tracking.
- Static extractors as they are migrated or independently implemented.
- Fixture, integration, and performance tests.

The existing `ugiordan/architecture-analyzer` clone is a reference implementation,
not a runtime dependency. The production pipeline builds and runs the project-owned
analyzer; it no longer dynamically clones the reference implementation.

JSON remains the internal fact interchange. Markdown remains the stable format for
agents and humans.

## Upstream Code

The referenced upstream repository was developed by a known collaborator who permits
reuse in this project, despite not publishing a formal license. Upstream code may be
copied selectively when it accelerates the implementation.

Add `src/arch-analyzer/UPSTREAM.md` to record:

- The upstream repository URL and source commit.
- The date code was imported.
- Files or packages copied or substantially derived from upstream.
- Local modifications and later upstream refreshes.
- Components implemented independently in this repository.

Prefer selective ports over copying the whole repository. Retain useful history and
attribution in commit messages. A formal license or written permission should still
be recorded before distributing the copied implementation outside the current project
or organization.

## Project Layout

```text
src/arch-analyzer/
  go.mod
  go.sum
  Makefile
  README.md
  UPSTREAM.md
  main.go
  cmd/
    root.go
  internal/
    extractor/
    gosource/
    model/
    normalize/
    platformfacts/
    pythonsource/
    renderer/
    rustsource/
    schema/
    websource/
```

The initial binary contract should be:

```text
arch-analyzer extract <repo> --output component-architecture.json
arch-analyzer render --input component-architecture.json --output GENERATED_ARCHITECTURE.md
arch-analyzer extract-schema <repo> --output-dir contracts/schemas
```

`component-architecture.json` compatibility minimizes changes to
`lib/phases/static_analysis.py` and allows the old and new extractors to be compared
against the same renderer.

## Baseline Policy

Comparison is intentionally asymmetric:

- **Retained baseline facts** measure coverage of the existing document.
- **Missing baseline facts** identify extractor or adapter work.
- **Conflicting populated cells** require review; they may be regressions or valid
  analyzer corrections.
- **Additional candidate facts** are reported separately and do not reduce recall.
- **Required headings and synthesis sections** measure compatibility with the
  Markdown contract consumed by agents.

The comparison uses normalized row identities rather than whole-file text. This
avoids treating wording, prose, ordering, and formatting differences as fact loss.

Run it with:

```bash
uv run python scripts/compare_component_architecture.py \
  architecture/rhoai.next/kueue.md candidate.md
```

Use `--format json` for machine-readable results, `--min-row-recall` for a coverage
gate, and `--fail-on-conflict` after reviewed equivalence rules are stable.

## Initial Kueue Result

The first experiment used:

- Baseline: `architecture/rhoai.next/kueue.md`
- Extracted data: `architecture/rhoai.next/kueue.json` from analyzer `0.2.0`
- Renderer: cloned architecture-analyzer commit `5cdc2e7ec`

The current architecture-analyzer renderer is not a drop-in replacement:

| Signal | Result |
|--------|--------|
| Stable baseline rows retained | 0 / 99 |
| Required H2 sections missing | 9 / 11 |
| Synthesis sections missing | 3 / 3 |
| Classified additional rows | 16 |
| Unmapped analyzer tables | 13 tables / 284 rows |

The zero recall primarily demonstrates a schema and renderer contract mismatch,
not an empty extraction. For example, service and secret names differ because the
baseline reflects RHOAI overlay names while the analyzer data contains upstream
base names. The stored JSON also lacks CRDs even though the baseline documents 11.

The analyzer found 13 `kueue-viz` WebSocket HTTP routes absent from the baseline.
It also contains substantial detail not represented by the initial comparator:
36 webhooks, 21 controller watches, 89 API types, and 33 Prometheus metrics. These
are candidate fixture improvements once their source references are verified.

This is a mixed-version experiment: old stored JSON was rendered by newer cloned
code. It establishes the adapter gap but should not be used as a current extractor
quality benchmark.

## Processing Design

Keep extraction, evidence, adaptation, and synthesis as separate stages:

1. **Extractor** produces typed facts with source file and line evidence.
2. **Normalizer** resolves manifests, kustomize overlays, controller-created
   resources, and component aliases into the deployed RHOAI/ODH view.
3. **Markdown adapter** always emits the existing template headings and tables,
   including empty table headers when no facts are found.
4. **Small agent synthesis pass** fills Purpose, Data Flows, and Architectural
   Analysis from the compact Markdown plus evidence. This is the initial remaining
   agent work, rather than having agents explore entire repositories.
5. **Fixture comparison** measures retained, conflicting, and additional facts for
   every `rhoai.next` component before expanding to other versions.

Extraction and normalization must remain separate. Generic repository parsing belongs
in extractor packages; product-specific overlay selection and naming belong in the
normalizer.

## MVP

The MVP proves the model, normalizer, renderer, and evaluation loop before replacing
the existing extractor.

It will:

1. Scaffold and build `src/arch-analyzer` as an independent Go module.
2. Read existing `component-architecture.json` files.
3. Convert the existing JSON into a project-owned normalized model.
4. Render the established component Markdown structure with all required headings
   and empty tables.
5. Populate high-confidence facts: metadata, CRDs, deployments/components, HTTP
   endpoints, services, RBAC, secrets, dependencies, controller watches, webhooks,
   and source references.
6. Compare generated Markdown to the matching `rhoai.next` fixture.

The MVP does not replace the production extraction phase. It does not modify
`PLATFORM.md` synthesis or diagram generation. Purpose, Data Flows, and Architectural
Analysis remain empty or explicitly pending until the structured rendering path is
measured.

## Initial Test Corpus

Use `kueue` for development, followed by a small cross-language matrix:

| Component | Coverage target |
|-----------|-----------------|
| `kueue` | Large Go operator, CRDs, controllers, webhooks, RBAC |
| `model-registry-operator` | Operator services and admission webhooks |
| `odh-dashboard` | TypeScript frontend and Go BFF behavior |
| `fms-guardrails-orchestrator` | Rust service, Axum HTTP, and downstream HTTP/gRPC dependencies |

For each component, preserve the analyzer version and repository commit used to
produce the JSON. Do not compare stored analyzer `0.2.0` JSON with a newer extractor
and call the result an extractor benchmark.

## MVP Tests

1. **Model and renderer unit tests**: synthetic JSON containing one fact of each
   supported type must render every fact and source reference in the correct table.
2. **Template validation**: generated Markdown must pass the existing architecture
   validator, including required headings and empty table structure.
3. **Fixture comparison**: report retained, missing, conflicting, additional, and
   unmapped facts for every corpus component.
4. **Evidence audit**: manually verify a sample of missing, conflicting, and additional
   rows against source to classify renderer, normalizer, extractor, or baseline errors.
5. **Version-matched extraction**: run both extractors on the same repository commit
   before comparing extraction quality.
6. **Performance measurement**: record extraction, normalization, rendering, and any
   later synthesis time independently.

MVP acceptance criteria:

- Rendering existing JSON takes less than one second per component.
- Every supported JSON fact and its evidence is preserved.
- Generated Markdown passes structural validation.
- Missing values remain explicit; the renderer does not fabricate facts.
- All four corpus comparisons produce actionable category-level reports.
- Every conflict can be reviewed as a baseline correction or analyzer defect.

Baseline row recall is initially a measurement, not a release gate. Set
category-specific gates after the corpus has been reviewed.

## MVP Results

The render-first MVP was implemented on 2026-07-17.

Completed:

- Created the standalone Go module at `src/arch-analyzer`.
- Added the tolerant compatibility JSON model, normalization layer, canonical
  Markdown renderer, `render` command, tests, build targets, and CI test job.
- Added `UPSTREAM.md`; no upstream implementation code has been copied yet.
- Updated the Markdown validator to recognize the existing Admission Webhooks
  section.
- Improved the fixture comparator for repeated RBAC rules, explicit unknown values,
  line-range evidence, list ordering, and pseudo-version precision.

All four generated documents pass structural validation. Rendering all four stored
JSON files takes approximately 0.03 seconds total; the focused renderer benchmark is
approximately 48 microseconds per document.

| Component | Retained rows | Recall | Conflicts | Unmapped rows |
|-----------|--------------:|-------:|----------:|--------------:|
| `kueue` | 10 / 121 | 8.26% | 0 | 36 |
| `model-registry-operator` | 30 / 121 | 24.79% | 3 | 3 |
| `odh-dashboard` | 35 / 292 | 11.99% | 7 | 3 |
| `fms-guardrails-orchestrator` | 2 / 116 | 1.72% | 0 | 0 |

These figures measure the stored analyzer `0.2.0` JSON, not the new extractor. The
results establish that the renderer and comparison loop work and expose the expected
extraction gaps. The Python service result is especially sparse, while the operator
fixtures retain substantially more structured data.

Reviewed conflicts are concentrated in:

- Overlay namespace and downstream resource-name normalization.
- Named port resolution and conflicting health-port values.
- HTTP versus HTTPS and Gateway API type interpretation.
- Architecture component type and purpose derivation.
- Semantically equivalent dependency descriptions.

The next implementation milestone is repository extraction, beginning with Kubernetes
YAML and kustomize resources before moving to Go and other source languages.

## Manifest Extraction Results

The manifest extraction milestone was implemented on 2026-07-17. The new `extract`
command reads repositories directly and emits the same compatibility JSON consumed
by the render-first MVP. The implementation is independent; no upstream source files
were copied.

The resolver composes local kustomize resources, bases, components, strategic merge
patches, targeted file-based JSON6902 patches, and scoped name/namespace transforms.
It extracts source-backed CRDs, workloads and probes, services, RBAC, secret
references, ingress resources, and admission webhooks. Unsupported kustomize features
are recorded under `data_coverage` instead of being treated as complete.

Exact-commit measurements against the stored `rhoai.next` baselines are:

| Component | Commit | Overlay | Extract | Render | Retained rows | Conflicts |
|-----------|--------|---------|--------:|-------:|--------------:|----------:|
| `kueue` | `02d9049` | `config/rhoai` | 0.06s | <0.01s | 25/121 (20.66%) | 7 |
| `model-registry-operator` | `4392f88` | `config/overlays/odh` | 0.02s | <0.01s | 5/121 (4.13%) | 2 |

Both outputs pass structural validation. Kueue matches all 11 CRDs. Model Registry
has no RHOAI overlay at the measured commit, and its baseline is dominated by
controller-created resources and Go behavior, so its ODH manifest result is not a
distribution-equivalent comparison.

The next milestone should add Go source extraction for dependencies, controller
watches, controller-created resources, and HTTP behavior before production pipeline
replacement is considered.

## Go Source Extraction Results

The Go source extraction milestone was implemented on 2026-07-17 using the standard
Go AST and `golang.org/x/mod/modfile`. It adds direct module dependencies,
controller-runtime watches, literal HTTP routes, manager health endpoints, and typed
Kubernetes client operations to the manifest-derived compatibility JSON.

| Component | Extract | Render | Source facts | Retained rows |
|-----------|--------:|-------:|--------------|--------------:|
| `kueue` | ~0.2s | <0.01s | 37 dependencies, 29 watches, 15 routes, 19 operation targets | 27/121 (22.31%) |
| `model-registry-operator` | ~0.03s | <0.01s | 17 dependencies, 19 watches, 2 routes, 15 operation targets | 18/121 (14.88%) |

This is an increase from manifest-only recall of 25/121 for Kueue and 5/121 for
Model Registry. Both documents continue to pass structural validation. The source
facts also expose fixture-normalization work: precise GVKs and module paths are often
classified as additional rows because the baseline uses synthesized component names.

The analyzer still lacks controller-created object reconstruction from templates,
multi-module scanning, dynamic expression resolution, type checking, and semantic
normalization from raw source identities to platform-level component names.

## Controller Template Results

Controller-created template extraction was implemented on 2026-07-17. The Go source
pass now discovers embedded Kubernetes YAML and Go-template YAML without an additional
repository parse. The template adapter preserves source lines, emits explicit dynamic
placeholders, retains possible conditional resources, and labels workloads and
routing as controller-created.

| Component | Extract | Retained rows | Conflicts | Key result |
|-----------|--------:|--------------:|----------:|------------|
| `kueue` | ~0.19s | 27/121 (22.31%) | 6 | No embedded resource templates; no recall regression |
| `model-registry-operator` | ~0.04s | 34/121 (28.10%) | 9 | 4/4 Services and 4/4 ingress identities retained |

Model Registry rises from 18 retained rows after Go AST extraction to 34. The
extractor recovers four managed Deployments, four managed Services, five possible
Route/HTTPRoute resources, RBAC, and secrets. Conditional 8080/8443 service variants
remain separate possible facts rather than being collapsed into a fabricated runtime
choice.

The largest remaining gaps are Go-constructed resource kinds beyond Secrets,
environment-derived runtime values, higher-level integration naming, and non-Go
language extraction.

## Runtime Default And Constructed Resource Results

Kubebuilder default resolution and initial Go-constructed resource extraction were
implemented on 2026-07-17. The Go pass builds a cross-package struct graph, associates
attached and standalone `+kubebuilder:default` markers with fields, and resolves only
the scalar defaults actually referenced by embedded resource templates. It also
recovers named Secrets from Go composite literals when the same local variable is
passed to a create or create-or-update call.

| Component | Extract | Retained rows | Conflicts | Key result |
|-----------|--------:|--------------:|----------:|------------|
| `kueue` | ~0.23s | 27/121 (22.31%) | 6 | No used template defaults or constructed Secrets; no score inflation |
| `model-registry-operator` | ~0.04s | 36/121 (29.75%) | 5 | Resolved 8080/8443/443 defaults and two source-constructed Secrets |

Model Registry service conflicts fall from four to one after resolving REST and
kube-rbac-proxy ports. The auto-provisioned per-registry PostgreSQL credential Secret
is now typed `Opaque` and attributed to controller Go source, removing its previous
fixture conflict. Dynamic Secret identities are merged only when both names contain a
placeholder and have the same unique suffix.

The remaining service conflict is the representation of conditional HTTP and HTTPS
variants: the analyzer preserves both possible ports while the baseline combines
them into one cell. Go object reconstruction is intentionally limited to Secrets in
this milestone; deployments, services, RBAC, and routing constructed wholly in Go
remain future work.

## Rust Source Extraction Results

Rust source extraction was implemented on 2026-07-17 and measured against the exact
recorded `fms-guardrails-orchestrator` commit. The corpus corrected the initial plan:
this component is a Rust service, not Python, at commit `270e5f2`.

The extractor uses a TOML parser for Cargo metadata, the existing YAML parser for
runtime configuration, and bounded source scanning for literal Axum route calls and
Clap field attributes. It emits source components, direct Cargo dependencies, HTTP
endpoints, binary listeners, downstream connections, secrets, and authentication
controls with line evidence.

| Signal | Result |
|--------|--------|
| Extraction | ~0.09s |
| Rendering | <0.01s |
| Retained baseline rows | 42/116 (36.21%) |
| Populated-cell conflicts | 5 |
| HTTP endpoint identities | 12/12 |
| Service identities | 2/2 |
| Secret identities | 4/4 |
| Authentication identities | 3/3 |
| External dependency identities | 11/12 |
| Egress identities | 4/7 |

The prior in-repo analyzer retained zero rows for this repository; the stored upstream
analyzer JSON retained 2/116. The generated Markdown passes structural validation.
Remaining gaps are optional downstreams not present in the example runtime config,
semantic naming of integration points, Git history, and synthesis prose. Macros and
call graphs remain explicit partial coverage rather than inferred behavior.

## Dashboard Monorepo Results

The dashboard milestone added nested Go-module discovery, structured npm workspace
analysis, Fastify and module-federation surface extraction, legacy kustomize
JSON6902 support, canonical operator configuration, and ODH/RHOAI semantic
adaptation. The exact-revision test uses dashboard commit `f1cdd9f22`.

| Signal | Result |
|--------|--------|
| Extraction | ~0.42s |
| Rendering | <0.01s |
| Retained baseline rows | 170/292 (58.22%) |
| Structured identity recall | 141/165 (85.45%) |
| Architecture component identities | 16/16 |
| HTTP endpoint identities | 13/13 |
| Service identities | 9/9 |
| Authentication identities | 7/7 |
| Integration identities | 26/35 |

Structured identity recall excludes recent-history prose and the baseline's broad
agent files-read inventory. The manifest-only analyzer retained 8/292 rows, while
the stored upstream analyzer JSON retained 35/292. The generated document passes
structural validation. Reviewed conflicts include source-backed corrections to the
fixture, notably its Prometheus/Thanos port and selected commit dates.

## Replacement Evaluation

The four-repository corpus now meets the technical gates for replacing the upstream
runtime dependency and most whole-repository agent exploration:

| Component | Extract | Render | Retained rows | Conflicts |
|-----------|--------:|-------:|--------------:|----------:|
| `kueue` | ~0.22s | <0.01s | 28/121 (23.14%) | 7 |
| `model-registry-operator` | ~0.05s | <0.01s | 54/121 (44.63%) | 6 |
| `odh-dashboard` | ~0.42s | <0.01s | 170/292 (58.22%) | 47 |
| `fms-guardrails-orchestrator` | ~0.06s | <0.01s | 42/116 (36.21%) | 5 |

All four outputs preserve source evidence, state partial analyzer coverage, render
in well under one second, and pass the component Markdown validator. Raw extraction
is substantially richer than exact baseline-row recall for the Go operators: Kueue,
for example, yields 11 CRDs, 50 HTTP endpoints including 35 webhooks, 88 RBAC roles,
and 44 integration facts. Its fixture instead uses curated names and synthesized
descriptions, so exact string recall is not an appropriate extraction gate.

The replacement boundary is therefore:

- The analyzer owns repository discovery, structured extraction, normalization,
  evidence, CRD schemas, and the canonical agent Markdown baseline.
- The component-summary agent preserves those facts and performs compact synthesis,
  targeted gap resolution, and conditional analysis such as FIPS, AIPCC, and build
  hermeticity.
- Broad recursive exploration and repository-exploration sub-agents are fallback
  behavior only when the analyzer baseline is unavailable.
- `PLATFORM.md` synthesis and diagrams remain outside this migration.

This establishes technical corpus viability. The platform-scale and agent evidence
below establishes the operational replacement boundary.

## Full Platform Results

The production static-analysis phase was run against `rhoai.next` with 10 workers and
`--force`. It built the project-owned binary, analyzed all configured component
checkouts, rendered the agent baselines, and extracted schemas in 27.80 seconds:

| Signal | Result |
|--------|--------|
| Configured components | 90 |
| Successful extractions | 90/90 |
| Analyzer Markdown documents | 90/90 |
| Structurally valid documents | 90/90 |
| CRD schemas | 325 |
| Failed components | 0 |

The first corpus pass failed on templated Helm YAML, modern targeted strategic
patches, missing generated kustomize paths, and Go template helpers. Those cases now
produce explicit partial-coverage notices instead of aborting extraction. Direct
extraction and rendering also pass for all 89 components represented by the stored
`rhoai.next` fixture set.

After adding structured Python package metadata, requirements, bounded literal
FastAPI/Flask/Starlette routes, environment-backed secrets, and applicable protobuf
services, the 89-fixture comparison is:

| Signal | Result |
|--------|--------|
| Exact stable-row recall | 1,856/11,097 (16.73%) |
| Exact structured identity recall | 1,192/6,109 (19.51%) |
| Median component recall | 11.69% |
| Median analyzer Markdown size | 10,896 bytes |
| 90th percentile Markdown size | 30,345 bytes |

Exact recall remains deliberately conservative: synthesized names and prose in the
legacy fixtures do not match source identities even when the analyzer has richer
facts. The dashboard exact-revision result remains the more useful high-coverage
check: 141/165 structured identities (85.45%).

The `agent_baseline` coverage gate was tightened after the A/B exposed that many
dependencies alone do not make a complete architecture baseline. The production
90-component distribution is now:

| Readiness | Components | Agent behavior |
|-----------|-----------:|----------------|
| `sufficient` | 65 (72.2%) | No broad repository discovery |
| `partial` | 17 (18.9%) | One bounded language-specific gap pass |
| `insufficient` | 8 (8.9%) | Preserve facts, then use legacy discovery |

The insufficient repositories are `must-gather`, `odh-deployer`, `odh-gitops`,
`ogx-distribution`, `rhds-llama-stack-distribution`, `vllm`, `vllm-rocm`, and
`vllm-spyre`. This is an explicit quality fallback, not silent empty output.

## Agent A/B Results

The primary same-model A/B used the same `caikit-nlp` source snapshot and Claude
Sonnet 4.5. The control had no analyzer Markdown; the treatment used it and followed
the bounded Python gap path.

| Signal | Legacy control | Analyzer-first | Change |
|--------|---------------:|---------------:|-------:|
| Wall time | 541s | 285s | -47.3% |
| Agent turns | 46 | 34 | -26.1% |
| Read/Bash/Write tools | 45 | 33 | -26.7% |
| Output tokens | 25,501 | 13,583 | -46.7% |
| Cost | $0.962 | $0.556 | -42.2% |
| Exact fixture recall | 37.89% | 40.00% | +2.11 points |
| External dependencies | 18/18 | 18/18 | unchanged |
| HTTP endpoint identities | 6/11 | 11/11 | improved |

A follow-up copy-and-edit treatment validated the lower-token document strategy. It
completed in 239 seconds, 55.8% faster than control, while remaining within 1.05
recall points of the control (36.84% versus 37.89%). It used fewer output tokens but
more edit turns than the first treatment, so copy-and-edit is required for fact
preservation and latency, not claimed as a universal cost reduction yet.

The large `odh-dashboard` corroboration used its `sufficient` analyzer baseline. The
agent read eight targeted files, made 19 tool calls, spawned no sub-agents, and
finished in 485 seconds. The stored legacy Opus document took 667 seconds and reports
105+ files and roughly 12,000 lines read; because the models differ, this is supporting
evidence rather than the controlled speed result. More importantly, the analyzer and
agent output both retain exactly 141/165 structured identities, so synthesis did not
drop any measured structured facts.

These runs also established a renderer-to-agent optimization: for `sufficient` and
`partial` baselines the skill copies `ANALYZER_ARCHITECTURE.md` to the requested
output and edits only metadata, pending synthesis, and conditional sections. It no
longer asks the model to regenerate populated tables.

## Dashboard Fidelity Follow-Up

The initial 141/165 dashboard result proved preservation but was not
replacement-level fidelity. A row-level follow-up audited all 24 missing structured
identities and all populated-cell conflicts at commit `f1cdd9f22`. Comparator,
normalization, serving-certificate, endpoint-selection, and dashboard semantic
extraction defects were corrected.

The fresh analyzer now retains 162/166 structured fixture identities (97.59%). The
four remaining raw misses are adjudicated fixture defects: browser links classified
as pod egress, an incomplete multi-group RBAC rule, an incorrect image-puller binding
identity/subject, and a stale MCP transport. Removing those four rows produces
162/162 adjudicated recall. The synthesis-rebased generated document preserves all
314 current analyzer identities with zero cell conflicts and passes structural
validation.

The revised comparator also reports structured recall separately from recent history
and source-file inventory. The `caikit-nlp` partial-path corroboration retains 20/20
current analyzer identities, while its bounded source pass raises fixture recall from
18/56 to 27/56 structured identities in 239 seconds. Full evidence and dispositions
are in `docs/notes/arch-analyzer-dashboard-fidelity-audit.md`.

## Production Integration

`lib/fetch.py` now builds `src/arch-analyzer` into `bin/arch-analyzer`; the dynamic
clone/build fallback has been removed. Static analysis extracts compatibility JSON,
renders `ANALYZER_ARCHITECTURE.md`, and writes versioned OpenAPI schemas for served
CRDs. Distribution-aware extraction retries automatic overlay selection when a
repository does not contain the requested product overlay.

The `repo-to-architecture-summary` skill treats the analyzer Markdown as its primary
input, preserves structured source-backed facts, and limits repository reads to
specific gaps. It copies partial/sufficient baselines and performs targeted edits
instead of full-file regeneration. The legacy deep-exploration path remains available
for manual runs with no analyzer output and for the eight explicitly insufficient
repository shapes.

## Decision And Gates

The approach is viable enough to supplant most of the current skill's repository
discovery. The analyzer now owns deterministic repository enumeration, structured
facts, evidence, normalization, schemas, and the initial Markdown document. Agents
remain responsible for synthesis and genuinely dynamic gaps.

Adopt these gates for subsequent changes:

- Production extraction, rendering, and structural validation: 100% of configured
  components.
- Static phase: no more than 60 seconds for 90 components with 10 workers on the
  current environment.
- `sufficient`: at least 70% of the platform; `insufficient`: no more than 10%.
- A `sufficient` agent treatment must preserve all measured structured identities
  from its analyzer input.
- A replacement-candidate generated document must reach at least 95% exact recall
  over an adjudicated structured fixture, with every remaining miss and conflict
  source-reviewed. History and source-file inventory are reported separately.
- A representative same-model treatment must remain within two exact-recall points
  of control while materially reducing wall time or exploration tools.
- Broad exploration and sub-agents remain prohibited for `sufficient` and `partial`
  baselines.

Future work is incremental rather than a viability blocker: improve dynamic framework
APIs and semantic aliases, reduce edit-turn cost, and add extractors only where the
19 partial or eight insufficient repositories show repeated gaps. A full 90-agent
platform run can still measure final production wall time, but it is not required to
decide whether the analyzer can replace most discovery work. `PLATFORM.md` synthesis
and diagrams were not modified by this migration.

## Completion Audit Refresh

The final audit reran the current production static phase after evidence-gated merge,
readiness routing, and the multi-surface readiness correction landed:

| Signal | Current result | Gate |
|--------|---------------:|-----:|
| Extracted and rendered | 90/90 | 100% |
| Structurally valid analyzer documents | 90/90 | 100% |
| CRD schemas | 325 | measured |
| Static wall time with 10 workers and binary build | 17.25s | <=60s |
| `sufficient` | 63/90 (70.0%) | >=70% |
| `partial` | 19/90 (21.1%) | measured |
| `insufficient` | 8/90 (8.9%) | <=10% |

The readiness-routed live matrix preserved 323/323 analyzer identities with zero
analyzer-to-final conflicts. Dashboard replacement fidelity remains 162/166 (97.59%)
raw and 162/162 after source adjudication. The complete requirement mapping and
verification record is in the
[completion audit](../notes/component-analyzer-migration-completion-audit-2026-07-18.md).
