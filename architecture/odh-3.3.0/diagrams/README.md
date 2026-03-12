# Platform Diagrams for Open Data Hub 3.3.0

Generated from: `architecture/odh-3.3.0/PLATFORM.md`
Date: 2026-03-12

## Available Diagrams

### For Architects
- [Component Dependency Graph](./platform-dependency-graph.mmd) - Shows component relationships and dependencies
- [Platform Workflows](./platform-workflows.mmd) - End-to-end flows spanning multiple components
- [Platform Maturity](./platform-maturity.mmd) - Health metrics and component statistics

### For Security Teams
- [Platform Network Topology (Mermaid)](./platform-network-topology.mmd) - Visual network architecture diagram
- [Platform Network Topology (ASCII)](./platform-network-topology.txt) - Precise text format for SAR submissions
- [Platform Security Overview](./platform-security-overview.mmd) - RBAC, auth mechanisms, secrets, service mesh policies

### For Platform Engineers
- [Component Dependency Graph](./platform-dependency-graph.mmd) - Understand integration points
- [Platform Network Topology (Mermaid)](./platform-network-topology.mmd) - Visualize network architecture
- [Platform Network Topology (ASCII)](./platform-network-topology.txt) - Debug connectivity issues (precise details)
- [Platform Workflows](./platform-workflows.mmd) - Trace request flows

## How to Use

### Mermaid Diagrams (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ````mermaid` code blocks
- **Render to PNG locally**:
   ```bash
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i diagram.mmd -o diagram.png -s 3
   ```
- **In VS Code**: Install "Markdown Preview Mermaid Support" extension

### ASCII Diagrams (.txt files)
- View in any text editor
- Include directly in security documentation
- Perfect for SAR (Security Architecture Review) submissions

## Diagram Descriptions

### Component Dependency Graph
Shows how platform components depend on each other. Central components (most dependencies) are highlighted with thicker borders. Useful for understanding blast radius of changes and planning upgrades.

**Color Coding**:
- Gray: External platform services (K8s API, OLM, OAuth, Istio)
- Blue (thick border): Central control plane (ODH Operator)
- Green (thick border): Primary user interface (Dashboard)
- Green: ODH components (Notebook Controller, MLflow, Feast)
- Orange: External services (PostgreSQL, Redis, S3, BigQuery, Quay)

### Platform Network Topology
Complete network architecture showing all ingress points, service mesh communication, and egress destinations. Includes exact port numbers, protocols, encryption, and authentication mechanisms.

**Two formats provided**:
- **Mermaid (.mmd)**: Visual diagram with color-coded trust zones. Great for presentations and architecture discussions.
  - Trust zones: External (gray), Ingress (orange), Service Mesh (green), Egress (yellow)
  - Shows protocol and port details on edges
- **ASCII (.txt)**: Precise text format with no ambiguity. Required for SAR (Security Architecture Review) submissions and compliance documentation.
  - Detailed tables for namespaces, RBAC, authentication, secrets
  - Complete connection details with trust boundaries

Both formats contain the same information - use Mermaid for visual clarity, ASCII for security reviews.

### Cross-Component Workflows
Sequence diagrams showing end-to-end user workflows that span multiple components.

**Workflows included**:
1. User Accesses Dashboard to Create Notebook
2. Experiment Tracking with MLflow from Notebook
3. Feature Engineering with Feast from Notebook
4. Platform Installation via DataScienceCluster
5. Idle Notebook Culling

Shows component interactions over time with protocol details (mTLS, HTTPS, gRPC) and authentication at each boundary crossing.

### Platform Security Overview
Visual representation of security architecture including ServiceAccounts, ClusterRoles, secrets, and service mesh policies. Shows which components have which permissions.

**Color Coding**:
- Red: Privileged ClusterRoles (controller-manager, notebook-controller-role)
- Yellow: Sensitive secrets (credentials, OAuth configs)
- Green: Service mesh policies (PeerAuthentication, AuthorizationPolicy)

**Elements shown**:
- 6 authentication mechanisms (OAuth, Bearer tokens, mTLS, OIDC, SA tokens, K8s RBAC)
- 6 key ServiceAccounts with namespace context
- 6 ClusterRoles (high privilege)
- 8+ critical secrets
- Service mesh policies (optional)

### Platform Maturity Dashboard
High-level metrics about platform health: component counts, mTLS coverage, API maturity, dependency counts. Useful for executive reviews and maturity assessments.

**Metrics categories**:
- Component Statistics (blue): Total components, operators, CRDs
- Security Posture (orange/yellow for optional, green for strong): Service mesh, mTLS, auth mechanisms, secrets
- Architecture Patterns (green): Multi-tenancy, HA, storage backends
- Cloud Compatibility (blue/green): AWS, GCP, Azure, CoreWeave support
- API Maturity (blue/green): HTTP endpoints, gRPC services, API versions
- Integration Points (orange/blue): External platform, services, internal integrations

## Updating Diagrams

To regenerate after platform changes:
1. Update component architectures: `/repo-to-architecture-summary`
2. Collect components: `/collect-component-architectures`
3. Aggregate platform: `/aggregate-platform-architecture`
4. Regenerate diagrams: `/generate-platform-diagrams`

## Platform Details

- **Platform**: Open Data Hub 3.3.0
- **Base Platform**: OpenShift Container Platform 4.19+ / Kubernetes 1.25+
- **Components**: 5 core components (ODH Operator, Dashboard, Notebooks, MLflow, Feast)
- **Architecture**: 100% operator-based, namespace multi-tenancy
- **Security**: Optional Istio service mesh, multi-layered authentication
- **Storage**: Flexible backends (PostgreSQL, Redis, MongoDB, S3, GCS, BigQuery, Snowflake)
- **Cloud Support**: AWS, GCP, Azure, CoreWeave

## Notes

- Diagrams are generated from PLATFORM.md (aggregated view), not individual component architectures
- Focus is on platform-level concerns: dependencies, cross-component flows, aggregated security
- **Network topology has dual formats**:
  - **Mermaid**: Visual, color-coded trust zones, great for presentations
  - **ASCII**: Precise text format, no ambiguity, required for SAR submissions
  - Both contain the same information, just different representations
- Mermaid diagrams can be embedded directly in documentation or rendered to PNG
- ASCII diagrams are precise and unambiguous for security reviews
- Service mesh (Istio) integration is optional; diagrams show both optional and required components
- Regenerate after running `/aggregate-platform-architecture` with updated component data
