# Architecture Changes: llm-d-planner

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | integration_points | Ollama :: HTTP client | * | <empty> | <empty> | Backend deployment configures OLLAMA_HOST=http://ollama:11434 for co-deployed Ollama LLM inference service; ollama Python SDK is a declared dependency | deploy/kubernetes/backend.yaml:54, deploy/kubernetes/ollama.yaml:90 |
