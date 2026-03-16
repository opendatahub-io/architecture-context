# Architecture Diagrams for Red Hat OpenShift AI 3.0 Platform

Generated from: `architecture/rhoai-3.0/PLATFORM.md`
Date: 2026-03-16

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./platform-component.png) ([mmd](./platform-component.mmd)) - Mermaid diagram showing internal components, operators, and workload relationships
- [Data Flows](./platform-dataflow.png) ([mmd](./platform-dataflow.mmd)) - Sequence diagram of key workflows including authentication, notebook creation, training, and inference
- [Dependencies](./platform-dependencies.mmd) - Component dependency graph showing relationships between operators and external systems

### For Architects
- [C4 Context](./platform-c4-context.dsl) - System context in C4 format (Structurizr) showing RHOAI in broader ecosystem
- [Component Overview](./platform-component.png) ([mmd](./platform-component.mmd)) - High-level platform architecture with all 13 components
- [Dependency Graph](./platform-dependencies.png) ([mmd](./platform-dependencies.mmd)) - Integration patterns and external dependencies

### For Security Teams
- [Security Network Diagram (PNG)](./platform-security-network.png) - High-resolution network topology with authentication flows
- [Security Network Diagram (Mermaid)](./platform-security-network.mmd) - Visual network topology (editable) with trust boundaries
- [Security Network Diagram (ASCII)](./platform-security-network.txt) - Precise text format for SAR submissions with detailed RBAC, secrets, and compliance information
- [RBAC Visualization](./platform-rbac.png) ([mmd](./platform-rbac.mmd)) - ServiceAccounts, ClusterRoles, ClusterRoleBindings, and API resource permissions

## How to Use

### PNG Files (.png files)
**Automatically generated** at 3000px width for high-resolution presentations and documentation.

- **Ready to use**: High-resolution images suitable for presentations, wikis, and documentation
- **Width**: 3000px (height auto-adjusts to content)
- **Use directly**: Include in PowerPoint, Google Slides, Confluence, etc.

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with \`\`\`mermaid code blocks - renders automatically!
- **Live editor**: https://mermaid.live (paste code, edit, export)
- **Editable**: Modify and regenerate if needed

**Manual PNG regeneration** (if you edit .mmd files):

1. **Ensure Mermaid CLI is installed**:
   ```bash
   npm install -g @mermaid-js/mermaid-cli
   ```

2. **Regenerate PNG** (3000px width):
   ```bash
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i diagram.mmd -o diagram.png -w 3000
   ```

3. **Alternative formats** (if needed):
   ```bash
   # SVG (vector, scales perfectly)
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i diagram.mmd -o diagram.svg

   # PDF
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i diagram.mmd -o diagram.pdf
   ```

**Note**: If \`google-chrome\` is not found, try \`chromium\` or \`which google-chrome\` to locate it

### C4 Diagrams (.dsl files)
- **Structurizr Lite**: \`docker run -p 8080:8080 -v .:/usr/local/structurizr structurizr/lite\`
- **CLI export**: \`structurizr-cli export -workspace diagram.dsl -format png\`

### ASCII Diagrams (.txt files)
- View in any text editor
- Include in documentation as-is
- Perfect for security reviews (precise technical details)

## Diagram Descriptions

### platform-component.mmd
**Purpose**: Visual overview of the entire RHOAI 3.0 platform architecture

**Shows**:
- Platform core: RHODS Operator, DataScienceCluster, DSCInitialization
- Gateway infrastructure: Gateway API v1, kube-auth-proxy, EnvoyFilter
- Application layer: 11 component operators (Dashboard, Notebook Controller, DSP, KServe, etc.)
- User workloads: Notebooks, InferenceServices, Training Jobs, Model Registries, Feature Stores
- Monitoring layer: Prometheus, Alertmanager, ServiceMonitors
- External dependencies: S3, OIDC, Container Registries, NVIDIA NGC, HuggingFace

**Key relationships**:
- RHODS Operator deploys and manages all component operators
- Gateway provides centralized ingress with OAuth2/OIDC authentication
- Dashboard manages lifecycle of notebooks, pipelines, and serving
- Operators create workloads in user namespaces
- Workloads integrate with external storage and ML ecosystem services

### platform-dataflow.mmd
**Purpose**: Technical sequence diagrams of key platform workflows

**Workflows covered**:
1. **User Authentication (RHOAI 3.x)**: OAuth2/OIDC flow via Gateway and kube-auth-proxy
2. **Launch Jupyter Workbench**: Dashboard creates Notebook CR, controller creates StatefulSet and HTTPRoute
3. **Distributed Model Training**: Submit PyTorchJob, download datasets from S3, train, register in Model Registry
4. **Model Deployment and Inference**: Create InferenceService, download model from S3, serve via Gateway
5. **ML Pipeline Orchestration**: Pipeline execution via DSP and Argo Workflows

**Technical details**:
- Port numbers (443/TCP, 8443/TCP, 8080/TCP, 6443/TCP)
- Protocols (HTTPS, HTTP, gRPC)
- Authentication mechanisms (OAuth2, Bearer tokens, ServiceAccount tokens, AWS SigV4)
- TLS encryption (TLS 1.3 at Gateway, TLS 1.2+ for external services)

### platform-security-network.txt (ASCII)
**Purpose**: Detailed network architecture for Security Architecture Reviews (SAR)

**Sections**:
1. **Network topology**: External → Ingress → Application Layer → Platform Core → K8s API → User Workloads → External Services
2. **Component details**: Ports, protocols, encryption, authentication for every service
3. **RBAC Summary**: ClusterRole permissions for all 11 platform operators
4. **Secrets Inventory**: TLS certificates, OAuth credentials, database passwords, storage credentials, auto-rotation policies
5. **Service Mesh Configuration**: PeerAuthentication, EnvoyFilter, VirtualService, DestinationRule, AuthorizationPolicy
6. **Network Policies**: Ingress/egress rules created by ODH Model Controller
7. **Trust Boundaries**: 5 security zones with authentication/encryption requirements
8. **Compliance & Security Posture**: FIPS 140-2, TLS 1.2+, multi-layered auth, audit logging, secret management

**Use cases**:
- Submit to security teams for architecture reviews
- Compliance documentation (SOC 2, ISO 27001, PCI-DSS)
- Network engineering for firewall rules and egress policies
- Incident response and threat modeling

### platform-security-network.mmd (Mermaid)
**Purpose**: Visual representation of security network architecture

**Shows**:
- Trust zones: External (untrusted), Ingress (DMZ), Platform Core, Application Layer, K8s API, User Workloads, Monitoring
- Network flows with port/protocol/encryption/auth details
- Color-coded trust boundaries
- External services: S3, OIDC, Container Registries, NVIDIA NGC, HuggingFace
- Database connections: PostgreSQL/MySQL for Model Registry, DSP, TrustyAI

**Differences from ASCII version**:
- Visual, color-coded diagram vs. precise text format
- Easier to understand at a glance for presentations
- ASCII version includes RBAC, secrets, and compliance details not in Mermaid

### platform-c4-context.dsl
**Purpose**: C4 architecture model for high-level system context

**Model includes**:
- **People**: Data Scientist, ML Engineer, Platform Admin
- **RHOAI containers**: 13 platform components (operators, services, monitoring)
- **External systems**: OpenShift, OAuth/OIDC, Service Mesh, S3, Databases, HuggingFace, NVIDIA NGC
- **Relationships**: ~80 relationships showing data flow and dependencies

**Views**:
1. **System Context**: RHOAI in broader ecosystem
2. **Container View**: Internal RHOAI components

**Use with Structurizr**:
```bash
docker run -p 8080:8080 -v $(pwd):/usr/local/structurizr structurizr/lite
# Open http://localhost:8080 and upload platform-c4-context.dsl
```

### platform-dependencies.mmd
**Purpose**: Component dependency graph showing integration patterns

**Dependencies shown**:
- **RHOAI components**: 13 operators and their relationships
- **Infrastructure dependencies (required)**: OpenShift, Gateway API, OAuth, Container Registries
- **Service Mesh dependencies (optional)**: Istio/OSSM, Knative Serving
- **Storage dependencies**: S3, PostgreSQL, MySQL, MariaDB
- **ML ecosystem dependencies**: HuggingFace Hub, NVIDIA NGC
- **Internal integrations**: Gateway, kube-auth-proxy, Prometheus, Kubernetes API

**Relationship types**:
- Solid lines: Required dependencies
- Dashed lines: Optional dependencies
- Arrows: Direction of dependency

**Use cases**:
- Understand impact of changes to one component
- Plan deployment order
- Identify external service dependencies for air-gapped installations

### platform-rbac.mmd
**Purpose**: RBAC permissions matrix for platform operators

**Shows**:
- **ServiceAccounts**: 12 operator ServiceAccounts (redhat-ods-operator, redhat-ods-applications namespaces)
- **ClusterRoleBindings**: Binds ServiceAccounts to ClusterRoles
- **ClusterRoles**: Permission sets for each operator
- **API Resources**: 40+ CRDs and core Kubernetes resources

**Permissions**:
- RHODS Operator: Platform-wide orchestration (Gateway, OAuth, Istio, RBAC)
- Component Operators: CRD lifecycle management + core resources (Deployments, Services, ConfigMaps)
- ODH Model Controller: Extends KServe with Routes, ServiceMonitors, NetworkPolicies
- TrustyAI Operator: Watches/patches KServe InferenceServices for guardrails injection

**Use cases**:
- Security reviews (principle of least privilege)
- Troubleshooting permission errors
- Understanding operator capabilities and blast radius

## Updating Diagrams

To regenerate after architecture changes:
```bash
# From repository root
cd architecture/rhoai-3.0
# Regenerate diagrams (output to diagrams/ subdirectory automatically)
# (assumes you have a diagram generation tool configured)
```

## Platform Architecture Summary

**Red Hat OpenShift AI 3.0** is an enterprise AI/ML platform with 13 integrated components:

1. **RHODS Operator**: Platform orchestrator
2. **ODH Dashboard**: Web console
3. **Notebook Controller**: Jupyter/RStudio/CodeServer workbenches
4. **Data Science Pipelines Operator**: Kubeflow Pipelines 2.5.0 + Argo Workflows
5. **KServe**: Model serving (serverless + raw modes)
6. **ODH Model Controller**: OpenShift extensions for KServe
7. **Model Registry Operator**: ML model metadata storage
8. **Training Operator**: Distributed training (PyTorch, TensorFlow, MPI, XGBoost, JAX)
9. **KubeRay Operator**: Ray clusters for distributed computing
10. **TrustyAI Service Operator**: Explainability, LM evaluation, AI guardrails
11. **Feast Operator**: Feature store for online/offline feature serving
12. **Llama Stack Operator**: LLM inference across multiple backends

**Key Architecture Changes in 3.0**:
- **Gateway API ingress** (replaces Routes for new workloads)
- **kube-auth-proxy authentication** (replaces oauth-proxy)
- **HTTPRoute + kube-rbac-proxy pattern** for component ingress
- **EnvoyFilter ext_authz integration** for Service Mesh
- **OIDC authentication support** (ROSA compatibility)
- **Raw deployment mode as default** for KServe (Knative optional)

**Maturity Indicators**:
- ✅ 13 components, 12 operators (92%)
- ✅ 40+ CRDs
- ✅ Multi-architecture (x86_64, aarch64, ppc64le, s390x)
- ✅ GPU support (NVIDIA CUDA 12.8, AMD ROCm 6.3/6.4)
- ✅ FIPS 140-2 compliant
- ✅ High availability (Dashboard 2 replicas, kube-auth-proxy 2 replicas, Prometheus 2 replicas, Alertmanager 3 replicas)
- ✅ Production-ready monitoring, health probes, metrics, TLS encryption, RBAC, audit logging

## Related Documentation

- [PLATFORM.md](../PLATFORM.md) - Detailed platform architecture documentation
- [Component Architecture Files](../) - Individual component architectures (13 files)
- OpenShift AI 3.0 Official Documentation (link when available)
- [Gateway API Specification](https://gateway-api.sigs.k8s.io/)
- [Kubeflow Documentation](https://www.kubeflow.org/)
- [KServe Documentation](https://kserve.github.io/website/)

---

**Generated by**: Architecture diagram generation tool
**Source**: architecture/rhoai-3.0/PLATFORM.md
**Component count**: 13
**Total diagrams**: 7 (5 Mermaid + PNG, 1 ASCII, 1 C4)
**Last updated**: 2026-03-16
