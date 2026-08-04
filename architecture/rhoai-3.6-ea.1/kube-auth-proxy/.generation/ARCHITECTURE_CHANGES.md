# Architecture Changes: kube-auth-proxy

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | http_endpoints | GET :: /robots.txt | * | <empty> | <empty> | Robots.txt handler registered in buildServeMux router | oauthproxy.go:52, oauthproxy.go:350 |
| add | http_endpoints | GET, POST :: /oauth2/sign_in | * | <empty> | <empty> | Sign-in page and basic auth form handler registered in proxy subrouter | oauthproxy.go:53, oauthproxy.go:370 |
| add | http_endpoints | GET :: /oauth2/sign_out | * | <empty> | <empty> | Sign-out handler with session clearing and OAuthAccessToken deletion | oauthproxy.go:54, oauthproxy.go:379 |
| add | http_endpoints | GET :: /oauth2/start | * | <empty> | <empty> | OAuth2 flow initiation redirect to configured provider | oauthproxy.go:55, oauthproxy.go:371 |
| add | http_endpoints | GET :: /oauth2/callback | * | <empty> | <empty> | OAuth2 provider callback handler with CSRF validation | oauthproxy.go:56, oauthproxy.go:372 |
| add | http_endpoints | GET :: /oauth2/auth | * | <empty> | <empty> | Auth-only check endpoint for ext_authz/auth_request integration | oauthproxy.go:57, oauthproxy.go:355 |
| add | http_endpoints | GET :: /oauth2/userinfo | * | <empty> | <empty> | User info JSON endpoint returning email, groups, and username | oauthproxy.go:58, oauthproxy.go:378 |
| add | authentication | Proxy upstream :: All | * | <empty> | <empty> | Multi-method client-facing authentication enforced by middleware chain | oauthproxy.go:425-464 |
| add | integration_points | OpenShift OAuth API :: REST | * | <empty> | <empty> | OAuthAccessToken deletion on sign-out when OpenShift provider is active | oauthproxy.go:62, oauthproxy.go:857-899 |
