# Platform Diagrams for Open Data Hub 3.3.0

Generated from: `architecture/odh-3.3.0/PLATFORM.md`
Date: 2026-03-12
Components Analyzed: 5 (OpenDataHub Operator, ODH Dashboard, Kubeflow Notebooks, MLflow, Feast)

## Available Diagrams

### For Architects
- [Component Dependency Graph](./platform-dependency-graph.mmd) - Shows component relationships and dependencies
- [Platform Workflows](./platform-workflows.mmd) - End-to-end flows spanning multiple components
- [Platform Maturity](./platform-maturity.txt) - Health metrics and component statistics

### For Security Teams
- [Platform Network Topology](./platform-network-topology.txt) - Complete network architecture with ports, protocols, TLS, auth
- [Platform Security Overview](./platform-security-overview.mmd) - RBAC, auth mechanisms, secrets, service mesh policies

### For Platform Engineers
- [Component Dependency Graph](./platform-dependency-graph.mmd) - Understand integration points
- [Platform Network Topology](./platform-network-topology.txt) - Debug connectivity issues
- [Platform Workflows](./platform-workflows.mmd) - Trace request flows

## How to Use

### Mermaid Diagrams (.mmd files)

**View in GitHub/GitLab:**
Paste into markdown with ` ```mermaid ` code blocks. Example:

````markdown
```mermaid
graph TB
    A --> B
```
````

**Render to PNG locally:**
```bash
# Install mermaid-cli (requires Node.js)
npm install -g @mermaid-js/mermaid-cli

# Render with Chrome (recommended for best quality)
PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i platform-dependency-graph.mmd -o platform-dependency-graph.png -s 3

# Or use default browser
mmdc -i platform-dependency-graph.mmd -o platform-dependency-graph.png -s 3
```

**Online rendering:**
- Copy file contents to [Mermaid Live Editor](https://mermaid.live)
- Export as PNG/SVG for presentations

### ASCII Diagrams (.txt files)
- View in any text editor or terminal
- Include directly in security documentation
- Perfect for SAR (Security Architecture Review) submissions
- Copy-paste into emails, tickets, or Confluence

```bash
# View in terminal
cat platform-network-topology.txt

# View in less
less platform-maturity.txt
```

## Diagram Descriptions

### 1. Component Dependency Graph
**File:** `platform-dependency-graph.mmd` (Mermaid)
**Audience:** Architects, Platform Engineers
**Purpose:** Shows how platform components depend on each other

Central components (most dependencies) are highlighted with thicker borders:
- **Kubernetes API Server** (gray, thick border) - All components depend on it
- **OpenDataHub Operator** (red, thick border) - Deploys all other components
- **ODH Dashboard** (blue, thick border) - Primary user interface

Useful for:
- Understanding blast radius of changes
- Planning component upgrades
- Identifying critical dependencies
- Onboarding new team members

### 2. Platform Network Topology
**File:** `platform-network-topology.txt` (ASCII)
**Audience:** Security Teams, SREs, Compliance
**Purpose:** Complete network architecture showing all ingress points, service mesh communication, and egress destinations

Includes exact details:
- Port numbers (external and internal)
- Protocols (HTTPS, HTTP, gRPC, PostgreSQL, Redis)
- Encryption (TLS versions)
- Authentication mechanisms (OAuth, Bearer Tokens, mTLS, AWS IAM)
- Namespaces and ServiceAccounts
- Trust boundaries (External, Ingress, Service Mesh, Egress)

**Required for:**
- Security Architecture Reviews (SAR)
- Compliance audits
- Network policy configuration
- Firewall rule documentation
- Incident response planning

### 3. Cross-Component Workflows
**File:** `platform-workflows.mmd` (Mermaid Sequence Diagrams)
**Audience:** Architects, Product Managers, SREs
**Purpose:** Shows end-to-end user workflows that span multiple components

**Workflows included:**
1. **User Creates Notebook via Dashboard** - OAuth flow, CR creation, notebook provisioning
2. **ML Experiment Tracking with MLflow** - Training script to artifact storage
3. **Feature Store Lifecycle** - Feature definition to online serving
4. **Platform Installation** - DataScienceCluster deployment via operator

Useful for:
- Understanding user journeys
- Debugging cross-component issues
- API integration planning
- Performance optimization

### 4. Platform Security Overview
**File:** `platform-security-overview.mmd` (Mermaid)
**Audience:** Security Teams, Compliance
**Purpose:** Visual representation of security architecture

Shows:
- **Authentication mechanisms** (OAuth, Bearer Tokens, mTLS, AWS IAM, OIDC)
- **ServiceAccounts and ClusterRoles** (RBAC bindings)
- **Critical secrets** (TLS certs, OAuth configs, S3 credentials, DB passwords)
- **Service mesh policies** (PeerAuthentication, AuthorizationPolicy)
- **Webhook security** (admission controllers)

**Highlights:**
- Highly privileged ClusterRoles (red)
- Sensitive secrets containing credentials (yellow)
- Service mesh enforcement (green)

### 5. Platform Maturity Dashboard
**File:** `platform-maturity.txt` (ASCII Tables)
**Audience:** Platform Engineers, Executives, Product Managers
**Purpose:** High-level metrics about platform health and maturity

**Metrics included:**
- Component counts and types (operators, services, web UIs)
- Security posture (mTLS, OAuth, RBAC, webhooks)
- Dependencies (external platform, data stores, integrations)
- API maturity (CRD versions, endpoint counts)
- High availability status
- Multi-tenancy implementation
- Storage backend flexibility
- Cloud compatibility
- Resource requirements
- Platform readiness assessment (85% production-ready)

**Use cases:**
- Executive reviews and roadmap planning
- Maturity assessments for certifications
- Capacity planning
- Cloud migration planning

## Updating Diagrams

To regenerate after platform changes:

```bash
# Step 1: Update component architectures (run in each component repo)
/repo-to-architecture-summary

# Step 2: Collect all component architectures
/collect-component-architectures

# Step 3: Aggregate into platform view
/aggregate-platform-architecture

# Step 4: Regenerate diagrams (this skill)
/generate-platform-diagrams
```

## Customization

### Generate specific formats only
```bash
/generate-platform-diagrams --formats=dependency,network
```

Available formats: `dependency`, `network`, `workflow`, `security`, `maturity`

### Use with different platform files
```bash
/generate-platform-diagrams --platform-file=architecture/rhoai-2.19/PLATFORM.md
```

### Specify output directory
```bash
/generate-platform-diagrams --output-dir=./custom-diagrams
```

## Integration with Documentation

### Embed in Markdown Docs
```markdown
## Architecture Overview

See our [platform dependency graph](./diagrams/platform-dependency-graph.mmd) for component relationships.

For security reviews, see [network topology](./diagrams/platform-network-topology.txt).
```

### Include in Security Reviews
```markdown
# Security Architecture Review - ODH 3.3.0

## Network Architecture
<paste contents of platform-network-topology.txt>

## Security Posture
<render platform-security-overview.mmd to PNG>
```

### Present to Stakeholders
1. Render Mermaid diagrams to PNG at 3x scale for clarity
2. Use platform-maturity.txt for executive summaries
3. Use platform-workflows.mmd to explain user journeys
4. Use platform-dependency-graph.mmd for technical discussions

## Differences from Component Diagrams

| Aspect | Component Diagrams | Platform Diagrams |
|--------|-------------------|-------------------|
| **Input** | GENERATED_ARCHITECTURE.md | PLATFORM.md |
| **Scope** | Single component internals | Cross-component relationships |
| **Audience** | Component developers | Architects, security teams |
| **Focus** | Component APIs, internal structure | Dependencies, workflows, network |
| **Security** | Component-specific RBAC | Platform-wide security posture |
| **Workflows** | Internal component flows | End-to-end multi-component flows |

## Troubleshooting

### Mermaid rendering issues
If diagrams don't render in GitHub:
1. Ensure file extension is `.mmd` or use ` ```mermaid ` code blocks in markdown
2. Check GitHub's Mermaid version compatibility
3. Use Mermaid Live Editor for validation

### PNG export with mmdc
If `mmdc` fails with "browser not found":
```bash
# Install Chrome/Chromium
sudo dnf install chromium  # Fedora/RHEL
sudo apt install chromium-browser  # Ubuntu

# Set browser path
export PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser
mmdc -i diagram.mmd -o diagram.png -s 3
```

### ASCII diagram formatting
If ASCII diagrams look misaligned:
- Use a monospace font (Courier New, Consolas, Monaco)
- Ensure editor doesn't auto-format or wrap lines
- View in terminal with `cat` or `less` for best results

## Related Skills

- `/repo-to-architecture-summary` - Analyze component repos
- `/collect-component-architectures` - Gather GENERATED_ARCHITECTURE.md files
- `/aggregate-platform-architecture` - Create PLATFORM.md from components
- `/rhoai-security-scanner:audit` - Security audit of repos
- `/fips-compliance-checker:fips-scan` - FIPS compliance checking

## Support

For issues or enhancements:
1. Check if PLATFORM.md is up-to-date
2. Verify component architectures are complete
3. Re-run `/aggregate-platform-architecture` if needed
4. Report issues with specific diagram format

## Version History

- **2026-03-12**: Initial generation for ODH 3.3.0
  - 5 components analyzed
  - 5 diagram formats created
  - ASCII + Mermaid formats
