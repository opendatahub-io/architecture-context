# Architecture Changes: argo-workflows

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | authentication | Argo Server API :: All | * | <empty> | <empty> | Gatekeeper interceptor enforces multi-mode authentication (Client/Server/SSO) on all argo-server gRPC and HTTP endpoints | server/auth/gatekeeper.go:90-117, server/auth/mode.go:14-18, server/auth/gatekeeper.go:166-218 |
| add | internal_dependencies | data-science-pipelines-operator | * | <empty> | <empty> | Dockerfile labels explicitly identify this component as deployed by the DSP operator for Data Science Pipelines | argo-workflowcontroller/Dockerfile.konflux:33-35, rhoai/Dockerfile.workflowcontroller:31-40 |
