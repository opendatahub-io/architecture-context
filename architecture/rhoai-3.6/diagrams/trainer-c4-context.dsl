workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Submits distributed training jobs via TrainJob CRs"
        platform = person "Platform Admin" "Manages ClusterTrainingRuntimes and cluster configuration"

        trainer = softwareSystem "Kubeflow Trainer" "Kubernetes operator that orchestrates distributed ML training jobs by reconciling TrainJob CRs against pluggable TrainingRuntime templates" {
            controller = container "trainer-controller-manager" "Reconciles TrainJob, TrainingRuntime, ClusterTrainingRuntime, and OptimizationJob CRDs" "Go controller-runtime operator"
            webhookServer = container "Webhook Server" "Mutates and validates TrainJob and runtime CRs" "In-process HTTPS server (9443/TCP)"
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics with TLS and auth" "In-process HTTPS server (8443/TCP)"
            statusServer = container "Status Server" "Receives training pod progress reports (alpha)" "In-process HTTPS server (10443/TCP)"
            datasetInit = container "dataset-initializer" "Downloads datasets from HuggingFace Hub or object storage" "Python init container"
            modelInit = container "model-initializer" "Downloads pre-trained model weights from HuggingFace Hub" "Python init container"
            plugins = container "ML Framework Plugins" "PyTorch, DeepSpeed, MPI, XGBoost, MLX, JAX — build JobSet specs" "Go plugin framework"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for CRD CRUD, leader election, and admission" "Infrastructure"
        jobset = softwareSystem "JobSet Controller" "Manages distributed job sets for multi-pod workloads" "Internal Platform"
        coscheduling = softwareSystem "CoScheduling (scheduler-plugins)" "Gang scheduling via PodGroup CRDs" "Internal Platform"
        volcano = softwareSystem "Volcano Scheduler" "Alternative gang scheduling backend" "Internal Platform"
        katib = softwareSystem "Katib" "Hyperparameter optimization and search" "Internal Platform"
        prometheus = softwareSystem "Prometheus (openshift-monitoring)" "Metrics collection and alerting" "Infrastructure"
        certController = softwareSystem "cert-controller (OPA)" "Webhook certificate lifecycle management" "Infrastructure"
        openshiftAPI = softwareSystem "OpenShift API" "Cluster TLS security profile configuration" "Infrastructure"
        hfHub = softwareSystem "HuggingFace Hub" "Model and dataset repository" "External"
        objStorage = softwareSystem "Object Storage (S3-compatible)" "Dataset and artifact storage" "External"

        user -> trainer "Creates TrainJob CR via kubectl/SDK"
        platform -> trainer "Manages ClusterTrainingRuntimes, Configuration"
        trainer -> k8sAPI "CRD CRUD, leader election, resource management" "HTTPS/6443"
        trainer -> jobset "Creates JobSet CRs for distributed training" "HTTPS/6443 (via API)"
        trainer -> coscheduling "Creates PodGroup CRs for gang scheduling" "HTTPS/6443 (via API)"
        trainer -> volcano "Creates PodGroup CRs (alternative)" "HTTPS/6443 (via API)"
        trainer -> katib "OptimizationJob trial management" "Go module"
        trainer -> certController "Webhook TLS certificate provisioning" "In-cluster"
        trainer -> openshiftAPI "Reads cluster TLS security profile" "HTTPS/6443"
        prometheus -> trainer "Scrapes /metrics endpoint" "HTTPS/8443"
        datasetInit -> hfHub "Downloads datasets" "HTTPS/443"
        datasetInit -> objStorage "Downloads datasets via OpenDAL" "HTTPS/443"
        modelInit -> hfHub "Downloads model weights" "HTTPS/443"

        controller -> webhookServer "Serves admission webhooks"
        controller -> metricsServer "Serves metrics"
        controller -> statusServer "Serves status updates"
        controller -> plugins "Delegates JobSet construction"
    }

    views {
        systemContext trainer "SystemContext" {
            include *
            autoLayout
        }

        container trainer "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #f5a623
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
