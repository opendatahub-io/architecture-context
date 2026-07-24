# Evidence-Gated Analyzer Merge Pilot: 2026-07-18

## Purpose

This note records the same-revision `MLServer` and `notebooks` pilot for the
evidence-gated analyzer document merge. It replays raw agent candidates from the
successful `rhoai-next-20260718T034628Z` run; it does not incur another agent run.

The pilot tests whether a final component document can preserve every analyzer fact,
retain source-backed agent additions, reject unsupported assertions, and keep the raw
candidate's fixture recall.

## Inputs

| Component | Commit | Readiness | Raw agent time | Tool calls | Reads | Cost |
|-----------|--------|-----------|---------------:|-----------:|------:|-----:|
| `MLServer` | `15d0a4c4d6ad4c0e666c4c6f3b4ffd25b51094de` | sufficient | 425.79s | 40 | 22 | $2.0872 |
| `notebooks` | `d931e69d7e8f893b0438f477253cc54ea8f2807b` | sufficient | 496.81s | 43 | 19 | $2.5009 |

Tool calls are counted from SDK `ToolUseBlock` records and include file operations,
shell commands, validation, and task tracking. The raw agents ran before the Markdown
change-record instruction existed. Their candidates were source-reviewed and replayed
with permanent evidence fixtures:

- [`MLServer.changes.md`](../../tests/fixtures/architecture_merge/MLServer.changes.md)
- [`notebooks.changes.md`](../../tests/fixtures/architecture_merge/notebooks.changes.md)

## Results

| Measure | MLServer raw | MLServer merged | notebooks raw | notebooks merged |
|---------|-------------:|----------------:|--------------:|-----------------:|
| Fixture structured recall | 80/102 (78.43%) | 80/102 (78.43%) | 7/72 (9.72%) | 7/72 (9.72%) |
| Fixture populated-cell conflicts | 38 | 29 | 9 | 8 |
| Analyzer structured preservation | 67/71 (94.37%) | 71/71 (100%) | 7/407 (1.72%) | 407/407 (100%) |
| Analyzer populated-cell conflicts | 14 | 0 | 4 | 0 |
| Evidence-backed additions applied | n/a | 37 | n/a | 32 |
| Unsupported additions rejected | n/a | 5 | n/a | 22 |
| Candidate changes restored | n/a | 163 | n/a | 446 |
| Structural validation | pass | pass | pass | pass |
| Deterministic merge time | n/a | 0.09s | n/a | 0.10s |

The merge also retained agent synthesis, conditional AIPCC and Sub-Component
sections, analyzer coverage metadata, and the union of analyzer, agent, and change
record source references.

The high notebooks restore count is expected. Its analyzer records 393 broad Python
dependencies, while the agent retained a small architecture-selected subset. The
pilot preserves the analyzer inventory because the agent provided no per-dependency
evidence that those facts were incorrect. Dependency relevance policy remains a
separate normalization problem.

## Source Review

For `MLServer`, the accepted additions are directly supported by registered FastAPI
routes, configured REST/gRPC/metrics servers, Kafka clients, the OTLP exporter, the
service-account namespace mount, and production-mode CORS/environment checks. Five
candidate additions remained rejected because this repository does not directly
prove them:

- KServe and storage-initializer internal dependency rows;
- the blanket claim that all `/v2/*` endpoints have no application authentication;
- KServe container-image and storage-initializer integration rows.

For `notebooks`, accepted additions are limited to manifest-enumerated image variants,
literal nginx routes, explicit build dependencies, JupyterLab startup, directly
packaged platform manifest trees, AIPCC base inputs, and Cachi2 build behavior.
Twenty-two candidate additions remained rejected. They primarily claim behavior
owned by other repositories: notebook-controller deployment, dashboard selection,
injected auth sidecars, pipeline execution, user-initiated runtime egress, and
external experiment or pipeline services. Four recent-history replacements also
remain rejected because a structured source-change record requires repository file
and line evidence.

The rejected rows remain visible in the generated `.merge.md` and `.merge.json`
reports. They are not silently discarded.

## Commands

The replay command shape is:

```bash
uv run python scripts/rebase_architecture_synthesis.py \
  ANALYZER_ARCHITECTURE.md RAW_GENERATED_ARCHITECTURE.md MERGED.md \
  --evidence-gated \
  --generated-by='Claude Opus 4.6' \
  --component=COMPONENT \
  --changes=COMPONENT.changes.md \
  --report-json=COMPONENT.merge.json \
  --report-markdown=COMPONENT.merge.md
```

The component-generation pipeline exposes the same behavior through
`generate-architecture --evidence-gated-merge`. That opt-in archives the raw
candidate and change record, writes both merge reports, and validates the final
document before reporting the agent as successful.

## Decision

The deterministic merge is ready as an opt-in quality guard, but it should not yet
be enabled by default for the full platform. These pilots prove replay behavior, not
that a live agent reliably emits complete change records under the updated skill.

The next task should run the updated contract live on a small readiness matrix and
then route:

- `sufficient` repositories through analyzer-owned structured output plus bounded
  synthesis and evidence-gated changes;
- `partial` repositories through a larger but still explicit gap budget; and
- `insufficient` repositories through the legacy full-document fallback.

That work must measure source reads and wall time. The merge itself costs about 0.1
seconds, but the recorded agents still cost seven to eight minutes each.

## Follow-Up

The requested live matrix subsequently passed and the route is now enabled by
default. See the
[readiness-routed evidence merge pilot](readiness-routed-evidence-merge-pilot-2026-07-18.md)
for the production decision and final measurements.
