# Architecture Changes: argo-workflows

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|---------------|----------------|--------|----------|
| add | authentication | Argo Server API :: All | * | <empty> | <empty> | Gatekeeper interceptor enforces Bearer token, SSO/OIDC, or server SA auth on all gRPC and HTTP API endpoints | server/auth/gatekeeper.go:90-104, server/apiserver/argoserver.go:295-312 |
| add | authentication | /metrics :: GET | * | <empty> | <empty> | Metrics endpoint has conditional authentication controlled by ARGO_SERVER_METRICS_AUTH environment variable | server/apiserver/argoserver.go:397-411 |
