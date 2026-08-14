# Architecture Changes: eval-hub

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | integration_points | MLflow Tracking Server :: HTTP client | * | <empty> | <empty> | MLflow tracking client is constructed with TLS-configured HTTP transport for experiment tracking; conditionally initialized when tracking URI is configured | internal/eval_hub/mlflow/mlflow.go:43-92 |
