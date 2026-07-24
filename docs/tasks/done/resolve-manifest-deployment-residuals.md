# Task: Resolve Manifest/Deployment Residuals

## Goal

Resolve or source-adjudicate the 18 unresolved mutations across 4 components
whose remaining gaps require deeper manifest analysis capabilities than the
generic Kubernetes manifest extraction contracts provide.

## Context

The original manifest extraction task
(`docs/tasks/done/extract-kubernetes-manifest-authentication-dependencies.md`)
resolved 3/27 mutations by analyzer and adjudicated 24/27. The 18 mutations
remaining here were not addressed because they require capabilities beyond
generic manifest parsing:

- Init container behavior extraction
- Annotation-based service discovery (Prometheus scraping)
- Python env-var to runtime client correlation
- Kustomize template variable resolution
- Java/Quarkus HTTP endpoint extraction (unsupported language)

Some of these gaps may be permanently unsupported (Java/Quarkus), making
certain components permanent agent residuals for specific categories.

## Source And Evidence

- Eligibility report:
  `tmp/architecture-corpus-runs/rhoai.next-20260720T173035Z-static/reports/eligibility-v1.json`
- Residual register: `docs/notes/analyzer-residual-agent-gaps.md`
- Adjudications: `lib/analyzer_correction_adjudications.json`
- Prior manifest task:
  `docs/tasks/done/extract-kubernetes-manifest-authentication-dependencies.md`

## Target Components

| Component | Mutations | Evidence | Blocker |
|-----------|----------:|----------|---------|
| `trustyai-explainability` | 7 | `explainability-service/manifests/base/trustyai-deployment.yaml` | Java/Quarkus probe handlers (`/q/health/live`, `/q/health/ready`); init container config-map-overrider with KServe URL template; annotation-based Prometheus (`prometheus.io/scrape`); Route with `tls: null` |
| `llm-d-planner` | 6 | `deploy/kubernetes/backend.yaml`, `deploy/kubernetes/gpu-reader-rbac.yaml` | Python env-var service bindings (PostgreSQL `DATABASE_URL`, Ollama `OLLAMA_HOST`); optional credentials (Vertex AI, OpenAI, HF, Model Catalog); RBAC-to-K8s-API dependency; Service-CA annotation |
| `rhoai-mcp` | 3 | `deploy/kustomize/base/deployment.yaml`, `src/mcp_server.py` | Python MCP framework `@mcp.custom_route` handler-to-probe correlation; ServiceAccount RBAC |
| `llm-d-routing-sidecar` | 2 | `deploy/common/patch-statefulset.yaml`, `deploy/openshift/patch-route.yaml` | Unresolved kustomize template variables (`${project_name}`); absence-only TLS evidence |

## Extraction Contracts

1. **Init container behavior**: Detect init containers in Deployment manifests
   that write ConfigMaps or configuration files. Correlate init container
   commands with downstream resource dependencies.

2. **Annotation-based service discovery**: Detect `prometheus.io/scrape`,
   `prometheus.io/port`, and `prometheus.io/path` annotations on Service
   resources. Emit Integration Point facts for Prometheus monitoring.

3. **Concrete env-var endpoint correlation**: For env vars containing concrete
   service endpoints (e.g., `postgresql://...@postgres:5432/planner`), emit
   Integration Point facts. Distinguish concrete endpoints from optional
   credential-only variables.

4. **RBAC-to-dependency correlation**: For ClusterRole/Role grants on specific
   API groups and resources, emit Internal Dependency facts when the RBAC
   proves Kubernetes API access patterns.

5. **Service-CA annotation**: Detect
   `service.beta.openshift.io/inject-cabundle` annotation on ConfigMap
   volumes. Emit Internal Dependency on OpenShift Service CA Operator.

### Likely Adjudications

- `trustyai-explainability` Java/Quarkus probe handlers: source-adjudicate
  as unsupported language. The probe-authentication contract requires a
  discovered HTTP handler; Java handler extraction is not implemented.
- `llm-d-routing-sidecar` kustomize template variables: source-adjudicate
  as unresolved template identity. Absence-only TLS evidence is already a
  negative control.
- `llm-d-planner` credential-only env vars (HF_TOKEN, OPENAI_API_KEY,
  MODEL_CATALOG_TOKEN): source-adjudicate per existing negative control
  that rejects credential-only integration evidence.

## Negative Controls

- Must not accept credential-only env vars as proof of integration.
- Must not infer authentication from absence of TLS configuration.
- Must not accept unresolved kustomize template variables as identities.
- Must not treat ConfigMap references as platform dependencies.
- Must not accept init container commands without evidence of what they
  produce.
- Must not correlate Java/Quarkus source without Java extraction support.
- Must not accept analyzer baseline output as source evidence.

## Acceptance Criteria

- [ ] Source-audit all 18 mutations and record invalid or overstated rows
  as explicit adjudications.
- [ ] Implement extraction contracts for resolvable patterns (annotation
  discovery, concrete env-var endpoints, RBAC-to-dependency, Service-CA).
- [ ] Add unit tests for each new contract with positive and negative cases.
- [ ] Preserve all existing tests.
- [ ] Run `go test ./...` and `go vet ./...` in `src/arch-analyzer`.
- [ ] Run Ruff and the Python suite for affected routing/rendering behavior.
- [ ] Run a fresh 90-component replay with zero false nominations.
- [ ] Add approval only after the fresh replay proves eligibility.
- [ ] Run a bounded one-component production matrix if approval changes
  routing.
- [ ] Write a validation note, update the residual register, and move this
  task to `docs/tasks/done/`.

## Likely Files

- `src/arch-analyzer/internal/extractor/` (manifest correlation)
- `src/arch-analyzer/internal/extractor/categorycoverage.go`
- `src/arch-analyzer/internal/normalize/normalize.go`
- `src/arch-analyzer/internal/platformfacts/platformfacts.go`
- `lib/analyzer_correction_adjudications.json`

## Status

Pending.
