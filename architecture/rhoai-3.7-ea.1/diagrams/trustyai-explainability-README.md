# Architecture Diagrams for TrustyAI Explainability

Generated from: `architecture/rhoai-3.7-ea.1/trustyai-explainability.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned).

**Scope**: The repo ships one product image, `odh-trustyai-service` (Quarkus, Java 17), plus the Java libraries `explainability-core`, `-connectors` and `-arrow`. In RHOAI 3.7-ea.1, trustyai-service-operator deploys the Python `odh-trustyai-service-py` image instead, so this Java service looks superseded. Operator-managed sidecars and Services are shown for reference. The in-repo manifests are legacy and labeled as such. Explainer endpoints are disabled in the `%rhoai` profile and appear dashed.

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./trustyai-explainability-component.mmd) - Service internals (consumers, reconcilers, storage, scheduler, publisher, explainers), library modules, integrations
- [Data Flows](./trustyai-explainability-dataflow.mmd) - Sequence diagram: ModelMesh ingestion, KServe CloudEvent ingestion, scheduled metrics + Prometheus scrape, explainer gRPC
- [Dependencies](./trustyai-explainability-dependencies.mmd) - Bundled libraries, external runtime deps, internal RHOAI integrations, storage backends

### For Architects
- [C4 Context](./trustyai-explainability-c4-context.dsl) - System context and containers in C4 format (Structurizr)
- [Component Overview](./trustyai-explainability-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./trustyai-explainability-security-network.mmd) - Trust zones, kube-rbac-proxy vs. internal proxy, plaintext legacy Route, egress
- [Security Network Diagram (ASCII)](./trustyai-explainability-security-network.txt) - Precise text format for SAR submissions, with Services, RBAC, secrets and security observations
- [RBAC Visualization](./trustyai-explainability-rbac.mmd) - Legacy cluster-wide ConfigMap ClusterRole and runtime proxy authorization

## Key Security Points
- The service itself does no authN/authZ. Access control comes entirely from operator-injected kube-rbac-proxy sidecars (8443 with Bearer/SAR).
- The internal proxy on 4443 bypasses auth for `/`, `/consumer/kserve/v2` and `/q/health/*`. Any in-cluster client that can reach it can inject inference data, and no NetworkPolicy is shipped.
- Explainer gRPC to model servers is plaintext (`usePlaintext()`). Targets are restricted to same-namespace short hostnames.
- The legacy manifests have a plaintext Route (`tls: null`), an HTTP ServiceMonitor scrape and a cluster-wide ConfigMap CRUD ClusterRole.
- DB credentials default to `quarkus/quarkus` when env vars are absent. Hibernate schema mode is `update`.

## How to Use

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ```` ```mermaid ```` code blocks - renders automatically!
- **Live editor**: https://mermaid.live (paste code, edit, export)
- **Editable**: Modify and regenerate if needed

**Manual PNG generation** (if needed):
```bash
npm install -g @mermaid-js/mermaid-cli
PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i diagram.mmd -o diagram.png -w 3000
```

### C4 Diagrams (.dsl files)
- **Structurizr Lite**: `docker run -p 8080:8080 -v .:/usr/local/structurizr structurizr/lite`
- **CLI export**: `structurizr-cli export -workspace diagram.dsl -format png`

### ASCII Diagrams (.txt files)
- View in any text editor
- Include in documentation as-is
- Perfect for security reviews (precise technical details)

## Updating Diagrams

To regenerate after architecture changes:
```bash
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/trustyai-explainability.md
```
