# Architecture Changes: eval-hub

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | services | eval-hub-api | * | <empty> | <empty> | Application binds to port 8080 with configurable TLS; Dockerfile EXPOSE confirms container port | Dockerfile.konflux:79, internal/eval_hub/server/server.go:93 |
| add | services | eval-hub-metrics | * | <empty> | <empty> | Dedicated MetricsServer listens on configurable port for Prometheus scraping in cluster mode | internal/eval_hub/server/metrics_server.go:24-28 |
| add | integration_points | PostgreSQL/SQLite :: SQL database client | * | <empty> | <empty> | Storage layer imports pgx (PostgreSQL) and modernc.org/sqlite drivers with configurable driver selection | internal/eval_hub/storage/sql/sql.go:14, 18, 33-37, 72-76 |
| add | integration_points | MLflow Tracking Server :: HTTP client | * | <empty> | <empty> | Server constructs mlflowClient used by evalcards ResultsExporter for experiment tracking | internal/eval_hub/server/server.go:37, 88, internal/eval_hub/config/sidecar_config.go:53-59 |
