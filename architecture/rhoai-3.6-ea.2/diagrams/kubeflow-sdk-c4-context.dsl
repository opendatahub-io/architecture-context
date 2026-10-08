workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Creates and manages ML training jobs, experiments, and models using Python APIs"

        kubeflowSDK = softwareSystem "Kubeflow SDK" "Unified Python SDK for managing ML workloads across Kubeflow projects — Trainer, Optimizer, Spark, Hub, and Pipelines" {
            trainerModule = container "kubeflow.trainer" "TrainerClient API for distributed training job lifecycle management with pluggable backends" "Python Module"
            rhaiModule = container "kubeflow.trainer.rhai" "RHOAI-specific trainers (Transformers, TrainingHub, SpeculativeDecoding) with code injection, progression tracking, and checkpointing" "Python Module (RHOAI Extension)"
            optimizerModule = container "kubeflow.optimizer" "OptimizerClient API for hyperparameter optimization via Katib Experiments" "Python Module"
            sparkModule = container "kubeflow.spark" "SparkClient API for Spark Connect sessions and job management" "Python Module"
            hubModule = container "kubeflow.hub" "ModelRegistryClient API for model artifact registration and retrieval" "Python Module"
            pipelinesModule = container "kubeflow.pipelines" "PipelinesClient wrapping kfp for pipeline definition and execution" "Python Module"
            commonModule = container "kubeflow.common" "Shared utilities, types, structured logging, and KubernetesBackendConfig" "Python Module"
        }

        kubeAPI = softwareSystem "Kubernetes API Server" "Core cluster API for all CR and resource operations" "External"
        trainerOperator = softwareSystem "Kubeflow Trainer Operator" "Reconciles TrainJob CRs into JobSets and training pods" "Internal RHOAI"
        katibOperator = softwareSystem "Katib / Optimizer Operator" "Reconciles Experiment CRs for hyperparameter optimization" "Internal RHOAI"
        sparkOperator = softwareSystem "Spark Operator" "Manages Spark clusters and SparkConnect sessions" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Stores and serves model artifact metadata" "Internal RHOAI"
        kfPipelines = softwareSystem "Kubeflow Pipelines" "Pipeline definition, compilation, and execution service" "Internal RHOAI"
        trainingHub = softwareSystem "Training Hub" "RHAI-specific training orchestration service" "Internal RHOAI"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for model checkpoints and artifacts" "External"
        huggingFaceHub = softwareSystem "HuggingFace Hub" "Model repository for config auto-detection and gated model access" "External"

        # User interactions
        dataScientist -> kubeflowSDK "Uses Python APIs to submit training jobs, register models, run experiments"

        # SDK → Kubernetes API
        trainerModule -> kubeAPI "Creates TrainJob CRs" "HTTPS/443, Bearer Token"
        optimizerModule -> kubeAPI "Creates Experiment CRs" "HTTPS/443, Bearer Token"
        sparkModule -> kubeAPI "Creates SparkConnect CRs" "HTTPS/443, Bearer Token"

        # SDK → Internal services
        hubModule -> modelRegistry "Registers and retrieves models" "HTTP(S)/443 or 8080, Bearer Token"
        pipelinesModule -> kfPipelines "Manages pipeline definitions and runs" "HTTPS/443, Bearer Token"

        # SDK → External services
        rhaiModule -> s3Storage "Uploads/downloads training checkpoints" "HTTPS/443, AWS credentials"
        rhaiModule -> huggingFaceHub "Downloads model configs for speculator auto-detection" "HTTPS/443, HF_TOKEN"

        # Server-side reconciliation
        kubeAPI -> trainerOperator "Dispatches TrainJob watch events"
        kubeAPI -> katibOperator "Dispatches Experiment watch events"
        kubeAPI -> sparkOperator "Dispatches SparkConnect watch events"

        # Internal relationships
        rhaiModule -> trainerModule "Extends with RHOAI-specific trainers"
        trainerModule -> commonModule "Uses shared types and configuration"
        optimizerModule -> commonModule "Uses shared types and configuration"
        sparkModule -> commonModule "Uses shared types and configuration"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
        }
    }
}
