---
name: repo-to-architecture-summary
description: Analyze an ODH/RHOAI component repository and generate an evidence-backed architecture summary.
allowed-tools: Read, Edit, Write, Glob, Grep, Bash, Task
---

# Repo to Architecture Summary

Generate `GENERATED_ARCHITECTURE.md` from the analyzer baseline and, when
authorized by the route, bounded source evidence. Analyzer-owned facts,
reviewed overlays, explicit unknowns, and provenance are authoritative.

## Arguments

- `[directory]` — repository path, default current directory.
- `--distribution=odh|rhoai|both`, default `both`.
- `--version=X.Y`, default auto-detect.
- `--output=FILENAME`, default `GENERATED_ARCHITECTURE.md`.
- `--generated-by=STRING`, optional metadata value.
- `--insights-output=FILENAME` and `--change-output=FILENAME`, optional
  synthesis/partial artifacts.
- Orchestrator controls: `--readiness`, `--analysis-route`,
  `--gap-categories`, `--baseline-preseeded`, `--file-budget`,
  `--allowed-source-files`, and `--gap-reasons`.

## Analyzer input contract

The orchestrator runs `arch-analyzer extract` and `arch-analyzer render` before
invoking this skill. The checkout contains `component-architecture.json` and
`ANALYZER_ARCHITECTURE.md`. The JSON supplies readiness, coverage, structured
facts, and provenance. The Markdown is the preseeded candidate baseline.

Do not run or regenerate the analyzer. If either required input is absent,
constrained routes are ineligible and the orchestrator applies fallback. The
baseline is evidence, not permission to invent facts.

## Hard route contract

Read the analyzer JSON and baseline before any source inspection.

### Partial (default for all analyzer-backed components)

Use Read/Edit/Write/Glob/Grep only. This is the default extend-and-improve
route for every component with valid analyzer artifacts (both
`component-architecture.json` and `ANALYZER_ARCHITECTURE.md`), regardless of
readiness classification (`sufficient`, `partial`, `insufficient`, or
`unknown`). The synthesis route is not selected for normal generation.
Discovery and reads are limited to the declared gap categories and
`--file-budget`. Read only files relevant to those gaps, including narrative,
safety-critical, and structural gaps as classified by `--gap-reasons`. Record
every read with path, lines, gap category, and output section. Do not use
Bash or Task. Do not perform broad discovery.

### Synthesis (not selected for normal generation)

Retained for reference only; normal routing never selects this route. Use
Read/Edit/Write only. Do not enumerate repositories, read source files, run
commands, or spawn agents. Refine the preseeded baseline and narrative
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
`unknown`/`not-extracted`.

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
- [`references/webhook-analysis.md`](references/webhook-analysis.md) — analyzer-backed webhook inventory
  synthesis, bounded handler semantics, provenance, and aggregation.
- Existing language, container, kustomize, multi-tenancy, Konflux, and
  controller references in this directory for their specialized procedures.

## Output contract

Read `templates/architecture-template.md` before writing. Use its exact
headings and table columns. The analyzer baseline is edited in place for
synthesis/partial routes; do not rewrite it wholesale. Every claim must have
an analyzer or source reference. Populate `Generated By` and the required
Source References tables. Platform operators require dynamic resources,
controller flows, integration points, and complete ingress chains.

Write the requested output filename at repository root. Write insights and
change records separately when requested. Insight artifacts are versioned,
non-authoritative JSON; an empty `insights` array is valid, and provenance may
only cite exact analyzer facts, queries, overlays, or source excerpts.

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
