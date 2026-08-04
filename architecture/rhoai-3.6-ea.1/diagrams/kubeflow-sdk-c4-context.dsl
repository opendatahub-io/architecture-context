workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages ML training workloads, hyperparameter tuning experiments, and Spark jobs"

        kubeflowSdk = softwareSystem "Kubeflow SDK" "Python client library providing TrainerClient interface for managing ML workloads on Kubernetes via Kubeflow APIs" {
            trainerClient = container "TrainerClient" "Public API for training workload management" "Python"
            kubernetesBackend = container "KubernetesBackend" "Production backend using kubernetes Python client for cluster operations" "Python"
            localProcessBackend = container "LocalProcessBackend" "Development backend for local execution without a cluster" "Python"
            rhaiModule = container "RHAI Module" "Red Hat AI-specific utilities: checkpoint injection, structured logging" "Python"
            trainerApi = container "kubeflow-trainer-api" "Pydantic models for TrainJob custom resources" "Python Package"
            katibApi = container "kubeflow-katib-api" "Pydantic models for Katib Experiment custom resources" "Python Package"
            sparkApi = container "kubeflow-spark-api" "Pydantic models for SparkConnect custom resources" "Python Package"
        }

        kubernetesApi = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "External"
        trainerControlPlane = softwareSystem "Kubeflow Trainer Controller" "Reconciles TrainJob CRs into training Pods" "Internal Platform"
        katibControlPlane = softwareSystem "Katib Controller" "Reconciles Experiment CRs for hyperparameter tuning" "Internal Platform"
        sparkOperator = softwareSystem "Spark Operator" "Manages SparkConnect CRs for Spark job execution" "Internal Platform"
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata and artifacts" "Internal Platform"
        s3Storage = softwareSystem "S3 Storage" "Object storage for datasets and model artifacts" "External"

        dataScientist -> kubeflowSdk "Submits training jobs, tunes hyperparameters via Python API"
        kubeflowSdk -> kubernetesApi "CRUD on Kubeflow CRs via CustomObjectsApi" "HTTPS/6443"
        kubernetesApi -> trainerControlPlane "Notifies of TrainJob CR changes"
        kubernetesApi -> katibControlPlane "Notifies of Experiment CR changes"
        kubernetesApi -> sparkOperator "Notifies of SparkConnect CR changes"
        kubeflowSdk -> modelRegistry "Fetches model metadata" "HTTPS (optional)"
        kubeflowSdk -> s3Storage "Accesses datasets and model artifacts" "HTTPS/443 (optional)"

        trainerClient -> kubernetesBackend "Dispatches operations"
        trainerClient -> localProcessBackend "Dispatches operations (dev mode)"
        trainerClient -> rhaiModule "Uses RHAI training utilities (optional)"
        kubernetesBackend -> trainerApi "Serializes TrainJob payloads"
        kubernetesBackend -> katibApi "Serializes Experiment payloads"
        kubernetesBackend -> sparkApi "Serializes SparkConnect payloads"
    }

    views {
        systemContext kubeflowSdk "SystemContext" {
            include *
            autoLayout
        }

        container kubeflowSdk "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
            }
            element "Software System" {
                background #1168BD
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}
