# Architecture Changes: odh-model-controller

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| update | authentication | /metrics :: Unknown | Auth Mechanism | Unknown | None | Source inspection confirms promhttp.Handler is served without authentication middleware on the model-serving-api metrics listener | server/observability/observability.go:87 |
| update | authentication | /metrics :: Unknown | Enforcement Point | Application (model-serving-api) | N/A | No authentication enforcement point; metrics served directly via promhttp.Handler over HTTPS | server/observability/observability.go:85-97 |
| update | authentication | /metrics :: Unknown | Policy | Dedicated metrics listener on port 8080; authentication not established by source | HTTPS metrics endpoint on port 8080 via promhttp.Handler; no authentication middleware; TLS via model-serving-api certificate | Source confirms HTTPS-only (TLS required) but no auth middleware applied | server/observability/observability.go:85-97, server/main.go:91-94 |
| add | authentication | /api/v1/gateways :: All | * | <empty> | <empty> | Bearer token authentication enforced by middleware.Auth for gateway discovery API endpoint | server/server.go:23, server/middleware/auth.go:24-41 |
| add | authentication | /api/v1/samples/llm-d :: All | * | <empty> | <empty> | Endpoint is intentionally unauthenticated; serves static public YAML templates embedded at build time | server/server.go:25-27 |
