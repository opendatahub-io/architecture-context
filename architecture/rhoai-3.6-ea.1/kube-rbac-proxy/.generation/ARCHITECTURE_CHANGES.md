# Architecture Changes: kube-rbac-proxy

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| update | http_endpoints | Unknown :: / | Auth | Unknown | Configurable (OIDC/TokenReview + SAR) | Source evidence shows WithAuthentication and WithAuthorization handler chain applied to all non-ignored paths on the main route | cmd/kube-rbac-proxy/app/kube-rbac-proxy.go:328-331 |
| update | http_endpoints | Unknown :: / | Encryption | Unknown | TLS (configurable) | Secure listener uses configurable TLS with cert hot-reloading | cmd/kube-rbac-proxy/app/kube-rbac-proxy.go:346-401 |
| update | http_endpoints | Unknown :: / | Purpose | Registered Go HTTP route | Reverse proxy route with authentication and authorization handler chain | Route serves as the main reverse proxy endpoint with full auth chain | cmd/kube-rbac-proxy/app/kube-rbac-proxy.go:340-341 |
| update | http_endpoints | Unknown :: /healthz | Auth | Unknown | None | Health check endpoint served on separate proxyEndpoints port with no authentication middleware | cmd/kube-rbac-proxy/app/kube-rbac-proxy.go:422 |
| update | http_endpoints | Unknown :: /healthz | Encryption | Unknown | TLS (configurable) | ProxyEndpoints listener clones TLS config from main listener | cmd/kube-rbac-proxy/app/kube-rbac-proxy.go:426 |
| update | http_endpoints | Unknown :: /healthz | Purpose | Registered Go HTTP route | Health check endpoint | Endpoint returns static "ok" response for liveness/readiness probes | cmd/kube-rbac-proxy/app/kube-rbac-proxy.go:422 |
| update | integration_points | kube-rbac-proxy :: Sidecar (localhost) | Role | unknown | provider | kube-rbac-proxy provides TLS termination and authentication enforcement as the proxy fronting upstream services | cmd/kube-rbac-proxy/app/kube-rbac-proxy.go:340-341, cmd/kube-rbac-proxy/app/transport.go:28 |
