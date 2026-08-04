# Architecture Changes: models-as-a-service

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | internal_dependencies | Kuadrant/Authorino | * | <empty> | <empty> | MaaSAuthPolicy controller creates Kuadrant AuthPolicy and TokenRateLimitPolicy resources for gateway-level authentication enforcement | maas-controller/pkg/controller/maas/maasauthpolicy_controller.go:1071 |
| add | internal_dependencies | PostgreSQL | * | <empty> | <empty> | maas-api loads database connection URL from maas-db-config Kubernetes secret at startup and uses pgx driver for API key, subscription, and tenant state persistence | maas-api/cmd/main.go:82-86 |
