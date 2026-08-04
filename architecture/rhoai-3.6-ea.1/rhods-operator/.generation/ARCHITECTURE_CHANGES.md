# Architecture Changes: rhods-operator

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | internal_dependencies | Kuadrant | * | <empty> | <empty> | Auth controller watches kuadrant-system namespace to trigger RBAC reconciliation when Kuadrant is deployed | internal/controller/services/auth/auth_controller.go:75 |
| add | internal_dependencies | Istio service mesh | * | <empty> | <empty> | Gateway controller conditionally owns EnvoyFilter and DestinationRule resources when Istio CRDs are available on the cluster | internal/controller/services/gateway/gateway_controller.go:57-58 |
