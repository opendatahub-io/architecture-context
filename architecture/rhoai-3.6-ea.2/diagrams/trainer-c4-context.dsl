workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages distributed AI training jobs via TrainJob CRDs"
        platformAdmin = person "Platform Admin" "Manages ClusterTrainingRuntimes and cluster-level training configuration"

        trainer = softwareSystem "Kubeflow Trainer" "Kubernetes-native distributed AI training operator that orchestrates large-scale model training and fine-tuning" {
            controllerManager = container "trainer-controller-manager" "Reconciles TrainJob/TrainingRuntime CRDs, manages distributed training lifecycle" "Go controller-runtime Operator"
            webhookServer = container "Webhook Server" "Validates and defaults TrainJob and TrainingRuntime CRDs" "Go HTTPS Server (9443/TCP)"
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics with authenticated scraping" "Go HTTPS Server (8443/TCP)"
            statusServer = container "Status Server" "Accepts real-time training status updates from training pods via OIDC auth" "Go HTTPS Server (10443/TCP, feature-gated)"
            pluginFramework = container "Runtime Plugin Framework" "Extensible plugins for training frameworks (PyTorch, MPI, DeepSpeed, Flux, JAX, XGBoost)" "Go Library"
            datasetInitializer = container "Dataset Initializer" "Downloads datasets from HuggingFace Hub or OpenDAL-supported storage" "Python Init Container"
            modelInitializer = container "Model Initializer" "Downloads pre-trained models from HuggingFace Hub" "Python Init Container"
            dataCache = container "Data Cache" "Distributed in-memory data cache for streaming datasets to GPU nodes" "Rust Service"

            controllerManager -> webhookServer "Serves admission webhooks"
            controllerManager -> metricsServer "Serves authenticated metrics"
            controllerManager -> statusServer "Serves status update endpoint"
            controllerManager -> pluginFramework "Uses plugins for framework-specific workload configuration"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Central control plane for CRD operations, RBAC, and workload management" "External"
        jobset = softwareSystem "JobSet Controller" "Manages replicated Job creation and lifecycle for distributed workloads" "Internal Platform"
        schedulerPlugins = softwareSystem "Kubernetes Scheduler Plugins" "CoScheduling PodGroups for gang scheduling of training workers" "Internal Platform"
        volcano = softwareSystem "Volcano Scheduler" "Alternative gang scheduler via PodGroup CRDs" "Internal Platform"
        openShiftAPIServer = softwareSystem "OpenShift APIServer" "Provides cluster TLS profile and adherence policy" "Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal Platform"
        certController = softwareSystem "cert-controller" "In-process OPA cert-controller for webhook/metrics/status TLS certificates" "Internal"
        huggingFace = softwareSystem "HuggingFace Hub" "Model and dataset repository for downloading pre-trained models and datasets" "External"
        cloudStorage = softwareSystem "Cloud Object Storage" "S3, GCS, Azure blob storage for datasets via OpenDAL" "External"

        dataScientist -> trainer "Creates TrainJob CRDs via kubectl" "HTTPS/6443"
        platformAdmin -> trainer "Manages ClusterTrainingRuntimes and Configuration" "HTTPS/6443"

        trainer -> kubernetesAPI "CRD reconciliation, JobSet/PodGroup/NetworkPolicy CRUD" "HTTPS/6443"
        trainer -> jobset "Creates JobSet CRs as workload primitive" "HTTPS/6443 via K8s API"
        trainer -> schedulerPlugins "Creates PodGroups for gang scheduling" "HTTPS/6443 via K8s API"
        trainer -> volcano "Creates PodGroups for gang scheduling (alternative)" "HTTPS/6443 via K8s API"
        trainer -> openShiftAPIServer "Reads TLS profile, watches for changes" "HTTPS/6443"
        trainer -> huggingFace "Downloads models and datasets (init containers)" "HTTPS/443"
        trainer -> cloudStorage "Downloads datasets via OpenDAL (init containers)" "HTTPS/443"

        prometheus -> trainer "Scrapes metrics via ServiceMonitor" "HTTPS/8443"
        certController -> trainer "Manages TLS certificates in-process"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Platform" {
                background #d79b00
                color #ffffff
            }
            element "Internal" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
