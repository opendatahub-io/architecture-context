# Architecture Changes: kube-rbac-proxy

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| update | http_endpoints | Unknown :: / | Method | Unknown | ALL | All HTTP methods are proxied through the root handler; the handler does not filter by method | cmd/kube-rbac-proxy/app/kube-rbac-proxy.go:300-341 |
| update | http_endpoints | Unknown :: / | Port |  | 8443 | Secure listener binds to configurable address, default port 8443 per deployment manifests | cmd/kube-rbac-proxy/app/kube-rbac-proxy.go:404-405 |
| update | http_endpoints | Unknown :: / | Protocol | HTTP | HTTPS | Root route is served on TLS listener only | cmd/kube-rbac-proxy/app/kube-rbac-proxy.go:345-413 |
| update | http_endpoints | Unknown :: / | Transport | HTTP/1.1 | HTTP/1.1, h2 | Server configured with NextProtos h2 and http/1.1 | cmd/kube-rbac-proxy/app/kube-rbac-proxy.go:401 |
| update | http_endpoints | Unknown :: / | Encryption | Unknown | TLS (configurable min version, configurable cipher suites) | TLS config uses configurable min version and cipher suites via k8s component-base | cmd/kube-rbac-proxy/app/kube-rbac-proxy.go:384-394 |
| update | http_endpoints | Unknown :: / | Auth | Unknown | OIDC or Kubernetes TokenReview + SubjectAccessReview; configurable ignore-paths bypass auth | Authentication chain applies WithAuthentication and WithAuthorization filters; ignore-paths bypass both | cmd/kube-rbac-proxy/app/kube-rbac-proxy.go:326-334 |
| update | http_endpoints | Unknown :: / | Purpose | Registered Go HTTP route | Authentication-enforced reverse proxy to upstream service | The root route is the core reverse proxy handler with auth enforcement | cmd/kube-rbac-proxy/app/kube-rbac-proxy.go:282-341 |
| update | http_endpoints | Unknown :: /healthz | Method | Unknown | GET | Healthz handler writes a static ok response | cmd/kube-rbac-proxy/app/kube-rbac-proxy.go:422 |
| update | http_endpoints | Unknown :: /healthz | Port |  | proxyEndpointsPort | Health endpoint bound to separate proxyEndpointsPort | cmd/kube-rbac-proxy/app/kube-rbac-proxy.go:420-422 |
| update | http_endpoints | Unknown :: /healthz | Protocol | HTTP | HTTPS | Health endpoint uses cloned TLS config from secure listener | cmd/kube-rbac-proxy/app/kube-rbac-proxy.go:426 |
| update | http_endpoints | Unknown :: /healthz | Transport | HTTP/1.1 | HTTP/1.1, h2 | Proxy endpoints server configured with NextProtos h2 and http/1.1 | cmd/kube-rbac-proxy/app/kube-rbac-proxy.go:432 |
| update | http_endpoints | Unknown :: /healthz | Encryption | Unknown | TLS (cloned from secure listener config) | Health endpoint server clones TLS config from main secure listener | cmd/kube-rbac-proxy/app/kube-rbac-proxy.go:426 |
| update | http_endpoints | Unknown :: /healthz | Auth | Unknown | None | Health endpoint handler has no authentication middleware | cmd/kube-rbac-proxy/app/kube-rbac-proxy.go:422 |
| update | http_endpoints | Unknown :: /healthz | Purpose | Registered Go HTTP route | Health check endpoint for liveness probing | Healthz writes static ok response for liveness probes | cmd/kube-rbac-proxy/app/kube-rbac-proxy.go:422 |
| update | integration_points | kube-rbac-proxy :: Sidecar (localhost) | Role | unknown | Authentication gateway | The proxy acts as an authentication gateway, enforcing auth before forwarding to upstream | cmd/kube-rbac-proxy/app/kube-rbac-proxy.go:277-298 |
| update | integration_points | kube-rbac-proxy :: Sidecar (localhost) | Purpose | Authentication enforcement | Reverse-proxies authenticated requests to co-located app | Source confirms reverse proxy pattern with configurable upstream transport | cmd/kube-rbac-proxy/app/kube-rbac-proxy.go:282-298 |
