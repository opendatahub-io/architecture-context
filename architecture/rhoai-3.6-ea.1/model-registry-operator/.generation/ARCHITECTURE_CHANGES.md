# Architecture Changes: model-registry-operator

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | authentication | {registry-name} REST API :: All | * | <empty> | <empty> | kube-rbac-proxy sidecar enforces SubjectAccessReview authorization requiring services:get RBAC permission scoped to the registry namespace and service name | internal/controller/config/templates/kube-rbac-proxy/kube-rbac-proxy-config.yaml.tmpl:17-23, internal/controller/modelregistry_oauth.go:48-70 |
| add | internal_dependencies | OpenShift Ingress Config (config.openshift.io) | * | <empty> | <empty> | Operator reads config.openshift.io/v1/Ingress cluster resource to discover the apps domain for Route hostname generation; conditional on OpenShift platform detection | internal/controller/config/defaults.go:197-209 |
| add | internal_dependencies | StorageVersionMigration (migration.k8s.io) | * | <empty> | <empty> | SVMStrategy creates and monitors StorageVersionMigration resources to orchestrate CRD version migration from v1alpha1 to v1beta1 | internal/migration/svm_strategy.go:116-134 |
