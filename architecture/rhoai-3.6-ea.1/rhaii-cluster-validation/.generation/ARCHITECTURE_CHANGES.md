# Architecture Changes: rhaii-cluster-validation

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | internal_dependencies | Gateway API (CRDs) | * | <empty> | <empty> | Validator checks for gateways and httproutes CRD presence as platform prerequisites for llm-d deployment | pkg/checks/crd/crd.go:51-61, pkg/config/platforms/ocp.yaml:26-27 |
| add | internal_dependencies | Gateway API Inference Extension | * | <empty> | <empty> | Validator checks for InferencePool CRD presence with fallback to graduated API group | pkg/checks/crd/crd.go:63-70, pkg/config/platforms/ocp.yaml:28 |
| add | internal_dependencies | LeaderWorkerSet | * | <empty> | <empty> | Validator checks for LeaderWorkerSet CRD presence and operator pod health | pkg/checks/crd/crd.go:71-75, pkg/checks/operator/operator.go:45-49, pkg/config/platforms/ocp.yaml:29, pkg/config/platforms/ocp.yaml:44-45 |
| add | internal_dependencies | cert-manager | * | <empty> | <empty> | Validator checks for cert-manager CRD presence and operator pod health | pkg/checks/crd/crd.go:76-80, pkg/checks/operator/operator.go:33-38, pkg/config/platforms/ocp.yaml:30, pkg/config/platforms/ocp.yaml:39-41 |
| add | internal_dependencies | Istio | * | <empty> | <empty> | Validator checks Istio operator pod health in configured namespaces | pkg/checks/operator/operator.go:39-44, pkg/config/platforms/ocp.yaml:42-43 |
