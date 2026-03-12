---
name: analyze-running-cluster
description: Validate architecture documentation against a running Kubernetes/OpenShift cluster. Compares expected architecture (from GENERATED_ARCHITECTURE.md) with actual deployed resources to find drift.
allowed-tools: Read, Glob, Grep, Write, Bash(kubectl *), Bash(oc *), Bash(jq *)
disable-model-invocation: true
---

# Analyze Running Cluster

Compare generated architecture documentation against an actual running Kubernetes/OpenShift cluster to identify drift between documentation and reality.

This helps validate that:
- Architecture docs match deployed resources
- Security configurations are correctly documented
- Network services match what's actually running
- RBAC permissions are accurately captured

## Arguments

Required/optional arguments:
- `--kubeconfig=<path>` (default: $KUBECONFIG or ~/.kube/config)
- `--architecture=<path>` (default: ./GENERATED_ARCHITECTURE.md)
- `--namespace=<namespace>` (optional: if not specified, uses namespace from architecture doc)
- `--component=<name>` (optional: component name to analyze)

Example: `/analyze-running-cluster --kubeconfig=~/.kube/rhoai-cluster --architecture=./GENERATED_ARCHITECTURE.md`

## Instructions

Validate architecture documentation against a running cluster:

### Step 1: Load Architecture Documentation

Read the architecture markdown file specified by `--architecture`:

```bash
# Read GENERATED_ARCHITECTURE.md
```

Parse the markdown to extract:
- **Component name**: From "# Component:" heading
- **Expected namespace**: From metadata or deployment sections
- **Expected deployments**: From deployment/resources sections
- **Expected services**: From "### Services" table
- **Expected RBAC**: From "### RBAC" tables
- **Expected secrets**: From "### Secrets" table
- **Expected network policies**: From network sections
- **Expected service mesh config**: From service mesh sections

### Step 2: Query Cluster Resources

Use `kubectl` or `oc` to query the cluster:

```bash
# Set kubeconfig
export KUBECONFIG={kubeconfig-path}

# Get namespace
kubectl get namespace {namespace} -o json

# Get deployments in namespace
kubectl get deployments -n {namespace} -o json

# Get statefulsets in namespace
kubectl get statefulsets -n {namespace} -o json

# Get services in namespace
kubectl get services -n {namespace} -o json

# Get network policies in namespace
kubectl get networkpolicies -n {namespace} -o json

# Get cluster roles (for this component)
kubectl get clusterrole -o json | jq -r '.items[] | select(.metadata.name | contains("{component-name}"))'

# Get role bindings in namespace
kubectl get rolebindings -n {namespace} -o json

# Get cluster role bindings (for this component)
kubectl get clusterrolebindings -o json | jq -r '.items[] | select(.metadata.name | contains("{component-name}"))'

# Get secrets in namespace (names only, not values)
kubectl get secrets -n {namespace} -o json | jq -r '.items[].metadata.name'

# Get service accounts in namespace
kubectl get serviceaccounts -n {namespace} -o json

# Get Istio PeerAuthentication (if service mesh present)
kubectl get peerauthentication -n {namespace} -o json

# Get Istio AuthorizationPolicy (if service mesh present)
kubectl get authorizationpolicy -n {namespace} -o json
```

### Step 3: Compare Expected vs Actual

For each resource type, compare what's documented vs what's deployed:

#### Deployments/StatefulSets

| Resource | Expected (Docs) | Actual (Cluster) | Status |
|----------|-----------------|------------------|--------|
| {deployment-name} | Yes | Yes | ✅ Match |
| {deployment-name} | Yes | No | ❌ Missing in cluster |
| {deployment-name} | No | Yes | ⚠️ Not documented |

Check for:
- Missing deployments (in docs but not in cluster)
- Extra deployments (in cluster but not in docs)
- Container image differences
- Replica count differences

#### Services

Compare service details:

| Service | Expected Port | Actual Port | Expected Type | Actual Type | Status |
|---------|---------------|-------------|---------------|-------------|--------|
| {service} | 8080/TCP | 8080/TCP | ClusterIP | ClusterIP | ✅ Match |
| {service} | 8080/TCP | 9090/TCP | ClusterIP | ClusterIP | ❌ Port mismatch |

Check for:
- Port number mismatches
- Protocol differences (TCP vs UDP)
- Service type differences (ClusterIP vs LoadBalancer)
- Selector mismatches

#### RBAC

Compare RBAC rules:

| Role | Expected API Groups | Actual API Groups | Expected Resources | Actual Resources | Status |
|------|---------------------|-------------------|--------------------|------------------|--------|
| {role} | apps | apps | deployments | deployments | ✅ Match |
| {role} | "" | "", apps | pods | pods, deployments | ⚠️ More permissive |

Check for:
- Missing cluster roles (documented but not found)
- Extra cluster roles (found but not documented)
- Permission differences (more/less permissive)
- API group mismatches

#### Secrets

Compare secrets inventory:

| Secret | Expected | Actual | Type Match | Status |
|--------|----------|--------|------------|--------|
| {secret} | Yes | Yes | Yes | ✅ Match |
| {secret} | Yes | No | - | ❌ Missing |
| {secret} | No | Yes | - | ⚠️ Not documented |

Check for:
- Missing secrets (documented but not in cluster)
- Extra secrets (in cluster but not documented)
- Type mismatches (kubernetes.io/tls vs Opaque)

#### Network Policies

Compare network policies:

| Policy | Expected | Actual | Rules Match | Status |
|--------|----------|--------|-------------|--------|
| {policy} | Yes | Yes | Yes | ✅ Match |
| {policy} | Yes | No | - | ❌ Missing |

#### Service Mesh Configuration

Compare Istio/service mesh config:

| Config | Expected | Actual | Status |
|--------|----------|--------|--------|
| mTLS Mode | STRICT | STRICT | ✅ Match |
| PeerAuthentication | Present | Present | ✅ Match |
| AuthorizationPolicy | {policy-name} | {policy-name} | ✅ Match |

### Step 4: Generate Drift Report

Create a comprehensive drift report showing all differences:

```markdown
# Architecture Drift Report

**Component**: {component-name}
**Namespace**: {namespace}
**Architecture Doc**: {architecture-file}
**Cluster**: {cluster-context}
**Analysis Date**: {date}

## Summary

- ✅ **Resources matching**: {count}
- ⚠️ **Resources with drift**: {count}
- ❌ **Resources missing from cluster**: {count}
- 🔍 **Undocumented resources found**: {count}

## Drift Details

### Deployments

{Table comparing expected vs actual deployments}

**Issues**:
- ❌ Deployment `{name}` documented but not found in cluster
- ⚠️ Deployment `{name}` has different replica count: expected {N}, actual {M}
- 🔍 Deployment `{name}` found in cluster but not documented

### Services

{Table comparing expected vs actual services}

**Issues**:
- ❌ Service `{name}` port mismatch: expected 8080/TCP, actual 9090/TCP
- ⚠️ Service `{name}` type mismatch: expected ClusterIP, actual LoadBalancer

### RBAC

{Table comparing expected vs actual RBAC}

**Issues**:
- ❌ ClusterRole `{name}` documented but not found in cluster
- ⚠️ ClusterRole `{name}` has more permissions than documented (verbs: get,list,watch,create vs get,list,watch)

### Secrets

{Table comparing expected vs actual secrets}

**Issues**:
- ❌ Secret `{name}` documented but not found in cluster
- 🔍 Secret `{name}` found in cluster but not documented

### Network Policies

{Table comparing expected vs actual network policies}

### Service Mesh

{Table comparing expected vs actual service mesh config}

## Recommendations

Based on drift analysis:

1. **Update architecture docs**:
   - Add missing resources found in cluster
   - Remove references to resources not in cluster
   - Update port numbers, types, and configurations to match reality

2. **Update cluster**:
   - Deploy missing resources if they should exist
   - Fix misconfigurations (ports, RBAC permissions, etc.)

3. **Investigate discrepancies**:
   - Why are extra resources deployed but not documented?
   - Why are documented resources not in the cluster?

## Next Steps

1. Review drift details above
2. Decide: Update docs to match cluster OR update cluster to match docs
3. Re-run analysis after making changes
4. Consider automating this check in CI/CD pipeline
```

### Step 5: Write Report

Save the drift report:
- Filename: `{component-name}-drift-report-{date}.md`
- Location: Current directory or specified output directory

### Step 6: Output Summary

Print a summary to the user:

```
✅ Cluster analysis complete!

Component: {component-name}
Namespace: {namespace}
Cluster: {cluster-context}

Drift Summary:
- ✅ Matching resources: {count}
- ⚠️ Resources with drift: {count}
- ❌ Missing from cluster: {count}
- 🔍 Undocumented resources: {count}

{If drift detected:}
⚠️ DRIFT DETECTED!

Critical Issues:
- {issue 1}
- {issue 2}
- {issue 3}

Report saved: {component-name}-drift-report-{date}.md

Recommendations:
1. Review drift report for details
2. Update GENERATED_ARCHITECTURE.md to match cluster state
   OR update cluster to match intended architecture
3. Re-run analysis after fixes

{If no drift:}
✅ NO DRIFT DETECTED!

All documented resources match deployed resources.
Architecture documentation is accurate and up-to-date.
```

## Error Handling

Handle common errors:

1. **Kubeconfig not found**: Check if file exists, suggest setting KUBECONFIG
2. **Cannot connect to cluster**: Check if cluster is reachable, verify kubeconfig
3. **Permission denied**: User may not have RBAC permissions to list resources
4. **Namespace not found**: Namespace may not exist in cluster
5. **Missing CRDs**: Some resources (Istio, etc.) may not be installed

For each error, provide helpful guidance to the user.

## Notes

- This is read-only analysis (no changes made to cluster)
- Requires `kubectl` or `oc` CLI to be installed
- Requires appropriate RBAC permissions to list cluster resources
- Does NOT compare actual secret values (only names/types)
- Useful for QA, documentation validation, and security audits
- Can be run periodically to detect configuration drift
- Helps ensure architecture docs stay current with deployments

## Advanced Usage

**Compare against multiple namespaces:**
```bash
/analyze-running-cluster --architecture=kserve/GENERATED_ARCHITECTURE.md --namespace=redhat-ods-applications
/analyze-running-cluster --architecture=kserve/GENERATED_ARCHITECTURE.md --namespace=opendatahub
```

**Analyze all components in a platform:**
```bash
# Run on each component's architecture doc
for component in repos/*/GENERATED_ARCHITECTURE.md; do
    /analyze-running-cluster --architecture=$component --kubeconfig=~/.kube/prod-cluster
done
```

**Generate drift report for CI/CD:**
Use this skill in a pipeline to ensure docs stay in sync with deployments.
