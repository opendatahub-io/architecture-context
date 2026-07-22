workspace {
    model {
        dataScientist = person "Data Scientist" "Submits and manages ML training jobs, hyperparameter optimization, and model registration"
        mlEngineer = person "ML Engineer" "Builds training pipelines and configures RHAI extensions for production fine-tuning"

        kubeflowSdk = softwareSystem "Kubeflow SDK" "Unified Python SDK for managing ML workloads (training, HPO, Spark, model registry) across Kubeflow and Red Hat AI platforms" {
            trainerClient = container "TrainerClient" "Main entry point for training job lifecycle (create, list, get, delete, wait, logs)" "Python"
            optimizerClient = container "OptimizerClient" "Hyperparameter optimization via Katib Experiments" "Python"
            sparkClient = container "SparkClient" "SparkConnect session management on Kubernetes" "Python"
            modelRegistryClient = container "ModelRegistryClient" "CRUD operations for registered models, versions, and artifacts" "Python"

            kubernetesBackend = container "KubernetesBackend" "Creates TrainJob CRs on Kubernetes clusters" "Python"
            containerBackend = container "ContainerBackend" "Runs training in Docker/Podman containers locally" "Python"
            localProcessBackend = container "LocalProcessBackend" "Runs training as local Python subprocesses" "Python"

            transformersTrainer = container "TransformersTrainer (RHAI)" "HuggingFace fine-tuning with progression tracking and JIT checkpointing" "Python"
            trainingHubTrainer = container "TrainingHubTrainer (RHAI)" "Algorithm-registry-based training with HTTP metrics injection" "Python"
            algorithmRegistry = container "Algorithm Registry" "Registry of training algorithms (sft, osft, lora_sft, lora_grpo)" "Python"
        }

        kubernetesApi = softwareSystem "Kubernetes API Server" "Cluster API for all CRD operations" "External"
        trainerOperator = softwareSystem "Kubeflow Trainer Operator" "Reconciles TrainJob CRs into Kubernetes workloads (JobSets, Pods)" "Internal RHOAI"
        katibController = softwareSystem "Katib Controller" "Reconciles Experiment CRs for hyperparameter optimization" "Internal RHOAI"
        sparkOperator = softwareSystem "Spark Operator" "Reconciles SparkApplication CRs for Spark jobs" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Stores ML model metadata, versions, and artifacts" "Internal RHOAI"
        sparkConnectServer = softwareSystem "SparkConnect Server" "Apache Spark session server" "External"
        dockerPodman = softwareSystem "Docker/Podman" "Local container runtime for development" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for checkpoints and datasets" "External"
        huggingFaceHub = softwareSystem "HuggingFace Hub" "Pre-trained model and dataset repository" "External"

        # System-level relationships
        dataScientist -> kubeflowSdk "Submits training jobs, queries models" "Python API"
        mlEngineer -> kubeflowSdk "Configures RHAI extensions and pipelines" "Python API"

        kubeflowSdk -> kubernetesApi "Creates and manages CRs (TrainJob, Experiment, SparkApplication)" "HTTPS/6443"
        kubeflowSdk -> modelRegistry "CRUD for models, versions, artifacts" "HTTPS/443"
        kubeflowSdk -> sparkConnectServer "Spark session connectivity" "gRPC/15002"
        kubeflowSdk -> dockerPodman "Container backend for local development" "Unix Socket"
        kubeflowSdk -> s3Storage "Checkpoint upload, dataset download" "HTTPS/443"
        kubeflowSdk -> huggingFaceHub "Model and dataset downloads" "HTTPS/443"

        kubernetesApi -> trainerOperator "Watch/Reconcile TrainJob CRs"
        kubernetesApi -> katibController "Watch/Reconcile Experiment CRs"
        kubernetesApi -> sparkOperator "Watch/Reconcile SparkApplication CRs"

        # Container-level relationships
        dataScientist -> trainerClient "create(), list(), get(), delete(), wait()"
        dataScientist -> optimizerClient "create_optimization_job()"
        dataScientist -> sparkClient "create_spark_session()"
        dataScientist -> modelRegistryClient "register_model(), list_models()"

        trainerClient -> kubernetesBackend "Dispatches (KubernetesBackendConfig)"
        trainerClient -> containerBackend "Dispatches (ContainerBackendConfig)"
        trainerClient -> localProcessBackend "Dispatches (LocalProcessBackendConfig)"

        transformersTrainer -> trainerClient "Extends with HF instrumentation"
        trainingHubTrainer -> trainerClient "Extends with algorithm registry"
        trainingHubTrainer -> algorithmRegistry "Reads algorithm specs"

        kubernetesBackend -> kubernetesApi "POST/GET/DELETE TrainJob CRs" "HTTPS/6443"
        optimizerClient -> kubernetesApi "POST/GET Experiment CRs" "HTTPS/6443"
        sparkClient -> kubernetesApi "POST SparkApplication CRs" "HTTPS/6443"
        sparkClient -> sparkConnectServer "Connect to Spark sessions" "gRPC/15002"
        modelRegistryClient -> modelRegistry "REST API calls" "HTTPS/443"
        containerBackend -> dockerPodman "Manage containers" "Unix Socket"
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
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
