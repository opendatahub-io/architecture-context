workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and manages ML training jobs, pipelines, and experiments"

        kubeflowSdk = softwareSystem "Kubeflow SDK" "Unified Python client library for managing ML workloads on Kubernetes via the RHOAI platform" {
            corePackage = container "kubeflow (Core)" "Namespace package with KubernetesBackendConfig for auth delegation" "Python Package"
            trainerModule = container "kubeflow.trainer" "Training job definitions and submission using kubeflow-trainer-api" "Python Package"
            rhaiExtensions = container "kubeflow.trainer.rhai" "Red Hat AI instrumentation: checkpoint management, progression tracking for Transformers trainers" "Python Package"
            katibModule = container "kubeflow.katib" "Hyperparameter tuning experiment definitions using kubeflow-katib-api" "Python Package"
            sparkModule = container "kubeflow.spark" "Spark workload definitions using kubeflow-spark-api (optional)" "Python Package"
            pipelinesModule = container "kubeflow.pipelines" "Pipeline definition and execution via kfp PipelinesClient (optional)" "Python Package"
        }

        kubernetesApi = softwareSystem "Kubernetes API Server" "Cluster API server for resource management and RBAC enforcement" "External"
        kubeflowTrainerCtrl = softwareSystem "Kubeflow Trainer Controller" "Reconciles TrainingJob custom resources into training pods" "Internal RHOAI"
        kubeflowKatibCtrl = softwareSystem "Katib Controller" "Manages hyperparameter tuning experiments" "Internal RHOAI"
        kubeflowSparkOp = softwareSystem "Spark Operator" "Manages Spark workloads on Kubernetes" "Internal RHOAI"
        kubeflowPipelinesApi = softwareSystem "Kubeflow Pipelines API" "API server for ML pipeline orchestration" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata and artifacts" "Internal RHOAI"

        user -> kubeflowSdk "Creates training jobs, pipelines, experiments using Python API"
        kubeflowSdk -> kubernetesApi "Submits CRs via kubernetes Python client" "HTTPS/6443, kubeconfig/SA token/OIDC"
        kubeflowSdk -> kubeflowPipelinesApi "Submits pipeline runs via kfp PipelinesClient" "HTTPS, kfp auth"
        kubernetesApi -> kubeflowTrainerCtrl "Notifies of TrainingJob CR changes" "Watch events"
        kubernetesApi -> kubeflowKatibCtrl "Notifies of Experiment CR changes" "Watch events"
        kubernetesApi -> kubeflowSparkOp "Notifies of SparkApplication CR changes" "Watch events"

        rhaiExtensions -> trainerModule "Injects instrumentation code into training jobs"
        trainerModule -> corePackage "Uses KubernetesBackendConfig for auth"
        katibModule -> corePackage "Uses KubernetesBackendConfig for auth"
        sparkModule -> corePackage "Uses KubernetesBackendConfig for auth"
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
                background #5dade2
                color #ffffff
            }
        }
    }
}
