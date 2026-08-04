# Architecture Changes: rhoai-mcp

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | authentication | MCP API :: All | * | <empty> | <empty> | OIDC/TokenReview Bearer authentication enforced by OIDCAuthMiddleware when OIDC is enabled; RBAC tool filtering via SubjectAccessReview | src/rhoai_mcp/auth/middleware.py:25-93, src/rhoai_mcp/server.py:271-273, src/rhoai_mcp/server.py:276-368 |
| add | authentication | /health :: GET | * | <empty> | <empty> | Health probe endpoint explicitly excluded from authentication middleware | src/rhoai_mcp/server.py:331, src/rhoai_mcp/auth/middleware.py:57-59 |
| add | authentication | /.well-known/oauth-protected-resource :: GET | * | <empty> | <empty> | RFC 9728 Protected Resource Metadata endpoint excluded from auth; registered when OIDC is enabled | src/rhoai_mcp/server.py:316-326, src/rhoai_mcp/server.py:331 |
| add | http_endpoints | GET :: /.well-known/oauth-protected-resource | * | <empty> | <empty> | OIDC Protected Resource Metadata endpoint registered via custom_route when OIDC is enabled | src/rhoai_mcp/server.py:319-326 |
| update | http_endpoints | GET :: /health | Auth | Unknown | None | Health endpoint is explicitly excluded from OIDC auth middleware | src/rhoai_mcp/server.py:331, src/rhoai_mcp/auth/middleware.py:57-59 |
| add | internal_dependencies | Kubeflow Training Operator (trainer.kubeflow.org) | * | <empty> | <empty> | ClusterRole grants CRD CRUD on trainjobs, trainingruntimes, and clustertrainingruntimes | deploy/kustomize/base/clusterrole.yaml:1 |
| add | internal_dependencies | Data Science Pipelines (opendatahub.io) | * | <empty> | <empty> | ClusterRole grants CRD CRUD on datasciencepipelinesapplications | deploy/kustomize/base/clusterrole.yaml:1 |
| add | internal_dependencies | Model Registry | * | <empty> | <empty> | HTTP client integration configured via RHOAI_MCP_MODEL_REGISTRY_URL with default in-cluster service URL | src/rhoai_mcp/config.py:183-212 |
