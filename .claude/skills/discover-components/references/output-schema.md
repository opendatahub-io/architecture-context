# Output Schema and Report Template

## Component Map JSON Schema (Step 8)

Create the component map structure:

```json
{
  "metadata": {
    "platform": "{platform}",
    "discovery_method": "breadcrumb",
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
      "discovered_via": "operator_operand|operator_bundle|container_image|image_dependency|dependency|installer|dsc_spec",
      "referenced_by": ["installer"],
      "shipped": true,
      "architecturally_significant": true,
      "consumer_count": 3,
      "consumers": ["awx-operator", "eda-operator", "hub-operator"],
      "capability": "optional-capability-name-if-applicable",
      "confidence": "high|medium|low|disputed",
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
Discovery method: Breadcrumb exploration

Results:
  Total repositories scanned: {total}
  Components discovered: {discovered}
  Components excluded: {excluded}

Core platform ({count}):
  ✓ rhods-operator (type: operator, tier: core_platform)
  ✓ odh-dashboard (type: ui, tier: core_platform)
  ✓ notebooks (type: controller, tier: core_platform)
  ✓ odh-model-controller (type: controller, tier: core_platform)
  ...

Optional platform ({count}):
  ✓ kserve (type: controller, tier: optional_platform)
  ✓ data-science-pipelines-operator (type: operator, tier: optional_platform)
  ✓ codeflare-operator (type: operator, tier: optional_platform)
  ✓ kuberay (type: controller, tier: optional_platform)
  ...

Payload components ({count}):
  ✓ vllm (type: service, tier: payload_component, ref by: odh-model-controller)
  ✓ data-science-pipelines (type: service, tier: payload_component, ref by: data-science-pipelines-operator)
  ✓ model-registry (type: service, tier: payload_component, ref by: model-registry-operator)
  ...

Shared libraries / API specs:
  ✓ kubeflow (type: shared_library, used by: N components) [ARCHITECTURALLY SIGNIFICANT]
  ✓ ml-metadata (type: shared_library, used by: N components) [ARCHITECTURALLY SIGNIFICANT]
  ...

Excluded repositories:
  ✗ RHOAI-Build-Config (build_infrastructure)
  ✗ must-gather (diagnostic_tool)
  ✗ konflux-central (build_infrastructure)
  ...

Output: architecture/{platform}/component-map.json

Next steps:
1. Review component-map.json (edit if needed)
2. Run: python main.py generate-architecture --platform={platform}
3. Run: python main.py collect-architectures --platform={platform}
================================================================================
```
