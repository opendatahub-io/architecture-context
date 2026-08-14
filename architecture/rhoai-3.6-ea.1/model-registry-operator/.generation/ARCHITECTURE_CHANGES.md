# Architecture Changes: model-registry-operator

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | authentication | {registry-name}:8443 :: REST | * | <empty> | <empty> | kube-rbac-proxy sidecar enforces SubjectAccessReview authorization on managed registry HTTPS port | internal/controller/config/templates/kube-rbac-proxy/kube-rbac-proxy-config.yaml.tmpl:17-23, internal/controller/config/templates/deployment.yaml.tmpl:220-272 |
| add | authentication | model-catalog:8443 :: REST | * | <empty> | <empty> | kube-rbac-proxy sidecar enforces SubjectAccessReview authorization on model-catalog HTTPS port | internal/controller/config/templates/kube-rbac-proxy/kube-rbac-proxy-config.yaml.tmpl:17-23, internal/controller/config/templates/deployment.yaml.tmpl:220-272 |
| add | internal_dependencies | config.openshift.io/v1/Ingress :: Resource read | * | <empty> | <empty> | Operator reads cluster-level Ingress resource for default application domain used in Route hostnames | internal/controller/config/defaults.go:197-211 |
| add | internal_dependencies | services.platform.opendatahub.io/v1alpha1/Auth :: Resource read | * | <empty> | <empty> | Operator detects platform Auth CRD availability and reads auth configuration for catalog reconciliation | internal/controller/util.go:39, internal/controller/modelcatalog_controller.go:1 |
| add | internal_dependencies | migration.k8s.io/v1alpha1/StorageVersionMigration :: CRD CRUD | * | <empty> | <empty> | Operator manages StorageVersionMigration resources for CRD v1alpha1-to-v1beta1 migration | internal/migration/svm_strategy.go:122 |
