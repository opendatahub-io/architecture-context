# MCP Lifecycle Internal Dependency Completeness Validation, 2026-07-19

## Decision

Approve `mcp-lifecycle-operator` for analyzer-only component generation. Its
`internal-platform-dependencies/v1` contract is source-backed complete-empty rather
than inferred from historical prose.

The repository-wide scan inspected 80 runtime source/config files against 23
platform aliases. The only match is `cert-manager.io` in
`config/default/kustomization.yaml`; every occurrence belongs to commented
Kubebuilder scaffolding and is not selected by the active Kustomize configuration.
The shell files under `.devcontainer` and `hack/mkdocs` are development and
documentation tooling, not deployed runtime surfaces. The unresolved Kustomize
image rewrite changes an already-selected container artifact but cannot select a
resource or establish an API relationship, so it does not block dependency
completeness.

## Generic Contract Changes

- Platform-alias evidence is classified as commented configuration, self-owned API,
  dependency declaration, selected or unselected manifest configuration, or runtime
  source/config evidence.
- Active selected-manifest and runtime references remain blocking unless represented
  by a normalized dependency fact.
- Support-only `.devcontainer` and documentation scripts are excluded, while
  deployment, entrypoint, hook, and operator scripts remain runtime surfaces.
- Kustomize warnings affect dependency completeness only when they can change
  resource selection or relationships. Image rewrites are an explicit negative
  control; remote resources, patches, replacements, generators, and similar
  unresolved behavior remain blocking.
- No component-name exception or historical standalone assertion is used.

## Full Static Replay

Artifacts:
`tmp/architecture-corpus-runs/rhoai-next-mcp-dependencies-static-20260719T131146Z`

| Measure | Result |
|---------|-------:|
| Components analyzed | 90 |
| Static-analysis failures | 0 |
| Static-analysis wall time | 12.72s |
| Analyzer-sufficient components | 63 |
| Approved analyzer-only components | 26 |
| Newly approved components | 1 |
| False nominations | 0 |
| Target corrections resolved | 3/3 |
| Analyzer identities retained | 8,353/8,358 (99.94%) |
| Accepted analyzer conflicts | 16 |
| Accepted analyzer row corrections | 5 |
| Unexplained analyzer conflicts | 0 |
| Unexplained missing analyzer rows | 0 |
| Structurally valid documents | 90/90 |
| Synthesis/structure quality | 90/90 |
| Required gates | PASS |

The accepted-production fixture retains 9,136/9,157 structured identities
(99.77%). The approved set projects 26 avoided agent invocations, $11.2777 in
historical cost, 2,248.77 summed agent seconds, 93 reads, 44 source files, and
104,245 output tokens. Estimated ten-worker agent wall avoidance is 264.46 seconds.

## Production-Path Matrix

Artifacts:
`tmp/architecture-corpus-runs/rhoai-next-mcp-dependencies-matrix-20260719T132000Z`

| Measure | Result |
|---------|-------:|
| Components | 1 |
| Analyzer-only routes | 1 |
| Agent invocations | 0 |
| Analyzer identities retained | 80/80 |
| Structural validation | 1/1 |
| Synthesis/structure quality | 1/1 |
| Required gates | PASS |
| Workflow wall time | 2.55s |

## Verification

- `GOCACHE=/tmp/arch-analyzer-go-cache go test ./...`: pass.
- `.venv/bin/ruff check .`: pass.
- `.venv/bin/pytest -q --ignore=tests/test_strace_agent.py`: 123 passed.
- `git diff --check`: pass.
