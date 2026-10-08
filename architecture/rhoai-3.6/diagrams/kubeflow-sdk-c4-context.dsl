workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages ML training jobs, models, and pipelines"
        mlEngineer = person "ML Engineer" "Builds training pipelines and deploys models to production"

        kubeflowSdk = softwareSystem "Kubeflow SDK" "Unified Python SDK (v0.4.1+rhai0) for managing ML workloads across the Kubeflow ecosystem with RHOAI-specific trainer extensions" {
            trainerClient = container "TrainerClient" "Creates and manages distributed training jobs via pluggable backends" "Python SDK Module"
            rhaiTrainers = container "RHAI Trainers" "TransformersTrainer, TrainingHubTrainer, SpeculativeDecodingTrainer with auto-instrumentation" "Python SDK Module (kubeflow.trainer.rhai)"
            optimizerClient = container "OptimizerClient" "Hyperparameter optimization via Katib Experiment CRs" "Python SDK Module"
            sparkClient = container "SparkClient" "Manages Apache Spark jobs via SparkConnect CRs" "Python SDK Module"
            hubClient = container "ModelRegistryClient" "Model lifecycle management and artifact registration" "Python SDK Module"
            pipelinesClient = container "PipelinesClient" "Pipeline definition and execution via kfp SDK" "Python SDK Module"
            common = container "Common" "Shared types (KubernetesBackendConfig), utilities, structured logging" "Python SDK Module"
        }

        k8sApi = softwareSystem "Kubernetes API Server" "Cluster API for CRD CRUD, pod management, and watch streams" "External"
        trainerController = softwareSystem "Kubeflow Trainer Controller" "Manages TrainJob lifecycle, schedules training pods" "Internal RHOAI"
        katibController = softwareSystem "Kubeflow Katib Controller" "Manages hyperparameter optimization Experiments and Trials" "Internal RHOAI"
        sparkOperator = softwareSystem "Spark Operator" "Manages SparkConnect sessions on Kubernetes" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata and artifact references" "Internal RHOAI"
        kfPipelines = softwareSystem "Kubeflow Pipelines" "Workflow orchestration for ML pipelines" "Internal RHOAI"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model and dataset repository" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for checkpoints and model artifacts" "External"

        dataScientist -> kubeflowSdk "Creates training jobs, optimizes hyperparameters, registers models" "Python API"
        mlEngineer -> kubeflowSdk "Builds and executes ML pipelines" "Python API"

        kubeflowSdk -> k8sApi "CRD CRUD, pod watch, configmap reads" "HTTPS/443"
        kubeflowSdk -> modelRegistry "Registers models, queries versions" "HTTPS/443 or HTTP/8080"
        kubeflowSdk -> kfPipelines "Defines and executes pipelines" "HTTPS/443"

        trainerController -> k8sApi "Watches TrainJob CRs, creates training pods" "HTTPS/443"
        katibController -> k8sApi "Watches Experiment CRs, creates Trials" "HTTPS/443"
        sparkOperator -> k8sApi "Watches SparkConnect CRs" "HTTPS/443"

        trainerClient -> trainerController "Creates TrainJob and TrainingRuntime CRs" "CRD API"
        rhaiTrainers -> trainerClient "Extends with RHOAI-specific trainers" "Internal"
        optimizerClient -> katibController "Creates Experiment CRs" "CRD API"
        sparkClient -> sparkOperator "Creates SparkConnect CRs" "CRD API"
        hubClient -> modelRegistry "REST API calls" "HTTPS/443"
        pipelinesClient -> kfPipelines "Pipeline compilation and submission" "HTTPS/443"

        kubeflowSdk -> huggingfaceHub "Downloads models and datasets (from training pods)" "HTTPS/443"
        kubeflowSdk -> s3Storage "Uploads/downloads checkpoints (from training pods)" "HTTPS/443"
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
