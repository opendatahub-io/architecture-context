# Architecture Changes: trainer-operator

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | integration_points | operator.openshift.io/JobSetOperator :: Dynamic CRD Watch | * | <empty> | <empty> | Controller dynamically watches JobSetOperator resource gated by CRD existence predicate; triggers re-reconciliation on dependency status changes | internal/controller/trainer_controller.go:184-187 |
| add | integration_points | trainer.kubeflow.org resources :: CRD CRUD | * | <empty> | <empty> | RBAC grants full CRUD on TrainJobs, TrainingRuntimes, and ClusterTrainingRuntimes; operator deploys and manages these resources via manifest rendering pipeline | config/rbac/role.yaml:137-139, internal/controller/trainer_controller.go:192-196 |
