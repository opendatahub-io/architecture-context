# Architecture Changes: must-gather

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | internal_dependencies | rhods-operator | * | <empty> | <empty> | must-gather detects operator namespace via Subscription lookup and reads CSV for version | collection-scripts/gather.sh:43, collection-scripts/common.sh:90-105 |
| add | internal_dependencies | opendatahub-operator CRDs | * | <empty> | <empty> | must-gather directly inspects DSCInitialization, DataScienceCluster, and component CRs | collection-scripts/gather.sh:70-98 |
| add | internal_dependencies | RHOAI application components | * | <empty> | <empty> | must-gather collects logs and resources from all RHOAI component namespaces | collection-scripts/gather.sh:57-64 |
| add | authentication | Kubernetes API :: All | * | <empty> | <empty> | must-gather pod uses ServiceAccount token provisioned by oc adm must-gather framework for all cluster API access | collection-scripts/gather.sh:57, collection-scripts/common.sh:25-26 |
| add | integration_points | Kubernetes API server :: REST API (oc/kubectl) | * | <empty> | <empty> | Primary integration: all diagnostic data is collected via Kubernetes API using oc/kubectl | collection-scripts/gather.sh:57-64, collection-scripts/common.sh:25-26 |
| add | integration_points | Helm :: CLI | * | <empty> | <empty> | Collects Helm release values and manifests for RHAI gitops namespace | collection-scripts/gather.sh:68, collection-scripts/common.sh:78-86 |
