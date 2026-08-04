# Architecture Changes: feast

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | integration_points | sparkoperator.k8s.io/SparkApplication :: Conditional CRD CRUD | * | <empty> | <empty> | Spark operator integration is a conditional integration point activated by engine_type=spark_application in RBAC templates | infra/feast-operator/internal/controller/services/rbac_templates/spark_application.yaml:1, infra/feast-operator/config/rbac/role.yaml:2 |
| add | internal_dependencies | Spark Operator (sparkoperator.k8s.io) | * | <empty> | <empty> | Spark operator is a conditional internal dependency for batch materialization via SparkApplication resources | infra/feast-operator/internal/controller/services/rbac_templates/spark_application.yaml:1, infra/feast-operator/config/rbac/role.yaml:2 |
