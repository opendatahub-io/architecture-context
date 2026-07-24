# Task: Batch Review Newly Eligible Components

## Goal

Review and approve (or reject) 11 components that became newly eligible
for analyzer-only routing after the shell script classification fix in
`categorycoverage.go`. Some of these are expected; others are surprising
and may be false positives.

## Context

The kube-auth-proxy task extended `isSupportOnlyShellScript()` to exclude
`contrib/`, `completions/`, `packaging/` directories and `build`/`dist`/
`make`/`package`/`release` basenames. This resolved "unsupported runtime
source languages" limitations across many components, causing 12 to become
eligible (1 already approved as kube-auth-proxy).

The 11 remaining unapproved eligible components include:
- Components previously blocked by specific gaps (MLServer, caikit,
  kubeflow-sdk, llm-d-kv-cache, llm-d-routing-sidecar, rhoai-mcp)
- Components previously classified as **permanent residuals** (notebooks,
  rhods-operator) — these MUST be scrutinized for false positives
- Components from the partial/legacy population that were never scoped
  for analyzer-only (caikit-tgis-backend, llama-stack-provider-trustyai-garak,
  pipelines-components)

## Source And Evidence

- Research note: `docs/notes/kube-auth-proxy-approval-research-2026-07-21.md`
- Validation note: `docs/notes/kube-auth-proxy-approval-validation-2026-07-21.md`
- Residual register: `docs/notes/analyzer-residual-agent-gaps.md`
- Approvals: `lib/analyzer_only_approvals.json`
- Adjudications: `lib/analyzer_correction_adjudications.json`
- Eligibility routing: `lib/architecture_routing.py`

## Target Components

### Previously blocked by specific gaps (6 components)

These were in the residual register with documented blockers. Verify
that their specific blockers are actually resolved, not just masked by
the shell script fix.

| Component | Prior blocker | Concern |
|-----------|---------------|---------|
| `MLServer` | 16 inbound gRPC, no auth facts (platform-delegated to KServe) | Was independently rejected TWICE for gRPC auth. How is it eligible now? Did the shell script fix remove the only limitation that was keeping auth partial? |
| `caikit` | 16 inbound gRPC, no auth facts (delegated to ModelMesh) | Same concern as MLServer |
| `kubeflow-sdk` | Uses setup.py, import analysis returns nothing | Was blocked on internal_dependencies (1 unresolved alias). How resolved? |
| `llm-d-kv-cache` | Python TokenizationService not seen by Go analyzer | Was blocked on auth (6 inbound surfaces) + kustomize gaps |
| `llm-d-routing-sidecar` | Kustomize template variables | Was blocked on auth (3 inbound surfaces) + kustomize + unresolved alias |
| `rhoai-mcp` | MCP handler extraction gap | Was blocked on auth (3 inbound surfaces) + 24 platform aliases + kustomize |

### Previously classified as permanent residuals (2 components)

These were formally documented as NEVER being analyzer-only. Their
eligibility is highly suspicious.

| Component | Permanent reason | Concern |
|-----------|-----------------|---------|
| `notebooks` | Non-runtime evidence model. 19 mutations from requirements.txt bundled-library inventory. No shipped application entrypoint. | If eligible, the eligibility system may be checking something different from what the permanent classification was about. |
| `rhods-operator` | Deliberate prose residual. Hierarchical lifecycle narrative not representable as structured facts. | Same — the permanent classification was about QUALITY of generation, not eligibility. May be technically eligible but wrong to approve. |

### Previously in partial/legacy population (3 components)

These were never scoped for analyzer-only. No prior audit exists.

| Component | Notes |
|-----------|-------|
| `caikit-tgis-backend` | Was in the evidence-gated partial population |
| `llama-stack-provider-trustyai-garak` | Was in the evidence-gated partial population |
| `pipelines-components` | Was in the evidence-gated partial population |

## Work

For EACH of the 11 components:

1. **Check architecture JSON**: Read `architecture/rhoai.next/<component>.json`
   and examine `category_coverage` for all three high-value categories
   (authentication, integration_points, internal_dependencies). Verify
   that each has either `status: "complete"` or is explained by a
   source-audited/contract-complete empty category entry.

2. **Check eligibility**: Run the eligibility check and confirm the
   component is genuinely eligible (not a routing bug).

3. **Assess quality**: For components that are technically eligible,
   determine whether approving them is correct:
   - Does the analyzer produce enough structured facts for a useful
     standalone document?
   - For permanent residuals (notebooks, rhods-operator): is eligibility
     correct, or should the permanent classification be updated?

4. **Approve or document**: For each component, either:
   - Add to `lib/analyzer_only_approvals.json` if genuinely eligible and
     correct to approve
   - Document why it should NOT be approved despite being eligible
   - Add source-audited empty category entries if needed

### Special handling for permanent residuals

For `notebooks` and `rhods-operator`, if the eligibility check passes
but the permanent classification reason still applies (prose quality,
evidence model mismatch), document whether:
- The eligibility system is correct (they meet the criteria) but the
  permanent classification was about generation quality, not eligibility
- OR the eligibility system has a gap (false positive)

If the former, they CAN be approved for analyzer-only routing even though
their docs may be less rich — the permanent classification was about a
different concern.

## Negative Controls

- Must not approve components without examining their full category
  coverage output.
- Must not approve if ANY high-value category has unresolved limitations
  (unless explained by source-audited or contract-complete entries).
- Must not approve permanent residuals without documenting why the
  permanent classification no longer applies or was about a different
  concern.
- Must not break existing coverage for 51 approved components.

## Acceptance Criteria

- [ ] Each of the 11 components examined with category coverage analysis
- [ ] Genuine eligibility verified (not routing bugs)
- [ ] Components approved where correct
- [ ] Components documented where NOT approved despite eligibility
- [ ] Permanent residual classifications reconciled
- [ ] 90-component replay: zero false nominations
- [ ] No regressions on 51 previously approved components
- [ ] Residual register updated with all dispositions
- [ ] Validation note written
- [ ] Task moved to `docs/tasks/done/`

## Likely Files

- `architecture/rhoai.next/*.json` (11 component files)
- `lib/analyzer_only_approvals.json`
- `lib/analyzer_correction_adjudications.json`
- `docs/notes/analyzer-residual-agent-gaps.md`

## Status

Done. 11 components reviewed against ANALYZER_ARCHITECTURE.md baseline.
9 were false positives (eligibility checked against agent-written markdown).
1 approved (kubeflow-sdk — 52nd component). 1 technically eligible but not
approved (rhods-operator — permanent residual for deliberate prose). 12
components remain ineligible with bounded correction gaps. See
[batch review validation](../notes/batch-eligible-review-validation-2026-07-21.md).
