# Architecture Changes: mlflow-operator

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | internal_dependencies | Auth (services.platform.opendatahub.io) | * | <empty> | <empty> | NamespaceRBACReconciler watches Auth CRD for workspace RBAC propagation; RBAC marker grants get/list/watch on auths resource | internal/controller/namespace_rbac_controller.go:48-52, internal/controller/namespace_rbac_controller.go:67, internal/controller/namespace_rbac_controller.go:104-106, internal/controller/routing.go:157-179 |
| add | integration_points | services.platform.opendatahub.io/v1alpha1/Auth :: Controller watch (Watches) | * | <empty> | <empty> | NamespaceRBACReconciler watches Auth objects and maps changes to namespace reconciliation for workspace RBAC | internal/controller/namespace_rbac_controller.go:84-106, internal/controller/routing.go:157-179 |
