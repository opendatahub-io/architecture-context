# Sub-Agent Controller & Webhook Analysis

When a repository has more than ~20 Go source files across controller and webhook directories, spawn sub-agents to read all files in parallel rather than attempting to read everything in the main agent's context.

## When to use sub-agents

Run these commands to count source files:

```bash
CONTROLLER_COUNT=$(find . -path ./vendor -prune -o \( -path "*/controller*" -o -path "*/webhook*" \) -name "*.go" ! -name "*_test.go" -print | wc -l)
TEMPLATE_COUNT=$(find . -path ./vendor -prune -o \( -path "*/controller*" -o -path "*/webhook*" \) \( -name "*.yaml" -o -name "*.tmpl.yaml" -o -name "*.tmpl" \) -print | wc -l)
echo "Controller/webhook Go files: $CONTROLLER_COUNT, Templates: $TEMPLATE_COUNT"
```

- **20 or fewer files total**: Read them yourself in the main agent. No sub-agents needed.
- **More than 20 files**: Use the sub-agent pattern described below.

## Step 1: Enumerate all source files

```bash
# All non-test Go files in controller and webhook directories
find . -path ./vendor -prune -o \( -path "*/controller*" -o -path "*/webhook*" \) -name "*.go" ! -name "*_test.go" -print | sort

# All template/manifest files in controller and webhook directories
find . -path ./vendor -prune -o \( -path "*/controller*" -o -path "*/webhook*" \) \( -name "*.yaml" -o -name "*.tmpl.yaml" -o -name "*.tmpl" \) -print | sort

# Also enumerate key pkg/ directories (platform detection, upgrade logic)
find ./pkg/cluster ./pkg/upgrade -name "*.go" ! -name "*_test.go" -print 2>/dev/null | sort
```

## Step 2: Group files into sub-agent batches

Group files by functional area. Each group should have 15-40 files — small enough for a sub-agent to read every file cover-to-cover.

**Grouping heuristics** (adapt based on what you find):

1. **Top-level controllers** — files directly managing the primary CRs (e.g., DSC controller, DSCI controller). These are the orchestrators.
2. **Service controllers** — platform services like gateway, auth, monitoring. Group the gateway controller with its `resources/` templates since they form a single functional unit.
3. **Component controllers** — individual component controllers. If there are many (e.g., 16 in rhods-operator), split into 2-3 groups of ~5-8 components each.
4. **Webhooks** — all admission webhooks. Group together since they're usually small files.
5. **Platform utilities** — `pkg/cluster/`, `pkg/upgrade/`, and any other `pkg/` directories with architecturally relevant code.
6. **Cloud/provider controllers** — if present (e.g., cloud manager controllers).

**Target**: 4-6 groups. Fewer is better — each sub-agent call has overhead.

### Example grouping for rhods-operator

| Group | Directories | ~Files | Purpose |
|-------|------------|--------|---------|
| 1 | `internal/controller/datasciencecluster/`, `internal/controller/dscinitialization/`, `internal/controller/status/` | ~12 | Top-level orchestrator controllers |
| 2 | `internal/controller/services/gateway/`, `internal/controller/services/gateway/resources/` | ~22 | Gateway/ingress stack (most critical for network architecture) |
| 3 | `internal/controller/services/auth/`, `internal/controller/services/monitoring/`, `internal/controller/services/certconfigmapgenerator/`, `internal/controller/services/setup/`, `internal/controller/services/registry/` | ~15 | Platform services |
| 4 | `internal/controller/components/dashboard/` through `internal/controller/components/kueue/` | ~28 | Component controllers batch 1 |
| 5 | `internal/controller/components/llamastackoperator/` through `internal/controller/components/workbenches/`, `internal/controller/components/registry/` | ~28 | Component controllers batch 2 |
| 6 | `internal/webhook/`, `internal/controller/cloudmanager/`, `pkg/cluster/`, `pkg/upgrade/` | ~30 | Webhooks, cloud manager, platform detection, upgrades |

## Step 3: Spawn sub-agents

For each group, spawn a sub-agent using the Task tool with `subagent_type=Explore`. Launch up to **3 sub-agents in parallel** (single message with multiple Task tool calls). If you have more than 3 groups, run them in batches of 3.

### Sub-agent prompt template

Use this prompt for each sub-agent, filling in `{repo_path}`, `{group_description}`, and `{file_list}`:

```
Analyze the following source files from a Kubernetes operator repository at {repo_path}.
This group covers: {group_description}.

Read EVERY file listed below. Do not skip any. Do not read *_test.go files.

Files to read:
{file_list}

For EACH file you read, extract and report ALL of the following that apply:

## Resources Created
Every Kubernetes resource the code constructs or templates generate.
Report as a table:

| File | Line(s) | Resource GVK | Name Pattern | Purpose |
|------|---------|-------------|--------------|---------|

Include: Deployments, Services, Routes, HTTPRoutes, EnvoyFilters, ConfigMaps,
Secrets, NetworkPolicies, ServiceAccounts, ClusterRoles, ClusterRoleBindings,
HorizontalPodAutoscalers, DestinationRules, Gateways, and any other K8s resources.

## Resources Watched/Owned
Every .Watches(), .Owns(), .WatchesGVK(), informer, or event handler.
Report as a table:

| File | Line(s) | GVK Watched | Watch Type | Purpose |
|------|---------|-------------|------------|---------|

## Webhooks
For webhook files: what GVKs are intercepted, what fields are validated or
mutated, what gets injected (sidecars, labels, annotations, env vars).
Report as a table:

| File | Line(s) | GVK Intercepted | Webhook Type | What It Does |
|------|---------|-----------------|-------------|-------------|

## Integration Points
Every reference to another component's CRD, cross-component label selector,
shared ConfigMap/Secret, external API call, or resource that connects this
code to other components.
Report as a table:

| File | Line(s) | Target Component/Resource | Interaction Type | Purpose |
|------|---------|--------------------------|-----------------|---------|

## Network Exposure
Every Service definition, port declaration, protocol, TLS configuration,
ingress rule, or egress rule.
Report as a table:

| File | Line(s) | Resource | Port | Protocol | TLS | Auth | Purpose |
|------|---------|----------|------|----------|-----|------|---------|

## RBAC
Every kubebuilder RBAC marker (//+kubebuilder:rbac) or ClusterRole/
RoleBinding resource.
Report as a table:

| File | Line(s) | API Group | Resources | Verbs |
|------|---------|-----------|-----------|-------|

CRITICAL: Read EVERY file. Report EVERY finding. Include file paths and
line numbers for all entries. If a file has no findings in a category,
that's fine — but you must still read the file to confirm.
```

## Step 4: Aggregate sub-agent findings

After all sub-agents return, merge their findings:

1. **Combine all Resources Created tables** — deduplicate by GVK + name pattern. These populate the Network Architecture (Services, Ingress) and Architecture Components sections.

2. **Combine all Resources Watched tables** — these show what the operator reacts to. Populate the Integration Points and Dependencies sections.

3. **Combine all Webhook tables** — populate the Security (Authentication & Authorization) section and any webhook-specific subsections.

4. **Combine all Integration Points tables** — populate the Integration Points section. This is one of the most valuable outputs. A platform operator should have 15-30+ integration point rows.

5. **Combine all Network Exposure tables** — populate Network Architecture (Services, Ingress, Egress). Every port, every TLS config, every auth mechanism.

6. **Combine all RBAC tables** — populate Security (RBAC - Cluster Roles, RBAC - Role Bindings).

7. **Build Source References** — every file the sub-agents read must appear in the Files Analyzed table with line ranges and sections informed.

Use the aggregated data to fill in the [architecture template](architecture-template.md) sections. The sub-agent findings are raw data — the main agent's job is to synthesize them into the template's structure with proper context and descriptions.
