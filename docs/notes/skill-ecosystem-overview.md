# Skill Ecosystem Overview

**Date**: 2026-07-19

This document describes the agentic skill repos that consume architecture-context
data, how they fit together as a pipeline, and where architecture-context
participates in their workflows.

## End-to-End Pipeline

Four skill repos form a sequential pipeline that takes a product need from
problem statement through to a code PR on a target repository:

```
RFE (rfe-creator)
  → Strategy (strat-creator)
    → Epic Decomposition (epic-creator)
      → Code Generation (epic-code-gen)
        → PR on target repo → CI → human review → merge
```

Each stage is a separate repo with its own Claude Code skills, CI integration,
and Jira project. The stages are loosely coupled through Jira issue links and
artifact files with YAML frontmatter.

## Skill Repos

### rfe-creator

**Purpose**: Create, review, score, split, and submit Requests for Enhancement
(RFEs) to the RHAIRFE Jira project.

**Key skills**: `/rfe.create`, `/rfe.review`, `/rfe.split`, `/rfe.submit`,
`/rfe.speedrun` (end-to-end), `/rfe.auto-fix` (batch review+revise+split).

**Pipeline trigger**: Manual invocation with an RHAIRFE ID, batch from YAML, or
batch from JQL query. CI runs via GitHub Actions triggering a GitLab pipeline.

**Architecture-context role**: Used during the technical feasibility review fork
of `/rfe.review`. Not used during `/rfe.create` — RFEs describe business needs,
not implementation. The feasibility reviewer reads PLATFORM.md to identify which
components an RFE touches, reads relevant component docs for detail, and reads
active overlays for corrections. If architecture data is unavailable, the review
proceeds with RFE content alone and notes the gap.

**Other context sources**: Jira (RHAIRFE) via Atlassian MCP or REST API, the
`assess-rfe` rubric plugin.

**CI infrastructure**: GitHub Actions for tests, GitLab (`rfe-autofixer`) for
production runs, GitLab results repo for run artifacts.

### strat-creator

**Purpose**: Take approved RFEs (the WHAT and WHY) and produce the HOW —
actionable implementation strategies grounded in real platform architecture.

**Key skills**: `strategy-create`, `strategy-refine`, `strategy-review`,
`strategy-signoff` (human step). Sub-skills for feasibility, testability, scope,
and architecture review run as parallel scoring agents.

**Pipeline trigger**: JQL query against RHAISTRAT using labels and statuses from
`config/pipeline-settings.yaml`, or curated batch config files. Two-stage
pre-filtering (Jira JQL + RHAISTRAT cross-check) before batching. Default batch
size 10.

**Architecture-context role**: The heaviest consumer. Used during both refinement
and review:
- `strategy-refine` reads PLATFORM.md, component docs, and overlays to ground
  the strategy in real architecture. Defines a 4-level priority chain: Staff
  Engineer Input > Overlays > Removed RFE Context > Architecture Context.
- `strategy-architecture-review` validates architecture claims against component
  docs and overlays.
- `strategy-feasibility-review` reads PLATFORM.md and component docs but does
  not read overlays (inconsistency noted in the
  [consumer inventory](downstream-consumer-inventory-2026-07-19.md)).

The strat-creator version of the fetch script is the most feature-rich: supports
local-path override for testing overlay changes before pushing upstream.

**Other context sources**: Jira (RHAISTRAT and RHAIRFE) via Atlassian MCP or
REST API, the `assess-strat` rubric plugin.

**CI infrastructure**: GitLab (`strat-pipeline`) for production runs,
GitLab (`strat-pipeline-data`) for run artifacts, GitLab Pages dashboard at
`strat-dashboard-*.gitlab.io` with aggregate stats and per-run trends.

### epic-creator

**Purpose**: Decompose refined RHAISTRAT strategies into implementation epic DAGs
with dependency ordering.

**Key skills**: `/epic-decompose`. Non-interactive batch pipeline.

**Pipeline trigger**: Explicit RHAISTRAT IDs or JQL query. Supports headless mode,
batch splitting, and parallel wave dispatch with synchronization barriers.

**Architecture-context role**: Lightweight consumer. Checks whether a component
architecture file exists (file-presence test) to determine if something is "in
the platform." Missing components trigger provisioning or investigation epics.
Does not read PLATFORM.md, component doc content, or overlays. The sparse
checkout excludes `overlays/`.

**Other context sources**: Jira (RHAISTRAT), `scripts/fetch_components.py` for
Jira component names.

### epic-code-gen

**Purpose**: Given an approved strategy and its epic decomposition, generate
implementation code against target repos — fully automated from spec through to
a reviewed, tested code diff.

**Key skills**: `/epic-codegen` with 4 phases: Spec & Plan → Implementation →
Multi-Dimensional Review (4 parallel reviewers: architecture 30%, tests 30%,
lint 20%, intent 20%) → Iterate or Complete (pass at ≥8.0 weighted average, up
to 3 iterations).

**Pipeline trigger**: The orchestrator `run_pipeline.py` accepts RHAISTRAT IDs,
fetches child epics from Jira, classifies by eligibility (status + dependency
DAG), and invokes `/epic-codegen` per eligible epic. Blocked epics are skipped
and become eligible in future runs.

**Architecture-context role**: Minimal. CLAUDE.md documents the fetch script and
`.context/` infrastructure, but the actual `/epic-codegen` SKILL.md does not
reference architecture-context data. The architecture reviewer agent reviews
code against target-repo conventions, not platform architecture.

**Other context sources**: Jira (RHAISTRAT), target repos cloned into
`.target-repo/`, the Superpowers plugin (`obra/superpowers`) for brainstorming
and subagent-driven development.

**CI infrastructure**: Dockerfile based on UBI9, installs Python 3.11, Go 1.24,
Node.js 22, Playwright, Claude Code CLI, and Superpowers plugin. CI wrapper
pattern (`run-claude.sh` + `stream-claude.py`) adapted from `strat-pipeline`.

## How Architecture-Context Is Consumed

All consumers follow the same general pattern:

1. **Fetch**: Sparse git checkout of `opendatahub-io/architecture-context` into
   `.context/architecture-context/`, discovering the latest `rhoai-*` version
   via the GitHub contents API.
2. **Discover version**: Read a `LATEST_VERSION` marker file (rfe-creator) or
   glob for `rhoai-*` directories (strat-creator, epic-creator).
3. **Read platform overview**: Read `PLATFORM.md` (~870 lines) to identify
   relevant components.
4. **Read component detail**: Read individual `{component}.md` files (~300 lines
   each) for CRDs, ports, RBAC, dependencies, security detail.
5. **Read overlays**: Glob `overlays/*.md`, parse YAML frontmatter for `status`,
   `release`, `affects`, read `## Fact` and `## Impact on Strategies` sections.
   Overlays take precedence over generated docs.

Not all consumers perform every step. See the
[consumer inventory](downstream-consumer-inventory-2026-07-19.md) for the
per-repo matrix.

### What Is Not Used

No consumer currently uses:
- `arch-query` CLI
- `component-map.json`
- `GENERATED_ARCHITECTURE.md` (the in-repo files before collection)
- Diagrams (`.mmd`, `.png`, `.dsl`, `.txt`)
- CRD JSON schemas from `contracts/`

## Shared Infrastructure Patterns

The skill repos share several infrastructure conventions despite being
independent repositories:

- **State persistence**: `scripts/state.py` for surviving context compression
  during long CI runs.
- **YAML frontmatter**: `scripts/frontmatter.py` for metadata on task and review
  artifact files.
- **Artifact schemas**: `scripts/artifact_utils.py` for consistent artifact
  structure.
- **Pipeline state machine**: `pipeline_state.py` for batch orchestration with
  wave dispatch and synchronization barriers.
- **CI wrapper**: `run-claude.sh` + `stream-claude.py` pattern originated in
  `strat-pipeline` on GitLab.
- **CI execution**: GitLab for production runs, GitHub Actions for tests and as
  triggers into GitLab.
- **Jira access**: Atlassian MCP server (preferred) with REST API fallback.

## Architecture-Context Integration Opportunities

The current integration is functional but has known inefficiencies documented in
the [consumer inventory](downstream-consumer-inventory-2026-07-19.md):

1. **Fetch script drift**: Three divergent copies of the same script with
   different feature sets.
2. **Full-document reads**: Agents read entire 300+ line docs to extract small
   fact sets — the pattern `arch-query` was designed to replace.
3. **No structured queries**: Consumers use Read/glob/grep instead of
   purpose-built query tools.
4. **Overlay consumption gaps**: epic-creator does not fetch overlays;
   strat-creator's feasibility review does not read them.
5. **No freshness validation**: No consumer checks whether the data is current.

The `arch-query` CLI with embedded data (released via the existing
`.github/workflows/release.yml` pipeline) could replace the sparse-checkout
fetch scripts and reduce tool calls. See
[arch-query design](../plans/arch-query-design.md) and
[arch-query bundling](../plans/arch-query-bundling.md) for the design. The
adoption gap is documented in the consumer inventory.

## Related Documents

- [Downstream consumer inventory](downstream-consumer-inventory-2026-07-19.md)
- [arch-query CLI design](../plans/arch-query-design.md)
- [arch-query bundled distribution](../plans/arch-query-bundling.md)
- [Architecture-context benchmark](../plans/architecture-context-benchmark.md)
