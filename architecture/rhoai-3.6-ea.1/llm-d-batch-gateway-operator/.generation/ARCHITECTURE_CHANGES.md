# Architecture Changes: llm-d-batch-gateway-operator

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | services | llm-d-batch-gateway-operator-metrics | * | <empty> | <empty> | MetricsController programmatically creates this ClusterIP Service targeting port 8443/TCP for Prometheus scraping | internal/monitoring/controller.go:119-143, internal/monitoring/controller.go:26-27 |
