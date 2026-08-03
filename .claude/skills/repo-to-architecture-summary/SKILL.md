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
Discovery and reads are limited to the declared gap categories.
`--file-budget` is guidance for how many unique source files should usually
settle the gaps. Prefer fewer reads. If a directly relevant file is needed for
an unresolved question, read it once at a bounded range and record why in
`SOURCE_READ_JUSTIFICATIONS.json`; the budget does not require stopping before
that one targeted follow-up. Once the question is answered or remains
unverified, stop and record the result. The budget is not permission to repeat
equivalent discovery or keep searching after the evidence trail is sufficient.
Read only files relevant to those gaps, including
narrative, safety-critical, and structural gaps as classified by
`--gap-reasons`. Record every checkout source file read with path, lines, gap
category, question, expected signal, outcome, and output section, including
reads made after the soft `--file-budget` guidance has been exceeded only when
they answer a newly identified unresolved question. Do not use Bash, Task, or
TodoWrite; this includes shell-style listing commands such
as `ls`, `find`, or `tree`. Use known file paths, targeted `Glob`, and
targeted `Grep` instead. Keep any planning in brief prose; do not create
tool-managed todos for component generation. Do not perform broad discovery.

Use `Glob` only with targeted patterns such as `**/kustomization.yaml`,
`**/*auth*.yaml`, or `cmd/**/main.go`; never use root-wide patterns like `*`,
`**`, or `**/*`. For Helm/Kustomize repositories, start with targeted patterns
such as `charts/**/Chart.yaml`, `charts/**/values.yaml`,
`charts/**/templates/**/*.yaml`, `components/**/kustomization.yaml`, and
`configurations/**/kustomization.yaml` instead of enumerating the checkout
root. Use `Grep` for filenames first; the execution guard rewrites Grep to
`files_with_matches` with a bounded result count. For source `Read` calls on
larger files, use `offset` and `limit` around the relevant symbol, function, or
manifest snippet. For large Helm values files, read a bounded top-level range
first, then only the specific component, dependency, gateway, auth, or TLS
section needed for the routed gap. If a gap remains unresolved after bounded
reads, write `unknown` or `not-extracted` rather than broadening discovery.
Never read a file in one whole-file operation when targeted bounded reads can
answer the question. If multiple bounded reads are needed for one file, keep
their source-read ledger entries separate and record each exact range; do not
combine them into one synthetic range spanning the whole file.
Preserve the analyzer's
`cross_cutting_evidence` families in the component output, especially
`security`, `ingress`, `supply_chain`, `disconnected_deployment`,
`high_availability`, and `deployment_topology`; do not replace an observed
fact with thinner prose merely because no source read was required.
When `fips_compliance` is routed, inspect the cited Cargo/build evidence and
write the `FIPS Compliance` subsection under `Security`. Distinguish a known
non-FIPS provider signal (such as an explicitly selected provider) from a
missing validation signal; use `unknown` or `not verified` when configuration
does not establish FIPS mode. Cite the source files that support both the
provider and the limitation. Do not infer FIPS compliance from the presence of
OpenSSL, a UBI base image, or a TLS dependency alone.
Preserve analyzer-rendered `Serving Runtime Definitions` rows as first-class
runtime inventory evidence. A row may establish that a runtime definition is
packaged by the selected manifest set; only call it default or shipped when the
rendered source path or selected overlay context supports that packaging claim.

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

### Bounded discovery protocol

Before the first `Glob` or `Grep`, state the unresolved question for each
declared gap and choose one bounded search plan for it. Prefer one broad,
specific search that can identify the relevant files, then read those files at
bounded ranges. Reuse search results across gap categories when they answer
more than one question. Do not repeat equivalent searches with spelling,
scope, or output-mode variations after the relevant files or a conclusive
absence have been established. Once a gap is resolved or its evidence-backed
limitation is recorded, stop discovery for that gap and synthesize the result.
Soft discovery-budget telemetry is a signal to stop redundant exploration,
not an invitation to continue searching until the model exhausts its turns.

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
place with `Edit` and do not rewrite the baseline wholesale. Treat the
following as the only agent-authored synthesis sections: `Purpose`, `Data
Flows`, and `Architectural Analysis`. `Security` is shared: preserve analyzer
evidence and add only evidence-backed synthesis subsections such as `FIPS
Compliance` or `Build Hermeticity`. Do not rewrite analyzer-owned metadata,
architecture component tables, API inventories, dependencies, network
inventories, integration tables, or recent-change sections. Do not use `Write`
on the preseeded primary output; reserve `Write` for sidecar artifacts such as
change records, insights, and read justifications. Every claim must have an
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

Treat the analyzer's `Deployment Type` as an evidence projection. Preserve
composite role labels when present (for example, an operator plus an SDK or
pod-mutation utility), and only describe a role when the corresponding
source-backed component, entrypoint, package, workload, or webhook evidence is
present. Do not collapse a supported composite into a generic label or add a
role based on the repository name alone.

The orchestrator owns final document assembly. After evidence-gated table
changes are adjudicated, it invokes the repository-local `bin/arch-doc
assemble` command to copy only the approved synthesis sections onto the
table-merged analyzer base. Do not bypass this boundary by promoting the raw
candidate directly; the command preserves analyzer-owned sections and rejects
malformed or duplicate section layouts.

Write the requested output filename exactly where `--output` specifies it; it
may be outside the repository checkout. Write insights and change records
exactly where their arguments specify. Insight artifacts are versioned,
non-authoritative JSON; an empty `insights` array is valid, and provenance may
only cite exact analyzer facts, queries, overlays, or source excerpts.

When `--change-output` is supplied, the change-record file must contain one
Markdown table with these exact headers:

`Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence`

Write it as a canonical Markdown table with leading and trailing `|` on the
header, separator, and every data row. Do not emit bare pipe-separated lines.

Emit one table row for every candidate-only or changed architecture fact that
the agent wants merged. For `add` and `delete` rows, use `Column` `*` and the
literal value `<empty>` in both value columns. For `update` rows, use the
specific changed column and include both the analyzer and candidate cell
values. Every row needs a concrete reason and numeric repository-relative
evidence such as `charts/README.md:42` or `config.yaml:10-18`. Every
comma-separated evidence item must include its own numeric line or line range;
bare file paths, directory paths, and glob patterns are invalid. Use a nearby
line such as `charts/dependencies/gateway-api/Chart.yaml:1` when the source
claim is established by a file header. Do not replace
this table with a prose change summary; prose may supplement the required
table, but the structured table is what the evidence-gated merge consumes.

Before finishing, cross-check every change-record identity against the
candidate Markdown tables. An `add` record is invalid unless the candidate
contains a row with the same normalized category and row key; an `update`
record is invalid unless the candidate contains the same row with the changed
cell value. Add the candidate row first, then emit its change record. Do not
emit a change record for a fact that exists only in prose or only in the change
sidecar. This applies equally to HTTP endpoints, integrations, dependencies,
services, authentication rows, and other gap categories.

Emit at most one change record for each `(Action, Category, Row Key, Column)`
identity. If multiple source reads support the same candidate row, combine all
of their evidence references into that one record. Never split one row into a
candidate-only record plus a second evidence-bearing record.

Evidence must always use a repository-relative path followed by a numeric line
or line range. Never use labels such as `platform-delegated:`, `analyzer:`,
`source-backed:`, or a prose phrase as evidence. If a platform relationship is
not supported by a checkout path and line, leave it unknown or cite the actual
manifest/overlay line that establishes it; do not invent a pseudo-path.

Change-record `Category` must be one of the architecture table categories,
never `metadata`. `Row Key` is the exact key tuple for that category, with
multiple key cells joined by ` :: ` in table order: `architecture_components`
uses `component`; `internal_dependencies` uses `component`; `authentication`
uses `endpoint :: methods`; `integration_points` uses
`component :: interaction_type`; `http_endpoints` uses `method :: path`; and
`grpc_services` uses `service`. For example, a valid new architecture row is:

For `authentication`, the key is always the first two table columns,
`endpoint :: methods`. In a row such as
`| Tracking Server API | All | kubernetes-auth plugin | Flask | policy |`,
the only valid row key is `Tracking Server API :: All`. The authentication
mechanism is a cell value, not part of the row key. Do not use
`Tracking Server API :: kubernetes-auth plugin` as the key.

`| add | architecture_components | rhai-on-xks-chart | * | <empty> | <empty> | Helm chart is a deployable architecture component | charts/rhai-on-xks-chart/Chart.yaml:3 |`

For an `add`, do not copy the candidate row contents into `Candidate Value`:
the candidate Markdown contains that row, while the change table only records
the evidence-backed authorization to add it.

When an architecture row's key cell changes, this is a row-key migration, not
an update. Never emit an `update` whose candidate value changes a key column.
Instead, omit the old row from the candidate, include the replacement row with
its new key, and emit two evidence-backed records: `delete` the old exact row
and `add` the new exact row. Both records use `Column` `*` and `<empty>` in
both value columns, and both carry the evidence that establishes the removal
or replacement. For authentication, changing `HTTP API :: All` to
`Tracking Server API :: All` requires a delete for the former key and an add
for the latter key; a separate `Gateway API :: All` row is another add. The
candidate table must contain every added row before the corresponding change
records are written.

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
Every checkout source file opened with Read must appear in the ledger even if
the read only proves that a fact is absent, stale, unknown, or unhelpful. Do not
record analyzer files, skill references, generated architecture files, or other
non-checkout inputs in this ledger. If one source file informs multiple gaps or
sections, include the relevant gap categories and sections in the same record.
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
