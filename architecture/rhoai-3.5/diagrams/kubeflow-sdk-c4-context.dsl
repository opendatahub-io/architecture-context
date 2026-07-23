workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages ML training jobs, hyperparameter optimization, and model registration using Python APIs"
        mlEngineer = person "ML Engineer" "Deploys distributed training workloads and configures training runtimes"

        kubeflowSDK = softwareSystem "Kubeflow SDK" "Unified Python SDK providing Pythonic APIs for managing AI/ML training, hyperparameter optimization, Spark processing, and model registry operations on Kubernetes" {
            trainerModule = container "kubeflow.trainer" "Client SDK for Kubeflow Trainer -- creates TrainJob CRs for distributed training with PyTorch, MPI, TorchTune" "Python Library"
            rhaiModule = container "kubeflow.trainer.rhai" "RHAI-specific trainer extensions -- TrainingHubTrainer (SFT/OSFT/LoRA) and TransformersTrainer with progression tracking and JIT checkpointing" "Python Library"
            optimizerModule = container "kubeflow.optimizer" "Client SDK for Katib-based hyperparameter optimization -- creates Experiment CRs" "Python Library"
            sparkModule = container "kubeflow.spark" "Client SDK for Spark Operator -- manages SparkConnect sessions on Kubernetes" "Python Library"
            hubModule = container "kubeflow.hub" "Client SDK for Model Registry -- registers and queries model artifacts" "Python Library"
            commonModule = container "kubeflow.common" "Shared utilities -- Kubernetes config, namespace detection, structured logging" "Python Library"

            rhaiModule -> trainerModule "Extends with RHAI trainers"
            trainerModule -> commonModule "Uses shared utilities"
            optimizerModule -> commonModule "Uses shared utilities"
            sparkModule -> commonModule "Uses shared utilities"
            hubModule -> commonModule "Uses shared utilities"
        }

        kubeflowTrainer = softwareSystem "Kubeflow Trainer Operator" "Reconciles TrainJob CRs into JobSets and pods for distributed training" "Internal RHOAI"
        katib = softwareSystem "Kubeflow Katib" "Hyperparameter optimization controller -- reconciles Experiment CRs" "Internal RHOAI"
        sparkOperator = softwareSystem "Kubeflow Spark Operator" "Manages SparkConnectServer CRs for Spark Connect sessions" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata, versions, and artifact locations" "Internal RHOAI"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for CRD and resource management" "Infrastructure"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for model checkpoints and training artifacts" "External"
        huggingFaceHub = softwareSystem "HuggingFace Hub" "Model and dataset repository for ML artifacts" "External"
        pypi = softwareSystem "PyPI / Package Index" "Python package repository for dynamic pip installs in training pods" "External"

        dataScientist -> kubeflowSDK "Creates training jobs, runs HP optimization, registers models" "Python API"
        mlEngineer -> kubeflowSDK "Configures distributed training with custom runtimes" "Python API"

        kubeflowSDK -> kubernetesAPI "Creates/reads TrainJob, Experiment, SparkConnectServer CRs; reads Pods, Secrets, ConfigMaps" "HTTPS/443, Bearer Token"
        kubeflowSDK -> modelRegistry "CRUD operations for registered models and versions" "HTTP(S)/443 or 8080, User Token"

        kubernetesAPI -> kubeflowTrainer "Notifies of TrainJob CR changes" "Watch"
        kubernetesAPI -> katib "Notifies of Experiment CR changes" "Watch"
        kubernetesAPI -> sparkOperator "Notifies of SparkConnectServer CR changes" "Watch"

        kubeflowTrainer -> kubernetesAPI "Creates JobSets and pods" "HTTPS/443"
        kubeflowSDK -> s3Storage "Uploads/downloads checkpoints via fsspec/s3fs" "HTTPS/443, AWS IAM"
        kubeflowSDK -> huggingFaceHub "Downloads models/datasets via hf:// URIs" "HTTPS/443, Access Token"
        kubeflowSDK -> pypi "Dynamic package installation in training pods" "HTTPS/443"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #f5a623
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
