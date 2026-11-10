# Architecture Diagrams for Models-as-a-Service (MaaS)

Generated from: `architecture/rhoai-3.7-ea.1/models-as-a-service.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned).

**Scope**: maas-controller (operator + validating webhooks), maas-api (per-tenant REST API and Authorino callbacks), optional maas-discovery, the cleanup CronJob and revocation Jobs, plus the operands the controller deploys (payload-processing ext_proc, usage-logs tenancy proxy). Gateway, Authorino, Limitador, KServe and external providers are shown as surrounding systems.

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./models-as-a-service-component.mmd) - controller reconcilers, maas-api public/internal/cleanup surfaces, MaaS CRDs, generated Kuadrant/Istio/Gateway API/llm-d resources, deployed operands
- [Data Flows](./models-as-a-service-dataflow.mmd) - Sequence diagram: inference with API key, API key creation, tenant reconcile, key cleanup and tenant revocation
- [Dependencies](./models-as-a-service-dependencies.mmd) - RHCL/Kuadrant, Istio, Gateway API, PostgreSQL, internal RHOAI integrations, key Go libraries

### For Architects
- [C4 Context](./models-as-a-service-c4-context.dsl) - System context and containers in C4 format (Structurizr)
- [Component Overview](./models-as-a-service-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./models-as-a-service-security-network.mmd) - Trust zones, ports, TLS and auth per hop; fail-open ext_proc and unauthenticated internal callbacks highlighted
- [Security Network Diagram (ASCII)](./models-as-a-service-security-network.txt) - Precise text format for SAR submissions, including RBAC summary, webhooks, mesh config, secrets, crypto/FIPS
- [RBAC Visualization](./models-as-a-service-rbac.mmd) - Service accounts, bindings, roles and API resources; high-privilege grants (RBAC CRUD, cluster-wide Secret read) highlighted

## Key Security Callouts

- `/internal/v1/api-keys/validate` and `/internal/v1/subscriptions/select` have no caller authentication. NetworkPolicy is the only protection.
- On the gateway → maas-api and gateway → payload-processing hops, the DestinationRules use `tls.mode: SIMPLE` with `insecureSkipVerify: true` (RHOAIENG-61070).
- maas-api egress is allow-all unless `Config.networkPolicyEgressRules` is set.
- The pre-auth ext_proc stage `ipp-pre` is fail-open. The post-auth stage `ipp` is fail-closed.
- The maas-controller ClusterRole can create and delete RBAC objects, read Secrets cluster-wide, create namespaces, and manage EnvoyFilters and NetworkPolicies.

## How to Use

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ```` ```mermaid ```` code blocks and it renders automatically.
- **Live editor**: https://mermaid.live (paste code, edit, export)
- **Editable**: Modify and regenerate if needed

**Manual PNG generation** (if needed):
```bash
npm install -g @mermaid-js/mermaid-cli
PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i diagram.mmd -o diagram.png -w 3000
```

### C4 Diagrams (.dsl files)
- **Structurizr Lite**: `docker run -p 8080:8080 -v .:/usr/local/structurizr structurizr/lite`
- **CLI export**: `structurizr-cli export -workspace models-as-a-service-c4-context.dsl -format png`

### ASCII Diagrams (.txt files)
- View in any text editor
- Include in documentation as-is
- Suited to security reviews because the technical details are exact

## Updating Diagrams

To regenerate after architecture changes:
```bash
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/models-as-a-service.md
```
