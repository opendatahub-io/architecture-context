# Architecture Diagrams for TrustyAI Service Operator

Generated from: `architecture/rhoai-3.7-ea.1/trustyai-service-operator.md`
Date: 2026-11-10

**Note**: Diagram filenames use the base component name without a version, because the directory is already versioned.

**Scope**: The diagrams cover two deployables. The first is the workload operator (`odh-trustyai-service-operator-rhel9`); RHOAI enables its TAS, LMES, EVALHUB and NEMO_GUARDRAILS controllers, and JOB_MGR is off. The second is the platform component-module controller (`odh-trustyai-module-operator-rhel9`). The diagrams also show the operands the operator creates: the TrustyAI Service, EvalHub (with optional MCP), NeMo Guardrails and LMEvalJob pods. The deployment chain is rhods-operator → `TrustyAI` CR → module → operator Deployment → per-namespace operand CRs.

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./trustyai-service-operator-component.mmd) - Module, the operator's controllers, the conversion webhook, the five CRDs, operands and integrations
- [Data Flows](./trustyai-service-operator-dataflow.mmd) - Sequence diagram of platform enablement, TrustyAIService with KServe payload logging, EvalHub evaluation and LMEvalJob
- [Dependencies](./trustyai-service-operator-dependencies.mmd) - Internal RHOAI integrations, external runtime dependencies and Go libraries

### For Architects
- [C4 Context](./trustyai-service-operator-c4-context.dsl) - System context and containers in C4 format (Structurizr)
- [Component Overview](./trustyai-service-operator-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./trustyai-service-operator-security-network.mmd) - Trust zones: external, router, control plane, tenant namespaces and backing services. Unauthenticated or plaintext surfaces are highlighted.
- [Security Network Diagram (ASCII)](./trustyai-service-operator-security-network.txt) - Precise text format for SAR submissions, with RBAC, NetworkPolicies, secrets, TLS/FIPS and security observations
- [RBAC Visualization](./trustyai-service-operator-rbac.mmd) - Operator per-service ClusterRoles and the module's superset ClusterRole

## Key Security Points
- Every HTTP operand is fronted by kube-rbac-proxy on 8443/TCP with a service-CA certificate and an OpenShift Route using `reencrypt` termination. EvalHub authorizes each request with a namespaced SubjectAccessReview, taking the namespace from the `X-Tenant` header.
- The operator's ServiceAccount has cluster-wide permissions: secrets CRUD, `pods/exec`, and ClusterRoleBinding create/update. The module's ServiceAccount is the most privileged identity: it can manage CRDs, webhook configurations, and ClusterRole create/bind.
- These surfaces are plaintext or unauthenticated:
  - module metrics on 8080
  - EvalHub metrics on 8081
  - TAS Service port 80→8080
  - NeMo Service port 80→8000
  - TAS `/consumer/kserve/v2` on 4443, which is protected by NetworkPolicy only
- NeMo Guardrails without the `security.opendatahub.io/enable-auth: "true"` annotation runs with no kube-rbac-proxy and an `edge` Route.
- The NeMo kube-rbac-proxy hardcodes TLS 1.2. The other listeners follow the cluster APIServer TLS profile, and the default curve preference is PQC `X25519MLKEM768`.
- Operator egress is allow-all (tracked as HPSTRAT-278).

## How to Use

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown inside ```` ```mermaid ```` code blocks. They render automatically.
- **Live editor**: https://mermaid.live (paste the code, edit, export)
- **Editable**: Modify and regenerate as needed

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
- Suited to security reviews because the technical details are exact

## Updating Diagrams

To regenerate after architecture changes:
```bash
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/trustyai-service-operator.md --output-dir=architecture/rhoai-3.7-ea.1/diagrams
```
