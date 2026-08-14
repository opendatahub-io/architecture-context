# Architecture Changes: rhoai-mcp

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| update | http_endpoints | /health :: GET | Port | http | 8000 | Analyzer recorded target port name; source confirms numeric port 8000 | Dockerfile.konflux:35, src/rhoai_mcp/server.py:307 |
| update | http_endpoints | /health :: GET | Auth | Unknown | None | Health endpoint is explicitly excluded from OIDC middleware | src/rhoai_mcp/server.py:385 |
| update | http_endpoints | /health :: GET | Owner | | RHOAIServer | Health endpoint registered by RHOAIServer._register_health_endpoint | src/rhoai_mcp/server.py:512-544 |
| update | http_endpoints | /health :: GET | Purpose | httpGet probe | Kubernetes liveness/readiness probe | Clarified purpose from source: returns 200/503 based on K8s connection and plugin health | src/rhoai_mcp/server.py:516-542 |
| add | http_endpoints | /.well-known/oauth-protected-resource :: GET | * | <empty> | <empty> | OIDC Protected Resource Metadata endpoint registered when OIDC is enabled | src/rhoai_mcp/server.py:370-380 |
| add | authentication | MCP API (SSE/streamable-http) :: All | * | <empty> | <empty> | OIDC Bearer authentication with JWT or TokenReview validation enforced by OIDCAuthMiddleware | src/rhoai_mcp/server.py:330-417 |
| add | authentication | /health :: GET | * | <empty> | <empty> | Health endpoint explicitly excluded from authentication middleware | src/rhoai_mcp/server.py:385 |
| add | authentication | /.well-known/oauth-protected-resource :: GET | * | <empty> | <empty> | Metadata endpoint explicitly excluded from authentication middleware | src/rhoai_mcp/server.py:385 |
