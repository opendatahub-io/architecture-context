# Architecture Changes

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | integration_points | training-service (self) :: HTTP REST | * | <empty> | <empty> | Prediction server downloads trained ML models from the co-deployed training server via HTTP REST at TRAINING_SERVER_URL (default http://training-service:8000) | prediction/prediction_server.py:68, prediction/prediction_server.py:155-179 |
| add | internal_dependencies | training-service (self) | * | <empty> | <empty> | Prediction server has runtime dependency on training server for model synchronization via HTTP polling | prediction/prediction_server.py:68, prediction/prediction_server.py:106-118 |
