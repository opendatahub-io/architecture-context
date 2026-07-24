# Analyzer Ownership Expansion

**Status**: Complete (2026-07-20)

## Goal

Iteratively expand `src/arch-analyzer` ownership of `rhoai.next` component
architecture generation until every analyzer-sufficient component is either safely
analyzer-only or has a documented, source-backed reason requiring an agent.

Maintain zero false analyzer-only nominations, complete analyzer-row preservation,
and all structural and synthesis-quality gates throughout the migration.

## Motivation

The accepted production workflow reduced wall time by 47.11%, but still invoked 75
component agents. Fifteen of 63 analyzer-sufficient components currently route
analyzer-only. The remaining sufficient components contain reusable extraction
opportunities mixed with genuinely dynamic or unsupported behavior.

The work should proceed as small, measured extractor tranches rather than another
large port. Each tranche must improve deterministic coverage or produce durable
evidence that the remaining behavior belongs to an agent.

## Scope

This goal covers:

- Structured facts in per-component `GENERATED_ARCHITECTURE.md` documents.
- Generic manifest, source-language, product-semantic, and normalization extractors.
- Category completeness contracts and analyzer-only routing.
- Corpus classification, bounded treatment matrices, and production quality gates.
- A residual register of agent-owned gaps.

This goal does not cover `PLATFORM.md` synthesis, architecture diagrams, or replacing
agent-written prose where deterministic evidence cannot support equivalent content.

## Iteration Loop

Each iteration must:

1. Select a small correction pattern using expected agent time/cost savings,
   frequency across the corpus, and extractor reusability.
2. Create a focused task file with source-backed examples and negative controls.
3. Implement repository-independent extraction or normalization. Do not add
   component-name exceptions to force analyzer-only eligibility.
4. Add unit, compatibility, renderer, routing, and regression tests appropriate to
   the changed surface.
5. Replay the 90-component static corpus and require zero false analyzer-only
   nominations against accepted structured corrections.
6. Run a bounded paid component matrix only when fresh routing changes or another
   production behavior cannot be established by replay.
7. Record route decisions, preservation, quality gates, agent count, wall time,
   cost, tools, reads, source files, and tokens.
8. Move the task to `docs/tasks/done/`, update the residual gap register, and select
   the next highest-value tranche.

## Current Queue

The classification task is complete. The ranked queue is derived from the
[prioritization report](../notes/analyzer-remaining-candidate-prioritization-2026-07-19.md)
and updated by the [completeness-only audit](../notes/completeness-only-candidate-audit-2026-07-19.md).

No remaining work items. The v1 migration is complete.

Completed queue items:

| Order | Work item | Result |
|------:|-----------|--------|
| 6 | [Finalize analyzer ownership migration v1](../tasks/done/finalize-analyzer-ownership-migration-v1.md) | Done. Reconciled all 64 components, approved llm-d-batch-gateway-operator (36→37), adjudicated 25 invalid evidence entries, created Python extraction task, validated 90-component production run (53 agents, 1546.70s, all gates pass), reduced skill, closed goal. |
| 5 | [Extract Python dynamic authentication middleware](../tasks/done/extract-python-dynamic-authentication-middleware.md) | Done. ASGI middleware registration, connected provider-factory, ABAC enforcement, semantic dedup. ogx 0→5 auth facts. Approved set unchanged at 36 (ogx blocked by Internal Dependencies). |
| — | [Extract model-registry KServe controller dependency](../tasks/done/extract-model-registry-kserve-controller-dependency.md) | Done. Generic KServe GVK mapping, generic watch-to-dependency fallback, alias scan improvements. Approved set 35 → 36. |
| 1 | [Extract eval-hub runtime boundaries](../tasks/done/extract-eval-hub-runtime-boundaries.md) | Done. Cross-file constructor reachability, delegated route registration. 3/8 resolved by analyzer, 5/8 adjudicated. Eval-hub not eligible; approved set unchanged at 36. |
| 3 | [Kubernetes manifest Authentication and dependencies](../tasks/done/extract-kubernetes-manifest-authentication-dependencies.md) | Done. Infrastructure API group RBAC-to-dependency for monitoring.coreos.com, cert-manager.io, gateway.networking.k8s.io. 3/27 resolved by analyzer, 24/27 adjudicated. Approved set unchanged at 36. |
| 4 | [ModelMesh runtime relationships](../tasks/done/extract-modelmesh-runtime-relationships.md) | Done. Outbound gRPC client detection, blank-import reachability, storage SDK constructors. 6/10 analyzer-resolved, 4/10 adjudicated. Approved set unchanged at 36. |

Two components (`notebooks`, `notebooks-downstream`) are classified as justified
agent residuals. Their 36 combined corrections derive from bundled-library
inventories in container image builds, not runtime service integration. See the
[residual register](../notes/analyzer-residual-agent-gaps.md).

The authoritative residual inventory is
[Analyzer Residual Agent Gaps](../notes/analyzer-residual-agent-gaps.md).

## Invariants

- Analyzer-only routing requires analyzer readiness and populated or recognized
  complete-empty high-value categories, plus an explicit corpus-validated rollout
  approval.
- Corpus replay must produce zero false analyzer-only nominations.
- Generated documents must retain 100% of analyzer-owned structured rows, except for
  explicitly adjudicated source-backed corrections.
- Unexplained populated-cell conflicts and missing analyzer rows are release blockers.
- Structural and synthesis-quality validation must pass for every generated document.
- Parse failures, unsupported relevant source, and unresolved dynamic behavior must
  remain visible limitations rather than inferred absence.
- Historical agent output is a regression fixture and discovery aid, not unquestioned
  ground truth.
- Full paid corpus runs are reserved for material route expansion or production
  questions that static replay and bounded matrices cannot answer.

## Completion Criteria

This goal is complete when:

- Every analyzer-sufficient component is analyzer-only or appears in a residual
  agent-gap register with exact source evidence and the unsupported behavior named.
- No remaining supported, reusable extractor tranche has a reasonable path to
  eliminating an agent invocation.
- The final 90-component replay has zero false nominations and passes preservation,
  structural, and synthesis gates.
- A final production run confirms the accepted routing policy and records actual
  agent count, wall time, cost, tools, reads, source files, and token usage.
- The component-summary skill describes only the residual agent responsibilities and
  no longer asks agents to rediscover analyzer-owned structured facts.

Conservative false negatives are acceptable at completion. Unsupported behavior must
not be reclassified as complete merely to increase the analyzer-only count.

## Baseline

The starting production reference is
`tmp/architecture-corpus-runs/rhoai-next-20260718T215431Z`:

| Measure | Baseline |
|---------|---------:|
| Components | 90 |
| Analyzer-sufficient components | 63 |
| Analyzer-only components | 15 |
| Agent invocations | 75 |
| Workflow wall time | 1903.90s |
| Reduction from one-hour reference | 47.11% |

The category-completeness replay established the initial safety boundary: 15 existing
nominations, zero new nominations, and zero false nominations.

The first ownership tranche increased the approved analyzer-only set to 17. See
[operator Authentication extraction validation](../notes/operator-authentication-extraction-validation-2026-07-19.md)
and the [residual agent-gap register](../notes/analyzer-residual-agent-gaps.md).

The trainer dependency tranche increased the approved set to 18. See
[trainer scheduler dependency validation](../notes/trainer-scheduler-dependency-validation-2026-07-19.md).

The controller Kubernetes API Authentication tranche increased the approved set to
19. See [controller Kubernetes API Authentication validation](../notes/controller-kubernetes-api-authentication-validation-2026-07-19.md).

The secure controller metrics Authentication tranche increased the approved set to
20. See [secure controller metrics Authentication validation](../notes/secure-controller-metrics-authentication-validation-2026-07-19.md).

The MaaS API Authentication tranche increased the approved set to 21. See
[MaaS API Authentication validation](../notes/maas-api-authentication-validation-2026-07-19.md).

The Feast service Authentication tranche increased the approved set to 22. See
[Feast service Authentication validation](../notes/feast-service-authentication-validation-2026-07-19.md).

The TrustyAI service Authentication tranche increased the approved set to 23. See
[TrustyAI service Authentication validation](../notes/trustyai-service-authentication-validation-2026-07-19.md).

The KubeRay Internal Platform Dependencies tranche increased the approved set to
24. See [KubeRay Internal Platform Dependencies validation](../notes/kuberay-internal-platform-dependencies-validation-2026-07-19.md).

The dynamic Kubernetes API dependency tranche increased the approved set to 25.
See [Dynamic Kubernetes API Dependencies validation](../notes/dynamic-kubernetes-api-dependencies-validation-2026-07-19.md).

The extended controller-runtime metrics Authentication tranche kept the approved
set at 25 while resolving two metrics rows and source-adjudicating three invalid
historical additions. See [Extended controller-runtime metrics Authentication validation](../notes/extended-controller-runtime-metrics-authentication-validation-2026-07-19.md).

The MCP lifecycle dependency-completeness tranche increased the approved set to 26.
It classified commented cert-manager scaffolding, support-only scripts, and
dependency-irrelevant Kustomize image rewrites without weakening active runtime or
selected-manifest evidence. See [MCP lifecycle Internal Dependency completeness validation](../notes/mcp-lifecycle-internal-dependency-completeness-validation-2026-07-19.md).

The Workbenches platform-projection tranche increased the approved set to 27. It
added typed CRD field-projection contracts with YAML line evidence, classified an
unused Kubeflow GVK declaration, and corrected an unsupported concrete orchestrator
owner attribution. See [Workbenches Platform Projection Dependencies validation](../notes/workbenches-platform-projection-dependencies-validation-2026-07-19.md).

The Workload Variant Autoscaler dependency tranche increased the approved set to
28. It normalized canonical platform GVK watches, preserved conditional controller
registration, extracted a constructed-and-used Prometheus client, and resolved
controller health listeners through repository-wide configuration bindings. See
[Workload Variant Autoscaler Platform Dependencies validation](../notes/workload-variant-autoscaler-platform-dependencies-validation-2026-07-19.md).

The Gateway API Inference Extension EPP tranche increased the approved set to 29.
It added runtime-reachable registered gRPC services, certificate-backed optional TLS
proofs, and typed CRD reference contracts while excluding conformance-only inbound
surfaces. See [Gateway API Inference Extension EPP validation](../notes/gateway-api-inference-extension-epp-validation-2026-07-19.md).

The shared llm-d EPP runtime-relationship tranche increased the approved set to 31.
It added converged model-serving metrics clients, standalone gRPC health and HTTP
metrics lifecycles, project-module ownership, and canonical EPP/ExtProc relationship
identities. See [shared llm-d EPP runtime relationships validation](../notes/shared-llm-d-epp-runtime-relationships-validation-2026-07-19.md).

The managed sub-component lifecycle tranche increased the approved set to 32. It
correlated CRD lifecycle schemas, registered manifest reconciliation, and selected
full-lifecycle RBAC, while correcting an unsupported historical secure-metrics
claim. See [managed sub-component lifecycle validation](../notes/managed-subcomponent-lifecycle-validation-2026-07-19.md).

The runtime data-service client tranche kept the approved set at 32 while resolving
four of eleven accepted `batch-gateway` corrections. A bounded Go call graph now
finds runtime-reachable PostgreSQL, Redis/Valkey, S3-compatible storage, and OTLP
client construction without accepting disconnected or receiver-colliding helpers.
See [runtime data-service client validation](../notes/runtime-data-service-clients-validation-2026-07-19.md).

The runtime command component tranche kept the approved set at 32 while resolving
or source-adjudicating three more `batch-gateway` corrections. Docker build targets,
runtime commands, and concrete Go entry points now identify shipped commands across
nine repositories without promoting examples, tools, tests, or redundant sole
binaries. See [runtime command component validation](../notes/runtime-command-components-validation-2026-07-19.md).

The runtime inference-gateway client tranche kept the approved set at 32 while
resolving two more `batch-gateway` corrections. A project-owned Resty wrapper now
requires executable reachability, runtime endpoint binding, concrete request
execution, one complete semantic ancestor, and llm-d module ownership. See
[runtime inference gateway client validation](../notes/runtime-inference-gateway-client-validation-2026-07-19.md).

The closed Go HTTP Authentication-boundary tranche increased the approved set to 33
and completed all eleven `batch-gateway` corrections. Repository-level mux analysis
now correlates helper-registered route inventories, complete local middleware
chains, returned handler fields, and invoked HTTP server lifecycles. It also corrected
the historical observability method set to source-derived `GET, HEAD`. See
[Go HTTP Authentication boundaries validation](../notes/go-http-authentication-boundaries-validation-2026-07-19.md).

The CLI Kubernetes runtime-boundary tranche increased the approved set to 34. The
fresh analyzer resolves all 3/3 accepted `odh-cli` additions, including OLM runtime
inspection and Kubernetes API credential/RBAC preflight behavior. The bounded matrix
invoked zero agents and passed all gates in 3.54 seconds. See
[CLI Kubernetes runtime boundaries validation](../notes/cli-kubernetes-runtime-boundaries-validation-2026-07-19.md).

The completeness-only candidate audit kept the approved set at 34. All three
candidates (guardrails-regex-detector, model-registry, ogx) retain false-candidate
status: Integration Points lacks a discovery contract, model-registry has a missed
KServe dependency, and ogx has dynamic Python auth the analyzer cannot extract.
Three focused tasks were created. See
[completeness-only candidate audit](../notes/completeness-only-candidate-audit-2026-07-19.md).

The Integration Points discovery contract tranche increased the approved set to 35.
It added the `integration-points/v1` bounded contract using existing RuntimeClient
and ExternalConnection extractor outputs, enabling `guardrails-regex-detector` as a
standalone Rust service with proven zero outbound connections. See
[Integration Points discovery contract validation](../notes/integration-points-discovery-contract-validation-2026-07-19.md).

The model-registry KServe controller dependency tranche increased the approved set
to 36. It added generic KServe package-path GVK mapping, a generic
`resourceGroups` fallback for watch-to-dependency conversion, and improved alias
scan classification (subdomain, Go identifier, and mock/sample directory
exclusions). All three improvements are repository-independent. See
[model-registry KServe controller dependency validation](../notes/model-registry-kserve-controller-dependency-validation-2026-07-19.md).

The eval-hub runtime boundaries tranche kept the approved set at 36. It added
cross-file constructor reachability for metrics server detection and delegated
route registration for conditional identity enforcement classification. Three of
eight corrections are now resolved by the analyzer; five are source-adjudicated
(single CMD binary, helper without lifecycle, Go interface dispatch, comment-only
proxy, implicit metrics auth). Eval-hub is not eligible due to structural
`architecture_components` and `internal_dependencies` gaps. See
[eval-hub runtime boundaries validation](../notes/eval-hub-runtime-boundaries-validation-2026-07-19.md).

The Python dynamic authentication middleware tranche kept the approved set at 36.
It added ASGI middleware registration detection, connected provider-factory
extraction, and operation-gating ABAC enforcement for Python servers. ogx gained
5 authentication facts (middleware, 2 providers, 2 ABAC surfaces) with
configuration-conditional policy preservation and semantic deduplication. ogx
remains ineligible due to an independent Internal Dependencies completeness
blocker. No other component's authentication facts changed. See
[Python dynamic authentication middleware validation](../notes/python-dynamic-authentication-middleware-validation-2026-07-20.md).

The Kubernetes manifest authentication and dependencies tranche kept the approved
set at 36. It added generic RBAC-to-dependency extraction for
`monitoring.coreos.com`, `cert-manager.io`, and `gateway.networking.k8s.io` to the
`resourceGroups` map. Three of twenty-seven corrections are resolved by the analyzer;
twenty-four are source-adjudicated (eight as invalid historical evidence failing
negative controls, sixteen as valid-but-unsupported extraction capabilities). No
target component is newly eligible. See
[Kubernetes manifest authentication dependencies validation](../notes/kubernetes-manifest-authentication-dependencies-validation-2026-07-20.md).

The v1 closeout increased the approved set to 37 (llm-d-batch-gateway-operator),
adjudicated 25 invalid historical corrections from non-production directories,
reconciled all 64 analyzer-sufficient components with source-backed dispositions,
identified one remaining reusable extraction tranche (Python runtime source
surfaces), reduced the skill to prohibit structured-fact rediscovery on sufficient
routes, and validated the final routing policy in a 90-component production run
(53 agents, 1546.70s wall time, $69.61 cost, all gates pass). See
[Analyzer ownership migration v1 milestone](../milestones/analyzer-ownership-migration-v1.md).

## Related Work

- [Component analyzer migration](../plans/component-analyzer-migration.md)
- [Analyzer category completeness](../plans/analyzer-category-completeness.md)
- [Category completeness validation](../notes/analyzer-category-completeness-validation-2026-07-19.md)
- [Analyzer-only full-corpus validation](../notes/analyzer-only-full-corpus-production-validation-2026-07-18.md)
