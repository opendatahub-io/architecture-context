# Output Schema and Report Template

## Component Map JSON Schema (Step 8)

Create the component map structure:

```json
{
  "metadata": {
    "platform": "{platform}",
    "discovery_method": "breadcrumb|release_payload_signals",
    "entry_point": "{entry_repo or 'multiple'}",
    "discovered_at": "{ISO timestamp}",
    "checkouts_dir": "{checkouts_dir}",
    "total_repos_scanned": {count},
    "components_discovered": {count},
    "components_excluded": {count}
  },
  "components": {
    "{component-key}": {
      "key": "{component-key}",
      "repo_org": "{org}",
      "repo_name": "{repo-name}",
      "repo_url": "https://github.com/{org}/{repo-name}",
      "ref": "main",
      "source_folder": "config",
      "checkout_path": "{full-path}",
      "checkout_branch": "{branch-from-git-rev-parse}",
      "has_architecture": false,
      "type": "operator|controller|service|ui|installer|asset|shared_library|api_specification",
      "tier": "core_platform|optional_platform|payload_component|ecosystem",
      "discovered_via": "release_payload_signal|operator_operand|operator_bundle|container_image|dependency|installer",
      "referenced_by": ["installer"],
      "shipped": true,
      "architecturally_significant": true,
      "consumer_count": 3,
      "consumers": ["awx-operator", "eda-operator", "hub-operator"],
      "capability": "optional-capability-name-if-applicable",
      "confidence": "high|medium|disputed",
      "consensus": {
        "votes": {"include": 2, "exclude": 1},
        "reviewers": {
          "structural": {"vote": "include", "type": "service", "rationale": "..."},
          "relational": {"vote": "include", "type": "service", "rationale": "..."},
          "functional": {"vote": "exclude", "type": "other", "rationale": "..."}
        }
      }
    }
  },
  "dependency_graph": {
    "{repo}": ["{dep1}", "{dep2}"]
  },
  "excluded": {
    "{repo-name}": "{reason}",
    "{repo-name-reviewed}": {
      "reason": "consensus_exclude",
      "confidence": "high|medium",
      "consensus": {
        "votes": {"include": 0, "exclude": 3},
        "reviewers": {
          "structural": {"vote": "exclude", "type": "other", "rationale": "..."},
          "relational": {"vote": "exclude", "type": "other", "rationale": "..."},
          "functional": {"vote": "exclude", "type": "other", "rationale": "..."}
        }
      }
    }
  }
}
```

## Report Summary Template (Step 10)

Output a summary to the user:

```
================================================================================
Component Discovery Complete
================================================================================

Platform: {platform}
Checkouts directory: {checkouts_dir}
Discovery method: {Breadcrumb exploration | Release payload signals}

Results:
  Total repositories scanned: {total}
  Components discovered: {discovered}
  Components excluded: {excluded}

--- If release payload signals were found: ---

Release payload signals detected: {signal_types}

Core platform ({count}):
  ✓ cluster-etcd-operator (type: operator, tier: core_platform)
  ✓ cluster-kube-apiserver-operator (type: operator, tier: core_platform)
  ✓ machine-config-operator (type: operator, tier: core_platform)
  ...

Optional platform ({count}):
  ✓ cluster-samples-operator (type: operator, tier: optional_platform, capability: openshift-samples)
  ✓ console-operator (type: operator, tier: optional_platform, capability: Console)
  ...

Shared libraries / API specs:
  ✓ library-go (type: shared_library, used by: N components) [ARCHITECTURALLY SIGNIFICANT]
  ✓ gateway-api (type: api_specification, upstream: kubernetes-sigs) [ARCHITECTURALLY SIGNIFICANT]
  ...

Consensus-reviewed (included):
  ✓ console (type: service, confidence: high, votes: 3/3 include)
      structural: include — "Has Dockerfile, deployed as pod"
      relational: include — "Image referenced by console-operator"
      functional: include — "Web UI served in production"
  ...

Consensus-reviewed (excluded — review recommended):
  ✗ some-tool (confidence: medium, votes: 2/3 exclude)
  ...

Disputed (needs human review):
  ⚠ ambiguous-repo (confidence: disputed, votes: 1/1/1)
  ...

Ecosystem (excluded — no release payload signals):
  ✗ aws-account-operator (ecosystem)
  ✗ addon-operator (ecosystem)
  ... and {N} more

--- If NO release payload signals found (breadcrumb mode): ---

Entry points used:
  - {entry1}
  - {entry2}

Discovered components:
  ✓ awx-operator (type: operator, via: operator_bundle, ref by: installer)
  ✓ eda-operator (type: operator, via: operator_bundle, ref by: installer)
  ✓ awx-api (type: service, via: container_image, ref by: awx-operator)
  ✓ django-ansible-base (type: shared_library, used by: 3 components) [ARCHITECTURALLY SIGNIFICANT]
  ✓ gateway-api (type: api_specification, upstream: kubernetes-sigs) [ARCHITECTURALLY SIGNIFICANT]
  ...

Consensus-reviewed (included):
  ✓ data-science-pipelines (type: service, confidence: medium, votes: 2/3 include)
      structural: include — "Has Dockerfile and kustomize manifests"
      relational: include — "Image referenced by data-science-pipelines-operator"
      functional: exclude — "Operand only, no standalone lifecycle"
  ...

Consensus-reviewed (excluded — review recommended):
  ✗ some-helper-tool (confidence: medium, votes: 2/3 exclude)
      structural: include — "Has Dockerfile"
      relational: exclude — "Not referenced by any included component"
      functional: exclude — "CI/CD helper, not a production workload"
  ...

Disputed (needs human review):
  ⚠ ambiguous-repo (confidence: disputed, votes: 1/1/1)
      structural: include — "..."
      relational: exclude — "..."
      functional: unsure — "..."
  ...

Excluded repositories:
  ✗ ansible-docs (documentation_only)
  ✗ ansible-ci-tools (development_tooling)
  ...

Output: architecture/{platform}/component-map.json

Next steps:
1. Review component-map.json (edit if needed)
2. Run: python main.py generate-architecture --platform={platform}
3. Run: python main.py collect-architectures --platform={platform}
================================================================================
```
