# Architecture Changes: rhods-operator

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | internal_dependencies | Istio Service Mesh | * | <empty> | <empty> | Gateway controller dynamically owns EnvoyFilter and DestinationRule when Istio CRDs are detected at runtime | internal/controller/services/gateway/gateway_controller.go:57-58 |
| add | internal_dependencies | Kuadrant | * | <empty> | <empty> | Auth controller watches kuadrant-system namespace to trigger reconciliation when Kuadrant is deployed | internal/controller/services/auth/auth_controller.go:74-76 |
