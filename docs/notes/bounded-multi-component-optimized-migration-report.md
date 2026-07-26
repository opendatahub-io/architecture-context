# Bounded Multi-Component Optimized Migration Report

Date: 2026-07-26

## Conclusion

The optimized route contract survived a three-component provisional matrix:
synthesis, partial, and legacy routes all completed. Synthesis used three
navigation reads and no source reads; partial used five bounded Python source
reads; legacy performed the expected full analysis. All generated architecture
documents passed validation, and both restricted-route insight artifacts
validated.

This is sufficient to continue provisional migration work. It is not evidence
for semantic equivalence, human-review success, external observability, or
legacy retirement. The tracked synthesis allowlist remains empty.

## Component matrix

| Component | Readiness | Route | Files read | Duration | Result |
|---|---|---|---:|---:|---|
| `rhoai-mcp` | sufficient | synthesis | 3 navigation files; 0 source | 97s | architecture, merge, insights valid |
| `caikit-nlp` | partial | partial | 3 baseline + 5 bounded Python files | 106s | architecture, merge, insights valid |
| `trustyai-service` | unknown | legacy | 41 source files (~8,500 lines) | 585s | full architecture valid |

Aggregate agent duration was approximately **788 seconds (13.1 minutes)**;
the reported container run cost was **$5.98**. These are run measurements,
not a controlled benchmark comparison.

## Route evidence

### Synthesis: `rhoai-mcp`

- Pre-seeded baseline consumed.
- Three navigation reads: generated output, analyzer baseline, and analyzer
  JSON.
- Zero component source, manifest, README, or `CLAUDE.md` reads.
- Zero discovery calls; two Bash calls were reported as timing-only by the
  agent and did not inspect repository content.
- Merge: 94 applied, 84 rejected, 48 restored, 14 unchanged.
- Insight artifact: 3 insights, valid.

### Partial: `caikit-nlp`

- Pre-seeded baseline consumed.
- Five bounded Python-specific source reads.
- One Bash `ls` call violated the requested Glob-only discovery preference;
  this was recorded in the component change record and did not broaden the
  source-read set.
- Merge: 59 applied, 45 rejected, 32 restored, 20 unchanged.
- Insight artifact: 2 insights, valid.

### Legacy: `trustyai-service`

- Unknown readiness correctly used the legacy route.
- Full analysis read 41 source files, approximately 8,500 lines.
- Generated architecture passed validation.
- No restricted-route insight artifact was required.

## Validation

Independent system-level checks passed for all three architecture documents:

```text
python3 .claude/skills/repo-to-architecture-summary/scripts/validate_architecture.py
  rhoai-mcp: VALIDATION PASSED
  caikit-nlp: VALIDATION PASSED
  trustyai-service: VALIDATION PASSED

load_insight_artifact()
  rhoai-mcp: 0 errors, 3 insights
  caikit-nlp: 0 errors, 2 insights
```

The container agent reported 76 focused route/phase tests and 185 broader
related tests passing. Host-side pytest was unavailable after the container
run recreated the ignored `.venv`; an offline rebuild was blocked by an
uncached `claude-agent-sdk` wheel and unavailable DNS. This environment issue
does not affect the independent artifact validators or the tracked source
diff.

## Artifacts and protections

All run artifacts remain under the ignored directory:

```text
tmp/analyzer-assisted-migration/migration-20260726-matrix/
```

No committed `architecture/` output, raw logs, API dumps, OTel payloads, or
secrets were added. The temporary allowlist was restored to its empty tracked
state.

## Recommendation and remaining gates

Continue with provisional evaluation and bounded migration review, but keep
the tracked allowlist empty until the matrix outputs receive independent
acceptance. Full rollout still requires the external MLflow registration,
external-fetch OTel producer, human root-cause adjudication, and human
semantic calibration gates documented in the architecture plan. The legacy
route remains active.
