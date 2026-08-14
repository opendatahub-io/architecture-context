# Architecture Changes: llm-d-router

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | services | llm-d-router (Helm-templated) :: grpc-ext-proc | * | <empty> | <empty> | Helm chart defines a ClusterIP Service with gRPC ExtProc port 9002 and appProtocol kubernetes.io/h2c | config/charts/routerlib/templates/_service.yaml:56-59 |
| add | services | llm-d-router (Helm-templated) :: http-metrics | * | <empty> | <empty> | Helm chart defines a ClusterIP Service with HTTP metrics port 9090 | config/charts/routerlib/templates/_service.yaml:60-62 |
