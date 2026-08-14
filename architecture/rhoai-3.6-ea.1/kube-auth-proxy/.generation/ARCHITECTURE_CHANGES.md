# Architecture Changes: kube-auth-proxy

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| update | http_endpoints | GET :: /ping | Auth | Unknown | None | Health check endpoint is served by pre-auth middleware and requires no authentication | oauthproxy.go:396-418 |
| update | http_endpoints | GET :: /ping | Purpose | httpGet probe | Health check probe | Clarify purpose description | oauthproxy.go:396 |
| add | http_endpoints | GET :: {prefix}/sign_in | * | <empty> | <empty> | OAuth2 sign-in page is a registered route in buildProxySubrouter | oauthproxy.go:370 |
| add | http_endpoints | GET :: {prefix}/start | * | <empty> | <empty> | OAuth2 flow initiation endpoint is a registered route in buildProxySubrouter | oauthproxy.go:371 |
| add | http_endpoints | GET :: {prefix}/callback | * | <empty> | <empty> | OAuth2 provider callback endpoint is a registered route in buildProxySubrouter | oauthproxy.go:372 |
| add | http_endpoints | GET, POST :: {prefix}/sign_out | * | <empty> | <empty> | Session sign-out endpoint is a registered route in buildProxySubrouter, requires session | oauthproxy.go:379 |
| add | http_endpoints | GET :: {prefix}/auth | * | <empty> | <empty> | Auth-only validation endpoint for ext_authz/subrequest patterns is registered in buildServeMux | oauthproxy.go:355 |
| add | http_endpoints | GET :: {prefix}/userinfo | * | <empty> | <empty> | User info endpoint is a registered route in buildProxySubrouter, requires session | oauthproxy.go:378 |
| add | http_endpoints | ALL :: /* | * | <empty> | <empty> | Catch-all reverse proxy route forwards authenticated requests to upstream | oauthproxy.go:363 |
| add | authentication | Upstream proxy :: OAuth2/OIDC, Bearer JWT, Basic Auth, K8s TokenReview | * | <empty> | <empty> | Primary authentication surface of the proxy: layered middleware chain with K8s TokenReview first, then JWT/OAuth session, then basic auth | oauthproxy.go:425-438, main.go:59-81 |
