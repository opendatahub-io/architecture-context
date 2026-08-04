# Architecture Changes: mlflow

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| delete | authentication | HTTP API :: All | * | <empty> | <empty> | Analyzer detected no auth middleware on the FastAPI gateway surface, but the RHOAI deployment disables the gateway and uses --app-name kubernetes-auth on the tracking server | Dockerfile.konflux:80, mlflow/server/__init__.py:218 |
| add | authentication | Tracking Server API :: All | * | <empty> | <empty> | The Dockerfile CMD passes --app-name kubernetes-auth which loads the kubernetes-auth plugin from mlflow-kubernetes-plugins==1.5.0 via the mlflow.app entry point group, providing Kubernetes-native authentication for all tracking server endpoints | Dockerfile.konflux:80, mlflow/server/__init__.py:218-226, requirements/konflux-pypi.in:13 |
