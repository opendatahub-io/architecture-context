# Architecture Changes: ogx-distribution

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | http_endpoints | POST :: /v1/messages | * | <empty> | <empty> | Anthropic Messages API endpoint explicitly documented in config.yaml comment | distribution/config.yaml:137 |
| add | authentication | OGX API (port 8321) :: All | * | <empty> | <empty> | OAuth2 token authentication with JWKS validation and resource-ownership access policy declared in server auth config | distribution/config.yaml:259-280 |
| add | internal_dependencies | PostgreSQL | * | <empty> | <empty> | PostgreSQL is the required storage backend for both kv_default and sql_default persistence | distribution/config.yaml:199-214 |
| add | internal_dependencies | vLLM | * | <empty> | <empty> | vLLM is the primary inference provider conditionally activated via VLLM_URL environment variable | distribution/config.yaml:25-32 |
| add | integration_points | PostgreSQL :: SQL client | * | <empty> | <empty> | Required SQL storage backend for key-value and relational persistence | distribution/config.yaml:199-214 |
| add | integration_points | vLLM :: HTTP client | * | <empty> | <empty> | Remote inference and embedding model serving provider | distribution/config.yaml:25-40 |
| add | integration_points | AWS Bedrock :: HTTP client | * | <empty> | <empty> | Conditional remote inference provider via AWS SDK | distribution/config.yaml:41-48 |
| add | integration_points | IBM WatsonX :: HTTP client | * | <empty> | <empty> | Conditional remote inference provider | distribution/config.yaml:48-53 |
| add | integration_points | Milvus :: HTTP/gRPC client | * | <empty> | <empty> | Conditional remote vector store with mTLS support | distribution/config.yaml:82-94 |
| add | integration_points | pgvector :: SQL client | * | <empty> | <empty> | Conditional remote vector store via PostgreSQL | distribution/config.yaml:95-105 |
| add | integration_points | Qdrant :: HTTP/gRPC client | * | <empty> | <empty> | Conditional remote vector store | distribution/config.yaml:106-121 |
| add | integration_points | S3 :: HTTP client | * | <empty> | <empty> | Conditional remote file storage provider | distribution/config.yaml:175-192 |
| add | integration_points | OpenTelemetry Collector :: OTLP | * | <empty> | <empty> | Conditional traces and metrics export via opentelemetry-instrument wrapper | distribution/entrypoint.sh:70-77 |
