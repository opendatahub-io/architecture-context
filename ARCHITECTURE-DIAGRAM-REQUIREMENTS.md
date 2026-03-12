# Architecture Diagram Requirements

## Overview
This document compiles common requirements and requests people make regarding architecture diagrams, based on analysis of:
- **Slack conversations** from June 2025 through March 2026 (AI/RHOAI-focused channels)
- **Jira tickets** from RHAIENG, RHAISTRAT, and RHOAIENG projects (2024-2026)
- **ADR repository** (opendatahub-io/architecture-decision-records) structure and maintenance patterns
- **Upstream ODH repositories** (opendatahub.io website, opendatahub-operator) to understand ODH vs RHOAI documentation strategies
- **RHOAI feature development lifecycle** (RFE → GA process analysis)

Section 11 specifically covers RHOAI (Red Hat OpenShift AI) and AI platform-specific requirements discovered through analysis of AI/RHOAI-focused channels. The Historical Jira Tickets section reveals that architecture diagrams are a mandatory deliverable for RHOAI features and documents ongoing automation initiatives. The Architecture Documentation Repository Analysis section examines the current state of the official ADR repository, identifying gaps and maintenance issues that support the automation initiative (RHOAIENG-52636). The Upstream vs Downstream Architecture Documentation section clarifies the relationship between Open Data Hub (ODH) upstream and RHOAI downstream documentation strategies.

---

## Architecture Diagrams in the Feature Development Lifecycle

**For complete lifecycle analysis, see**: `./RHOAI_LIFECYCLE_ANALYSIS.md` (1969 lines, comprehensive RFE→GA process investigation)

### Official Process (Where Diagrams Should Happen)

**Stage 4: Architecture & Design** (after Feature Refinement, before Implementation):
- **ADR (Architecture Decision Record)** - Marked "optional" in current process
- **Architecture Design Document (ADD)** - Marked "recommended" (not required)
- **Architecture diagrams** - "Begin/Complete" with **no enforcement gate**
- **Timing**: "Start at least two weeks in advance of planned merge into RHOAI"

**Expected workflow**:
```
RFE Approval → Architecture Review → ADR → Architecture Diagrams → Implementation → Product Docs → GA
```

### Actual Practice (What Really Happens)

**Critical Finding**: Architecture diagrams are created **retroactively** as cleanup work, not proactively as design artifacts.

**Evidence**:
- ❌ **28+ Jira tickets** titled "Feature documented in architecture diagrams" (retroactive CLONE tasks)
- ❌ **Architecture docs lag 3+ months** (arch-overview.md v2.13 from Dec 2025, product v3.3 from March 2026)
- ❌ **Product docs written BEFORE architecture docs** (process inversion)
- ❌ **No enforcement gates** prevent shipping to Dev Preview, Tech Preview, or GA without architecture diagrams
- ⚠️ **RFE Council sets `requires_architecture_review` label** but no tracking/enforcement of completion

**Actual workflow**:
```
RFE Approval → Implementation → Product Docs → GA → (maybe) Architecture Diagrams (months later)
```

### Process Gaps Affecting Architecture Diagrams

1. **Ownership Ambiguity**: No clear owner for creating/maintaining architecture diagrams (everyone assumes someone else will do it)
2. **Optional ADRs**: Architecture Decision Records marked "optional" despite being foundation for diagrams
3. **Broken Automation**: RHAIRFE→RHAISTRAT auto-cloning disabled (Jan 2025), requiring manual PM intervention
4. **Missing Gates**: No release blockers for missing architecture documentation at any stage (DP/TP/GA)
5. **Label Without Enforcement**: `requires_architecture_review` label set by RFE Council but never validated

### Proposed Improvements (DRAFT "From Chaos to Clarity" Framework)

**Status**: 📝 DRAFT for RHOAI 3.4 EA1 MVP (target approval: January 23, 2026)

**Proposed gates for architecture diagrams**:
- **Before Dev Preview**: If `requires_architecture_review` label → Architecture review MUST be completed
- **Before Tech Preview**: Architecture diagrams MUST be created in ADR repository
- **Before GA**: arch-overview.md MUST be updated to reflect new components/changes

**Proposed ownership**:
- Technical Lead: Create initial architecture diagrams
- Architecture Team: Integrate diagrams into arch-overview.md within 1 sprint of Tech Preview
- SPSE Architect: Sign-off required for both ADR and diagrams

**Note**: This framework is **proposed but not yet implemented** as of March 11, 2026. See lifecycle document for full details.

### Implications for Automation (RHOAIENG-52636)

**Risk**: Automating diagram generation without fixing the workflow will create pretty diagrams that are still 3 months out of date.

**Recommended phased approach** (from lifecycle analysis):
1. **Phase 1**: Enforce workflow gates FIRST (prevent TP/GA without architecture docs)
2. **Phase 2**: Add AI tooling support FOR creation (generate draft ADRs, suggest diagram updates)
3. **Phase 3**: Continuous improvement (dashboards, metrics, freshness tracking)

**Key principle**: Automation should enforce proper workflow, not codify broken processes.

---

## 1. Format & Tool Requirements

### Image Formats
- **Standard formats**: PNG, JPG for easy integration into documentation
- **Static images preferred** over HTML files for accessibility
- **SVG support** needed for complex/large diagrams to maintain quality
- **Vector formats** preferred for diagrams with many components

### Diagramming Tools & Standards
- **Miro** boards for collaborative design
- **Google Cloud icons** for cloud infrastructure diagrams
- **Structurizr** for C4 model diagrams
- **Mermaid.js** diagrams (though rendering can be problematic in some platforms)
- **draw.io / Excalidraw** for general diagrams
- **UTF-8 box-drawing characters** for text-based diagrams in ADRs
- **Inkscape** for creating official Red Hat diagrams

---

## 2. Core Content Requirements

### Component-Level Details
- **All system components** clearly labeled and identified
- **Component communication patterns** and data flows
- **Component relationships and dependencies**
- **Integration points** between systems/services
- **API endpoints** and their purposes
- **Operator/service interactions** for Kubernetes-based systems

### Infrastructure & Deployment
- **Where resources run**: Cloud (AWS, Azure, GCP), on-premises, hybrid, edge
- **Specific cloud resources used**: Compute (VMs, containers), Storage (S3, RDS), Networking, etc.
- **Deployment topology**: Single cluster, multi-cluster, hub-and-spoke
- **Infrastructure as Code references** when applicable
- **Container/pod placement** and node architecture

### Network Architecture
- **Network topology** showing all networks (control plane, storage, tenant, external, provider)
- **Required network ports** between all components
- **Port purposes** clearly documented (e.g., "8446 - Nginx port")
- **Network segmentation and isolation**
- **Load balancer placement and configuration**
- **DNS and service discovery patterns**
- **Firewall requirements** (internal vs external)
- **Data flow direction** and protocols used

### Data & Storage
- **Database architecture** (PostgreSQL, RDS, etc.)
- **Storage systems** (ODF, S3, EBS, etc.)
- **Data flows** between components
- **Backup and restore flows**
- **Data replication patterns**
- **Caching layers** and their placement

---

## 3. Security & Compliance

### Security Elements
- **Trust boundaries** clearly marked
- **Authentication flows** (OAuth, OIDC, JWT, STS)
- **Authorization mechanisms** (RBAC, policies)
- **Secret management** (Vault, sealed secrets)
- **Encryption points** (TLS, at-rest)
- **Attack surface analysis** documentation
- **Security review artifacts** for product security teams

### Security Review Requirements
- **Communication between operators/components** for SDLC onboarding
- **Certificate exchange flows**
- **Integration with external identity providers**
- **Data exposure points**

---

## 4. High Availability & Disaster Recovery

### HA Architecture
- **Redundancy and failover patterns**
- **Load balancing strategy**
- **Multi-zone/multi-region deployment**
- **Cluster topology** (management clusters, hosted clusters)
- **Replica counts and scaling patterns**

### DR & Backup
- **Backup flows and schedules**
- **Restore procedures** documented
- **RPO/RTO targets** indicated
- **Failover scenarios** illustrated
- **Data replication for DR**

---

## 5. Documentation Context

### Integration with Other Documentation
- **Alignment with deployment guides**
- **References to configuration examples** (YAML, NetworkAttachmentDefinition, etc.)
- **Links to relevant Jira issues** for tracking
- **Version-specific diagrams** for each release
- **Changelog/revision history** for diagram updates

### Architecture Decision Records (ADRs)
When diagrams are part of ADRs, include:
- **System/Component diagram** showing relevant components and boundaries
- **Data flow visualization**
- **Options considered** with visual representation
- **Trade-offs** illustrated
- **Context** for the decision

### Reference Architecture
- **Detailed HLD (High-Level Design)**
- **Lessons learned** from implementations
- **Deployment best practices** illustrated
- **GPU strategy** (for AI/ML workloads): dedicated GPU, MIG partitioning, time-sliced
- **Storage and networking patterns**
- **Multi-tenancy approaches**

---

## 6. Specific Use Case Requirements

### For Product Documentation
- **Customer-facing simplicity** - not too complex
- **Component version numbers** when relevant
- **Support for different deployment models** (IPI, UPI, etc.)
- **Example configurations** that match the diagram

### For Marketplace Submissions
- **Underlying infrastructure** clearly shown
- **Resource utilization** labeled
- **Standard cloud provider icons** used
- **Partner/customer tenant boundaries** identified

### For Troubleshooting & Support
- **Clear entry points** for debugging
- **Log flow** and observability points
- **Health check locations**
- **Common failure points** identified
- **Diagnostic flow paths**

### For Development Teams
- **Repository structure** alignment
- **CI/CD pipeline flows**
- **Testing architecture** (E2E sectors, integration points)
- **Development vs production differences**
- **Component ownership** boundaries

---

## 7. Common Questions Addressed by Diagrams

### Infrastructure Questions
- "Do we have an architecture diagram I can check?"
- "Where do the containers run?"
- "What acts as the proxy to the outside world?"
- "What are the network port requirements?"
- "How does the gateway determine which HA'd component handles requests?"

### Component Relationship Questions
- "How does component X communicate with component Y?"
- "What's the data flow between services?"
- "Where does code live?"
- "How are components integrated?"

### Deployment Questions
- "Is this classical self-managed or Hosted Control Planes based?"
- "What cloud resources are utilized?"
- "Where should components be placed?"
- "What's the cabling and switch configuration?"

### Scalability & Performance
- "What are the resource scaling patterns?"
- "How does the system handle high load?"
- "What are the concurrency patterns?"
- "Where are the bottlenecks?"

---

## 8. Quality Standards

### Clarity & Readability
- **Not overly complex** - break into multiple diagrams if needed (component-level, system-level, etc.)
- **Clear labels** for all elements
- **Consistent naming** with actual implementation
- **Legend/key** when using symbols or colors
- **Readable at standard zoom levels**

### Accuracy & Maintenance
- **Matches actual implementation** - not aspirational
- **Version-specific** where architecture changes between releases
- **Updated with code changes** when architecture evolves
- **Validated by subject matter experts**
- **Tested against actual deployments**

### Accessibility
- **Color-blind friendly** color choices
- **Text alternatives** for visual elements when needed
- **High contrast** for visibility
- **Multiple formats** available (vector and raster)

---

## 9. Platform-Specific Requirements

### Kubernetes/OpenShift
- **Namespace organization**
- **Operator relationships**
- **Custom Resource Definitions (CRDs)**
- **Pod network policies**
- **Service mesh integration**
- **Storage class usage**

### Cloud Platforms
- **AWS**: VPC structure, Security Groups, IAM roles, account IDs
- **Azure**: Resource Groups, Virtual Networks, Managed Identity
- **GCP**: Projects, VPCs, Service Accounts

### AI/ML Workloads
- **Model serving architecture**
- **Training vs inference separation**
- **GPU allocation strategy**
- **Model registry/catalog integration**
- **Inference scaling patterns** (vLLM, llm-d)

---

## 10. Common Pitfalls to Avoid

### Things Users Complained About
- **Missing port information** - port numbers not shown on diagrams
- **Ambiguous resource placement** - unclear where things run
- **Outdated diagrams** - don't reflect current implementation
- **Too generic** - not platform-specific enough when needed
- **Missing authentication flows** - security not clearly shown
- **No version information** - unclear which release the diagram represents
- **Incomplete data flows** - partial view of system interactions
- **Missing component details** - "we don't have any idea about architecture how MCP runs"

### Documentation Gaps That Cause Problems
- **No diagram at all** - "Since we lack architecture diagrams and documentation about this, these inter-project dependencies are only in the engineer's minds"
- **Diagram format not accessible** - HTML when PNG/JPG needed
- **No component-level detail** - only high-level views provided
- **Missing relationship documentation** - how components connect not clear

---

## 11. RHOAI & AI Platform-Specific Requirements

### C4 Model Architecture (June 2025 onwards)
- **C4 Context diagrams** - System landscape showing RHOAI in ecosystem
- **C4 Container diagrams** - Runtime containers and their relationships
- **C4 Component diagrams** - Internal structure of containers
- **Multiple C4 views** required for different audiences and purposes
- **Structurizr integration** for maintaining C4 models

### LlamaStack & AI Framework Integration (RHOAI 3.0+)
- **LlamaStack as core component** - Show integration with RHOAI 3.0
- **Provider integrations** - 3rd party AI providers (AWS AI, Azure AI)
- **Safety/Shield components** - TrustyAI and guardrails placement
- **Kubeflow Pipelines** integration points
- **Inference server topology** - vLLM, OpenVINO, TGIS configurations
- **Training capability** architecture

### Feature Development & Refinement Requirements
From RHOAI feature refinement process, diagrams must include:
- **Architecture Design Document (ADD)** - Formal design documentation
- **Architecture Decision Records (ADR)** - With rationale and trade-offs
- **Component integration diagrams** - For new ODH/RHOAI components
- **Workflow diagrams** - Sequence diagrams for user flows
- **Development flow diagrams** - Branching strategies, release processes
- **Security diagrams** - For SDLC security reviews (required)

### Model-as-a-Service (MaaS) Architecture
- **Gateway topology** - Default `openshift-ai-inference` gateway placement
- **Gateway policies** - How MaaS policies integrate with existing gateways
- **LLMInferenceService flows** - Network flow from client to model
- **Public vs private gateways** - Access control and network topology
- **Namespace segregation** - Which namespaces can reference which gateways
- **Precise-Prefix-Cache-Aware Routing** - For TTFT optimization
- **User tier annotations** - RBAC/OIDC integration points

### Kueue & Workload Management
- **Kueue integration** - With Workbenches, Ray, Model Serving
- **Namespace labeling** - Managed vs unmanaged namespaces
- **Workload queue management** - Resource quotas and priorities
- **Mermaid diagrams** for complex Kueue configurations (requires zooming)
- **RHBoK (Red Hat Build of Kueue)** vs Managed Kueue differences
- **Race conditions** and edge cases documented

### Network & Security Flows
- **Ingress flows** - ABAC/RBAC at entry points
- **Governance integration** - watsonx.governance placement
- **Route sharding** - Multiple Ingress Controllers for traffic isolation
- **Certificate management** - cert-manager as dependent operator
- **mTLS configuration** - Ray clusters, service-to-service
- **OAuth/OIDC flows** - OpenShift OAuth service integration
- **Envoy filter chains** - For auth-service integration

### Component-Specific Diagrams Requested
- **Dashboard architecture** - RHOAI Dashboard vs MaaS Dashboard
- **Notebook integration** - Jupyter, Elyra, custom workbenches
- **Ray/Codeflare** - Operator removal roadmap, future state security
- **Feast integration** - Feature store with Workbench connections
- **S3 File Explorer** - Federated module widget architecture
- **AutoRAG/AutoML** - UI component sharing patterns
- **NIM Operator** - Integration flows with RHOAI

### Development & Release Workflows
- **Branching diagrams** - main (stream), stable (lake), rhoai (ocean)
- **Fork-based vs branch-based** development flows
- **Release branch creation** - Version management strategies
- **Konflux CI/CD** - Build and deployment pipelines
- **ArgoCD deployment** - Bootstrap and sync wave diagrams
- **Operator dependency chains** - How RHOAI consumes component manifests

### Hybrid Cloud & Multi-Cloud Architectures
- **AWS AI integration** - RHOAI with AWS SageMaker, Bedrock
- **Azure AI integration** - RHOAI with Azure OpenAI, ML services
- **Snowflake connectivity** - Data science workflows with external data
- **On-premises + Cloud** - Hybrid deployment topologies
- **Multi-cluster management** - ACM integration for failover

### GPU & Accelerator Architecture
- **NVIDIA GPU Operator** - Integration with RHOAI
- **GPU allocation strategies** - Dedicated, MIG, time-sliced
- **ROCm support** - AMD GPU configurations
- **Accelerator entitlements** - RHAIE (Red Hat AI Enterprise) constraints
- **Mixed cluster architecture** - Taints/tolerations for AI workloads on specific nodes
- **Bare-metal GPU nodes** - Attached to vSphere control planes

### Observability & Monitoring
- **Metrics collection** - Prometheus integration points
- **Log aggregation** - Splunk sidecar patterns
- **Health checks** - Liveness/readiness endpoints
- **Dashboard visualization** - Grafana, custom dashboards
- **Alert flows** - Integration with incident management

### Custom Notebook Images
- **Base image hierarchy** - minimal-cpu, minimal-cuda, minimal-ROCm
- **Framework variants** - TensorFlow, PyTorch, Data Science
- **Elyra integration** - Pipeline authoring capabilities
- **Dockerfile templates** - For user customization
- **Image import flows** - Settings → Image Import process

### Common RHOAI-Specific Questions
From June 2025-March 2026 discussions:

1. "Do we have architecture diagrams for hybrid cloud setup (RHOAI/RHEL AI/RHAIIS with AWS/Azure AI)?"
2. "Where are the RHOAI network diagrams showing required ports?"
3. "What components can be set to managed or removed in the RHOAI operator?"
4. "How does the MaaS gateway work with route sharding?"
5. "What's the architecture for RHOAI 3.0 with LlamaStack?"
6. "How do Connections API integrate with Notebooks 2.0?"
7. "What's the security flow for Ray with mTLS?"
8. "How does cert-manager integrate as a dependent operator?"
9. "What's included in the 'KServe' component - vLLM, OpenVINO?"
10. "How does AutoRAG/AutoML share UI components?"

### Required Miro Boards
Many RHOAI teams maintain collaborative Miro boards:
- **Main RHOAI architecture** - C4 diagrams and component views
- **Gateway/BYOIDC** - High-level MaaS architecture
- **Ray/Codeflare security** - Current and future state
- **Branching/release strategy** - Development workflows
- **Feature-specific boards** - Per major feature/epic

### Tools & Standards for RHOAI Teams
- **Miro** - Primary collaboration platform (most referenced)
- **draw.io** - For importable/exportable diagrams
- **Mermaid** - For documentation and sequence diagrams
- **Structurizr** - For maintaining C4 model consistency
- **GitHub repos** - For versioning diagram source files
- **Google Docs/Slides** - For presentations and ADRs

---

## Summary of Most Frequent Requests

Based on message frequency analysis, these are the top requests:

1. **Network ports and connectivity** - Most common technical detail requested
2. **Component communication patterns** - How services talk to each other
3. **Standard image format (PNG/JPG)** - For easy integration
4. **Infrastructure resource identification** - What cloud resources are used
5. **HA/DR topology** - Redundancy and failover patterns
6. **Security review artifacts** - Trust boundaries and auth flows
7. **Data flow visualization** - How data moves through the system
8. **Integration points** - External system connections
9. **Reference architectures** - Proven deployment patterns
10. **Version-specific diagrams** - Aligned with release documentation

---

## Recommendations for Creating Architecture Diagrams

When creating architecture diagrams, ensure you:

1. **Start with the audience** - Security review vs customer documentation vs internal dev
2. **Use standard formats** - PNG/JPG for docs, draw.io/Miro source files for editing
3. **Show network details** - Ports, protocols, firewalls
4. **Document data flows** - Direction and purpose
5. **Indicate resource placement** - Cloud, on-prem, specific clusters
6. **Include security boundaries** - Trust zones, authentication points
7. **Show HA/DR patterns** - Redundancy and failover
8. **Maintain multiple views** - System context, container, component, deployment
9. **Keep diagrams current** - Update with architecture changes
10. **Validate with SMEs** - Review with engineers and architects before publishing

---

## Historical Jira Tickets (RHAIENG, RHAISTRAT, RHOAIENG)

### Critical Active Initiatives (March 2026)

**RHOAIENG-52647**: "[spike] research historical arch diagram requirements"
- **Priority**: Critical
- **Assignee**: <REMOVED>
- **Created**: March 11, 2026 (today)
- **Status**: To Do
- **Purpose**: Research historical architecture diagram requirements to inform automation

**RHOAIENG-52636**: "AI Automation for RHOAI architecture"
- **Priority**: Critical
- **Type**: Initiative
- **Created**: March 11, 2026 (today)
- **Assignee**: <REMOVED>
- **Goal**: Explore automating generation of RHOAI architecture, specify format, ensure repeatable auto-generation
- **Slack channel**: <REMOVED>
- **Significance**: This represents a major shift toward automated architecture diagram generation

---

### RHOAIENG: Primary Project for Architecture Diagrams

#### Established Pattern: Standard Feature Requirement
RHOAIENG has **30+ "CLONE - Feature documented in architecture diagrams"** tasks, demonstrating that architecture diagrams are a **mandatory deliverable** for every major feature.

#### Notable Completed Architecture Diagram Tickets:

**Model Serving & MaaS:**
- **RHOAIENG-32575**: Model-as-a-Service architectural diagram (Resolved, Nov 2025)
  - Created ADR with architecture: https://github.com/opendatahub-io/architecture-decision-records/pull/105
  - Community docs: https://opendatahub-io.github.io/maas-billing/architecture/
- **RHOAIENG-46926**: MLFlow architecture diagram (Closed, Feb 2026)
  - Updated Miro board with 3.4 EA1 architecture
  - Location: https://miro.com/app/board/uXjVJBd41q0=/
- **RHOAIENG-19092**: Model Mesh architectural requirements

**Multi-Tenancy & Security:**
- **RHOAIENG-46869**: Multi-tenant architecture documentation
- **RHOAIENG-40682**: Access control and authorization architecture
- **RHOAIENG-40681**: Authentication architecture for gen-ai
- **RHOAIENG-20041**: Security-based architecture diagram

**Platform & Infrastructure:**
- **RHOAIENG-39067**: End-to-end testing workflow documentation
- **RHOAIENG-31096**: Model server and metrics architecture
- **RHOAIENG-10981**: Establish Architecture diagram standard template and tooling (Closed, April 2024)
  - This was the original ticket to establish diagram standards

**Documentation & Process:**
- **RHOAIENG-50051**: AI Safety architecture high-level workflows
- **RHOAIENG-27747**: Centralized high-level release document

**Customer Requests:**
- **RHOAIENG-9736**: Customer request for Network Topology Diagram (Closed, Feb 2024)
  - Early example of external need for architecture diagrams

#### Recent Feature Documentation (2026):
- RHOAIENG-52618, RHOAIENG-52595, RHOAIENG-52574, RHOAIENG-52540, RHOAIENG-52497
- RHOAIENG-51861, RHOAIENG-51709, RHOAIENG-51694, RHOAIENG-51643, RHOAIENG-51620
- All include "Feature documented in architecture diagrams" as a subtask

---

### RHAIENG: Red Hat AI Engineering Project

RHAIENG has fewer architecture diagram tickets compared to RHOAIENG, but includes:

**Product Architecture:**
- **RHAIENG-2000**: RHEL AI Product Architecture Diagrams (June 2025)
- **RHAIENG-853**: Improve RHAI architectures and documentation (March 2025)
- **RHAIENG-129**: RHAI Project Architecture Diagram (Sept 2024)

**Development & Instrumentation:**
- **RHAIENG-40**: Install InstructLab on RHEL AI Development Preview (May 2024)

#### Pattern:
RHAIENG focuses more on high-level product architecture diagrams rather than per-feature documentation. This suggests different documentation standards between RHOAIENG (feature-level) and RHAIENG (product-level).

---

### RHAISTRAT: Red Hat AI Strategy Project

RHAISTRAT has minimal direct architecture diagram tickets:

**Strategic Planning:**
- **RHAISTRAT-1237**: Various strategic initiatives (Epic)
- **RHAISTRAT-1042**: Architecture and design planning
- **RHAISTRAT-763**: Integration architecture discussions

#### Pattern:
RHAISTRAT tickets focus more on strategic planning and features rather than detailed architecture diagram documentation. This is consistent with the "STRAT" (strategy) focus of the project.

---

### Cross-Project Analysis

#### Architecture Documentation Requirements by Project:

**RHOAIENG (Red Hat OpenShift AI Engineering):**
1. **Architecture Design Document (ADD)** - Formal design doc
2. **Architecture Diagram** - Visual representation (mandatory for all features)
3. **Architecture Decision Record (ADR)** - When architectural decisions are made
4. **Miro Board Update** - For collaborative C4 diagrams
5. **GitHub ADR Repo** - For version-controlled architecture decisions
6. **Standard Feature Checklist** includes:
   - Design and development
   - **Feature documented in architecture diagrams** ← Standard requirement
   - Security requirements
   - Testing
   - Documentation

**RHAIENG (Red Hat AI Engineering):**
1. **Product-level architecture diagrams** - Broader scope than feature-level
2. **Documentation improvements** - Ongoing refinement of existing diagrams
3. **No standard per-feature pattern observed**

**RHAISTRAT (Red Hat AI Strategy):**
1. **Strategic architecture planning** - High-level design thinking
2. **No consistent architecture diagram deliverable pattern**

#### Key Observations:

1. **RHOAIENG has the most mature architecture diagram process** with mandatory per-feature requirements
2. **Automation initiative (RHOAIENG-52636) signals major evolution** in how diagrams are created and maintained
3. **Research spike (RHOAIENG-52647) directly supports automation effort** by analyzing historical requirements
4. **Standard locations consistently referenced:**
   - Miro: https://miro.com/app/board/uXjVJBd41q0=/
   - GitHub ADRs: https://github.com/opendatahub-io/architecture-decision-records
   - Community docs: https://opendatahub-io.github.io/
5. **Timeline shows evolution:**
   - 2024: Establishing standards (RHOAIENG-10981)
   - 2025: Widespread adoption with CLONE pattern
   - 2026: Automation exploration

#### Common Diagram Types by Project:

**RHOAIENG:** Network topology, component integration, security flows, deployment architecture, C4 models, MaaS topology, multi-tenancy, GPU architecture

**RHAIENG:** Product architecture, RHEL AI system design, InstructLab integration

**RHAISTRAT:** Strategic integration plans, high-level architectural concepts

---

## Architecture Documentation Repository Analysis

### Repository: opendatahub-io/architecture-decision-records

**Location**: https://github.com/opendatahub-io/architecture-decision-records

This repository serves as the central location for:
- **Architecture Decision Records (ADRs)** - Formal architectural decisions with rationale
- **Architecture Documentation** - Component-level and aggregate architecture documentation
- **Diagram Source Files** - draw.io and exported PNG diagrams

### The Aggregate Architecture Document: arch-overview.md

**Purpose**: `documentation/arch-overview.md` serves as the **primary aggregate architecture reference** for RHOAI, consolidating all component architectures into a single comprehensive document.

**Current State (as of March 11, 2026):**
- **Version Header**: "RHOAI Architecture - 2.13"
- **Last Updated**: December 10, 2025 (Feast/Feature Store update)
- **Status**: **Approximately 3 months out of date**

### Current Component Coverage

**Documented Components with Diagrams (D1-D9):**

| Diagram | Component | Image Location |
|---------|-----------|----------------|
| Overview | Full Architecture | `images/RHOAI Architecture-Overview.drawio.png` |
| D1 | RHOAI Operator | `images/RHOAI Architecture - D1 - Operator.png` |
| D2 | Data Science Pipelines | `images/RHOAI Architecture - D2 - DSP.png` |
| D3 | Workbenches (Notebooks) | `images/RHOAI Architecture - D3 - Workbenches.png` |
| D4 | Dashboard | `images/RHOAI Architecture - D4 - Dashboard.png` |
| D5 | Distributed Workloads | `images/RHOAI Architecture - D5 - Distr Workloads.png` |
| D6a | Model Serving (KServe) | `images/RHOAI Architecture - D6a - Model Serving.png` |
| D6b | Model Serving (ModelMesh) | `images/RHOAI Architecture - D6b - Model Serving.png` |
| D6c | Model Serving (Controller) | `images/RHOAI Architecture - D6c - Model Serving.png` |
| D7 | TrustyAI | `images/RHOAI Architecture - D7 - Trusty.png` |
| D9 | Feature Store (Feast) | `images/RHOAI Architecture - D9 - Feature Store.png` |
| Network | Network Architecture | `images/RHODS Architecture - Network Diagram.png` |

**Notable Gap**: **D8 is missing** - No diagram numbered D8 exists in the sequence.

**Network Diagrams** (added April 2025):
- Dashboard network flow
- Data Science Pipelines network flow
- Distributed Workloads (KubeRay & Kubeflow Training Operator)
- Workbenches network flow
- Model Serving network flow
- TrustyAI network flow
- Model Registry network flow

### Missing Components (Exist in Repo but NOT in arch-overview.md)

#### 1. AutoML
- **ADR**: `architecture-decision-records/automl/ODH-ADR-0001-automl.md`
- **Date**: January 21, 2026 (2 months ago)
- **Status**: Proposed
- **Description**: Automated ML for tabular data using AutoGluon + Kubeflow Pipelines
- **Has Architecture**: Yes, includes Mermaid diagrams in ADR
- **Should be**: Integrated as D10 or within Data Science Pipelines section
- **Impact**: Major new capability not reflected in aggregate document

#### 2. AutoRAG
- **ADR**: `architecture-decision-records/autorag/ODH-ADR-0001-autorag.md`
- **Has Architecture**: Yes, includes Mermaid diagrams in ADR
- **Should be**: Integrated as D11 or within appropriate section
- **Impact**: New RAG capability not documented in aggregate

#### 3. Eval Hub
- **ADRs**:
  - `eval-hub/ODH-ADR-EH-0001-eval-hub-service.md`
  - `eval-hub/ODH-ADR-EH-0002-multi-tenancy-and-authz.md`
- **Diagrams**: Multiple draw.io diagrams exist:
  - `eval-hub/images/eh-service.drawio.png`
  - `eval-hub/images/eh-deployment.drawio.png`
  - `eval-hub/images/eh-flow1.drawio.png`
  - `eval-hub/images/eh-multi-tenancy.drawio.png`
- **Should be**: Integrated as D12 or within Model Serving section
- **Impact**: Evaluation infrastructure not visible in aggregate architecture

#### 4. LlamaStack
- **Component Directory**: `documentation/components/llama-stack/` exists but contains only `.gitkeep`
- **CODEOWNERS**: Assigned to `@opendatahub-io/llama-team`
- **Slack/Jira Context**: Identified as critical for RHOAI 3.0
- **Miro Board**: https://miro.com/app/board/uXjVJRyr8IY=/
- **Should be**: Major new section for RHOAI 3.0 architecture
- **Impact**: **Critical component for RHOAI 3.0 has no documentation in ADR repo**

#### 5. Model Registry
- **Component Docs**: `documentation/components/model-registry/README.md` **EXISTS** (7.6KB)
- **Additional Docs**: `model-registry-tenancy.md` **EXISTS** (4.7KB)
- **Diagrams**: Contains Mermaid diagrams in component README
- **arch-overview.md Status**: Still says "**To be included yet**" (line 100)
- **Network Diagram**: Exists at `images/network/ModelRegistry.png`
- **Should be**: Full section with D8 or D10 diagram reference
- **Impact**: **Documented component not integrated into aggregate document**

### Repository Structure & Organization

```
architecture-decision-records/
├── architecture-decision-records/     # ADRs organized by component
│   ├── ODH-ADR-0000-template.md      # Template for new ADRs
│   ├── automl/
│   ├── autorag/
│   ├── data-science-pipelines/
│   ├── distributed-workloads/
│   ├── eval-hub/
│   ├── explainability/
│   ├── model-serving/
│   └── operator/
├── documentation/
│   ├── arch-overview.md              # AGGREGATE DOCUMENT (out of date)
│   ├── components/                    # Component-specific documentation
│   │   ├── dashboard/
│   │   ├── distributed-workload/
│   │   ├── explainability/
│   │   ├── feature_store/
│   │   ├── llama-stack/              # Empty (only .gitkeep)
│   │   ├── model-registry/           # Has docs but not in arch-overview.md
│   │   ├── pipelines/
│   │   ├── platform/
│   │   ├── serving/
│   │   └── workbenches/
│   ├── diagram/                       # Source .drawio files
│   │   ├── RHOAI Architecture.drawio
│   │   └── RHOAI_Network_Architecture.drawio
│   └── images/                        # Exported PNG diagrams
│       ├── RHOAI Architecture-Overview.drawio.png
│       ├── RHOAI Architecture - D1 - Operator.png
│       ├── ... (D2-D9, missing D8)
│       └── network/
└── .github/
    └── CODEOWNERS                     # All changes require @opendatahub-io/architects
```

### Implicit Process Requirements (Undocumented)

Through analysis of git history and repository structure, the **implicit process** for maintaining architecture diagrams is:

#### For Adding/Updating Component Diagrams:

1. **Create or update draw.io source file** in `documentation/diagram/`
   - Naming: `RHOAI Architecture.drawio` (main) or `{Component}_Architecture.drawio`

2. **Export PNG images** to `documentation/images/`
   - Naming pattern: `RHOAI Architecture - D{N} - {Component}.png`
   - Also export overview diagram if main file changed

3. **Update component documentation** in `documentation/components/{component}/README.md`
   - Include component-specific architecture details
   - May include embedded Mermaid diagrams

4. **Update aggregate document** `documentation/arch-overview.md`
   - Add component section with description
   - Reference diagram: `![Description](images/RHOAI Architecture - D{N} - Component.png)`
   - Update version header if needed

5. **Submit Pull Request**
   - Requires approval from `@opendatahub-io/architects`
   - Requires approval from component team (per CODEOWNERS)

#### For ADRs with Architecture Decisions:

1. **Create ADR** in `architecture-decision-records/{component}/`
   - Use template: `ODH-ADR-0000-template.md`
   - Include architecture diagrams (Mermaid or draw.io + PNG)

2. **May or may not update arch-overview.md** (no clear standard)
   - Example: AutoML ADR created Jan 2026, not in arch-overview.md
   - Example: Eval Hub has ADRs + diagrams, not in arch-overview.md

### Diagram Tools & Standards

**Primary Tool**: **draw.io**
- Web version: https://www.drawio.com/
- Source files stored as `.drawio` in `documentation/diagram/`
- Export to PNG for inclusion in markdown
- Per `diagram/README.MD`: "Use https://www.drawio.com/ (client) to open and edit it"

**Secondary Tool**: **Mermaid**
- Used for embedded diagrams in markdown (ADRs, component docs)
- Common for sequence diagrams, flow diagrams, component relationships
- Examples: Dashboard, Feature Store, AutoML, AutoRAG

**Diagram Naming Convention**:
- Source: `{Purpose}.drawio` or `{Component}_Architecture.drawio`
- Exports: `RHOAI Architecture - D{N} - {Component}.png`
- Network diagrams: `{Component}.png` in `/images/network/`

### Update Frequency & Maintenance Issues

**Git Log Analysis** (architecture diagram updates):
- **Dec 3, 2024**: Updated architecture diagrams to version 2.13 (12 files changed)
- **Apr 4, 2025**: Added network architecture diagrams (8 new network PNGs)
- **Dec 10, 2025**: Updated Feast architecture in RHOAI

**Issue**: **3+ month lag** between component ADRs/docs and arch-overview.md updates
- AutoML ADR: Jan 21, 2026 → Not in arch-overview.md (2 months later)
- Model Registry docs exist → arch-overview.md says "To be included yet"
- LlamaStack critical for RHOAI 3.0 → No documentation in repo

### Code Ownership & Review Requirements

Per `.github/CODEOWNERS`:
- **All files**: `@opendatahub-io/architects` (mandatory approval)
- **Component-specific**: Component team approval also required
  - Dashboard: `@opendatahub-io/exploring-team`
  - Model Serving: `@opendatahub-io/model-serving`
  - Distributed Workloads: `@opendatahub-io/training-experimentation`
  - Platform: `@opendatahub-io/platform`
  - LlamaStack: `@opendatahub-io/llama-team`

### Critical Gaps Identified

❌ **No formal written process** for maintaining arch-overview.md aggregate document
❌ **Version header out of sync** (says 2.13, current is likely 2.14 or 2.15+)
❌ **Diagram numbering gap** - D8 missing from sequence
❌ **New components lag behind** - AutoML, AutoRAG, Eval Hub ADRs exist but not integrated
❌ **Model Registry placeholder** never updated despite docs existing since before Dec 2024
❌ **LlamaStack empty** despite being critical for RHOAI 3.0
❌ **No MaaS-specific diagram** despite being major feature discussed extensively in Slack/Jira
❌ **No automation** for syncing ADRs → arch-overview.md

### Recommendations

1. **Formalize the process** for updating arch-overview.md when new components are added
2. **Define update triggers** - When ADR is approved? When component ships? When version bumps?
3. **Resolve D8 gap** - Either assign to Model Registry or renumber
4. **Establish component integration checklist** - What's required for arch-overview.md inclusion
5. **Version synchronization process** - How and when to update version header
6. **Consider automation** - This directly supports RHOAIENG-52636 automation initiative

### Direct Support for Automation Initiative (RHOAIENG-52636)

The **3-month lag** between component documentation and aggregate document updates demonstrates:
- Manual process is not scalable
- Knowledge in engineers' heads (Section 10 pitfall: "dependencies are only in the engineer's minds")
- Clear need for automated sync between:
  - Component ADRs → arch-overview.md
  - Component diagrams → aggregate diagram
  - Version releases → documentation updates

**This analysis directly informs the automation requirements for RHOAIENG-52636.**

---

## Upstream vs Downstream Architecture Documentation

### Repository Relationship: ODH (Upstream) vs RHOAI (Downstream)

**Key Understanding**:
- **Open Data Hub (ODH)** = Upstream open-source project (`opendatahub-io/*` GitHub organization)
- **Red Hat OpenShift AI (RHOAI)** = Downstream productized version (`red-hat-data-services/*` GitHub organization)

### Upstream ODH Architecture Documentation

#### opendatahub.io Website Repository

**Repository**: https://github.com/opendatahub-io/opendatahub.io
- **Purpose**: Website shell for opendatahub.io
- **Framework**: Gatsby static site generator
- **Documentation Strategy**: **Pulls documentation from external repository**

**Critical Finding - Documentation Architecture**:
```typescript
// gatsby-config.ts - Documentation is git-sourced
{
  name: `docs`,
  remote: `https://github.com/opendatahub-io/opendatahub-documentation.git`,
  branch: `v3.0`,  // or v2.25, v2.24, etc. per release
  local: "public/static/docs",
}
```

**The opendatahub.io repository uses a DUAL-SOURCE documentation strategy:**

**Gatsby Configuration** (`gatsby-config.ts`):
1. **Git-sourced** from `opendatahub-documentation` (branch: v3.0) → Modern user docs (592 modules)
2. **Local files** from `src/content/docs/` → Legacy/static pages including architecture.md

#### PUBLIC WEBSITE HAS SEVERELY OUTDATED ARCHITECTURE PAGE

**CRITICAL ISSUE**: The public-facing website at **https://opendatahub.io/docs/architecture/** is serving 3-year-old architecture information that misrepresents the current ODH platform.

**Source File**: `opendatahub.io/src/content/docs/architecture.md`
- **Last Updated**: May 23, 2023 (nearly 3 years old, 94 lines)
- **Describes**: ODH v1.7 (June 2023) architecture
- **Public URL**: https://opendatahub.io/docs/architecture/
- **Status**: **Frozen and severely outdated - ACTIVELY MISLEADING**

**What the Live Public Page Lists as "Current Included Components"**:
- Ceph
- Apache Spark
- JupyterHub
- Prometheus
- Grafana
- Seldon

**What's WRONG with This Public Information**:
- ❌ **Ceph** - Not part of ODH anymore
- ❌ **Apache Spark** - Removed; replaced by Spark Operator (added Jan 2026)
- ❌ **Seldon** - Deprecated; replaced by KServe
- ❌ **Missing ALL modern components**: Dashboard, Data Science Pipelines, KServe, Ray, Training Operator, Trainer, TrustyAI, Model Registry, Kueue, LlamaStack, MLflow, etc.
- ❌ **No mention of**: v3.0 features (Llama Stack, AI Safety, Gen AI capabilities, Evaluating AI systems, etc.)

**Architecture Diagrams on Public Site**:
- `src/content/assets/img/architecture.png` (high-level, outdated, from 2023)
- `src/content/assets/img/pages/arch/figure-{1-8}.png` (workflow diagrams, outdated, from 2023)

**Impact of Outdated Public Architecture Page**:
- **New users** evaluating ODH see components that no longer exist
- **Architects** making decisions based on outdated information
- **Comparison shoppers** comparing ODH to alternatives get false impression
- **Security reviewers** analyzing outdated architecture
- **Contributors** getting confused about platform composition
- **Academic researchers** citing incorrect architecture in papers

#### Modern Documentation Location

**Actual documentation lives in**: `opendatahub-io/opendatahub-documentation` (separate repository, NOT cloned)

Recent releases pointing to this external repo:
- v3.0 (Dec 2025)
- v2.25 (Nov 2025)
- v2.24 (Oct 2025)
- v2.23, v2.22, v2.21 (2024-2025)

**Navigation structure** (from const.ts):
- Installing/Upgrading Open Data Hub
- Getting started
- Working with projects
- Data science IDE
- Working with AI pipelines
- Deploying models
- Gen AI playground
- Configuring model serving
- Managing and monitoring models
- **Customize models to build gen AI applications** (new in v3.0)
- Enabling AI Safety (new in v3.0)
- Evaluating AI systems (new in v3.0)
- Monitoring AI systems (new in v3.0)
- Working with distributed workloads
- Working with accelerators
- Working with connected applications
- S3 object store
- Model registries and model catalog
- **Working with Llama Stack** (new feature)
- Managing ODH
- Managing resources
- Machine learning features
- Architecture (frozen old page)
- Tiered Components
- Release Notes

### Upstream ODH Operator Design Documentation

**Repository**: `opendatahub-io/opendatahub-operator`
**Design Doc**: `docs/DESIGN.md`
- **Last Updated**: January 28, 2026
- **Status**: **Current and actively maintained**
- **Diagram**: `docs/images/odh-operator-design.png` (with source: `odh-operator-design.drawio`)

**Documented Components** (as of Jan 2026):
- Dashboard
- Data Science Pipelines
- Feature Store (Feast Operator)
- KServe
- Kueue
- Model Registry
- Ray
- Training Operator
- TrustyAI
- Workbenches (IDEs)
- **LlamaStack Operator** (added June 2025)
- **MLflow Operator** (added Dec 2025)
- **Spark Operator** (added Jan 2026)

**Removed/Deprecated Components** (per git log):
- ModelMesh (removed Oct 2025)
- CodeFlare operator (removed Sept-Oct 2025)
- Serverless Mode & Service Mesh infrastructure (removed Oct 2025)
- Authorino Infrastructure (removed Oct 2025)

**Operator Architecture Details**:
- Uses DataScienceCluster (DSC) and DSCInitialization (DSCI) CRs
- Each component has dedicated internal CRD and controller
- Platform-level services: Auth, Monitoring
- Feature Tracker for cross-namespace resource management
- Accessory controllers: Cert ConfigMap Generator, Setup/cleanup

### Upstream vs Downstream Differences

**Build Modes** (from opendatahub-operator README):
```bash
# Operator can be built in ODH or RHOAI mode
ODH_PLATFORM_TYPE=rhoai make image  # Build RHOAI mode
# Default is ODH mode
```

**Namespace Differences**:
- **ODH**: Uses `opendatahub` namespace by default
- **RHOAI**: Uses `rhods-notebooks` namespace for workbenches (downstream)

**Component Availability**:
- ODH includes experimental/incubating features first
- RHOAI productizes subset with support lifecycle
- Example: LlamaStack, MLflow, Spark operators are recent ODH additions

### Critical Gaps in Upstream Documentation

❌ **No aggregate architecture document** equivalent to RHOAI's `arch-overview.md`
- The opendatahub.io/architecture.md is frozen at 2023
- Modern docs are in separate repo (`opendatahub-documentation`, not cloned)
- No central architecture reference showing current state (v3.0 as of Dec 2025)

❌ **No upstream equivalent to architecture-decision-records repo**
- `opendatahub-io/architecture-decision-records` is **shared** between ODH and RHOAI
- ADRs reference both "Open Data Hub" and "RHOAI"
- The repo serves **both upstream and downstream**

✅ **Operator design doc is current** (Jan 2026)
- Well-maintained in opendatahub-operator repo
- Includes architecture diagram with draw.io source
- Documents all active components

✅ **Component integration guide exists**
- `docs/COMPONENT_INTEGRATION.md` documents how to add new components
- Includes scaffolding CLI tool for boilerplate generation
- Process-focused, not architecture-focused

### Documentation Strategy Differences

| Aspect | ODH (Upstream) | RHOAI (Downstream) |
|--------|----------------|-------------------|
| **Architecture docs location** | Separate `opendatahub-documentation` repo | `architecture-decision-records` repo |
| **Website repo** | `opendatahub.io` (pulls docs via git) | Uses official Red Hat docs portal |
| **Architecture page** | Frozen at 2023 | `arch-overview.md` updated Dec 2025 |
| **Operator design** | `opendatahub-operator/docs/DESIGN.md` | Same repo (shared) |
| **Component docs** | In `opendatahub-documentation` (branched per version) | `architecture-decision-records/documentation/components/` |
| **ADRs** | Shared repo (`architecture-decision-records`) | Shared repo |
| **Diagrams** | Operator design only (drawio) | Full component diagrams (D1-D9, draw.io + PNG) |
| **Update frequency** | Website: 3-month release cycles | ADR repo: As needed, lags 3 months |

### Implications for Architecture Diagram Requirements

1. **ODH uses external documentation repository** - The website is just a shell
2. **Shared ADR repository** - `opendatahub-io/architecture-decision-records` serves both ODH and RHOAI
3. **RHOAI has more comprehensive architecture diagrams** - D1-D9 component diagrams don't exist for ODH
4. **ODH documentation is versioned by branch** - v3.0, v2.25, v2.24, etc. in separate repo
5. **Operator design doc is the only current architectural reference** for ODH
6. **No ODH equivalent to RHOAI's arch-overview.md aggregate document** (or it's in the separate opendatahub-documentation repo which wasn't cloned)

### Official Documentation Repositories (from <REMOVED>)

**Source**: Slack message from <REMOVED> in <REMOVED> (January 2026)

#### Upstream: Open Data Hub
- **Repository**: https://github.com/opendatahub-io/opendatahub-documentation
- **Published Site**: https://opendatahub.io/docs/getting-started-with-open-data-hub/
- **Purpose**: Open-source, upstream documentation

#### Downstream: Red Hat OpenShift AI
- **Repository**: https://<REMOVED>/documentation-red-hat-openshift-data-science-documentation/openshift-ai-documentation
- **Published Site**: https://docs.redhat.com/en/documentation/red_hat_openshift_ai/
- **Purpose**: Official product documentation (downstream)

#### Documentation Flow (Upstream-First)
Per <REMOVED>:
> "Those are the repos we use for making upstream and downstream changes, with that exact flow you described about upstream first, followed by downstream (if changes are needed in both places). Several times there are updates that may need downstream-only changes, which is why docs clarifies where the changes need to be applied."

**Process**:
1. Changes made to **upstream** (`opendatahub-io/opendatahub-documentation`) **first**
2. Synced to **downstream** GitLab (`openshift-ai-documentation`)
3. Some updates are **downstream-only** when needed (product-specific features, support lifecycle, etc.)

---

### Documentation Repository Analysis: opendatahub-documentation

**Repository**: https://github.com/opendatahub-io/opendatahub-documentation (cloned to `./src.repos/opendatahub-documentation`)
**Purpose**: **User-facing documentation only** (how-to guides, procedures, tutorials)
**Format**: AsciiDoc following Red Hat modular documentation standards
**Publishing**: https://opendatahub.io/docs via Read the Docs

**Critical Finding**: This repository contains **ZERO architecture documentation**.

**Repository Structure**:
- **592 modular documentation files** in `/modules/` directory
- Procedural docs: "Creating a workbench", "Deploying models", "Configuring pipelines"
- Conceptual docs: "About model serving", "About persistent storage"
- Reference docs: "About workbench images", "About base training images"
- **No architecture diagrams, no component architecture docs, no system design**

**CLAUDE.md File** (comprehensive AI assistant guidelines):
- Confirms this is the **upstream source** for Red Hat OpenShift AI user documentation
- Documents 70+ repositories for ODH components (comprehensive technology reference)
- Documentation flow: ODH docs (upstream) → Red Hat GitLab (downstream) → docs.redhat.com
- Focus: **"How to use"** not **"how it works"**
- References `architecture-decision-records` repo as separate architecture documentation

**Architecture Mentions** (grep results):
- Only incidental references: "server-client architecture" (workbench IDE explanation)
- "Classic architecture" (AWS ROSA platform variant)
- "Model serving platform architecture" (KServe description for users)
- **No system architecture, no component diagrams, no design docs**

**Conclusion**: The opendatahub-documentation repository is **exclusively end-user documentation**. Architecture documentation lives in the separate `architecture-decision-records` repository (shared between ODH and RHOAI).

### Architecture Documentation Strategy - Final Clarification

**Upstream ODH Architecture Documentation Locations**:
1. **`opendatahub-operator/docs/DESIGN.md`** - Operator architecture (current, actively maintained, updated Jan 2026)
2. **`architecture-decision-records`** - Component architecture, ADRs (**shared with RHOAI downstream**)
3. **`opendatahub.io/src/content/docs/architecture.md`** - ⚠️ **PROBLEM**: Frozen at May 2023 but **STILL SERVING on public website** at https://opendatahub.io/docs/architecture/

**Public-Facing Architecture Documentation - Mixed Status**:

**1. Landing Page Interactive Diagram** (https://opendatahub.io/)
- **Component**: `ArchitectureMap.tsx` - "Built on open-source" section
- **Format**: Interactive layered architecture diagram with clickable components
- **Status**: **More current than /docs/architecture/ but still outdated**

**Architecture Layers Shown**:
- **Storage**: Ceph
- **ODH Dashboard**: User-facing dashboard
- **Notebook Controller**: Jupyter, PyTorch, TensorFlow, Kubeflow Notebook Controller, ODH Notebook Controller
- **Model Serving**: ModelMesh, TrustyAI, OpenVINO
- **Data Science Pipelines**: Kubeflow Pipelines, Tekton
- **Monitoring**: Prometheus
- **Open Data Hub Operator**: Deployment and maintenance
- **Kubernetes/OKD/OpenShift**: Platform layer
- **Hybrid Cloud**: Infrastructure layer

**Issues with Landing Page Diagram**:
- ❌ **Shows Ceph** as storage component (not part of ODH anymore)
- ❌ **Shows ModelMesh** as model serving (removed Oct 2025)
- ❌ **Missing KServe** (current model serving platform, replaced ModelMesh)
- ❌ **Missing Ray** (distributed workloads)
- ❌ **Missing Training Operator** and **Trainer** (ML training)
- ❌ **Missing Kueue** (workload scheduling)
- ❌ **Missing Model Registry** (model versioning)
- ❌ **Missing LlamaStack** (LLM framework, added June 2025)
- ❌ **Missing MLflow** (experiment tracking, added Dec 2025)
- ❌ **Missing Spark Operator** (added Jan 2026)
- ❌ **Missing Feast** (Feature Store)

**2. Architecture Page** (https://opendatahub.io/docs/architecture/)
- **File**: `src/content/docs/architecture.md` (94 lines, May 2023)
- **Content**: Describes ODH v1.7 from June 2023 (nearly 3 years old)
- **Listed Components**: Ceph, Spark, Seldon, Prometheus, Grafana (mostly removed/deprecated)
- **Missing Components**: Dashboard, Data Science Pipelines, KServe, Ray, TrustyAI, Model Registry, Kueue, LlamaStack, MLflow, Trainer, and all v3.0 features
- **Impact**: Actively misleading new users, architects, and evaluators about ODH's current capabilities

**Comparison**:
| Feature | Landing Page Diagram | Docs Architecture Page |
|---------|---------------------|------------------------|
| Last updated | Unknown (in code) | May 23, 2023 |
| Shows Dashboard | ✅ Yes | ❌ No |
| Shows Data Science Pipelines | ✅ Yes | ❌ No |
| Shows TrustyAI | ✅ Yes | ❌ No |
| Shows ModelMesh | ⚠️ Yes (removed Oct 2025) | ❌ No (shows Seldon instead) |
| Shows KServe | ❌ No | ❌ No |
| Shows Ray | ❌ No | ❌ No |
| Shows Model Registry | ❌ No | ❌ No |
| Interactive | ✅ Yes (clickable) | ❌ No (static text) |
| Format | Visual layered diagram | Prose description |

**Overall Assessment**: The landing page interactive diagram is **more current** but **still significantly outdated** (missing 8+ major components added in 2025-2026)

**Upstream ODH does NOT maintain**:
- ❌ Aggregate architecture overview document (like RHOAI's `arch-overview.md`)
- ❌ Component-level architecture diagrams (no D1-D9 equivalents)
- ❌ Network architecture diagrams
- ❌ System-level architecture documentation
- ❌ Current public-facing architecture page (frozen since 2023)

### Final Assessment: ODH vs RHOAI Architecture Documentation

**RHOAI (Downstream) has significantly more comprehensive architecture documentation than ODH (Upstream)**:

| Aspect | ODH (Upstream) | RHOAI (Downstream) |
|--------|----------------|-------------------|
| **Official doc repository** | ✅ GitHub: `opendatahub-io/opendatahub-documentation` | ✅ GitLab: `openshift-ai-documentation` (internal) |
| **Published documentation** | ✅ https://opendatahub.io/docs/ | ✅ https://docs.redhat.com/en/documentation/red_hat_openshift_ai/ |
| **User documentation** | ✅ `opendatahub-documentation` (592 modules, AsciiDoc) | ✅ Synced from upstream, adapted for product |
| **Landing page arch diagram** | ⚠️ Interactive `ArchitectureMap.tsx` (outdated, missing 8+ components) | N/A (uses product portal) |
| **Public architecture page** | ❌ **SEVERELY OUTDATED** - /docs/architecture/ frozen May 2023 (v1.7) | ✅ Product docs at docs.redhat.com (current) |
| **Operator architecture** | ✅ `opendatahub-operator/docs/DESIGN.md` (Jan 2026) | ✅ Same repo (shared) |
| **Component architecture** | ⚠️ Minimal ADRs in `architecture-decision-records` | ✅ Full `arch-overview.md` + comprehensive ADRs |
| **Architecture diagrams** | ⚠️ Landing page interactive + operator design | ✅ D1-D9 component diagrams + network diagrams |
| **Aggregate arch doc** | ❌ None (frozen 2023 page + outdated interactive) | ✅ `arch-overview.md` (updated Dec 2025, v2.13) |
| **ADRs** | ✅ Shared `architecture-decision-records` repo | ✅ Same repo (primary contributor) |
| **Architecture images** | ❌ Outdated 2023 images on /docs/architecture/ | ✅ `documentation/images/` with D1-D9 PNGs |
| **draw.io sources** | ❌ None (ArchitectureMap is TSX code) | ✅ `documentation/diagram/` with .drawio files |
| **Maintenance** | ⚠️ Public site outdated, no maintenance process | ❌ 3-month lag, components missing |

**Why the Difference**:

**ODH (Upstream)** is a **community-driven open-source project** focused on:
- Rapid feature development and integration
- Component innovation and experimentation
- Providing upstream source for RHOAI
- User-facing documentation for community adoption

**RHOAI (Downstream)** is a **productized enterprise offering** requiring comprehensive architecture documentation for:
- **Security Architecture Reviews (SAR)** - Mandatory for SDLC compliance
- **Customer Architecture Planning** - Enterprise deployment planning
- **Support Escalations** - L3 support requires architectural understanding
- **Enterprise Compliance** - Regulatory and security audit requirements
- **Sales Engineering** - Solution architecture and reference architectures
- **Feature Documentation Standard** - "Feature documented in architecture diagrams" (30+ Jira tickets)

**Key Insights for Automation (RHOAIENG-52636)**:

1. **The architectural documentation burden falls ENTIRELY on RHOAI downstream**, not ODH upstream. This explains:
   - Why RHOAI has D1-D9 diagrams and ODH doesn't
   - Why `arch-overview.md` exists only in RHOAI context
   - Why automation is critical for RHOAI but not requested for ODH
   - Why the 3-month documentation lag is a RHOAI problem (enterprise customers need current docs)

2. **ODH upstream has a PUBLIC-FACING ARCHITECTURE PROBLEM** (dual outdated sources):

   **A. Static Architecture Page** (https://opendatahub.io/docs/architecture/):
   - Serves 3-year-old content (May 2023, ODH v1.7)
   - Lists deprecated/removed components (Ceph, Spark, Seldon) as "current"
   - Omits ALL modern components added since 2023

   **B. Landing Page Interactive Diagram** (https://opendatahub.io/ - "Built on open-source"):
   - More current than /docs/architecture/ but still significantly outdated
   - Shows deprecated ModelMesh (removed Oct 2025), Ceph
   - Missing 8+ major components: KServe, Ray, Training Operator, Kueue, Model Registry, LlamaStack, MLflow, Spark Operator, Feast
   - Source: `ArchitectureMap.tsx` (TypeScript React component)

   **Impact**: Misleads potential adopters, architects, and researchers evaluating ODH

   **Recommendation**:
   - Update `ArchitectureMap.tsx` to include all v3.0 components (KServe, Ray, etc.)
   - Either update /docs/architecture/ to v3.0 OR remove it entirely and redirect to interactive diagram
   - Establish maintenance process tied to operator releases

3. **Different documentation philosophies**:
   - ODH: User-focused "how to use" (opendatahub-documentation)
   - RHOAI: User docs + comprehensive "how it works" architecture documentation
   - This reflects upstream community vs downstream enterprise product needs

---

## RHOAI Product Documentation Architecture Content

**Critical Discovery**: Unlike upstream ODH which has frozen/outdated public architecture pages, **RHOAI product documentation at docs.redhat.com contains CURRENT architecture documentation** that is actively maintained and published with each product release.

### Documentation Location

**Official Product Documentation**:
- **Self-Managed**: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/
- **Cloud Service**: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_cloud_service/

**Architecture Chapter**:
- **Title**: "Chapter 1. Architecture of OpenShift AI Self-Managed" (or "Architecture of OpenShift AI" for Cloud Service)
- **Location**: Installing and uninstalling guide
- **Versions Available**: 2.22, 2.23 (2-latest), 3.2, 3.3 (latest as of March 2026)
- **Status**: ✅ **Actively maintained and updated with each release**

**Example URLs**:
- Version 2.22: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.22/html/installing_and_uninstalling_openshift_ai_self-managed/architecture-of-openshift-ai-self-managed_install
- Version 2-latest: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2-latest/html/installing_and_uninstalling_openshift_ai_self-managed/architecture-of-openshift-ai-self-managed_install
- Disconnected environments: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2-latest/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/architecture-of-openshift-ai-self-managed_install

### Architecture Content Documented

Based on web search analysis, the RHOAI product documentation architecture chapter covers:

#### 1. Product Deployment Models

**Self-Managed vs Cloud Service**:
- **Self-Managed**: Operator available in self-managed environments (OpenShift Container Platform)
- **Cloud Service**: Fully Red Hat managed cloud service available as add-on to:
  - Red Hat OpenShift Dedicated
  - Red Hat OpenShift Service on AWS (ROSA classic)

**Important Cloud Service Note**: Updates for Red Hat OpenShift AI Cloud Service are only provided up to the end of October 2025.

#### 2. Namespace/Project Architecture

When you install the Red Hat OpenShift AI Operator, the following projects are created:

| Namespace | Purpose | Components |
|-----------|---------|------------|
| `redhat-ods-operator` | Contains the Red Hat OpenShift AI Operator | Operator controller |
| `redhat-ods-applications` | Dashboard and core components | Dashboard, model-registry-operator-controller-manager, other required components |
| `redhat-ods-monitoring` | Monitoring and billing services | Alertmanager, OpenShift Telemetry, Prometheus |
| `rhods-notebooks` | Workbench deployment | Basic workbenches deployed by default |

**Verification Note** (from opendatahub-documentation sources):
- The repository uses conditional compilation with `ifdef::self-managed[]`, `ifdef::cloud-service[]`, `ifdef::upstream[]`
- Upstream ODH uses `opendatahub` namespace instead of `redhat-ods-applications`
- Downstream RHOAI namespaces start with `redhat-ods-` or `rhods-` prefix

**Important Constraint**: "Do not install independent software vendor (ISV) applications in namespaces associated with OpenShift AI."

#### 3. Core Architectural Components

**Meta-Operator**:
- Deploys and maintains all components and sub-operators that are part of OpenShift AI
- Uses DataScienceCluster (DSC) and DSCInitialization (DSCI) custom resources
- Manages component lifecycle and dependencies

**Dashboard**:
- Customer-facing dashboard
- Shows available and installed applications for the OpenShift AI environment
- Provides learning resources: tutorials, quick start examples, documentation
- Located in `redhat-ods-applications` namespace
- Deployed as `rhods-dashboard` deployment

**Model Serving**:
- Deploy trained machine-learning models to serve intelligent applications in production
- Applications can send requests to the model using its deployed API endpoint
- Supports multiple runtimes and serving platforms

**Data Science Pipelines**:
- Build portable machine learning (ML) workflows with data science pipelines 2.0
- Uses Docker containers for portability
- Allows data scientists to automate workflows during model development

**Monitoring & Observability**:
- **Alertmanager**: Alert management and routing
- **OpenShift Telemetry**: Cluster metrics collection
- **Prometheus**: Metrics gathering, organization, and display
- Purpose: Monitoring and billing for OpenShift AI resources
- Located in `redhat-ods-monitoring` namespace

#### 4. Additional Architecture Topics Covered

Based on Slack message references, the architecture chapter includes:

**Disconnected Environment Architecture**:
- Separate documentation for disconnected/air-gapped deployments
- Special considerations for GPU operators in disconnected environments
- Certificate authority (CA) bundle configuration for database connections

**Component Lifecycle Management**:
- Enabling/disabling components via DataScienceCluster CR
- Component resource customization
- Management state: `Managed`, `Removed`, `Unmanaged`

**Example from opendatahub-documentation** (enabling Model Registry):
```yaml
spec:
  components:
    modelregistry:
      managementState: Managed
      registriesNamespace: rhoai-model-registries
```

### Upstream vs Downstream Documentation Files

**Source Files**: The `opendatahub-documentation` repository (cloned to `./src.repos/opendatahub-documentation`) contains **user-facing documentation modules** that use **conditional compilation** to generate both ODH and RHOAI docs from the same AsciiDoc sources.

**Example Conditional Patterns**:
```asciidoc
ifdef::self-managed,cloud-service[]
.. In the {openshift-platform} console, from the *Project* list, select *redhat-ods-applications*.
endif::[]
ifdef::upstream[]
.. In the {openshift-platform} console, from the *Project* list, select *opendatahub*.
endif::[]
```

**Files Mentioning RHOAI Architecture Namespaces** (25 files found):
- `modules/enabling-the-model-registry-component.adoc` - References `redhat-ods-applications` namespace for operator deployment
- `modules/enabling-nvidia-gpus.adoc` - References `redhat-ods-applications` for migration-gpu-status ConfigMap
- `modules/viewing-audit-logs.adoc` - Monitoring namespace references
- Many others using conditional `redhat-ods-*` namespace references

**No Dedicated Architecture Files**: The `opendatahub-documentation` repository contains **ZERO dedicated architecture files** - architecture documentation exists only in:
1. Downstream RHOAI product docs (docs.redhat.com) - **CURRENT**
2. Architecture-decision-records repository (shared ODH/RHOAI) - Mixed currency
3. Upstream ODH operator DESIGN.md - Current for operator only
4. Upstream ODH public website - **SEVERELY OUTDATED** (frozen 2023)

### Key Differences from ODH Upstream

| Aspect | ODH (Upstream) | RHOAI (Downstream Product Docs) |
|--------|----------------|--------------------------------|
| **Architecture page** | ❌ Frozen at May 2023 (v1.7) on opendatahub.io/docs/architecture/ | ✅ Current "Chapter 1. Architecture" in Installing guide, updated per release |
| **Namespace naming** | `opendatahub` | `redhat-ods-operator`, `redhat-ods-applications`, `redhat-ods-monitoring`, `rhods-notebooks` |
| **Publishing location** | https://opendatahub.io/docs/ (Read the Docs) | https://docs.redhat.com/ (official Red Hat product portal) |
| **Maintenance** | ⚠️ Public architecture page not maintained since 2023 | ✅ Updated with each product release (2.22, 2.23, 3.2, 3.3) |
| **Format** | Static markdown page + outdated interactive React diagram | Official Red Hat product documentation (likely HTML/DocBook or AsciiDoc-generated) |
| **Audience** | Open-source community, developers | Enterprise customers, administrators, architects |
| **Versioning** | Website shows "current" without version clarity | Clear versioning: 2.22, 2.23, 3.2, 3.3 with per-version docs |
| **Deployment models** | Single: self-managed OpenShift | Dual: Self-Managed + Cloud Service (managed add-on) |
| **Support lifecycle** | Community best-effort | Enterprise support with documented EOL dates |

### Significance for Architecture Automation (RHOAIENG-52636)

This discovery reveals **RHOAI already publishes current architecture documentation at docs.redhat.com**, but this exists **separately** from the `architecture-decision-records` repository.

**Implications**:

1. **Two Architecture Documentation Systems**:
   - **A. Product documentation** (docs.redhat.com) - Chapter 1 architecture in Installing guide
   - **B. ADR repository** (architecture-decision-records) - `arch-overview.md` + D1-D9 diagrams

2. **Potential Sync Issues**:
   - Product docs are updated per release
   - ADR repository `arch-overview.md` lags 3+ months (last updated Dec 2025, says v2.13)
   - Risk of inconsistent architecture information across documentation sources

3. **Automation Opportunities**:
   - Could ADR repository `arch-overview.md` be **source of truth** for docs.redhat.com Chapter 1?
   - Or should automation keep them in sync bidirectionally?
   - Or are they documenting different aspects (product install vs component architecture)?

4. **Missing Link**:
   - We found product docs at docs.redhat.com describe architecture
   - We analyzed ADR repository with `arch-overview.md` and diagrams
   - **UNKNOWN**: What is the relationship between these two documentation sources?
   - **UNKNOWN**: Which one is authoritative for RHOAI architecture?
   - **UNKNOWN**: How does downstream GitLab repository (`openshift-ai-documentation`) relate to ADR repository?

### Analysis of Downstream GitLab Repository (openshift-ai-documentation)

**CRITICAL FINDING**: After analyzing the downstream GitLab repository at `<REMOVED>:documentation-red-hat-openshift-data-science-documentation/openshift-ai-documentation`, the relationship between the two architecture documentation sources is now clear.

**Repository**: https://<REMOVED>/documentation-red-hat-openshift-data-science-documentation/openshift-ai-documentation (cloned to `./src.repos/openshift-ai-documentation`)

**Architecture Source Files Found**:
- `modules/architecture-of-openshift-ai-self-managed.adoc` (39 lines)
- `modules/architecture-of-openshift-ai.adoc` (33 lines for Cloud Service variant)

**Included In**:
- **Self-Managed Installing Guide**: `self-managed-installing-rhoai/master.adoc` → "Installing and uninstalling {productname-short} Self-Managed"
- **Self-Managed Disconnected Installing Guide**: `self-managed-disconnected-installing-rhoai/master.adoc`
- **Cloud Service Installing Guide**: `installing-rhoai/master.adoc` → "Installing and uninstalling {productname-short}"

**Published To**: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/[version]/html/installing_and_uninstalling_openshift_ai_self-managed/architecture-of-openshift-ai-self-managed_install

### The Two Architecture Documentation Systems - DEFINITIVELY IDENTIFIED

**RHOAI has TWO SEPARATE, NON-OVERLAPPING architecture documentation artifacts with different purposes and audiences:**

#### Documentation System A: Product User Documentation (docs.redhat.com)

**Source**: `openshift-ai-documentation` GitLab repository → `modules/architecture-of-openshift-ai*.adoc`
- **Length**: 33-39 lines (very brief)
- **Location**: Chapter 1 in Installing and uninstalling guides
- **Audience**: Enterprise customers, administrators installing RHOAI
- **Purpose**: High-level conceptual overview for installation planning
- **Publishing**: https://docs.redhat.com/en/ (official Red Hat product documentation portal)
- **Maintenance**: Part of standard product documentation release cycle
- **Status**: ✅ **Current** - updated with each product release (2.22, 2.23, 3.2, 3.3)

**Content Coverage**:
- Product deployment models (Self-Managed Operator vs Cloud Service managed)
- Service layer components (Dashboard, Model serving, AI pipelines, Jupyter, Distributed workloads, RAG)
- Management layer (Meta-operator, Monitoring services)
- **Namespace architecture** - the 4 key namespaces created during installation:
  - `redhat-ods-operator` - Contains the RHOAI Operator
  - `redhat-ods-applications` - Dashboard and core components
  - `redhat-ods-monitoring` - Monitoring and billing (Cloud Service only)
  - `rhods-notebooks` - Workbench deployment
- Installation constraints (no ISV apps in RHOAI namespaces)

**What It Does NOT Cover**:
- ❌ Component-level architecture diagrams (no D1-D9 diagrams)
- ❌ Component interaction details
- ❌ Network architecture
- ❌ Detailed component design decisions
- ❌ Architecture Decision Records (ADRs)
- ❌ Technical depth on operator architecture

#### Documentation System B: Component Architecture Documentation (ADR Repository)

**Source**: `architecture-decision-records` GitHub repository → `documentation/arch-overview.md`
- **Length**: 94 lines + D1-D9 PNG diagrams + draw.io sources
- **Location**: Separate GitHub repository (opendatahub-io/architecture-decision-records)
- **Audience**: Architects, engineers, component teams, security reviewers
- **Purpose**: Detailed component architecture and design decisions
- **Publishing**: GitHub repository (not published to docs.redhat.com)
- **Maintenance**: Updated by architects/engineers as components change
- **Status**: ⚠️ **Out of date** - last updated Dec 2025, says v2.13, missing components (AutoML, LlamaStack, Model Registry integration)

**Content Coverage**:
- Component-specific architecture with D1-D9 diagrams:
  - D1: Operator
  - D2: Dashboard
  - D3: Pipelines
  - D4: ModelMesh Serving
  - D5: KServe
  - D6: Training (Distributed Workloads)
  - D7: TrustyAI
  - D9: Workbenches
  - D8: **MISSING**
- Network architecture diagrams (in `/images/network/`)
- Architecture Decision Records (ADRs) for component integration
- Component interaction patterns and dependencies
- Technical design details for engineers

**What It Does NOT Cover**:
- ❌ High-level product deployment overview for users
- ❌ Installation procedures or prerequisites
- ❌ User-facing conceptual information
- ❌ Monitoring/billing architecture (product ops focus)

### Relationship Between The Two Systems

**THEY ARE COMPLEMENTARY, NOT DUPLICATE**:

| Aspect | Product Docs (docs.redhat.com) | ADR Repository (GitHub) |
|--------|-------------------------------|------------------------|
| **Purpose** | Installation planning overview | Component architecture reference |
| **Audience** | Customers, admins installing RHOAI | Engineers, architects, security teams |
| **Depth** | High-level conceptual (39 lines) | Detailed technical (94 lines + diagrams) |
| **Diagrams** | None | D1-D9 component diagrams + network diagrams |
| **Format** | AsciiDoc prose description | Markdown with diagram PNGs + draw.io sources |
| **Publishing** | docs.redhat.com (official product docs) | GitHub repository (internal reference) |
| **Currency** | ✅ Current (updated per release) | ⚠️ Lags 3+ months |
| **Part of release** | Yes (standard docs release) | No (maintained separately) |
| **Version tracking** | By product version (2.22, 2.23, 3.2, 3.3) | Single "current" with manual version header |
| **Covers namespaces** | ✅ Yes (installation focus) | Minimal (component focus) |
| **Covers components** | ✅ List with brief descriptions | ✅ Detailed with architecture diagrams |
| **ADRs** | ❌ No | ✅ Yes (separate ADR files) |
| **Draw.io sources** | ❌ No | ✅ Yes (`documentation/diagram/`) |
| **Network diagrams** | ❌ No | ✅ Yes (`documentation/images/network/`) |

### Why Both Exist

**Product Documentation** (docs.redhat.com):
- **Required for product release** - Every GA release must have current documentation
- **Customer-facing** - Helps customers understand what they're installing
- **Compliance** - Meets Red Hat product documentation standards
- **Support** - L1/L2 support teams reference for basic architecture questions
- **Sales** - Product overview for pre-sales and solution architects

**ADR Repository** (GitHub):
- **Engineering reference** - Component teams need detailed architecture
- **Security reviews** - SAR (Security Architecture Review) requires detailed diagrams
- **Architecture governance** - ADRs document design decisions and rationale
- **Cross-team coordination** - Shared understanding of component interactions
- **Technical depth** - D1-D9 diagrams show internal component architecture
- **Not customer-facing** - Internal reference for Red Hat engineering

### Implications for Automation (RHOAIENG-52636)

The automation initiative (RHOAIENG-52636) should focus on the **ADR repository** (System B), NOT the product documentation (System A), because:

1. **Product docs are already maintained** - They're updated with each release as part of standard documentation workflow
2. **ADR repository lags significantly** - 3+ month gap shows manual process doesn't scale
3. **Product docs are brief** - 39 lines, no diagrams, doesn't benefit from automation
4. **ADR repository is complex** - 94 lines + D1-D9 diagrams + draw.io sources + network diagrams require automation

**Automation Scope Should Include**:
- ✅ Syncing component ADRs → `arch-overview.md` aggregate document
- ✅ Updating D1-D9 component diagrams when components change
- ✅ Maintaining version header in sync with releases
- ✅ Detecting missing components (e.g., AutoML, LlamaStack not yet integrated)
- ✅ Validating diagram numbering (fixing D8 gap)
- ❌ Product documentation `architecture-of-openshift-ai*.adoc` modules (already maintained manually)

**Potential Future Integration**:
- Could ADR repository diagrams be **referenced** from product docs? (Currently they're not)
- Could product docs link to ADR repository for "more detailed architecture information"?
- Could automation generate simplified overview from ADR repository for product docs?

### Upstream Sync Structure

**Discovered**: The `openshift-ai-documentation` repository has an `upstream/` directory containing:
- `opendatahub-documentation-main/` - Fetched upstream ODH documentation
- `fraud-detection-main/` - Upstream tutorial content
- `fetch-upstream.sh` - Script to sync upstream content

**Upstream-First Flow**:
1. Changes made to `opendatahub-io/opendatahub-documentation` (upstream GitHub)
2. Fetched to `openshift-ai-documentation/upstream/opendatahub-documentation-main/` (downstream GitLab)
3. Adapted with RHOAI-specific content using AsciiDoc conditionals (`ifdef::self-managed[]`, `ifdef::cloud-service[]`)
4. Published to docs.redhat.com

**Architecture Modules**:
- `architecture-of-openshift-ai*.adoc` are **downstream-only** (not in upstream ODH docs)
- Upstream ODH has NO equivalent architecture documentation module
- This confirms ODH architecture documentation burden falls on RHOAI downstream (as previously identified)

---

## Additional Resources Referenced

### Key Miro Boards Mentioned
- RHOAI C4 Architecture: https://miro.com/app/board/uXjVJBd41q0=/
- Gateway/BYOIDC Architecture: https://miro.com/app/board/uXjVI2ds8IE=/
- LlamaStack Integration: https://miro.com/app/board/uXjVJRyr8IY=/
- Branching Strategy: https://miro.com/app/board/uXjVJSKkKO4=/
- Ray/Codeflare Security: https://miro.com/app/board/uXjVKbCItV0=/

### Official Documentation Repositories
- **ODH (Upstream)**: https://github.com/opendatahub-io/opendatahub-documentation → https://opendatahub.io/docs/
- **RHOAI (Downstream)**: https://<REMOVED>/documentation-red-hat-openshift-data-science-documentation/openshift-ai-documentation → https://docs.redhat.com/en/documentation/red_hat_openshift_ai/
- **Documentation Flow**: Upstream-first (GitHub → GitLab), per <REMOVED>
- Feature Refinement Template: <REMOVED>
- Architecture Design Document (ADD) Template: <REMOVED>
- RHOAI Operator Dependencies: <REMOVED>
- Definition of Ready/Done: <REMOVED>

### GitHub Resources
- OpenDataHub Architecture Decision Records: https://github.com/opendatahub-io/architecture-decision-records

---

*Document compiled from:*
- *Slack message analysis: June 2025 - March 2026 (AI/RHOAI-focused channels)*
- *Jira ticket analysis: RHAIENG, RHAISTRAT, RHOAIENG projects (2024-2026)*
- *ADR repository analysis: opendatahub-io/architecture-decision-records (cloned March 11, 2026)*
- *Upstream ODH repositories: opendatahub.io, opendatahub-operator, opendatahub-documentation*
*Primary focus: General architecture diagrams + RHOAI/AI platform-specific requirements + Upstream vs Downstream documentation strategies*
*Last updated: March 11, 2026*
