# Architecture Changes: data-science-pipelines-operator

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | services | data-science-pipelines-operator | * | <empty> | <empty> | Operator metrics Service defined in manager-service.yaml exposes port 8080 for Prometheus scraping | config/manager/manager-service.yaml:1, config/prometheus/monitor.yaml:1, main.go:170 |
| add | authentication | DSPA CRDs (datasciencepipelinesapplications.opendatahub.io) :: Kubernetes API | * | <empty> | <empty> | RBAC aggregation ClusterRoles provide tiered edit/view access to DSPA and Pipeline resources, mirroring the Argo RBAC aggregation pattern | config/rbac/aggregate_dspa_role_edit.yaml:1, config/rbac/aggregate_dspa_role_view.yaml:1 |
| add | internal_dependencies | Ray (ray.io) | * | <empty> | <empty> | manager-role RBAC grants CRD CRUD on ray.io resources (rayclusters, rayjobs, rayservices), establishing a structural platform dependency | config/rbac/role.yaml:195 |
| add | internal_dependencies | CodeFlare AppWrappers (workload.codeflare.dev) | * | <empty> | <empty> | manager-role RBAC grants full CRD CRUD on workload.codeflare.dev/appwrappers, establishing a structural platform dependency for distributed workload scheduling | config/rbac/role.yaml:201 |
| add | internal_dependencies | Seldon Deployments (machinelearning.seldon.io) | * | <empty> | <empty> | manager-role RBAC grants wildcard verbs on machinelearning.seldon.io/seldondeployments, establishing a structural platform dependency for model serving | config/rbac/role.yaml:188 |
