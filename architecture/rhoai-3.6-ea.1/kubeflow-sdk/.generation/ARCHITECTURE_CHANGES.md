# Architecture Changes

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | internal_dependencies | Kubeflow Trainer API | * | <empty> | <empty> | Direct required dependency providing training job type definitions from kubeflow/trainer repo | pyproject.toml:32 |
| add | internal_dependencies | Kubeflow Katib API | * | <empty> | <empty> | Direct required dependency providing hyperparameter tuning experiment definitions from kubeflow/katib repo | pyproject.toml:33 |
| add | internal_dependencies | Kubeflow Spark API | * | <empty> | <empty> | Optional dependency providing Spark workload type definitions from kubeflow/spark-operator repo | pyproject.toml:50 |
