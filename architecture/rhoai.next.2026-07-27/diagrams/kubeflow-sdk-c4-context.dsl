workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Creates and manages ML training jobs, hyperparameter tuning, Spark workloads, and model artifacts"

        kubeflowSDK = softwareSystem "kubeflow SDK" "Python client library for managing Kubeflow ML workloads via Kubernetes API" {
            commonModule = container "kubeflow.common" "Shared types including KubernetesBackendConfig for authentication" "Python Module"
            trainerModule = container "kubeflow.trainer" "Training orchestration with multiple backends (Kubernetes, Docker, Podman)" "Python Module"
            rhaiExtensions = container "kubeflow.trainer.rhai" "RHOAI-specific extensions: transformers integration, training hub" "Python Module"
            optimizerModule = container "kubeflow.optimizer" "Katib-based hyperparameter optimization" "Python Module"
            sparkModule = container "kubeflow.spark" "SparkConnect workload management via Spark Operator" "Python Module"
            hubModule = container "kubeflow.hub" "Model Registry integration for artifact management" "Python Module"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for CRD operations" "External"
        kubeflowTrainer = softwareSystem "Kubeflow Trainer" "Manages TrainJob CRDs for distributed model training" "Internal RHOAI"
        kubeflowKatib = softwareSystem "Kubeflow Katib" "Manages Experiment CRDs for hyperparameter optimization" "Internal RHOAI"
        sparkOperator = softwareSystem "Spark Operator" "Manages SparkConnect CRDs for distributed Spark workloads" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Stores and serves model metadata and artifacts" "Internal RHOAI"
        s3Storage = softwareSystem "S3 Storage" "Object storage for checkpoints and datasets" "External"
        dockerDaemon = softwareSystem "Docker / Podman" "Local container runtime for non-K8s training" "External"

        dataScientist -> kubeflowSDK "Imports and uses via Python API"
        kubeflowSDK -> kubernetesAPI "CRD CRUD operations" "HTTPS/6443 TLS"
        kubernetesAPI -> kubeflowTrainer "Dispatches TrainJob events"
        kubernetesAPI -> kubeflowKatib "Dispatches Experiment events"
        kubernetesAPI -> sparkOperator "Dispatches SparkConnect events"
        kubeflowSDK -> modelRegistry "Registers and retrieves model artifacts" "REST/gRPC"
        kubeflowSDK -> s3Storage "Reads/writes checkpoints and datasets" "HTTPS/443"
        kubeflowSDK -> dockerDaemon "Local container training" "Unix socket"

        trainerModule -> commonModule "Uses KubernetesBackendConfig"
        optimizerModule -> commonModule "Uses KubernetesBackendConfig"
        sparkModule -> commonModule "Uses KubernetesBackendConfig"
        hubModule -> commonModule "Uses KubernetesBackendConfig"
        trainerModule -> rhaiExtensions "RHOAI transformers support"
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
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #5ba0f2
                color #ffffff
            }
        }
    }
}
