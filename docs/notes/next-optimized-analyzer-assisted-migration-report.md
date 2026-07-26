# Next Optimized Analyzer-Assisted Migration Report

Date: 2026-07-26

## Conclusion

The optimized analyzer-sufficient route worked for a bounded `rhoai-mcp`
fixture: the agent used only pre-seeded analyzer evidence, read zero component
source files, made zero discovery calls, and produced valid architecture,
change, and insight artifacts. This supports continuing provisional migration
work, but one run is insufficient to claim a general performance improvement
or expand production rollout. The tracked allowlist remains empty.

## Method

The run used a writable copy of the real checkout at source revision `dabe473`
under the ignored temporary directory:

```text
tmp/analyzer-assisted-migration/migration-20260726-optimized-retry/
```

The analyzer baseline and component JSON were pre-seeded. The temporary
allowlist contained only `rhoai-mcp` during the run and was restored to its
empty tracked state by an exit trap.

The initial host SDK attempt used:

```text
UV_CACHE_DIR=/tmp/uv-cache uv run --env-file .env main.py generate-architecture \
  --platform=rhoai.next \
  --architecture-dir=tmp/analyzer-assisted-migration/migration-20260726-optimized/architecture \
  --component=rhoai-mcp --force --model=opus --max-concurrent=1 \
  --log-dir=tmp/analyzer-assisted-migration/migration-20260726-optimized/logs
```

It timed out during Claude SDK initialization after 100.3 seconds. It
produced no source reads or candidate and is recorded as an infrastructure
failure, not a migration result.

The retry used the stable container launcher and file prompt:

```text
scripts/run_claude_container.sh --prompt-file tmp/claude-task-prompt.md \
  > /tmp/claude-task-runs/agent-driver.jsonl 2>&1
```

The prompt explicitly selected `--analysis-route=synthesis`, prohibited
source/discovery reads, and required the pre-seeded output, change record, and
insight artifact. The candidate was then merged with:

```text
python3 scripts/rebase_architecture_synthesis.py \
  <ANALYZER_ARCHITECTURE.md> <rhoai-mcp.candidate.md> \
  <GENERATED_ARCHITECTURE.md> --evidence-gated \
  --changes <ARCHITECTURE_CHANGES.md> \
  --report-json <rhoai-mcp.merge.json> \
  --report-markdown <rhoai-mcp.merge.md> \
  --component rhoai-mcp --generated-by 'Claude Opus 4.6'
```

## Results

| Field | Result |
|---|---|
| Component | `rhoai-mcp` |
| Route | `synthesis` |
| Readiness | `sufficient` |
| Gap category | `authentication` |
| Baseline pre-seeded | yes |
| Source files read | 0 |
| Navigation reads | 3 |
| Discovery calls | 0 |
| Agent turns | 65 |
| Agent duration | 408.5s (6m 48.5s) |
| Reported cost | $4.83 |
| Merge | 0 applied, 2 rejected, 7 restored, 50 unchanged |
| Architecture validation | PASS |
| Insight validation | PASS; 3 insights |

The prior `rhoai-mcp` synthesis run recorded 44 turns, 42 tool calls, 20
denials, 16 reads, approximately 600 seconds, and $2.21. The new run shows the
intended route-boundary reduction in reads and denials. Its duration and cost
are not a controlled comparison because the agent performed additional test
and skill-review work during the run; no causal speed or cost claim is made.

## Artifacts

- Generated output: ignored temporary `rhoai-mcp/GENERATED_ARCHITECTURE.md`
- Candidate: ignored temporary `logs/rhoai-mcp.candidate.md`
- Merge reports: ignored temporary `logs/rhoai-mcp.merge.{json,md}`
- Insights: ignored temporary `rhoai-mcp/INSIGHTS_ARTIFACT.json`
- Human-readable report: this document

No raw logs, API dumps, OTel payloads, secrets, or committed `architecture/`
output were added.

## Limitations and next step

This was a single-component provisional route check. It does not establish
semantic quality, human review equivalence, external MLflow registration,
external-fetch OTel coverage, or permission to retire the legacy route. The
next step is another bounded multi-component provisional run using temporary
allowlist entries, followed by independent review before any tracked
allowlist expansion.
