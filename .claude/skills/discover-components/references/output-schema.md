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
  },
  "provenance": {
    "metadata": {
      "generated_at": "{ISO timestamp}",
      "checkouts_dirs": ["{dir1}", "{dir2}"],
      "github_api_available": true,
      "total_repos": "{count}",
      "repos_with_upstream": "{count}",
      "repos_with_downstream": "{count}"
    },
    "repos": {
      "{org}/{repo}": {
        "org": "{org}",
        "repo": "{repo-name}",
        "is_fork": false,
        "upstream": "{upstream-org}/{repo-name}|null",
        "upstream_detection": "github_api|sync_workflow|null",
        "downstream": ["{downstream-org}/{repo-name}"],
        "downstream_detection": "cross_org_match|null",
        "sync_mechanism": "sync_workflow|rebase_workflow|auto_merge|manual|null",
        "sync_workflows": ["sync-upstream.yml"]
      }
    }
  }
}
```

## Provenance Section

The `provenance` top-level key is populated automatically by the harness post-processing step (not by the agent). It maps upstream/downstream fork relationships for all repos in the checkouts directories.

- Keyed by `org/repo` (e.g., `opendatahub-io/kserve`)
- `upstream`: the source repo this was forked from (null if not a fork)
- `upstream_detection`: method used -- `github_api` (fork metadata) or `sync_workflow` (workflow file analysis)
- `downstream`: repos in other orgs with the same name
- `downstream_detection`: always `cross_org_match` when present
- `sync_mechanism`: how upstream changes flow -- `sync_workflow`, `rebase_workflow`, `auto_merge`, or `manual`
- `sync_workflows`: list of workflow filenames that handle syncing (e.g., `sync-upstream.yml`)

**Do NOT write the provenance section in Step 8.** The harness adds it after discovery completes.

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
