workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Creates and manages ML training jobs, optimization experiments, Spark sessions, and model registrations"

        kubeflowSdk = softwareSystem "Kubeflow SDK" "Unified Python SDK for managing ML workloads across the Kubeflow ecosystem" {
            trainerClient = container "TrainerClient" "Unified API for distributed ML training across Kubernetes, Docker/Podman, and local process backends" "Python SDK Module"
            optimizerClient = container "OptimizerClient" "Hyperparameter optimization API wrapping Katib Experiments" "Python SDK Module"
            sparkClient = container "SparkClient" "Spark data processing API managing SparkConnect CRDs and PySpark sessions" "Python SDK Module"
            hubClient = container "ModelRegistryClient" "Model registry client for model versioning and artifact management" "Python SDK Module"
            rhaiExtensions = container "RHAI Extensions" "TransformersTrainer with progress tracking/checkpointing and TrainingHubTrainer with algorithm integration" "Python SDK Module (RHAI)"
            commonModule = container "Common Module" "Shared types, constants, namespace detection utilities" "Python SDK Module"
        }

        kubernetesApi = softwareSystem "Kubernetes API Server" "Cluster API for CRD CRUD, pod management, and event streaming" "External"
        trainerOperator = softwareSystem "Kubeflow Trainer Operator" "Server-side reconciliation of TrainJob CRs into JobSets and Pods" "Internal RHOAI"
        katibController = softwareSystem "Katib Controller" "Server-side management of hyperparameter optimization experiments" "Internal RHOAI"
        sparkOperator = softwareSystem "Spark Operator" "Server-side management of SparkConnect sessions" "Internal RHOAI"
        jobsetController = softwareSystem "JobSet Controller" "Orchestrates distributed training pods via ReplicatedJob resources" "External"
        modelRegistryServer = softwareSystem "Model Registry Server" "Backend storage for registered models, versions, and artifacts" "Internal RHOAI"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Dataset and model downloads for initializers" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Dataset/model downloads and checkpoint storage" "External"
        mavenCentral = softwareSystem "Maven Central" "Spark Connect JAR download for SparkConnect sessions" "External"
        dockerDaemon = softwareSystem "Docker/Podman Daemon" "Container lifecycle management for local development" "External"

        dataScientist -> kubeflowSdk "Uses SDK to create training jobs, optimize hyperparameters, run Spark sessions, register models" "Python API"

        trainerClient -> kubernetesApi "Creates/reads/deletes TrainJob, TrainingRuntime CRDs" "HTTPS/443"
        optimizerClient -> kubernetesApi "Creates/reads/deletes Experiment CRDs" "HTTPS/443"
        sparkClient -> kubernetesApi "Creates/reads/deletes SparkConnect CRDs" "HTTPS/443"
        hubClient -> modelRegistryServer "Registers and queries models, versions, artifacts" "HTTPS/443 or HTTP/8080"
        rhaiExtensions -> kubernetesApi "Creates TrainJob with RHAI annotations" "HTTPS/443"

        trainerClient -> commonModule "Uses shared types and namespace detection"
        optimizerClient -> commonModule "Uses shared types and namespace detection"
        sparkClient -> commonModule "Uses shared types and namespace detection"
        optimizerClient -> trainerClient "Uses TrainerBackend to build trial templates"

        trainerClient -> dockerDaemon "Container lifecycle (container backend)" "Unix socket"

        kubernetesApi -> trainerOperator "Notifies of TrainJob changes" "Controller Watch"
        kubernetesApi -> katibController "Notifies of Experiment changes" "Controller Watch"
        kubernetesApi -> sparkOperator "Notifies of SparkConnect changes" "Controller Watch"
        trainerOperator -> jobsetController "Creates JobSet resources" "CRD creation"

        sparkClient -> sparkOperator "PySpark session via SparkConnect Service" "gRPC/15002"

        rhaiExtensions -> huggingfaceHub "Downloads datasets and models" "HTTPS/443"
        rhaiExtensions -> s3Storage "Uploads checkpoints, downloads datasets/models" "HTTPS/443"
        sparkClient -> mavenCentral "Downloads Spark Connect JAR" "HTTPS/443"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
