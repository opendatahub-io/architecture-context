workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages ML training workloads, HPO experiments, and model registrations using Python APIs"

        kubeflowSDK = softwareSystem "Kubeflow SDK" "Unified Python client library for managing ML training workloads across Kubeflow projects with RHAI extensions" {
            trainerClient = container "TrainerClient" "Core training client — creates/manages TrainJob CRs, supports Custom, Builtin, and RHAI trainers" "Python Module"
            rhaiTrainers = container "RHAI Trainers" "TransformersTrainer (HF/TRL with JIT checkpointing, progression tracking) and TrainingHubTrainer (SFT/OSFT/LoRA)" "Python Extension Module"
            optimizerClient = container "OptimizerClient" "Hyperparameter optimization client — creates Katib Experiment CRs" "Python Module"
            sparkClient = container "SparkClient" "Spark client — manages SparkApplication CRs for distributed data processing" "Python Module"
            hubClient = container "ModelRegistryClient" "Model Registry client — registers, queries, and manages models via REST API" "Python Module"
            kubernetesBackend = container "KubernetesBackend" "Production backend — communicates with Kubernetes API to create/manage CRDs" "Python Backend"
            containerBackend = container "ContainerBackend" "Local development backend — runs training in Docker/Podman containers" "Python Backend"
            localProcessBackend = container "LocalProcessBackend" "Quick prototyping backend — runs training as Python subprocesses" "Python Backend"
            commonUtils = container "Common Utils" "Shared types (KubernetesBackendConfig), namespace detection, K8s config loading" "Python Utility Module"
        }

        kubeflowTrainer = softwareSystem "Kubeflow Trainer Operator" "Watches TrainJob CRs and manages distributed training pod lifecycle" "Internal ODH"
        katib = softwareSystem "Kubeflow Katib" "Hyperparameter optimization — watches Experiment CRs and runs HPO trials" "Internal ODH"
        sparkOperator = softwareSystem "Kubeflow Spark Operator" "Manages SparkApplication CRs for Spark Connect sessions" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry Server" "Stores model metadata, versions, and artifact references" "Internal ODH"
        rhoaiController = softwareSystem "RHOAI Trainer Controller" "Polls RHAI training pods for progression data via annotations and HTTP metrics" "Internal RHOAI"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API server for CRD management, pod lifecycle, secrets, and events" "Infrastructure"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for checkpoint upload/download (AWS S3, MinIO, Ceph)" "External"
        hfHub = softwareSystem "HuggingFace Hub" "Model and dataset repository for ML artifacts" "External"
        dockerPodman = softwareSystem "Docker/Podman" "Local container runtime for development/testing" "External"

        # User relationships
        dataScientist -> kubeflowSDK "Creates training jobs, HPO experiments, registers models" "Python API (pip install kubeflow)"

        # SDK to backends
        trainerClient -> kubernetesBackend "Delegates job creation"
        trainerClient -> containerBackend "Delegates local training"
        trainerClient -> localProcessBackend "Delegates subprocess training"
        trainerClient -> rhaiTrainers "Uses RHAI trainers (TransformersTrainer, TrainingHubTrainer)"
        trainerClient -> commonUtils "Uses shared types and utilities"
        optimizerClient -> commonUtils "Uses shared types and utilities"
        sparkClient -> commonUtils "Uses shared types and utilities"

        # SDK to Kubernetes API
        kubernetesBackend -> k8sAPI "CRUD on TrainJob/TrainingRuntime CRs, pod logs, events, configmaps, secrets" "HTTPS/443, Bearer Token, TLS 1.2+"
        optimizerClient -> k8sAPI "CRUD on Experiment CRs" "HTTPS/443, Bearer Token, TLS 1.2+"
        sparkClient -> k8sAPI "CRUD on SparkApplication CRs" "HTTPS/443, Bearer Token, TLS 1.2+"

        # Kubernetes API to controllers
        k8sAPI -> kubeflowTrainer "Watch stream for TrainJob CRs"
        k8sAPI -> katib "Watch stream for Experiment CRs"
        k8sAPI -> sparkOperator "Watch stream for SparkApplication CRs"

        # SDK to external services
        hubClient -> modelRegistry "Model registration and querying" "HTTP/HTTPS, Bearer Token (optional)"
        rhaiTrainers -> s3Storage "Checkpoint upload/download (via fsspec/s3fs)" "HTTPS/443, AWS IAM"
        rhaiTrainers -> hfHub "Model/dataset download (via hf:// URI)" "HTTPS/443, Bearer Token (optional)"
        containerBackend -> dockerPodman "Local container execution" "Unix socket"

        # RHOAI controller interaction
        rhoaiController -> rhaiTrainers "Polls in-pod metrics server for progression data" "HTTP/28080, No auth"
    }

    views {
        systemContext kubeflowSDK "SystemContext" {
            include *
            autoLayout
        }

        container kubeflowSDK "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Internal RHOAI" {
                background #e74c3c
                color #ffffff
            }
            element "Infrastructure" {
                background #f39c12
                color #ffffff
            }
        }
    }
}
