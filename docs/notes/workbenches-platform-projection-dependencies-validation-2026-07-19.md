# Workbenches Platform Projection Dependencies Validation, 2026-07-19

## Decision

Approve `workbenches-operator` for analyzer-only component generation. The analyzer
now parses explicit CRD OpenAPI field-projection contracts as typed facts with
field-level YAML source evidence.

The selected Workbenches CRD proves that a platform orchestrator projects
`gatewayDomain`, `mlflowEnabled`, and `platform`; `GatewayConfig` supplies the first
value, and DSC `MLflowOperator` state supplies the second. The repository does not
identify the generic platform orchestrator as the `rhods-operator` process, so that
historical owner attribution is source-adjudicated instead of copied.

The dependency scan also found a package-level
`kubeflow.org/v1 Notebook` `schema.GroupVersionKind`. Repository-wide AST usage
inspection proves the declaration is unused, so it is classified as negative
evidence and does not create a runtime dependency.

## Generic Extraction

- Selected CRD OpenAPI schemas are walked as structured YAML objects.
- Only the explicit phrase `Projected by ...` creates a field-projection fact;
  ordinary prose mentioning an orchestrator is a negative control.
- The raw projector, upstream source, CRD identity, field path, description, and YAML
  line are retained in analyzer JSON.
- Explicit `GatewayConfig` and `MLflowOperator` projection sources normalize to
  internal dependency rows without a component-name rule.
- Package-level literal GVK declarations are classified as unused only after a
  repository-wide Go AST reference inventory. Used GVK values remain blocking.
- Generated and test Go sources do not establish runtime alias relationships.

## Full Static Replay

Artifacts:
`tmp/architecture-corpus-runs/rhoai-next-workbenches-projections-static-20260719T133450Z`

| Measure | Result |
|---------|-------:|
| Components analyzed | 90 |
| Static-analysis failures | 0 |
| Static-analysis wall time | 12.79s |
| Analyzer-sufficient components | 63 |
| Approved analyzer-only components | 27 |
| Newly approved components | 1 |
| False nominations | 0 |
| Target corrections resolved or adjudicated | 6/6 |
| Analyzer identities retained | 8,359/8,364 (99.94%) |
| Accepted analyzer conflicts | 16 |
| Accepted analyzer row corrections | 5 |
| Unexplained analyzer conflicts | 0 |
| Unexplained missing analyzer rows | 0 |
| Structurally valid documents | 90/90 |
| Synthesis/structure quality | 90/90 |
| Required gates | PASS |

The accepted-production fixture retains 9,135/9,157 structured identities
(99.76%). The one additional mismatch is intentional: `Platform orchestrator`
replaces the unsupported historical `rhods-operator (Platform Orchestrator)` owner.

The approved set projects 27 avoided agent invocations, $12.0720 in historical
cost, 2,450.17 summed agent seconds, 100 reads, 48 source files, and 113,720 output
tokens.

## Production-Path Matrix

Artifacts:
`tmp/architecture-corpus-runs/rhoai-next-workbenches-projections-matrix-20260719T134000Z`

| Measure | Result |
|---------|-------:|
| Components | 1 |
| Analyzer-only routes | 1 |
| Agent invocations | 0 |
| Analyzer identities retained | 50/50 |
| Historical structured recall | 43/45 (95.56%) |
| Structural validation | 1/1 |
| Synthesis/structure quality | 1/1 |
| Required gates | PASS |
| Workflow wall time | 2.54s |

## Verification

- `GOCACHE=/tmp/arch-analyzer-go-cache go test ./...`: pass.
- `.venv/bin/ruff check .`: pass.
- `.venv/bin/pytest -q --ignore=tests/test_strace_agent.py`: 123 passed.
- `git diff --check`: pass.
