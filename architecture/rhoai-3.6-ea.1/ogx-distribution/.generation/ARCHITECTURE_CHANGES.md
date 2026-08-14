# Architecture Changes: ogx-distribution

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | http_endpoints | ALL :: /v1/inference/* | * | <empty> | <empty> | OGX server exposes inference API on port 8321 | distribution/config.yaml:14-80 |
| add | http_endpoints | ALL :: /v1/responses/* | * | <empty> | <empty> | OGX server exposes responses API for agentic workflows | distribution/config.yaml:122-139 |
| add | http_endpoints | ALL :: /v1/messages/* | * | <empty> | <empty> | OGX server exposes Anthropic Messages API passthrough | distribution/config.yaml:136-150 |
| add | http_endpoints | ALL :: /v1/batches/* | * | <empty> | <empty> | OGX server exposes batch processing API | distribution/config.yaml:191-195 |
| add | http_endpoints | ALL :: /v1/vector-io/* | * | <empty> | <empty> | OGX server exposes vector I/O API for RAG | distribution/config.yaml:81-121 |
| add | http_endpoints | ALL :: /v1/tool-runtime/* | * | <empty> | <empty> | OGX server exposes tool runtime API for search and MCP | distribution/config.yaml:145-165 |
| add | http_endpoints | ALL :: /v1/files/* | * | <empty> | <empty> | OGX server exposes files API for upload and management | distribution/config.yaml:166-193 |
| add | http_endpoints | ALL :: /v1/file-processors/* | * | <empty> | <empty> | OGX server exposes file processors API | distribution/config.yaml:187-190 |
| add | authentication | OGX API :: All | * | <empty> | <empty> | OAuth2 bearer token auth with JWKS validation and owner-based access policy | distribution/config.yaml:259-280 |
| add | internal_dependencies | PostgreSQL | * | <empty> | <empty> | Required storage backend for KV and SQL persistence | distribution/config.yaml:198-214 |
| add | internal_dependencies | vLLM | * | <empty> | <empty> | Primary optional inference backend for LLM and embedding models | distribution/config.yaml:25-40 |
| add | integration_points | PostgreSQL :: SQL/KV client | * | <empty> | <empty> | Persistent storage for all state, metadata, and relational data | distribution/config.yaml:198-214 |
| add | integration_points | vLLM :: HTTP client | * | <empty> | <empty> | LLM inference and embedding model serving | distribution/config.yaml:25-40 |
| add | integration_points | AWS Bedrock :: HTTP client | * | <empty> | <empty> | Cloud inference via AWS Bedrock API | distribution/config.yaml:41-48 |
| add | integration_points | IBM WatsonX :: HTTP client | * | <empty> | <empty> | Cloud inference via WatsonX API | distribution/config.yaml:49-53 |
| add | integration_points | Azure AI :: HTTP client | * | <empty> | <empty> | Cloud inference via Azure OpenAI API | distribution/config.yaml:54-60 |
| add | integration_points | Google Vertex AI :: HTTP client | * | <empty> | <empty> | Cloud inference via Vertex AI API | distribution/config.yaml:61-65 |
| add | integration_points | OpenAI :: HTTP client | * | <empty> | <empty> | Cloud inference via OpenAI API | distribution/config.yaml:66-70 |
| add | integration_points | Google Gemini :: HTTP client | * | <empty> | <empty> | Cloud inference via Gemini API | distribution/config.yaml:71-76 |
| add | integration_points | Anthropic :: HTTP client | * | <empty> | <empty> | Cloud inference via Anthropic API | distribution/config.yaml:77-80 |
| add | integration_points | Milvus :: HTTP client | * | <empty> | <empty> | Remote vector database for RAG | distribution/config.yaml:82-100 |
| add | integration_points | PGVector :: SQL client | * | <empty> | <empty> | Vector database via PostgreSQL extension | distribution/config.yaml:101-112 |
| add | integration_points | Qdrant :: HTTP/gRPC client | * | <empty> | <empty> | Vector database for RAG | distribution/config.yaml:106-121 |
| add | integration_points | Brave Search :: HTTP client | * | <empty> | <empty> | Web search tool runtime | distribution/config.yaml:150-154 |
| add | integration_points | Tavily Search :: HTTP client | * | <empty> | <empty> | Web search tool runtime | distribution/config.yaml:155-159 |
| add | integration_points | S3 :: HTTP client | * | <empty> | <empty> | Remote file storage | distribution/config.yaml:175-193 |
| add | integration_points | OTEL Collector :: OTLP client | * | <empty> | <empty> | Traces and metrics export when OTEL_SERVICE_NAME is set | distribution/entrypoint.sh:70-77 |
