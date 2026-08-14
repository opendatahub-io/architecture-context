# Architecture Changes: model-metadata-collection

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | integration_points | HuggingFace API :: REST | * | <empty> | <empty> | model-extractor fetches model collections from HuggingFace API during CI; uses optional HF_TOKEN Bearer auth | internal/huggingface/client.go:57 |
| add | integration_points | GitHub API :: REST | * | <empty> | <empty> | model-extractor fetches agent metadata from GitHub API during CI; uses optional GITHUB_TOKEN Bearer auth | internal/github/client.go:49 |
| add | integration_points | OCI Container Registries :: REST | * | <empty> | <empty> | model-extractor queries OCI registries for image manifest metadata via containers/image library during CI | internal/registry/registry.go:14 |
