workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models using Python code"
        mlEngineer = person "ML Engineer" "Manages training infrastructure and model lifecycle"

        kubeflowSDK = softwareSystem "Kubeflow SDK" "Unified Python SDK providing consistent APIs to manage ML workloads across Kubeflow ecosystem components" {
            trainerClient = container "TrainerClient" "Train and fine-tune AI models via TrainJob/TrainingRuntime CRDs" "Python Client"
            optimizerClient = container "OptimizerClient" "Hyperparameter optimization via Katib Experiment CRDs" "Python Client"
            sparkClient = container "SparkClient" "Manage Apache Spark Connect sessions" "Python Client"
            hubClient = container "ModelRegistryClient" "Register, version, and query ML model artifacts" "Python Client"
            rhaiTrainers = container "RHAI Trainers" "TransformersTrainer and TrainingHubTrainer with progression tracking, JIT checkpointing" "Python Extension (RHOAI-only)"
            commonUtils = container "Common Utilities" "Shared types, constants, namespace resolution" "Python Module"

            trainerClient -> commonUtils "Uses shared types"
            optimizerClient -> commonUtils "Uses shared types"
            sparkClient -> commonUtils "Uses shared types"
            rhaiTrainers -> trainerClient "Extends"
        }

        kubeflowTrainerOp = softwareSystem "Kubeflow Trainer Operator" "Manages training job lifecycle on Kubernetes via TrainJob CRDs" "Internal Platform"
        katibController = softwareSystem "Katib Controller" "Manages hyperparameter optimization trials" "Internal Platform"
        sparkOperator = softwareSystem "Spark Operator" "Provisions and manages Spark Connect sessions" "Internal Platform"
        modelRegistry = softwareSystem "Model Registry Server" "Model artifact registration, versioning, and querying" "Internal Platform"
        jobSetController = softwareSystem "JobSet Controller" "Underlying workload orchestration for TrainJobs" "Internal Platform"

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for CRD CRUD operations" "External Infrastructure"
        s3Storage = softwareSystem "S3-compatible Storage" "Model checkpoint and dataset storage" "External Service"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Pre-trained model and dataset repository" "External Service"
        dockerPodman = softwareSystem "Docker/Podman Runtime" "Container runtime for local development" "External Tool"
        pypi = softwareSystem "PyPI" "Python package index for training container dependencies" "External Service"
        mavenCentral = softwareSystem "Maven Central" "Java artifact repository for Spark Connect JARs" "External Service"

        dataScientist -> kubeflowSDK "Submits training jobs, queries models, runs Spark sessions" "Python API"
        mlEngineer -> kubeflowSDK "Configures training runtimes, manages model lifecycle" "Python API"

        trainerClient -> k8sAPI "Creates TrainJob, reads TrainingRuntime CRDs" "HTTPS/443, Bearer Token"
        optimizerClient -> k8sAPI "Creates Experiment, reads Trial CRDs" "HTTPS/443, Bearer Token"
        sparkClient -> k8sAPI "Creates SparkConnect CRDs" "HTTPS/443, Bearer Token"
        hubClient -> modelRegistry "Registers and queries models" "REST API, HTTPS/443 or HTTP/8080"

        rhaiTrainers -> s3Storage "Uploads JIT checkpoints" "HTTPS/443, AWS IAM"
        rhaiTrainers -> huggingfaceHub "Downloads gated models/datasets" "HTTPS/443, Bearer Token"

        sparkClient -> sparkOperator "Connects to Spark driver pods" "gRPC/15002"
        trainerClient -> dockerPodman "Local development training" "Unix Socket"

        kubeflowTrainerOp -> jobSetController "Creates JobSets for training workloads" "CRD"
        k8sAPI -> kubeflowTrainerOp "Reconciles TrainJob CRDs" "Internal"
        k8sAPI -> katibController "Reconciles Experiment CRDs" "Internal"
        k8sAPI -> sparkOperator "Reconciles SparkConnect CRDs" "Internal"
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
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "External Service" {
                background #999999
                color #ffffff
            }
            element "External Infrastructure" {
                background #666666
                color #ffffff
            }
            element "External Tool" {
                background #bbbbbb
                color #333333
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
