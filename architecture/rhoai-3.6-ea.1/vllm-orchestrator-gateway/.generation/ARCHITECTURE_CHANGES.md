# Architecture Changes: vllm-orchestrator-gateway

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | http_endpoints | POST :: /{route_name}/v1/chat/completions | * | <empty> | <empty> | Dynamic HTTP endpoints registered per route in config; axum router binds POST handlers for each route name | src/main.rs:87-106, config/config.yaml:12-17 |
| add | authentication | /{route_name}/v1/chat/completions :: POST | * | <empty> | <empty> | Gateway forwards Authorization and x-forwarded-* headers to orchestrator without local enforcement | src/main.rs:422-433, src/main.rs:493-501 |
| add | integration_points | vLLM Orchestrator :: REST | * | <empty> | <empty> | Gateway proxies enriched requests to orchestrator /api/v2/chat/completions-detection endpoint | src/main.rs:218-231, src/main.rs:276-288, src/config.rs:15-27 |
| add | internal_dependencies | vLLM Orchestrator | * | <empty> | <empty> | Backend orchestrator service is a required runtime dependency for request proxying | src/main.rs:218-231, src/config.rs:15-27, config/config.yaml:1-3 |
