# Data Science Pipelines Operator - Architecture Diagrams

Generated from: `architecture/rhoai-3.0/data-science-pipelines-operator.md`
Component: data-science-pipelines-operator
Date: 2026-03-15
Output directory: `architecture/rhoai-3.0/diagrams/`

## Summary

All diagram formats have been successfully generated for the Data Science Pipelines Operator component.

**Total Files Generated**: 11 diagram files (5 Mermaid source + 5 PNGs + 1 ASCII + 1 C4 DSL)

## Generated Diagrams

### Mermaid Diagrams (Source + PNG)

All Mermaid diagrams are available in both `.mmd` (editable source) and `.png` (3000px high-resolution) formats.

#### 1. Component Structure Diagram
- **Source**: `data-science-pipelines-operator-component.mmd` (4.1K)
- **PNG**: `data-science-pipelines-operator-component.png` (242K)
- **Purpose**: Shows DSPO controller, DSP instance components (API server, persistence agent, workflow controller), optional storage (MariaDB, Minio, MLMD), and integrations
- **Audience**: Developers, architects
- **Content**:
  - DSPO Controller with health probes and metrics
  - DSP Instance Components (API Server, Persistence Agent, Scheduled Workflow, Workflow Controller)
  - Optional components (MariaDB, Minio, MLMD gRPC, MLMD Envoy)
  - Custom Resources (DSPA CR, Workflow CRs, Pipeline CRs)
  - External dependencies (Argo Workflows, Kubernetes API, S3, external DB)
  - Internal ODH dependencies (Dashboard, DSC, KServe, Workbenches, Service Mesh)

#### 2. Data Flow Diagram
- **Source**: `data-science-pipelines-operator-dataflow.mmd` (3.1K)
- **PNG**: `data-science-pipelines-operator-dataflow.png` (339K)
- **Purpose**: Sequence diagrams showing pipeline submission, execution, persistence, and artifact retrieval
- **Audience**: Developers, SREs
- **Flows**:
  1. **Pipeline Submission via Dashboard**: Browser → Route → OAuth Proxy → API Server → MariaDB → Workflow Controller → K8s API
  2. **Pipeline Execution**: K8s → Pipeline Pod → API Server → S3 → MLMD gRPC → MariaDB
  3. **Workflow State Persistence**: Persistence Agent → K8s API → API Server → MariaDB
  4. **Artifact Retrieval**: Browser → Route → OAuth Proxy → API Server → MariaDB → S3 (signed URL)
- **Technical Details**: All ports, protocols, encryption (TLS 1.2+, pod-to-pod TLS, mTLS), authentication mechanisms

#### 3. Dependencies Graph
- **Source**: `data-science-pipelines-operator-dependencies.mmd` (3.6K)
- **PNG**: `data-science-pipelines-operator-dependencies.png` (260K)
- **Purpose**: Shows external dependencies, storage/database options, and ODH integrations
- **Audience**: Architects, integration engineers
- **Content**:
  - **External Dependencies**: Kubernetes/OpenShift 4.11+, Argo Workflows v3.4+, S3-compatible storage (required), MariaDB 10.3 (optional)
  - **Storage Options**: AWS S3, Ceph S3 (production) vs Minio (dev/test only)
  - **Database Options**: External MySQL/MariaDB/PostgreSQL (production) vs Internal MariaDB (dev/test)
  - **Internal ODH Dependencies**: Dashboard (UI), DSC (deployment), KServe (model serving), Workbenches (notebooks), Service Mesh (optional), Monitoring
  - **Platform Services**: CoreDNS, CSI Storage, CNI, RBAC, OpenShift Service Serving Certs, Network Policies, Routes
  - **Build/Deployment**: Red Hat Konflux CI/CD, registry.redhat.io

#### 4. RBAC Visualization
- **Source**: `data-science-pipelines-operator-rbac.mmd` (6.6K)
- **PNG**: `data-science-pipelines-operator-rbac.png` (138K)
- **Purpose**: RBAC permissions for operator and DSPA instances
- **Audience**: Security teams, compliance
- **Content**:
  - **Operator ServiceAccount**: controller-manager (namespace: redhat-ods-applications)
    - ClusterRole: manager-role (full access to DSPA CRs, Argo workflows, pipelines, pods, deployments, RBAC, routes, network policies, KServe, Ray)
    - Role: leader-election-role
  - **DSPA Instance ServiceAccounts** (per namespace):
    - ds-pipeline-{name}: API Server and Persistence Agent (Role: workflow management)
    - ds-pipeline-argo-{name}: Workflow Controller (ClusterRole: argo-specific permissions)
    - pipeline-runner-{name}: Pipeline execution pods (Role: pod/configmap/secret/pvc/service access)
  - **Aggregate Roles**: argo-aggregate-to-admin, argo-aggregate-to-edit, argo-aggregate-to-view
  - Visual mapping of ServiceAccounts → RoleBindings → Roles → API Resources with specific verbs

#### 5. Security Network Diagram (Mermaid)
- **Source**: `data-science-pipelines-operator-security-network.mmd` (5.6K)
- **PNG**: `data-science-pipelines-operator-security-network.png` (323K)
- **Purpose**: Visual network topology with trust zones and security details
- **Audience**: Security teams (presentations)
- **Trust Zones**:
  - **External (Untrusted)**: Data Scientist Browser
  - **Ingress (DMZ)**: OpenShift Route (443/TCP → 8443/TCP, TLS Reencrypt)
  - **DSPA Namespace (Pod-to-Pod TLS)**: All internal components with service-serving certs
    - API Server Pod (OAuth Proxy + API Container)
    - Persistence Agent Pod
    - Workflow Controller Pod
    - Pipeline Execution Pod
    - MariaDB Pod (with NetworkPolicy mariadb-{name})
    - MLMD gRPC Pod (with NetworkPolicy ds-pipeline-metadata-grpc-{name})
    - MLMD Envoy Pod (with NetworkPolicy mlmd-envoy-dashboard-access)
    - Minio Pod (dev/test only)
  - **Operator Namespace**: DSPO Controller (redhat-ods-applications)
  - **Kubernetes Control Plane**: K8s API Server (6443/TCP)
  - **External Services**: External S3, External DB, Container Registries
- **Technical Details**: All ports, protocols, encryption, authentication, NetworkPolicies

### Security Network Diagram (ASCII)
- **File**: `data-science-pipelines-operator-security-network.txt` (27K)
- **Purpose**: Precise text-based network topology for Security Architecture Reviews (SAR)
- **Audience**: Security teams, compliance auditors
- **Content**:
  - **Network Topology**: Detailed ASCII diagram with all trust boundaries
  - **Port/Protocol Details**: Exact specifications for every connection
  - **Encryption**: TLS versions, pod-to-pod TLS via service-serving certs
  - **Authentication**: OAuth tokens, ServiceAccount tokens, DB passwords, S3 credentials, mTLS
  - **RBAC Summary**: All ClusterRoles, Roles, RoleBindings with permissions
  - **Network Policies**: Detailed ingress/egress rules for all components
  - **Secrets**: TLS certificates (auto-rotated), credential secrets (user-managed)
  - **Service Mesh Configuration**: Optional Istio PeerAuthentication and AuthorizationPolicy

### C4 Context Diagram
- **File**: `data-science-pipelines-operator-c4-context.dsl` (7.0K)
- **Purpose**: System context in Structurizr C4 format
- **Audience**: Architects, stakeholders
- **Content**:
  - **People**: Data Scientist, Platform Administrator
  - **Software System**: Data Science Pipelines Operator
    - **Containers**: DSPO Controller, DSP API Server, Persistence Agent, Scheduled Workflow Controller, Workflow Controller, MariaDB, Minio, MLMD gRPC, MLMD Envoy
    - **Components**: Reconciler, Health Probes, Metrics, REST API, gRPC API, OAuth Proxy
  - **External Systems**: Kubernetes/OpenShift, Argo Workflows, External S3, External DB, Container Registries
  - **Internal ODH Systems**: ODH Dashboard, DataScienceCluster, KServe, Workbenches, Service Mesh, OpenShift Monitoring
  - **Relationships**: All integration points with ports, protocols, authentication

## How to Use These Diagrams

### For Developers
1. **Component Diagram**: Understand DSPO architecture and how components interact
2. **Data Flow Diagram**: Trace request flows through the system (pipeline submission, execution, artifact retrieval)
3. **Dependencies Graph**: Identify required vs optional dependencies, understand integration points

### For Architects
1. **C4 Context Diagram**: View DSPO in broader ML platform ecosystem
2. **Component Diagram**: High-level architectural overview
3. **Dependencies Graph**: Plan integrations and infrastructure requirements

### For Security Teams
1. **Security Network Diagram (ASCII)**: Use in SAR documentation, provides precise technical details
2. **Security Network Diagram (PNG/Mermaid)**: Use in presentations, visual trust boundaries
3. **RBAC Diagram**: Understand permissions and service accounts for security reviews

### For SREs/Operations
1. **Data Flow Diagram**: Troubleshoot request flows, understand bottlenecks
2. **Dependencies Graph**: Plan infrastructure, understand what's required vs optional
3. **Security Network Diagram**: Configure network policies, firewall rules, ingress/egress

## Viewing Diagrams

### PNG Files
- **Ready to use**: 3000px width, high-resolution
- **Use in**: PowerPoint, Google Slides, Confluence, wikis, documentation
- **No tools required**: Just open in any image viewer or embed in documents

### Mermaid Files (.mmd)
- **GitHub/GitLab**: Renders automatically in markdown (use ````mermaid` code blocks)
- **Live Editor**: https://mermaid.live (paste, edit, export)
- **Regenerate PNG**:
  ```bash
  PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i diagram.mmd -o diagram.png -w 3000
  ```

### C4 Diagrams (.dsl)
- **Structurizr Lite**:
  ```bash
  docker run -p 8080:8080 -v $(pwd):/usr/local/structurizr structurizr/lite
  # Then open http://localhost:8080
  ```
- **CLI Export**:
  ```bash
  structurizr-cli export -workspace diagram.dsl -format png
  ```

### ASCII Diagrams (.txt)
- **View in**: Any text editor (monospaced font recommended)
- **Perfect for**: SAR submissions, email, plain-text documentation
- **No rendering required**: Copy/paste directly into documents

## Key Architecture Insights

### Multi-Tenancy
- Each namespace can have its own DSPA instance with isolated resources
- Namespace-scoped Argo Workflows controller per DSPA instance
- Network policies isolate traffic between instances

### Security-First Design
- Pod-to-pod TLS enabled by default using OpenShift service-serving certificates
- Automatic certificate rotation
- OAuth proxy for external access
- mTLS for internal gRPC communication (MLMD)
- Network policies restrict access to sensitive components (MariaDB, MLMD gRPC)

### Production vs Dev/Test
- **Production**: Use external S3 and external database (MySQL/PostgreSQL)
- **Dev/Test**: Can use operator-deployed Minio and MariaDB (not supported for production)
- All diagrams clearly distinguish between production and dev/test options

### Integration Points
- **ODH Dashboard**: Web UI for pipeline management
- **KServe**: Deploy inference services from pipelines
- **Workbenches**: Submit pipelines from Jupyter notebooks
- **Service Mesh**: Optional mTLS and traffic management
- **Monitoring**: Prometheus metrics from operator, API server, workflow controller

### Workflow Execution
- Based on Argo Workflows v3.4+ (not legacy Tekton)
- Namespace-scoped workflow controller per DSPA instance
- Persistence agent syncs workflow state to database
- Scheduled workflow controller for cron-scheduled pipelines

## Component Details

**Repository**: https://github.com/red-hat-data-services/data-science-pipelines-operator.git
**Version**: 0.0.1
**Branch**: rhoai-3.0
**Distribution**: RHOAI
**Languages**: Go 1.21
**Based on**: Kubeflow Pipelines 2.5.0

## Regenerating Diagrams

If the architecture file is updated, regenerate diagrams with:

```bash
# From repository root
cd architecture/rhoai-3.0

# Regenerate all diagrams
python ../../scripts/generate_architecture_diagrams.py data-science-pipelines-operator.md

# Regenerate PNGs only (if you edited .mmd files)
python ../../scripts/generate_diagram_pngs.py diagrams --width=3000
```

## Files Summary

```
diagrams/
├── data-science-pipelines-operator-component.mmd          (4.1K) - Mermaid source
├── data-science-pipelines-operator-component.png          (242K) - High-res PNG
├── data-science-pipelines-operator-dataflow.mmd           (3.1K) - Mermaid source
├── data-science-pipelines-operator-dataflow.png           (339K) - High-res PNG
├── data-science-pipelines-operator-dependencies.mmd       (3.6K) - Mermaid source
├── data-science-pipelines-operator-dependencies.png       (260K) - High-res PNG
├── data-science-pipelines-operator-rbac.mmd               (6.6K) - Mermaid source
├── data-science-pipelines-operator-rbac.png               (138K) - High-res PNG
├── data-science-pipelines-operator-security-network.mmd   (5.6K) - Mermaid source
├── data-science-pipelines-operator-security-network.png   (323K) - High-res PNG
├── data-science-pipelines-operator-security-network.txt   (27K)  - ASCII diagram
└── data-science-pipelines-operator-c4-context.dsl         (7.0K) - Structurizr DSL
```

**Total**: 11 files, ~1.3 MB
