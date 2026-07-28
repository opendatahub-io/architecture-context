---
name: repo-to-architecture-summary
description: Analyze an ODH/RHOAI component repository and generate an evidence-backed architecture summary.
allowed-tools: Read, Edit, Write, Glob, Grep, Bash, Task
---

# Repo to Architecture Summary

Generate the requested architecture document from the analyzer baseline and, when
authorized by the route, bounded source evidence. Analyzer-owned facts,
reviewed overlays, explicit unknowns, and provenance are authoritative.

## Arguments

- `[directory]` — repository path, default current directory.
- `--analyzer-dir=PATH` — directory containing the analyzer JSON, rendered
  baseline, and optional schemas. This may be outside the repository checkout.
- `--distribution=odh|rhoai|both`, default `both`.
- `--version=X.Y`, default auto-detect.
- `--output=PATH`, default `GENERATED_ARCHITECTURE.md` for standalone use.
- `--generated-by=STRING`, optional metadata value.
- `--insights-output=FILENAME` and `--change-output=FILENAME`, optional
  synthesis/partial artifacts.
- `--read-justifications-output=PATH`, optional JSON sidecar for source-read
  metadata. When supplied, emit one record for every source file read.
- Orchestrator controls: `--readiness`, `--analysis-route`,
  `--gap-categories`, `--baseline-preseeded`, `--file-budget`,
  `--allowed-source-files`, and `--gap-reasons`.

## Analyzer input contract

The orchestrator runs `arch-analyzer extract` and `arch-analyzer render` before
invoking this skill. It supplies an analyzer directory containing
`component-architecture.json`, `analyzer_architecture.md`, and the compact
`analyzer_synthesis_context.md` projection. Read the compact context and the
Markdown baseline first. Read the full JSON only when an exact fact or
provenance path is absent from the projection; use offset/limit for large JSON
files rather than attempting an unbounded read. The JSON supplies readiness,
coverage, structured facts, deterministic cross-references, compact synthesis
evidence, and provenance. The repository checkout remains the source root;
source reads must continue to use it, not the architecture output directory.

The compact context may also contain a `Gap Evidence Index`. Treat each entry
as a bounded candidate location and unresolved question, never as proof. Use
its paths, line ranges, and symbols to target a source read before using
discovery tools. A candidate can be stale, incomplete, or semantically
insufficient; the source read must decide that explicitly.

Do not run or regenerate the analyzer. If either required input is absent,
constrained routes are ineligible and the orchestrator applies fallback. The
baseline is evidence, not permission to invent facts.

## Hard route contract

Read the analyzer JSON and baseline before any source inspection.

### Partial (default for all analyzer-backed components)

Use Read/Edit/Write/Glob/Grep only. This is the default extend-and-improve
route for every component with valid analyzer artifacts (both
`component-architecture.json` and `analyzer_architecture.md`), regardless of
readiness classification (`sufficient`, `partial`, `insufficient`, or
`unknown`). The synthesis route is not selected for normal generation.
Discovery and reads are limited to the declared gap categories and
`--file-budget`. Read only files relevant to those gaps, including narrative,
safety-critical, and structural gaps as classified by `--gap-reasons`. Record
every read with path, lines, gap category, and output section. Do not use
Bash, Task, or TodoWrite. Keep any planning in brief prose; do not create
tool-managed todos for component generation. Do not perform broad discovery.
Preserve the analyzer's
`cross_cutting_evidence` families in the component output, especially
`security`, `ingress`, `supply_chain`, `disconnected_deployment`,
`high_availability`, and `deployment_topology`; do not replace an observed
fact with thinner prose merely because no source read was required.

### Synthesis (not selected for normal generation)

Retained for reference only; normal routing never selects this route. Use
Read/Edit/Write only. Do not enumerate repositories, read source files, run
commands, spawn agents, or use TodoWrite. Refine the preseeded baseline and narrative
sections from analyzer evidence only. Preserve analyzer source references and
mark them `Analyzer-seeded`. Skip discovery and validation steps; the
orchestrator validates the merged result.

### Legacy

Reserved for missing or invalid analyzer artifacts, or an explicit operator
override (`readiness_routing=False`). Use the analyzer baseline to avoid
rereading established facts. Inspect broadly only when the analyzer is absent,
incomplete, stale, contradictory, or leaves required safety-critical behavior
unresolved. Use the references below and retain all source-reference
requirements. Legacy is the only route that may use broad discovery and
sub-agents.

## Analyzer-first and isolation rules

Treat analyzer-covered, source-backed facts as already inspected. Add source
reads only for a declared gap, contradiction, stale fact, missing category, or
required dynamic safety behavior. Never infer absent facts; render
`unknown`/`not-extracted`. Treat `coverage_findings` with status
`confirmed-empty` as a bounded negative fact; treat `not-verified` as a reason
to preserve uncertainty, not as evidence of absence. Use deterministic
cross-references to enrich narrative relationships before opening source files.
Treat the cross-cutting evidence families as required synthesis inputs for
platform-facing fidelity. If a family is `unresolved` or contradictory, use a
bounded targeted source read and record the specific question and output
sections it resolves. If it is `confirmed-empty`, preserve that status rather
than inventing a narrative. Multi-category read justifications must be emitted
as a JSON array; readers may accept legacy comma-joined values for compatibility.

Files under prior `architecture/**/*.md` runs are comparison-only. Never read,
stage, or use them as synthesis inputs or fallback. The execution guard denies
those reads. Approved overlays, analyzer JSON/Markdown, indexes, and query
results may be used only when supplied by the orchestrator contract.

## References

Read only those applicable to the selected route and component:

- [`references/legacy-deep-analysis.md`](references/legacy-deep-analysis.md) — legacy discovery, source tracking,
  language selection, sub-agents, and required architecture surfaces.
- [`references/operator-preparation.md`](references/operator-preparation.md) and
  [`references/rhoai-ingress-patterns.md`](references/rhoai-ingress-patterns.md) — operator preparation and dynamic
  Gateway/Envoy/auth/Route behavior.
- [`references/aipcc-analysis.md`](references/aipcc-analysis.md) — Konflux Python/AIPCC checks.
- [`references/security-build-analysis.md`](references/security-build-analysis.md) — FIPS, crypto, and hermetic builds.
- [`references/provenance-and-quality.md`](references/provenance-and-quality.md) — lineage, output quality, and report.
- [`references/insight-artifact-contract.md`](references/insight-artifact-contract.md) — exact schema for optional insight artifacts.
- [`references/webhook-analysis.md`](references/webhook-analysis.md) — analyzer-backed webhook inventory
  synthesis, bounded handler semantics, provenance, and aggregation.
- Existing language, container, kustomize, multi-tenancy, Konflux, and
  controller references in this directory for their specialized procedures.

## Output contract

Read `templates/architecture-template.md` before writing. Use its exact
headings and table columns. For synthesis/partial routes, the orchestrator
preseeds the requested output from the analyzer baseline; edit that output in
place and do not rewrite the baseline wholesale. Every claim must have an
analyzer or source reference. Populate `Generated By` and the required
inline source citations. Do not add a `Source References` section or
files-read table to the final Markdown; source-read audit metadata belongs in
the sidecar specified by `--read-justifications-output`. Platform operators
require dynamic resources, controller flows, integration points, and complete
ingress chains. `Architectural Analysis` must be authored synthesis: rewrite
any analyzer preseed placeholder, do not retain analyzer-internal coverage
diagnostics (`Analyzer coverage`, `Category coverage`, `Coverage Findings`,
`Deterministic Cross-References`, or `Bounded Synthesis Evidence`), and do not
leave deterministic inventory bullets as the final analysis.

Write the requested output filename exactly where `--output` specifies it; it
may be outside the repository checkout. Write insights and change records
exactly where their arguments specify. Insight artifacts are versioned,
non-authoritative JSON; an empty `insights` array is valid, and provenance may
only cite exact analyzer facts, queries, overlays, or source excerpts.
When `--insights-output` is present, read
`references/insight-artifact-contract.md` and emit the exact schema described
there. Analyzer coverage-gap names are not insight categories. The
`--platform` and `--version` values supplied by the orchestrator must be
copied into the artifact envelope.

When `--read-justifications-output` is present, write a JSON object with
`schema_version`, `component`, and a `reads` array. Emit one metadata record
per source file read with `path`, `line_range`, `gap_category` (an array),
`question`, `expected_signal`, `outcome`, and `sections`. Outcomes are one of
`resolved`, `partially-resolved`, `contradicted`, or `unhelpful`. Use paths
relative to the checkout and line ranges when known. This ledger is metadata
only: do not include source excerpts, secret values, prompts, or transcripts.
Prefer exact symbols, functions, handlers, manifests, or YAML snippets over
whole files. Before reading a large file, use analyzer context, filenames,
headings, symbols, or targeted search results to identify the narrowest useful
range. For a read spanning more than 400 lines, include `scope_reason`
explaining why narrower symbol-, function-, or manifest-snippet evidence was
insufficient; missing `scope_reason` makes the read unjustified in orchestrator
telemetry.
The orchestrator compares it with read telemetry in warning-only mode.

## Validation and report

Legacy runs invoke `scripts/validate_architecture.py` and repair failures.
Synthesis/partial runs rely on orchestrator validation and must not invoke
Bash validation. Report output path, component, distribution, version, counts,
source/search totals, inferred sections, validation state, and limitations.

## Safety and precision

Never read `*_test.go`. Never expose Secret values. Use exact ports,
protocols, encryption, authentication, API groups, and resource names. Do not
claim security, ownership, performance, tenancy, or upstream behavior without
evidence. Preserve unknowns and stale/incomplete status explicitly.
