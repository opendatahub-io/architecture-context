# Analyzer-First Summary Test: rhods-operator and odh-dashboard

Date: 2026-07-26
Task: `docs/tasks/done/test-analyzer-first-summary-on-operator-and-dashboard.md`
Run artifacts: ignored `tmp/analyzer-first-rhods-dashboard/`

## Conclusion

The analyzer-first synthesis route worked for both RHOAI 3.5 components with
zero agent source reads and zero grep/search patterns. Both outputs passed the
architecture validator. This demonstrates the intended inspection reduction;
it does not establish semantic quality, full rollout, or legacy retirement.

## Results

| Component | Readiness / route | Duration | Agent source reads | Validation |
|---|---|---:|---:|---|
| `rhods-operator` | sufficient / synthesis | 252s | 0 | PASS |
| `odh-dashboard` | sufficient / synthesis | 237s | 0 | PASS, 1 informational warning |

The run used fresh temporary `arch-analyzer extract` and `render` outputs,
then pre-seeded `GENERATED_ARCHITECTURE.md` before invoking the skill with
`--readiness=sufficient --analysis-route=synthesis --baseline-preseeded`.
The agent reported 107,086 and 110,747 tokens respectively; total container
cost was `$11.7130` over approximately 598 seconds. No MLflow tracking was
needed for this focused test.

Compared with the prior broad-route measurements, the analyzer-first route
used 0 versus 97 source files/13 grep patterns for `rhods-operator`, and 0
versus 49 source files/11 grep patterns for `odh-dashboard`. Analyzer-derived
integration and RBAC rows were more numerous than the prior manually-read
outputs, but this is an observation, not a causal quality claim.

## Validation and provenance

- `validate_architecture.py` passed both outputs; dashboard emitted one
  informational warning for an analyzer-produced `Admission Webhooks` section.
- Output source-reference file sets were preserved from the analyzer baseline,
  with one additional analyzer-JSON-backed `rhods-operator` reference.
- All generated files, timing data, and reports remain under ignored `tmp/`.
- No committed architecture output, source checkout, raw log, API dump, OTel
  payload, or secret changed.

## Limitations and follow-up

The pre-existing checkout JSON artifacts use a schema shape incompatible with
the current binary (`resource_ops.source` differs). Fresh extraction was
therefore required. `arch-analyzer extract --distribution rhoai.next` also
failed with `no kustomization matches distribution`, so the fresh extraction
used the default distribution and may omit distribution-specific overlays.
The synthesis route intentionally leaves provenance lineage, deployment
manifests, multi-tenancy, FIPS, and build-hermeticity sections unresolved when
the analyzer does not extract them; partial or legacy routing remains
available for those gaps.
