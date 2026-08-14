# Architecture Changes: mlflow

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| delete | authentication | HTTP API :: All | * | <empty> | <empty> | Analyzer detected no auth middleware on the FastAPI/Starlette gateway surface, but the RHOAI container starts with --app-name kubernetes-auth which loads a server-side auth plugin; the generic "HTTP API" endpoint name does not reflect the actual deployment | Dockerfile.konflux:80, mlflow/server/__init__.py:218-226 |
| add | authentication | Tracking Server API :: All | * | <empty> | <empty> | The Dockerfile CMD --app-name kubernetes-auth loads the mlflow-kubernetes-plugins entry point which provides Kubernetes service account bearer token authentication; mlflow/server/auth provides RBAC enforcement with role-based permissions | Dockerfile.konflux:80, mlflow/server/__init__.py:218-226, mlflow/server/auth/__init__.py:229-367, mlflow/tracking/request_auth/kubernetes_request_auth_provider.py:203-258, requirements/konflux-pypi.in:13 |
