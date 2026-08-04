# Architecture Changes: llama-stack-provider-trustyai-garak

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |

No architecture table rows were added, updated, or deleted. Source inspection confirmed:

- **HTTP Endpoints**: The component is a batch Job adapter, not a web service. No FastAPI/Starlette route decorators, no `uvicorn.run()` call, and the Dockerfile label `io.openshift.expose-services=""` explicitly declares no exposed services. The uvicorn dependency is transitive from garak or eval-hub-sdk. The empty table is correct.
- **Services**: No Kubernetes Service manifests or kustomization files exist in the repository. The component runs as a K8s Job, not a long-running service. The empty table is correct.
- **Authentication**: The component has no inbound endpoints requiring authentication. Its outbound authentication (SA tokens for KFP, AWS credentials for S3, API keys for LLM endpoints) is documented in the Architectural Analysis and Data Flows sections as narrative, not as authentication table rows, because the Authentication & Authorization table captures inbound endpoint auth enforcement.
- **FIPS Compliance**: Added as a narrative subsection under Security with a structured evidence table. No architecture table rows affected.
