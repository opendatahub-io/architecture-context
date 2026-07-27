# Task: Mine Partial-Run Logs for arch-analyzer Improvements

## Goal

Use the completed analyzer-assisted partial run as an empirical demand dataset
to identify and prioritize deterministic `arch-analyzer` extraction/rendering
improvements that reduce agent source reads, edit turns, runtime, and cost
without weakening provenance or inventing facts.

## Context

The partial agents are now bounded to analyzer artifacts plus declared source
files, but completed logs still show roughly 30–44 model turns and 5–10 minutes
per component. The logs record which analyzer gaps caused reads, which files
were selected, which document sections were edited, and which facts required
semantic interpretation.

## Plan

### 1. Establish the run boundary and inputs

- Identify the completed run, analyzer version, model, concurrency, component
  count, and phase timings.
- Confirm raw logs, generated outputs, API dumps, and telemetry remain ignored
  and are not committed.
- Use only the current run as primary evidence; prior architecture documents
  remain comparison-only and are not synthesis inputs.

### 2. Build a redacted demand inventory

Parse component logs into structured records containing only non-secret
metadata:

- component, route, readiness, analyzer version, model, duration, cost;
- tool counts and source-read paths;
- declared gap categories, allowed-file lists, and actual reads;
- edited output sections and repeated edit/write operations;
- explicit unknowns later resolved by source evidence;
- validation results and failure/limitation markers.

Never persist prompts, raw source content, credentials, API payloads, OTel
payloads, or complete model transcripts in a tracked artifact.

### 3. Classify improvement opportunities

Group demand by deterministic analyzer capability:

- entrypoint and runtime-component mapping;
- Dockerfile/image/deployment relationships;
- route and handler ownership;
- dependency role and external-service classification;
- configuration, environment, probes, and lifecycle behavior;
- authentication, TLS, RBAC, secrets, ingress, and egress;
- controller watches, integrations, webhooks, and data flows;
- recurring narrative sections that remain thin after rendering.

For each candidate, record frequency, representative evidence paths, current
gap category, expected output field/section, determinism, and safety risk.

### 4. Prioritize analyzer changes

Rank candidates using:

- frequency across components;
- source-read and edit-turn reduction potential;
- confidence that extraction is deterministic and source-backed;
- schema/rendering impact;
- safety/provenance risk;
- implementation effort.

Prefer high-frequency, low-inference enrichments first. Keep ambiguous
semantic synthesis in the agent route until extraction contracts are proven.

### 5. Implement and replay in bounded increments

For each accepted improvement:

- update analyzer schema/extraction/rendering and focused tests;
- add sanitized fixtures or committed expected structured output;
- replay representative components from the completed demand inventory;
- compare source reads, edit turns, duration, output quality, fact preservation,
  and explicit unknown behavior against the baseline run.

Do not use raw logs as golden architecture documents. Use them to define
replay cases and measurable demand patterns.

## Deliverables

- Redacted demand-inventory schema and extractor under `scripts/` or `lib/`.
- Human-readable report under `docs/notes/` with frequency tables, examples,
  prioritized analyzer opportunities, and limitations.
- Machine-readable summary under ignored `tmp/` unless a sanitized artifact is
  explicitly useful and contains no secrets or raw transcript content.
- Follow-up implementation tasks for the highest-priority analyzer changes.

## Acceptance Criteria

- [x] The completed run and phase boundaries are identified.
- [x] At least 90% of completed component logs parse or are classified with an
      explicit reason for exclusion.
- [x] Demand is grouped by gap category, source-file pattern, and output
      section, with raw-content and secret redaction verified.
- [x] The report identifies at least five prioritized analyzer opportunities
      and distinguishes deterministic extraction from agent-only semantics.
- [x] A replay baseline records route, reads, edits, duration, cost, and
      validation outcomes for representative components.
- [x] No raw logs, generated architecture outputs, API dumps, OTel payloads,
      secrets, or unrelated working-tree changes are staged or committed.

## Validation

```bash
PYTHONPATH=. ./.venv/bin/pytest -q
git diff --check
```

## Status

Phases 1–5 are complete for the accepted P1 inventory and P2 narrative
rendering increments. Full post-change agent-runtime replay remains a
measurement follow-up because the original component checkouts are not
present in this workspace. See:
`docs/tasks/done/extend-analyzer-runtime-and-api-inventory.md` and
`docs/tasks/done/render-analyzer-factual-narratives.md`.

## Phase 1–4 Review Evidence

- Boundary: 97 component records/logs under `logs/generate-architecture/`;
  platform and diagram phase logs completed afterward.
- Inventory: `scripts/mine_partial_run_logs.py` generated the ignored
  `tmp/partial-run-demand-inventory.json`; 97/97 records parsed.
- Report: `docs/notes/partial-run-log-demand-report.md` documents demand counts,
  five prioritized opportunity classes, deterministic/agent-owned boundaries,
  replay representatives, and limitations.
- Redaction: transcript/credential marker scan clean; raw logs and generated
  outputs were not staged.
- Validation: Python compilation and inventory schema/record-count checks
  passed. Repository-wide diff warnings are pre-existing generated-output and
  `.gitignore` blank-line warnings; task-scoped checks passed.
