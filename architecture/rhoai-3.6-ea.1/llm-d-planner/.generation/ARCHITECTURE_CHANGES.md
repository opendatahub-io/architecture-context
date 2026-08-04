# Architecture Changes: llm-d-planner

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | integration_points | Ollama :: HTTP client | * | <empty> | <empty> | Co-deployed Ollama instance accessed via HTTP at OLLAMA_HOST for local LLM inference | deploy/kubernetes/backend.yaml:57-58 |
| add | integration_points | PostgreSQL :: SQL client (psycopg2) | * | <empty> | <empty> | Co-deployed PostgreSQL accessed via DATABASE_URL for benchmark and config storage | deploy/kubernetes/backend.yaml:43-44 |
| add | internal_dependencies | PostgreSQL | * | <empty> | <empty> | Co-deployed PostgreSQL database accessed via psycopg2 SQL client for benchmark storage | deploy/kubernetes/backend.yaml:43-44 |
| add | internal_dependencies | Ollama | * | <empty> | <empty> | Co-deployed Ollama LLM server accessed via HTTP client for local inference | deploy/kubernetes/backend.yaml:57-58 |
