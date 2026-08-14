# Architecture Changes: llm-d-latency-predictor

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | integration_points | training-service (self) :: HTTP client | * | <empty> | <empty> | Prediction server polls training server for model downloads via HTTP GET at TRAINING_SERVER_URL | prediction/prediction_server.py:68, deploy/base/prediction/configmap.yaml:13 |
| add | integration_points | llm-d inference gateway :: HTTP server | * | <empty> | <empty> | Training server receives latency observations via POST /add_training_data_bulk from llm-d gateway | training/training_server.py:31-32, deploy/base/training/deployment.yaml:26 |
| add | internal_dependencies | llm-d | * | <empty> | <empty> | Component is designed as a latency prediction sidecar for the llm-d inference gateway which sends observed TTFT/TPOT samples | prediction/prediction_server.py:68, training/training_server.py:31 |
