# Architecture Changes: trainer

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| update | integration_points | /v1/Pod :: Resource read | Purpose | list operations | List training pods to locate primary pod for progression metrics polling | Source shows pod listing by multiple label selector fallback strategies to find primary training pod for RHOAI progression tracking | pkg/rhai/progression/progression.go:144-179 |
| update | integration_points | config.openshift.io/v1/apiservers :: Resource read | Purpose | get operations | Read cluster TLS security profile for webhook and metrics server configuration | Source shows dynamic client GET of APIServer cluster resource to extract and apply TLS cipher suite profile | pkg/tls/tls.go:99-131 |
| update | integration_points | networking.k8s.io/v1/NetworkPolicy :: Resource CRUD | Purpose | get, update operations | Create and reconcile per-TrainJob NetworkPolicy for training workload network isolation | Source shows full create/get/update lifecycle with owner-referenced cleanup for per-TrainJob NetworkPolicy | pkg/rhai/networkpolicy.go:152-180 |
| add | integration_points | Training Pod (in-cluster) :: HTTP poll | * | <empty> | <empty> | RHOAI progression package polls primary training pod via plain HTTP for training progress metrics (percentage, steps, epochs) | pkg/rhai/progression/progression.go:48-73 |
