# Task: Approve Source-Audited Empty Category Components

## Goal

Source-audit and approve NeMo-Guardrails and llm-d-latency-predictor by
adding `source_audited_empty_categories` entries to
`lib/analyzer_correction_adjudications.json` for categories that are
provably legitimately empty.

## Context

The Python import→category coverage wiring task (Task 8) confirmed that
these two components have category gaps that are legitimately empty — no
platform packages or SDK clients exist in their shipped source. The
validation note at `docs/notes/python-import-category-wiring-validation-2026-07-21.md`
documents this finding (lines 93-99).

The `source_audited_empty_categories` mechanism is well-established:
8 entries already exist for 5 components (caikit-tgis-serving,
argo-workflows, distributed-workloads, trustyai-explainability,
modelmesh-runtime-adapter). The eligibility system at
`lib/architecture_routing.py` (line 289) unions these with
contract-complete empty categories to form the `explained` set.

This is a zero-code task — no Go changes needed. Just source audit,
adjudication entries, approval, and validation.

## Source And Evidence

- Validation note: `docs/notes/python-import-category-wiring-validation-2026-07-21.md`
- Residual register: `docs/notes/analyzer-residual-agent-gaps.md`
- Adjudications: `lib/analyzer_correction_adjudications.json`
- Approvals: `lib/analyzer_only_approvals.json`
- Eligibility routing: `lib/architecture_routing.py`

## Target Components

| Component | Empty categories to audit | Prior evidence |
|-----------|--------------------------|----------------|
| `NeMo-Guardrails` | `internal_dependencies` | No Python packages map to platform components. Zero kubeflow/kserve/ray/cert-manager references in shipped source. SDK client (Azure OpenAI) already resolved. Auth already has facts. |
| `llm-d-latency-predictor` | `integration_points`, `internal_dependencies` | No platform or SDK packages used in shipped source. Auth resolved (absence-of-auth fact). No outbound runtime clients or external connections detected. |

## Work

1. **Source audit NeMo-Guardrails `internal_dependencies`**: Verify that
   no platform aliases (from `platformfacts.InternalDependencyDiscoveryAliases()`)
   appear in runtime source files. Check the category coverage output in the
   component's architecture JSON to confirm `status: "complete"` with
   `fact_count: 0` or that the only limitation is the empty category itself.

2. **Source audit llm-d-latency-predictor `integration_points` and
   `internal_dependencies`**: Same verification. Confirm no outbound clients,
   no external connections, no platform aliases in runtime source.

3. **Add `source_audited_empty_categories` entries**: For each verified
   empty category, add an entry to
   `lib/analyzer_correction_adjudications.json` following the existing
   format (component, category, reason, evidence array).

4. **Add approvals**: Add both components to `lib/analyzer_only_approvals.json`.

5. **Validate**: Run a fresh 90-component replay. Verify both components
   route as `analyzer-only`. Verify zero false nominations and no
   regressions on the 47 previously approved components.

6. **Update documentation**: Update the residual register, write a
   validation note, move this task to `docs/tasks/done/`.

## Negative Controls

- Must not add source-audited entries without verifying the component's
  architecture JSON category coverage output.
- Must not approve if the category coverage shows blocking limitations
  beyond the empty category itself.
- Must not add entries for categories that have facts (fact_count > 0).

## Acceptance Criteria

- [ ] Source audit confirms `internal_dependencies` is legitimately empty
  for NeMo-Guardrails.
- [ ] Source audit confirms `integration_points` and `internal_dependencies`
  are legitimately empty for llm-d-latency-predictor.
- [ ] `source_audited_empty_categories` entries added with evidence arrays.
- [ ] Both components added to `lib/analyzer_only_approvals.json`.
- [ ] 90-component replay: zero false nominations, both route analyzer-only.
- [ ] No regressions on 47 previously approved components.
- [ ] Validation note written.
- [ ] Residual register updated.
- [ ] Task moved to `docs/tasks/done/`.

## Likely Files

- `lib/analyzer_correction_adjudications.json`
- `lib/analyzer_only_approvals.json`
- `docs/notes/analyzer-residual-agent-gaps.md`

## Status

Done. See [validation note](../notes/source-audited-empty-categories-validation-2026-07-21.md).
