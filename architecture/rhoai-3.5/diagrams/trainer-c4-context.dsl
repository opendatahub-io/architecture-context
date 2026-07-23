workspace {
    model {
        user = person "Data Scientist" "Creates and manages distributed ML training jobs"
        platformAdmin = person "Platform Admin" "Configures ClusterTrainingRuntimes and operator settings"

        trainer = softwareSystem "Kubeflow Trainer" "Kubernetes-native operator for distributed ML training (PyTorch, MPI, DeepSpeed, MLX, TorchTune)" {
            controller = container "trainer-controller-manager" "Manages TrainJob lifecycle, converts specs to JobSet objects via plugin framework" "Go Operator (controller-runtime)"
            webhookServer = container "Webhook Server" "Validates TrainJob, TrainingRuntime, and ClusterTrainingRuntime resources" "Go HTTPS Service (9443/TCP)"
            pluginFramework = container "Plugin Framework" "Extensible pipeline: Torch, MPI, DeepSpeed, MLX, CoScheduling, Volcano, JobSet plugins" "Go Library"
            rhaiExtensions = container "RHAI Extensions" "Progression tracking (metrics polling), NetworkPolicy enforcement, TLS profile integration" "Go Library"
            datasetInitializer = container "Dataset Initializer" "Downloads and prepares training datasets" "Python Init Container"
            modelInitializer = container "Model Initializer" "Downloads and prepares pre-trained models" "Python Init Container"
        }

        dataCacheSystem = softwareSystem "Data Cache" "Apache Arrow Flight-based distributed dataset caching (experimental)" "External" {
            dataCacheHead = container "Data Cache Head" "Arrow Flight server for cache coordination" "Rust Service"
            dataCacheWorker = container "Data Cache Worker" "DataFusion + Iceberg data access" "Rust Service"
        }

        jobset = softwareSystem "JobSet" "Manages groups of Jobs as a single unit for distributed training" "External"
        certController = softwareSystem "cert-controller" "Self-signed certificate rotation for webhooks (open-policy-agent)" "External"
        schedulerPlugins = softwareSystem "scheduler-plugins" "CoScheduling PodGroup gang-scheduling" "External"
        volcano = softwareSystem "Volcano" "Volcano PodGroup gang-scheduling" "External"
        leaderWorkerSet = softwareSystem "LeaderWorkerSet" "Alternative workload orchestration for data cache" "External"

        rhodsOperator = softwareSystem "rhods-operator" "Deploys trainer operator via kustomize manifests" "Internal RHOAI"
        openshiftAPI = softwareSystem "OpenShift APIServer" "Provides cluster TLS security profile configuration" "Internal RHOAI"
        trainingHub = softwareSystem "Training Hub Images" "Pre-built universal training images (CUDA, ROCm, CPU)" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Platform monitoring via PodMonitor scraping" "Internal RHOAI"

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API server for all CRD and resource operations" "External"

        # User interactions
        user -> trainer "Creates TrainJob via kubectl/SDK" "HTTPS/443"
        platformAdmin -> trainer "Configures ClusterTrainingRuntimes" "kubectl"

        # Core operator flows
        controller -> webhookServer "Validates CRDs"
        controller -> pluginFramework "Invokes plugins for TrainJob reconciliation"
        controller -> rhaiExtensions "Progression tracking, NetworkPolicy creation"

        # External dependencies
        trainer -> jobset "Creates and monitors JobSet objects" "HTTPS/443 (Kubernetes API)"
        trainer -> k8sAPI "CRD CRUD, leader election, webhook cert management" "HTTPS/443"
        trainer -> certController "Webhook TLS certificate rotation"
        trainer -> schedulerPlugins "Creates CoScheduling PodGroups" "HTTPS/443"
        trainer -> volcano "Creates Volcano PodGroups" "HTTPS/443"

        # Internal RHOAI dependencies
        rhodsOperator -> trainer "Deploys via kustomize manifests"
        trainer -> openshiftAPI "Reads TLS security profile" "HTTPS/443"
        trainer -> trainingHub "References pre-built training images"
        prometheus -> trainer "Scrapes operator metrics" "HTTPS/8443"

        # Init containers
        datasetInitializer -> k8sAPI "Downloads datasets" "HTTPS"
        modelInitializer -> k8sAPI "Downloads models" "HTTPS"
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
                background #6cb4ee
                color #ffffff
            }
        }
    }
}
