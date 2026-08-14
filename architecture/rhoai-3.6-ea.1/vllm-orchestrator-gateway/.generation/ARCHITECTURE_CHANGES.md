# Architecture Changes: vllm-orchestrator-gateway

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | http_endpoints | POST :: /{route_name}/v1/chat/completions | * | <empty> | <empty> | Dynamic routes created from YAML config; each route registers a POST handler for OpenAI-compatible chat completions | src/main.rs:84-108 |
| add | authentication | /{route_name}/v1/chat/completions :: POST | * | <empty> | <empty> | Gateway forwards Authorization headers to orchestrator without local enforcement | src/main.rs:422-432 |
| add | integration_points | vllm-orchestrator :: REST | * | <empty> | <empty> | Gateway forwards augmented chat completion requests to orchestrator at /api/v2/chat/completions-detection | src/main.rs:218-230, src/config.rs:20-27 |
| add | internal_dependencies | vllm-orchestrator | * | <empty> | <empty> | Backend orchestrator service that receives detector-augmented requests from this gateway | src/main.rs:218-230, src/config.rs:14-27 |
