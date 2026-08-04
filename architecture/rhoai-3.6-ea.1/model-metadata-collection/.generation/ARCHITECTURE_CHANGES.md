# Architecture Changes: model-metadata-collection

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | integration_points | HuggingFace API :: REST client | * | <empty> | <empty> | Build-time REST client for fetching model collections and metadata | internal/huggingface/client.go:57, cmd/model-extractor/main.go:153 |
| add | integration_points | GitHub API :: REST client | * | <empty> | <empty> | Build-time REST client for fetching agent metadata and README files | internal/github/client.go:37-45, internal/github/client.go:78-79 |
| add | integration_points | Container registries :: OCI client | * | <empty> | <empty> | Build-time OCI client for fetching image architectures and artifact metadata | internal/registry/registry.go:77, cmd/model-extractor/main.go:206 |
| add | authentication | HuggingFace API (build-time) :: GET | * | <empty> | <empty> | Build-time Bearer token authentication for HuggingFace API using HF_TOKEN env var | internal/huggingface/client.go:36-51 |
| add | authentication | GitHub API (build-time) :: GET | * | <empty> | <empty> | Build-time Bearer token authentication for GitHub API using GITHUB_TOKEN env var | internal/github/client.go:30-45 |
| add | authentication | Container registries (build-time) :: OCI protocol | * | <empty> | <empty> | Build-time system credential chain authentication via containers/image/v5 | internal/registry/registry.go:14, go.mod:9 |

## Prose Summary

The analyzer baseline had empty integration points and authentication tables because the component exposes no runtime APIs or services. Source inspection revealed three build-time integration points (HuggingFace API, GitHub API, container registries) and their corresponding authentication mechanisms. These are outbound HTTP client interactions used during CI/CD catalog generation and are not present in the shipped container image. The FIPS compliance, HTTP endpoints, services, and internal dependencies gaps were resolved as confirmed-empty or not-applicable for a data-only container.
