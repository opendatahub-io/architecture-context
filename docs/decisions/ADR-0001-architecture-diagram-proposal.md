# Architecture Diagram Automation Proposal
**AI-Driven Architecture Documentation Generation for ODH and RHOAI**

**Date**: March 11, 2026
**Status**: Draft Proposal
**Related Initiatives**: RHOAIENG-52636 (AI Automation for RHOAI architecture)
**Context Documents**:
- [`Architecture Diagram Requirements`](../notes/architecture-diagram-requirements.md) - Requirements from Slack/Jira/repository analysis
- `./RHOAI_LIFECYCLE_ANALYSIS.md` - Feature development lifecycle and process gaps

---

## 🎯 Critical Requirement: Structured Markdown for Security Diagrams

**Issue Identified**: Security diagrams require **precise technical details**, not vague prose:
- ✅ Exact port numbers: `8443/TCP` (not "HTTPS port")
- ✅ Specific protocols: `gRPC/HTTP2`, `PostgreSQL wire protocol` (not "network traffic")
- ✅ TLS versions: `TLS 1.3`, `mTLS with STRICT PeerAuthentication` (not "encrypted")
- ✅ Auth mechanisms: `mTLS client certificates`, `AWS IAM role credentials` (not "authenticated")
- ✅ RBAC details: Specific API groups, resources, verbs (not "has permissions")
- ✅ Network policies: Exact CIDR blocks, port ranges (not "restricted network")

**Solution for MVP (Phase 0)**: **Structured Markdown with Tables**
- Use **markdown tables** for ports, protocols, TLS, auth (machine-parseable by LLMs)
- Use **structured sections** consistently (Network Architecture, Security, Data Flows)
- **LLM-based transpilation**: Claude reads markdown → generates diagrams (Mermaid, security diagrams)
- **Human-editable**: Engineers can review/fix in familiar format
- **Single source of truth**: Markdown is both documentation AND data source

**Optional Enhancement (Phase 1+)**: **Add YAML if needed**
- Consider YAML only if: Template-based transpilation needed for speed, strict schema validation required
- For MVP: Structured markdown is sufficient and simpler

**Why This Matters**: Security Architecture Reviews (SAR) are **mandatory** for RHOAI features. Imprecise diagrams fail security review, blocking releases. Auto-generated diagrams MUST have 100% precision on security-critical details.

**Components Output (Phase 0)**: `GENERATED_ARCHITECTURE.md` (structured markdown with tables)

---

## Executive Summary

This proposal outlines an AI-driven system for automatically generating and maintaining architecture documentation for Open Data Hub (ODH) and Red Hat OpenShift AI (RHOAI). The system addresses the critical 3+ month lag in architecture documentation by:

1. **Scanning component repositories** to generate component-level architecture summaries (structured markdown with tables)
2. **Aggregating component summaries** into platform-level architecture documentation
3. **Generating multiple diagram formats** from structured data (Mermaid, C4, security diagrams, PNG)
4. **Supporting multi-distribution** architecture (ODH upstream + RHOAI downstream)
5. **Producing version-specific diagrams** from release branches
6. **Serving multiple stakeholders** with appropriate diagram types and abstraction levels

**Key Innovation**: Use **structured markdown with tables** as the source of truth (capturing precise port numbers, protocols, TLS versions, auth mechanisms). Diagrams are generated via **LLM-based transpilation** (Claude reads markdown → generates Mermaid/C4/security diagrams), ensuring security diagrams have the exact technical details needed for security reviews.

**🎯 Recommended Starting Point: Skills-Based MVP** (Weeks 1-4, not months)

Instead of building production-grade custom agents immediately, **start with Claude Code skills** for rapid prototyping and stakeholder validation:

- ✅ **Faster to value**: Create 4 skills in days (not custom agents in months)
- ✅ **Lower risk**: Get architect/security feedback BEFORE committing to automation infrastructure
- ✅ **Iterative refinement**: Adjust markdown structure based on real stakeholder feedback
- ✅ **Proof of concept**: Generate actual architecture docs for 5-10 RHOAI components
- ✅ **Decision gate**: Only build production agents (Phase 1+) if MVP validates the approach

**MVP Skills to Create**:
1. `/repo-to-architecture-summary` - Analyze single component repo → Structured markdown
2. `/aggregate-platform-architecture` - Combine component markdowns → Platform architecture
3. `/markdown-to-diagram` - Transpile markdown → Mermaid/C4/security diagrams
4. `/analyze-running-cluster` - QA generated docs against actual deployed cluster

**Why Skills First?**
- Manual invocation is fine for MVP (5-10 components)
- Zero infrastructure to maintain (skills are prompts, not code)
- Rapid iteration on markdown structure and output format
- Real outputs for stakeholder review (not theoretical examples)
- Clear go/no-go decision before building Phase 1 automation

---

## Problem Statement

### Current State (From Lifecycle Analysis)

**Architecture documentation is fundamentally broken**:
- ❌ Architecture docs lag **3+ months** behind product releases (arch-overview.md v2.13 from Dec 2025, product v3.3 from March 2026)
- ❌ **28+ retroactive cleanup tickets** for "Feature documented in architecture diagrams"
- ❌ **Process inversion**: Product docs written BEFORE architecture docs (should be opposite)
- ❌ **No enforcement gates**: Features ship to GA without architecture documentation
- ❌ **Ownership ambiguity**: Unclear who creates/maintains architecture diagrams
- ❌ **Manual maintenance doesn't scale**: 70+ component repositories, multiple versions, dual distributions

### Why Manual Processes Fail

1. **Volume**: 70+ ODH component repositories, each evolving independently
2. **Velocity**: Rapid feature development (RHOAI 3.0 introduces significant changes)
3. **Complexity**: Dual distribution (ODH upstream + RHOAI downstream) with version branches
4. **Distributed ownership**: Component teams implement, architects document (3+ month delay)
5. **Context loss**: Implementation decisions made, code written, then someone tries to reverse-engineer architecture months later

### What We Need

**Architecture documentation that**:
- ✅ Stays current with codebase (auto-updated on commits/releases)
- ✅ Captures implementation reality (not outdated design intentions)
- ✅ Serves multiple stakeholders (engineers, architects, security, customers)
- ✅ Supports multiple distributions (ODH, RHOAI, version branches)
- ✅ Generates multiple diagram types (C4, component, network, deployment)
- ✅ Integrates with existing workflows (ADR repo, product docs, release process)

---

## Proposed Solution: AI Agent-Based Architecture Documentation System

### Core Architecture: Component → Platform Aggregation

**Philosophy**: Architecture documentation should be **derived from implementation**, not manually written after the fact.

```
┌─────────────────────────────────────────────────────────────────┐
│  PHASE 1: COMPONENT ANALYSIS (Parallel per-repo agents)        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Component Repo      AI Agent Scans        Component           │
│  ──────────────  →   ─────────────────  →  Architecture        │
│  (Go/Python/TS)      • Code structure       Summary            │
│                      • APIs/interfaces      ──────────          │
│  - Operator CRDs     • Dependencies         (Markdown)         │
│  - API endpoints     • Deployment configs   ──────────          │
│  - Service mesh      • Network topology     • Purpose          │
│  - Config files      • Data flows           • Architecture     │
│  - Helm charts       • Security boundaries  • Dependencies     │
│  - README/docs       • Running clusters     • APIs             │
│                        (optional)            • Deployment       │
│                                              • Network          │
│                                              • Security         │
│                                              • Metadata         │
│                                                                 │
│  Outputs: 70+ component markdown files (one per repo)          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  PHASE 2: PLATFORM AGGREGATION (Single aggregator agent)       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Component           Aggregator Agent     Platform              │
│  Summaries (70+)  →  ────────────────  →  Architecture         │
│  ──────────          • Relationship        Document             │
│  (Markdown)            detection          ────────────          │
│                      • Dependency graph    (Markdown)           │
│  + Version context   • Integration         ────────────         │
│  + Distribution        points              • Overview           │
│    (ODH/RHOAI)       • Network topology    • Components (all)   │
│                      • Data flows          • Integrations       │
│                      • Trust boundaries    • Network arch       │
│                      • Deployment models   • Security           │
│                                            • Deployment          │
│                                              topologies          │
│                                                                 │
│  Outputs: Unified platform architecture markdown               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  PHASE 3: DIAGRAM GENERATION (Transpilation)                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Platform            Transpilers          Multiple              │
│  Architecture     →  ─────────────────  → Diagram               │
│  (Markdown)          (Template-based)     Formats               │
│                      (LLM-assisted)       ──────────            │
│                                                                 │
│  Stakeholder-specific outputs:                                 │
│                                                                 │
│  • Engineers:        Mermaid (in markdown, PRs, wikis)         │
│  • Architects:       Structurizr/C4 (Context, Container,       │
│                        Component, Deployment views)            │
│  • Security:         Network diagrams (trust boundaries,       │
│                        data flows, attack surface)             │
│  • Product Docs:     PNG/SVG exports (for docs.redhat.com)     │
│  • ADR Repository:   draw.io + PNG (D1-D9 component diagrams)  │
│  • Presentations:    Slide-optimized SVG/PNG                   │
│                                                                 │
│  Outputs: 10+ diagram formats per platform version             │
└─────────────────────────────────────────────────────────────────┘
```

### Key Design Decisions

#### 1. Structured Markdown as Source of Truth (Phase 0 MVP)

**Critical Insight**: Security diagrams require **precise technical details** (port 8443/TCP/TLS1.3, not "uses HTTPS"), but this can be captured in **structured markdown** using tables and consistent section formatting.

**MVP Solution (Phase 0)**: **Structured Markdown Only**

Use markdown with **tables and consistent sections** to capture precise security details:
- **Tables** for ports, protocols, TLS versions, auth mechanisms
- **Structured sections** for consistent parsing (Network Architecture, Security, Data Flows)
- **LLM-based transpilation**: Claude reads markdown → generates diagrams
- **Human-editable**: Engineers can review/fix errors in familiar format
- **Single source of truth**: Markdown is both documentation AND data source

**Why Structured Markdown for MVP?**
- ✅ **Captures security details**: Tables with port 8443/TCP/TLS1.3 (precise, not vague)
- ✅ **Machine-parseable by LLMs**: Claude can read tables and generate diagrams
- ✅ **Human-editable**: Engineers know markdown (no YAML syntax errors)
- ✅ **Git-friendly**: Readable diffs, familiar format
- ✅ **Simpler for MVP**: One format instead of two (YAML + markdown)
- ✅ **LLM-native**: Claude excels at reading/writing structured markdown

**Component Output (Phase 0)**:
```
summaries/
└── kserve/
    └── GENERATED_ARCHITECTURE.md    # Structured markdown (source of truth)
```

**Optional Enhancement (Phase 1+)**: Add YAML if needed for:
- Template-based transpilation (faster than LLM calls at scale)
- Strict schema validation (markdown too flexible)
- Programmatic parsing by non-LLM tools

---

### Component Architecture Markdown Template (Phase 0)

> **📝 IMPORTANT - Phase 0 MVP Uses Structured Markdown (Not YAML)**
>
> For the **Phase 0 MVP**, we use **structured markdown with tables** as the single source of truth. This approach is:
> - ✅ Simpler (one format instead of two)
> - ✅ LLM-native (Claude excels at reading/writing markdown tables)
> - ✅ Human-editable (engineers know markdown, no YAML syntax errors)
> - ✅ Machine-parseable (LLMs can read tables and generate diagrams)
>
> **The YAML schema examples below are for reference only** and represent a potential Phase 1+ enhancement if we need template-based transpilation at scale. **For MVP: Focus on structured markdown, not YAML.**

---

**Purpose**: Structured markdown that captures ALL technical details for security/network diagrams

#### Example: KServe Component Architecture (Structured Markdown)

```markdown
# Component: KServe

## Metadata
- **Repository**: https://github.com/opendatahub-io/kserve
- **Version**: 0.13.0
- **Distribution**: ODH, RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Standardized serverless ML inference platform on Kubernetes

**Detailed**: KServe provides a Kubernetes CRD for serving ML models with auto-scaling, traffic management, and multi-framework support. Enables declarative deployment of inference services with predictors, transformers, and explainers.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| kserve-controller-manager | Operator Controller | Watches InferenceService/TrainedModel CRDs, creates Knative Services and predictor Deployments |
| kserve-webhook-server | Validating/Mutating Webhook | Validates InferenceService specs, injects storage initializer containers and ServiceMesh sidecars |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | Declares inference service with predictor/transformer/explainer |
| serving.kserve.io | v1alpha1 | TrainedModel | Namespaced | References trained model artifacts for serving |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /v1/models/{model_name}:predict | POST | 8080/TCP | HTTP | mTLS (ServiceMesh) | Optional Bearer Token | Model inference endpoint |
| /v1/models/{model_name} | GET | 8080/TCP | HTTP | mTLS (ServiceMesh) | None | Model metadata retrieval |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| inference.GRPCInferenceService | 8081/TCP | gRPC | mTLS | Optional mTLS client cert | gRPC inference protocol |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Istio | 1.20+ | Yes | Traffic management, mTLS, authn/authz |
| Knative Serving | 1.12+ | Yes | Serverless autoscaling, revision management |
| cert-manager | 1.13+ | Yes | TLS certificate provisioning |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| odh-model-controller | Watches same CRDs | Model serving coordination |
| service-mesh | Sidecar injection | mTLS, traffic routing |
| model-registry | API calls | Model metadata and artifact locations |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kserve-controller-manager-metrics | ClusterIP | 8080/TCP | 8080 | HTTP | None | Prometheus | Internal only |
| kserve-webhook-server-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.3 | mTLS client certs | Internal only |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| istio-gateway | Istio Gateway | *.example.com | 443/TCP | HTTPS | TLS 1.3 | SIMPLE (TLS termination) | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| s3.amazonaws.com | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM credentials | Model artifact download |
| kubernetes.default.svc | 443/TCP | HTTPS | TLS 1.3 | Service account token | Kubernetes API calls |

### Service Mesh Configuration

| Setting | Value | Notes |
|---------|-------|-------|
| mTLS Mode | STRICT | All service-to-service communication must use mTLS |
| Peer Authentication | STRICT (namespace-scoped) | Applied to all pods in deployment namespace |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kserve-manager-role | serving.kserve.io | inferenceservices, trainedmodels | get, list, watch, create, update, patch, delete |
| kserve-manager-role | "" (core) | services, serviceaccounts | get, list, watch, create, update, patch, delete |
| kserve-manager-role | apps | deployments | get, list, watch, create, update, patch, delete |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kserve-manager-rolebinding | {deployment.namespace} | kserve-manager-role | kserve-controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| kserve-webhook-server-cert | kubernetes.io/tls | TLS certificate for webhook server | cert-manager | Yes (90 days) |
| storage-config | Opaque | S3 credentials (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY) | Manual/External Secrets Operator | No |

### TLS Certificates

| Certificate | Issuer | Common Name | Validity | Auto-Renewal |
|-------------|--------|-------------|----------|--------------|
| webhook-server-cert | cert-manager | kserve-webhook-server-service.{namespace}.svc | 90 days | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /v1/models/*:predict | POST | Optional Bearer Token | Istio RequestAuthentication | Validated if provided |
| /v1/models/*:predict | POST | Optional mTLS client cert | ServiceMesh | Validated if ServiceMesh enabled |
| /v1/models/*:predict | POST | Namespace-based authz | Istio AuthorizationPolicy | Allow: {deployment.namespace}, user-workbenches; Deny: external |

## Data Flows

### Flow 1: Inference Request (External Client → Model)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | Istio Gateway | 443/TCP | HTTPS | TLS 1.3 | Optional Bearer Token |
| 2 | Istio Gateway | Knative Activator | 8012/TCP | HTTP | mTLS (ServiceMesh) | Service Identity |
| 3 | Knative Activator | Predictor Pod | 8080/TCP | HTTP | mTLS (ServiceMesh) | Service Identity |
| 4 | Predictor Pod | S3 Storage | 443/TCP | HTTPS | TLS 1.2 | AWS IAM Role |

### Flow 2: Model Deployment (User → InferenceService Created)

| Step | Source | Destination | Port | Protocol | Encryption | Auth | Action |
|------|--------|-------------|------|----------|------------|------|--------|
| 1 | User (kubectl) | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | Kubeconfig token | Create InferenceService CR |
| 2 | Kubernetes API | KServe Controller | N/A (internal watch) | Internal | N/A | Service account token | Watch notification |
| 3 | KServe Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | Service account token | Create Deployment |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| model-registry | API Client (gRPC) | 9090/TCP | gRPC | mTLS | Fetch model metadata and artifact URIs |
| data-science-pipelines | CRD Creation | 6443/TCP | Kubernetes API | TLS 1.3 | Automated model deployment from pipelines |
| dashboard | API Client (HTTP) | 8080/TCP | HTTP | mTLS | UI for managing InferenceServices |

## Recent Changes (auto-detected from git)

| Version | Date | Changes |
|---------|------|---------|
| 0.13.0 | 2026-01 | - Added vLLM runtime support for LLM serving<br>- Improved autoscaling (5s → 2s cold start)<br>- Security: Enforced mTLS for all predictor communication |
| 0.12.1 | 2025-11 | - Removed ModelMesh integration (deprecated)<br>- Migrated to Knative-based autoscaling |
```

---

### YAML Schema Reference (Phase 1+ Only)

> **⚠️ NOTE: This section documents the YAML-based approach from the original proposal.**
>
> **For Phase 0 MVP**, we are using **structured markdown with tables** (see example above) as the single source of truth. This YAML schema is included for reference only and represents a potential Phase 1+ enhancement if we need template-based transpilation for performance at scale.
>
> **Phase 0 MVP does NOT use YAML.** The skills will generate and work with structured markdown directly.

The examples below show what auto-generated markdown might look like if we implemented YAML-based templates in Phase 1+:

```markdown
# Component: KServe Operator

## Metadata
- Repository: opendatahub-io/kserve
- Version: 0.13.0
- Distribution: ODH, RHOAI
- Language: Go
- Deployment: Kubernetes Operator

## Purpose
Standardized serverless ML inference platform on Kubernetes...

## Architecture

### Components
- InferenceService Controller (watches InferenceService CRDs)
- Webhook Server (validates/mutates inference service specs)
- Predictor Framework Adapters (SKLearn, XGBoost, TensorFlow, PyTorch, ONNX)

### APIs Exposed
- CRDs:
  - InferenceService (v1beta1)
  - TrainedModel (v1alpha1)
  - ClusterServingRuntime (v1alpha1)
- HTTP/gRPC Inference API (predictor endpoints)

### Dependencies
- External:
  - Istio/Knative (networking, autoscaling)
  - Cert Manager (TLS certificates)
  - Kubernetes API (CRD registration, controllers)
- Internal ODH Components:
  - odh-model-controller (model serving coordination)
  - ServiceMesh (traffic management)

### Deployment Topology
- Namespace: redhat-ods-applications (RHOAI) / opendatahub (ODH)
- Pods:
  - kserve-controller-manager (Deployment, 1 replica)
  - kserve-webhook-server (Deployment, 1 replica)
- Service Accounts: kserve-controller-manager

### Network Architecture
- Ingress: Istio Gateway (external model serving traffic)
- Service Mesh: Envoy sidecars (all predictor pods)
- Internal: ClusterIP services (controller → API server)
- Egress: Model storage access (S3, PVC)

### Security
- RBAC: ClusterRole for CRD management
- mTLS: Between predictor pods (via ServiceMesh)
- Secrets: Model credentials, S3 access keys
- Network Policies: Isolate predictor namespaces

## Data Flows
1. User creates InferenceService CR → kserve-controller watches
2. Controller creates Knative Service + predictor Deployment
3. Inference requests → Istio Gateway → Knative Activator → Predictor pods
4. Predictor loads model from S3/PVC → Serves predictions

## Integration Points
- Model Registry: Fetches model metadata and artifact locations
- Data Science Pipelines: Automated model deployment from pipelines
- Dashboard: UI for managing inference services

## Recent Changes (auto-detected from git)
- v0.13.0 (Jan 2026): Added vLLM runtime support
- v0.12.1 (Nov 2025): Removed ModelMesh integration (deprecated)
```

**Markdown Structure** (Platform-level):
```markdown
# Red Hat OpenShift AI (RHOAI) Platform Architecture

## Metadata
- Version: 3.3
- Release Date: March 2026
- Distribution: RHOAI Self-Managed
- Base Platform: OpenShift Container Platform 4.14+

## Overview
RHOAI is an AI/ML platform for developing, training, and serving models...

## Component Inventory
1. Dashboard (odh-dashboard)
2. Model Serving (KServe, ModelMesh deprecated)
3. Data Science Pipelines (Kubeflow Pipelines v2)
4. Distributed Workloads (Ray, Training Operator, Kueue)
5. Model Registry
... (all 70+ components)

## Namespace Architecture
- redhat-ods-operator: Operator controller
- redhat-ods-applications: Dashboard, model-registry-operator, core services
- redhat-ods-monitoring: Prometheus, Alertmanager, Telemetry
- rhods-notebooks: Workbench deployments

## Component Relationships
[Component A] --depends-on--> [Component B]
[Component A] --integrates-with--> [Component C]
... (auto-derived from component summaries)

## Network Topology
[Auto-aggregated from component network architectures]

## Security Architecture
[Auto-aggregated from component security sections]

## Deployment Models
- Self-Managed Operator: Customer-managed OpenShift clusters
- Cloud Service (deprecated Oct 2025): Red Hat-managed

## Version-Specific Changes (3.3)
- Added: LlamaStack integration (RAG, Gen AI)
- Added: vLLM optimal config recipes
- Removed: ModelMesh (replaced by KServe)
- Updated: Training Operator (v1.8)
```

#### 2. Dual-Distribution Support (ODH + RHOAI)

**Challenge**: ODH (upstream) and RHOAI (downstream) have different:
- Component sets (ODH has experimental features first)
- Namespaces (`opendatahub` vs `redhat-ods-*`)
- Deployment models (community vs enterprise)
- Documentation requirements (minimal vs comprehensive)

**Solution**: Conditional generation based on distribution flag

```bash
# Generate for ODH upstream
./arch-agent.sh --distribution=odh --version=v3.0

# Generate for RHOAI downstream
./arch-agent.sh --distribution=rhoai --version=3.3

# Generate for both
./arch-agent.sh --distribution=both --version=3.3
```

**Component Markdown Includes Distribution Metadata**:
```markdown
## Metadata
- Distribution: ODH, RHOAI  # or "ODH only" or "RHOAI only"
- ODH Namespace: opendatahub
- RHOAI Namespace: redhat-ods-applications
```

**Platform Aggregator Filters/Adapts** based on distribution:
- ODH mode: Include only components with "ODH" or "both"
- RHOAI mode: Include only components with "RHOAI" or "both"
- Namespace substitution: Replace namespace references

#### 3. Version-Specific Diagram Generation

**Challenge**: Need diagrams for:
- Current development (main branch)
- Release branches (RHOAI 3.3, 3.2, 2.25, etc.)
- ODH versions (v3.0, v2.25, v2.24, etc.)

**Solution**: Use gh-org-clone to fetch version-specific codebases

```bash
# Clone all opendatahub-io repos at v3.0 tag
gh-org-clone --org opendatahub-io \
  --output-dir ./repos/odh-v3.0 \
  --tag v3.0 \
  --include-archived=false

# Clone all red-hat-data-services repos at release-3.3 branch
gh-org-clone --org red-hat-data-services \
  --output-dir ./repos/rhoai-3.3 \
  --branch release-3.3 \
  --include-archived=false

# Run component agents on version-specific repos
./component-agent.sh --repo-dir ./repos/rhoai-3.3/kserve \
  --output ./summaries/rhoai-3.3/kserve.md

# Aggregate for specific version
./platform-agent.sh --summaries-dir ./summaries/rhoai-3.3 \
  --version 3.3 \
  --distribution rhoai \
  --output ./platform/rhoai-3.3-architecture.md
```

**Benefit**: Can regenerate historical architecture documentation to fill gaps

#### 4. Running Cluster Inspection (Optional Enhancement)

**Current Proposal**: Scan code repositories (static analysis)

**Future Enhancement**: Also scan running clusters (dynamic analysis)

**Why?**
- ✅ Captures actual runtime topology (not just intended design)
- ✅ Detects configuration drift (cluster state vs code)
- ✅ Discovers emergent architecture (integration patterns not in code)
- ✅ Validates security policies (actual vs declared)

**How?**
```bash
# Component agent with cluster access
./component-agent.sh --repo-dir ./repos/kserve \
  --kubeconfig ~/.kube/config \
  --namespace redhat-ods-applications \
  --include-runtime-topology

# Agent queries:
# - Running pods/deployments
# - Service endpoints and routes
# - ConfigMaps/Secrets
# - Network policies
# - RBAC rules
# - Resource usage
# - Inter-service traffic (if ServiceMesh telemetry available)
```

**Trade-offs**:
- ➕ More accurate (reality vs intention)
- ➕ Detects undocumented patterns
- ➖ Requires cluster access (security/permissions)
- ➖ Slower (API calls vs local file reads)
- ➖ May vary by cluster (dev vs prod)

**Recommendation**: Start with code-only, add cluster inspection as Phase 2

---

## Implementation Plan

The detailed implementation plan (agent designs, pseudo-code, phased rollout, integration workflows, alternatives considered, risks, and next steps) was split into a separate document:

**[Implementation Plan: Architecture Diagram Automation](../plans/000-architecture-diagram-implementation.md)**

---

**Document Status**: Draft Proposal
**Last Updated**: March 11, 2026
**Next Review**: After stakeholder feedback
**Owner**: [To be assigned]
**Related JIRA**: RHOAIENG-52636 (AI Automation for RHOAI architecture)
