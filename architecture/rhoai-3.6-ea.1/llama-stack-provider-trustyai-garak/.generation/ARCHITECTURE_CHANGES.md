# Architecture Changes: llama-stack-provider-trustyai-garak

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|

No table-level changes are proposed. Source inspection confirmed that the empty HTTP Endpoints, Services, and Authentication tables accurately reflect this component's architecture: it runs as a Kubernetes Job consuming platform APIs rather than exposing endpoints. The FIPS Compliance subsection was added under Security as authored synthesis prose rather than a table row change.
