workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and manages ML workloads using Python APIs"

        kubeflowSDK = softwareSystem "Kubeflow SDK" "Unified Python SDK for managing ML workloads across Kubeflow ecosystem (v0.4.1+rhai0)" {
            trainerModule = container "kubeflow.trainer" "Training client with pluggable backends (Kubernetes, Container, LocalProcess)" "Python Module"
            rhaiModule = container "kubeflow.trainer.rhai" "RHOAI-specific trainers: TransformersTrainer, TrainingHubTrainer, SpeculativeDecodingTrainer with auto-instrumentation" "Python Module"
            optimizerModule = container "kubeflow.optimizer" "Hyperparameter optimization client wrapping Katib" "Python Module"
            sparkModule = container "kubeflow.spark" "Spark Connect client for distributed data processing" "Python Module"
            hubModule = container "kubeflow.hub" "Model Registry client for artifact and version management" "Python Module"
            pipelinesModule = container "kubeflow.pipelines" "KFP client for pipeline definition and execution" "Python Module"
            commonModule = container "kubeflow.common" "Shared utilities, types, and structured logging" "Python Module"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for CRD operations" "External"
        trainerOperator = softwareSystem "Kubeflow Trainer Operator" "Reconciles TrainJob CRs and manages training pods" "Internal Platform"
        katib = softwareSystem "Kubeflow Katib" "Hyperparameter optimization controller" "Internal Platform"
        sparkOperator = softwareSystem "Kubeflow Spark Operator" "Manages Spark Connect sessions" "Internal Platform"
        modelRegistry = softwareSystem "Kubeflow Model Registry" "Stores model metadata, artifacts, and versions" "Internal Platform"
        kfpServer = softwareSystem "Kubeflow Pipelines Server" "ML workflow orchestration" "Internal Platform"
        s3Storage = softwareSystem "S3-compatible Storage" "Cloud checkpoint upload/download" "External"
        hfHub = softwareSystem "HuggingFace Hub" "Model config retrieval for speculator layer detection" "External"
        dockerPodman = softwareSystem "Docker / Podman" "Local container execution for development" "External"

        user -> kubeflowSDK "Uses Python APIs to submit ML workloads"
        kubeflowSDK -> k8sAPI "Creates/watches CRDs (TrainJob, SparkConnect, etc.)" "HTTPS/443"
        kubeflowSDK -> modelRegistry "Registers and queries model artifacts" "HTTP(S)/443 or 8080"
        kubeflowSDK -> kfpServer "Manages ML pipelines" "HTTPS"
        kubeflowSDK -> s3Storage "Uploads/downloads checkpoints" "HTTPS/443"
        kubeflowSDK -> hfHub "Downloads model configs" "HTTPS/443"
        kubeflowSDK -> dockerPodman "Runs containers locally" "Unix socket"

        k8sAPI -> trainerOperator "Notifies of TrainJob changes" "Watch/Informer"
        k8sAPI -> katib "Notifies of OptimizationJob changes" "Watch/Informer"
        k8sAPI -> sparkOperator "Notifies of SparkConnect changes" "Watch/Informer"

        trainerModule -> commonModule "Uses shared types and utilities"
        rhaiModule -> trainerModule "Extends with RHOAI-specific trainers"
        optimizerModule -> commonModule "Uses shared types and utilities"
        sparkModule -> commonModule "Uses shared types and utilities"
        hubModule -> commonModule "Uses shared types and utilities"
        pipelinesModule -> commonModule "Uses shared types and utilities"
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
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
