---
name: aggregate-platform-architecture
description: Combine multiple component architecture summaries into a platform-level architecture document. Use after generating component summaries to create a wholistic platform view.
allowed-tools: Read, Glob, Grep, Write, Bash(ls *), Bash(find *)
disable-model-invocation: true
---

# Aggregate Platform Architecture

Combine component architecture summaries (`GENERATED_ARCHITECTURE.md` files) into a comprehensive platform-level architecture document.

## Arguments

Required/optional arguments:
- `--distribution=odh|rhoai` (default: rhoai)
- `--version=X.Y` (default: 3.3)
- `--repos-dir=<path>` (default: current directory)

Example: `/aggregate-platform-architecture --distribution=rhoai --version=3.3 --repos-dir=~/repos`

## Instructions

Aggregate component architectures into a platform-level document by following these steps:

### Step 1: Discover Component Summaries

Find all `GENERATED_ARCHITECTURE.md` files in subdirectories:

```bash
find $repos-dir -name "GENERATED_ARCHITECTURE.md" -type f
```

If no files found, output error and stop.

### Step 2: Read Component Summaries

For each `GENERATED_ARCHITECTURE.md` file found:
1. Read the entire file
2. Extract component name from the "# Component:" heading
3. Extract metadata (distribution, version, deployment type)
4. Store the content for aggregation

### Step 3: Filter by Distribution

Include only components that match the requested distribution:
- If `--distribution=odh`: Include components with "Distribution: ODH" or "Distribution: ODH, RHOAI"
- If `--distribution=rhoai`: Include components with "Distribution: RHOAI" or "Distribution: ODH, RHOAI"

### Step 4: Extract Structured Data

From each component markdown, parse:
- **Dependencies**: Look for "### Internal ODH Dependencies" tables
- **Network Services**: Extract all "### Services" tables
- **Security**: Collect all RBAC tables, secrets, auth policies
- **Integration Points**: Find "## Integration Points" tables
- **APIs**: Gather all CRDs, HTTP endpoints, gRPC services

### Step 5: Build Dependency Graph

Analyze component dependencies to understand relationships:
1. Create a list of all components found
2. For each component, list what it depends on (from "Internal ODH Dependencies")
3. Identify central components (most dependencies pointing to them)
4. Identify leaf components (few/no dependents)

### Step 6: Aggregate Network Architecture

Combine network information:
1. Merge all services tables (deduplicate if same service appears in multiple components)
2. List all ingress points (external entry points to the platform)
3. List all egress destinations (external services the platform calls)
4. Identify service mesh configuration (mTLS modes, peer authentication)

### Step 7: Aggregate Security

Combine security information:
1. Merge all RBAC tables (cluster roles, role bindings)
2. List all secrets used across components
3. Identify authentication patterns (Bearer tokens, mTLS, AWS IAM, etc.)
4. Summarize authorization policies

### Step 8: Synthesize Platform Architecture

Generate `{distribution}-{version}-PLATFORM.md` with this structure:

```markdown
# Platform: Red Hat OpenShift AI {version}

## Metadata
- **Distribution**: {distribution}
- **Version**: {version}
- **Release Date**: {date}
- **Base Platform**: OpenShift Container Platform 4.14+
- **Components Analyzed**: {count}

## Platform Overview

{2-3 paragraph summary of what the platform does, derived from component purposes}

## Component Inventory

| Component | Type | Version | Purpose |
|-----------|------|---------|---------|
| {component} | {Operator/Service/Frontend} | {version} | {short purpose} |

## Component Relationships

### Dependency Graph

{Text-based visualization of component dependencies, showing which components depend on others}

Example:
```
odh-dashboard → model-registry (API calls)
              → kserve (API calls)

kserve → istio (traffic management)
       → knative-serving (autoscaling)
       → model-registry (model metadata)

data-science-pipelines → kserve (model deployment)
                       → model-registry (model storage)
```

### Central Components
{List components with most dependencies - core platform services}

### Integration Patterns
{Common patterns: API calls, CRD creation, event watching, etc.}

## Platform Network Architecture

### Namespaces

| Namespace | Purpose | Components |
|-----------|---------|------------|
| {namespace} | {purpose} | {components deployed here} |

### External Ingress Points

{Aggregate all ingress from component summaries}

| Component | Ingress Type | Hosts | Port | Protocol | Encryption | Purpose |
|-----------|--------------|-------|------|----------|------------|---------|
| {component} | {Istio Gateway/Route} | {hosts} | {443/TCP} | {HTTPS} | {TLS 1.3} | {purpose} |

### External Egress Dependencies

{Aggregate all egress from component summaries}

| Component | Destination | Port | Protocol | Encryption | Purpose |
|-----------|-------------|------|----------|------------|---------|
| {component} | {destination} | {443/TCP} | {HTTPS} | {TLS 1.2+} | {purpose} |

### Internal Service Mesh

| Setting | Value | Components Using |
|---------|-------|------------------|
| mTLS Mode | {STRICT/PERMISSIVE} | {components} |
| Peer Authentication | {config} | {namespaces} |

## Platform Security

### RBAC Summary

{Aggregate cluster roles, showing which components need which permissions}

| Component | ClusterRole | API Groups | Resources | Verbs |
|-----------|-------------|------------|-----------|-------|
| {component} | {role} | {groups} | {resources} | {verbs} |

### Secrets Inventory

{List all secrets used across the platform}

| Component | Secret Name | Type | Purpose |
|-----------|-------------|------|---------|
| {component} | {secret} | {type} | {purpose} |

### Authentication Mechanisms

{Summarize auth patterns across platform}

| Pattern | Components Using | Enforcement Point |
|---------|------------------|-------------------|
| Bearer Tokens (JWT) | {components} | {Istio/etc} |
| mTLS Client Certs | {components} | ServiceMesh |
| AWS IAM Credentials | {components} | External services |

## Platform APIs

### Custom Resource Definitions

{Aggregate all CRDs from components}

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| {component} | {group} | {kind} | {Namespaced/Cluster} | {purpose} |

### Public HTTP Endpoints

{Aggregate user-facing HTTP endpoints}

| Component | Path | Method | Port | Protocol | Auth | Purpose |
|-----------|------|--------|------|----------|------|---------|
| {component} | {path} | {method} | {8080/TCP} | {HTTPS} | {auth} | {purpose} |

## Data Flows

### Key Platform Workflows

{Identify 3-5 major workflows that span multiple components}

Example:
#### Workflow 1: Model Training to Deployment

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | Notebook | User trains model | Uploads to S3 |
| 2 | Data Science Pipelines | Orchestrates deployment | Creates InferenceService CR |
| 3 | KServe | Deploys model | Registers with Model Registry |
| 4 | Model Registry | Stores metadata | - |

## Deployment Architecture

### Deployment Topology

{Describe how components are deployed across namespaces}

### Resource Requirements

{If available from component summaries, aggregate resource requests/limits}

## Version-Specific Changes ({version})

{Aggregate recent changes from all components for this version}

| Component | Changes |
|-----------|---------|
| {component} | - Change 1<br>- Change 2 |

## Platform Maturity

{Analyze platform based on component data}

- **Total Components**: {count}
- **Operator-based Components**: {count}
- **Service Mesh Coverage**: {percentage}%
- **mTLS Enforcement**: {STRICT/PERMISSIVE/MIXED}
- **CRD API Versions**: {list of API versions used}

## Next Steps for Documentation

{Suggest what should be documented next}

1. Generate diagrams from this platform architecture
2. Update ADRs (Architecture Decision Records) repository
3. Create user-facing architecture documentation
4. Generate security network diagrams for SAR (Security Architecture Review)
```

### Step 9: Write Output File

Create the platform architecture file:
- Filename: `{distribution}-{version}-PLATFORM.md` (e.g., `rhoai-3.3-PLATFORM.md`)
- Location: `platform-architecture/` subdirectory of repos-dir (create if doesn't exist)

### Step 10: Report Results

Output a summary:

```
✅ Platform architecture aggregated!

Distribution: {distribution}
Version: {version}
Components analyzed: {count}

Components:
- {component1}
- {component2}
...

File created:
- platform-architecture/{distribution}-{version}-PLATFORM.md

Summary:
- {N} components aggregated
- {N} CRDs documented
- {N} namespaces identified
- {N} external dependencies found
- {N} internal integrations mapped

Next steps:
1. Review platform-architecture/{distribution}-{version}-PLATFORM.md
2. Share with Architecture Council for feedback
3. Generate diagrams from structured markdown (Mermaid, C4, security diagrams)
4. Use for Security Architecture Review (SAR) documentation
```

## Notes

- Component summaries must exist first (run `/repo-to-architecture-summary` on each component)
- This skill parses markdown tables to extract structured data
- The aggregation focuses on platform-level relationships, not repeating all component details
- The output is optimized for generating platform-wide diagrams
- Pay attention to cross-component integration patterns
