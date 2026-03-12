# Architecture Diagrams for Kubeflow Notebook Controllers

Generated from: `../checkouts/opendatahub-io/kubeflow/GENERATED_ARCHITECTURE.md`
Date: 2026-03-12

## Available Diagrams

### For Developers
- [Component Structure](./kubeflow-notebook-controllers-component.mmd) - Mermaid diagram showing internal components, CRDs, created resources, and dependencies
- [Data Flows](./kubeflow-notebook-controllers-dataflow.mmd) - Sequence diagram of notebook creation, user access, and idle culling flows
- [Dependencies](./kubeflow-notebook-controllers-dependencies.mmd) - Component dependency graph showing external and internal ODH dependencies

### For Architects
- [C4 Context](./kubeflow-notebook-controllers-c4-context.dsl) - System context in C4 format (Structurizr) showing components in the broader ODH ecosystem
- [Component Overview](./kubeflow-notebook-controllers-component.mmd) - High-level component view with controllers, CRDs, and integrations

### For Security Teams
- [Security Network Diagram](./kubeflow-notebook-controllers-security-network.txt) - Detailed network topology with ports, protocols, TLS versions, authentication mechanisms, RBAC summary, NetworkPolicies, secrets inventory, and deployment security controls
- [RBAC Visualization](./kubeflow-notebook-controllers-rbac.mmd) - RBAC permissions and bindings for both notebook-controller and odh-notebook-controller

## How to Use

### Mermaid Diagrams (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ` ```mermaid ` code blocks
- **Render to PNG**:
  ```bash
  npx @mermaid-js/mermaid-cli -i kubeflow-notebook-controllers-component.mmd -o kubeflow-notebook-controllers-component.png
  ```
- **Live editor**: https://mermaid.live (copy/paste diagram content)
- **VS Code**: Install "Markdown Preview Mermaid Support" extension

### C4 Diagrams (.dsl files)
- **Structurizr Lite** (local rendering):
  ```bash
  docker run -p 8080:8080 -v $(pwd):/usr/local/structurizr structurizr/lite
  # Open http://localhost:8080
  ```
- **CLI export to PNG/SVG**:
  ```bash
  # Install Structurizr CLI first
  structurizr-cli export -workspace kubeflow-notebook-controllers-c4-context.dsl -format png
  ```
- **Online editor**: https://structurizr.com/dsl (upload .dsl file)

### ASCII Diagrams (.txt files)
- View in any text editor or terminal:
  ```bash
  cat kubeflow-notebook-controllers-security-network.txt
  less kubeflow-notebook-controllers-security-network.txt
  ```
- Include directly in documentation (perfect for security reviews with precise technical details)
- Print for architecture review meetings

## Diagram Descriptions

### 1. Component Structure Diagram
**File**: `kubeflow-notebook-controllers-component.mmd`
**Format**: Mermaid

Shows the internal architecture of Kubeflow Notebook Controllers including:
- Core components: notebook-controller, odh-notebook-controller, webhook, culler
- Custom Resource Definitions (Notebook v1, v1beta1, v1alpha1)
- Created Kubernetes resources: StatefulSet, Service, Route, HTTPRoute, VirtualService, OAuth, NetworkPolicy, RBAC
- External dependencies: Kubernetes API, Istio, Data Science Pipelines, OpenShift OAuth, cert-manager
- Integration points: Dashboard, Prometheus, Feast

### 2. Data Flow Diagram
**File**: `kubeflow-notebook-controllers-dataflow.mmd`
**Format**: Mermaid Sequence Diagram

Visualizes three critical flows with complete network details:
- **Flow 1**: Notebook creation and provisioning (User → API Server → Webhook → Controller → DSPA → Resources)
- **Flow 2**: User access to notebook (User → Router/Gateway → OAuth → Notebook)
- **Flow 3**: Idle notebook culling (Culler → Notebook metrics → API Server)

Each step includes port numbers, protocols, encryption (TLS versions), and authentication mechanisms.

### 3. Security Network Diagram
**File**: `kubeflow-notebook-controllers-security-network.txt`
**Format**: ASCII Art

Comprehensive security topology diagram with:
- **Network layers**: External, Ingress (DMZ), Application, Control Plane, External Services
- **Precise details**: Port numbers (e.g., 443/TCP, 8443/TCP), protocols (HTTP/HTTPS/gRPC), encryption (TLS 1.2+, mTLS, plaintext), authentication (OAuth, Service Account Tokens, mTLS certs)
- **RBAC summary**: ClusterRoles with detailed API groups, resources, and verbs
- **Network policies**: Ingress/egress rules for notebook namespaces
- **Secrets inventory**: TLS certificates, OAuth configs, pipeline credentials with provisioning details
- **Auth/AuthZ matrix**: Endpoint-level authentication and authorization policies
- **Deployment security**: Security contexts, resource limits, leader election

Perfect for Security Architecture Reviews (SAR), compliance audits, and threat modeling.

### 4. C4 Context Diagram
**File**: `kubeflow-notebook-controllers-c4-context.dsl`
**Format**: Structurizr DSL (C4 Model)

System context showing:
- **Actors**: Data Scientist
- **System boundary**: Kubeflow Notebook Controllers (containers: notebook-controller, odh-notebook-controller, webhook, culler)
- **External systems**: Kubernetes, Istio, cert-manager, Container Registries
- **Internal ODH systems**: Data Science Pipelines, OpenShift OAuth, Gateway API, Feast, Prometheus
- **Relationships**: API calls, integrations, authentication flows with protocols and ports

Ideal for architectural documentation, onboarding, and stakeholder presentations.

### 5. Dependency Graph
**File**: `kubeflow-notebook-controllers-dependencies.mmd`
**Format**: Mermaid Graph

Shows all component dependencies categorized by type:
- **External required**: Kubernetes, controller-runtime
- **External optional**: Istio, cert-manager (dashed lines)
- **Internal ODH**: Data Science Pipelines, OpenShift OAuth, Routes, Gateway API, ImageStreams, Feast
- **Integration points**: ODH Dashboard, Prometheus, Service Mesh
- **External services**: Container Registries, Kubernetes API Server

Color-coded:
- Blue: Kubeflow Notebook Controllers
- Gray: External dependencies
- Green: Internal ODH components
- Orange: External services

### 6. RBAC Visualization
**File**: `kubeflow-notebook-controllers-rbac.mmd`
**Format**: Mermaid Graph

Visualizes RBAC hierarchy:
- **Service Accounts**: notebook-controller-service-account, odh-notebook-controller-manager
- **ClusterRoleBindings**: Bind service accounts to ClusterRoles
- **ClusterRoles**: notebook-controller-role, odh-notebook-controller-manager-role, leader-election-role
- **Permissions**: Detailed API groups, resources, and verbs for each role

Helps understand permission scopes and identify least-privilege gaps.

## Updating Diagrams

To regenerate diagrams after updating the architecture documentation:

```bash
# From the repository root
/generate-architecture-diagrams --architecture=./checkouts/opendatahub-io/kubeflow/GENERATED_ARCHITECTURE.md --output-dir=./diagrams
```

Or to generate only specific formats:
```bash
/generate-architecture-diagrams --formats=mermaid,security
```

## Use Cases by Audience

### Developers
- Use **Component Structure** to understand internal architecture
- Use **Data Flow** to trace request/response paths and debug issues
- Use **Dependencies** to understand integration points when developing new features

### Architects
- Use **C4 Context** for architectural documentation and ADRs
- Use **Component Structure** for design reviews and refactoring planning
- Use **Dependencies** to assess impact of upstream/downstream changes

### Security Teams
- Use **Security Network Diagram** for Security Architecture Reviews (SAR)
- Use **RBAC Visualization** to audit permissions and verify least privilege
- Use **Data Flow** to understand trust boundaries and authentication flows
- Use **Security Network Diagram** sections (secrets, auth matrix, network policies) for compliance audits

### SREs / Platform Engineers
- Use **Data Flow** to troubleshoot networking issues
- Use **Dependencies** to plan upgrades and assess compatibility
- Use **Security Network Diagram** (egress section) to configure firewalls and proxy rules

### Product Managers / Stakeholders
- Use **C4 Context** for high-level understanding of system boundaries
- Use **Dependencies** to understand external vs. internal components

## Tips

1. **Embed Mermaid in Markdown**: GitHub, GitLab, and many documentation platforms render Mermaid natively:
   ````markdown
   ```mermaid
   graph TD
       A[Component A] --> B[Component B]
   ```
   ````

2. **Export to Images**: For presentations, export Mermaid/C4 diagrams to PNG/SVG using CLI tools (see "How to Use" section above)

3. **Security Reviews**: Print the ASCII security network diagram for in-person architecture reviews - no ambiguity, precise technical details

4. **Version Control**: Keep diagrams alongside code in git for version history and change tracking

5. **Living Documentation**: Regenerate diagrams after significant architecture changes to keep documentation fresh

## Related Documentation

- **Source**: [../checkouts/opendatahub-io/kubeflow/GENERATED_ARCHITECTURE.md](../checkouts/opendatahub-io/kubeflow/GENERATED_ARCHITECTURE.md)
- **Repository**: https://github.com/opendatahub-io/kubeflow
- **Component Version**: v1.7.0-15-519
- **Distribution**: OpenDataHub (ODH) and Red Hat OpenShift AI (RHOAI)

## Questions or Issues?

If you find issues with the diagrams or need additional diagram types, please:
1. Regenerate from the latest architecture markdown
2. File an issue if the source architecture documentation needs updates
3. Extend the `/generate-architecture-diagrams` skill to support new diagram formats
