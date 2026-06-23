workspace {
    model {
        dataScientist = person "Data Scientist" "Creates TrainJob resources to run distributed ML training"
        platformAdmin = person "Platform Admin" "Defines ClusterTrainingRuntime resources with approved training configurations"

        trainer = softwareSystem "Kubeflow Trainer" "Kubernetes operator that orchestrates distributed ML training workloads via TrainJob, TrainingRuntime, and ClusterTrainingRuntime CRDs" {
            controllerManager = container "trainer-controller-manager" "Reconciles TrainJob/TrainingRuntime/ClusterTrainingRuntime CRDs; manages JobSet lifecycle, webhook validation, plugin framework" "Go Operator (controller-runtime)" "Operator"
            webhookServer = container "Webhook Server" "Validates TrainJob, TrainingRuntime, ClusterTrainingRuntime on CREATE/UPDATE" "Go (embedded in controller)" "Webhook"
            pluginFramework = container "Plugin Framework" "Executes ML-specific policies: PyTorch (torchrun/torchtune), MPI, CoScheduling, Volcano, JobSet builder" "Go (in-process)" "Framework"
            rhaiProgression = container "RHAI Progression Tracker" "Polls training pod metrics (port 28080) and updates TrainJob annotations with real-time progress" "Go (RHOAI only)" "RHOAI Feature"
            rhaiNetPolicy = container "RHAI NetworkPolicy Enforcer" "Creates per-TrainJob NetworkPolicies restricting metrics access to controller pod" "Go (RHOAI only)" "RHOAI Feature"
            dataCache = container "Data Cache" "Distributed dataset caching with head-worker topology using Apache Arrow Flight and Iceberg metadata" "Rust" "Optional"
            datasetInitializer = container "Dataset Initializer" "Init container that prepares training datasets before training pod startup" "Go" "Init Container"
            modelInitializer = container "Model Initializer" "Init container that downloads pre-trained model weights before training" "Go" "Init Container"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform and API server" "External"
        jobset = softwareSystem "JobSet Controller" "Orchestrates multi-pod job topologies (sigs.k8s.io/jobset v0.10.1)" "External"
        schedulerPlugins = softwareSystem "Scheduler Plugins" "CoScheduling gang scheduling for training pods (sigs.k8s.io/scheduler-plugins v0.34.1)" "External"
        volcano = softwareSystem "Volcano Scheduler" "Alternative gang scheduling with queue and priority support (volcano.sh v1.13.1)" "External"
        certController = softwareSystem "cert-controller" "Webhook certificate management and auto-rotation (open-policy-agent v0.14.0)" "External"
        leaderWorkerSet = softwareSystem "LeaderWorkerSet" "Manages head-worker pod topology for data cache" "External"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics scraping via PodMonitor" "External"
        icebergStore = softwareSystem "Iceberg Metadata Store" "Table metadata for data cache file discovery" "External"

        rhodsOperator = softwareSystem "rhods-operator / opendatahub-operator" "Platform operator that deploys Trainer via kustomize overlay" "Internal ODH"
        kueue = softwareSystem "Kueue" "Workload management for TrainJobs via managedBy field" "Internal ODH"

        # Relationships - Users
        dataScientist -> trainer "Creates TrainJob via kubectl/API"
        platformAdmin -> trainer "Defines ClusterTrainingRuntime/TrainingRuntime"

        # Relationships - Internal
        controllerManager -> webhookServer "Embeds webhook server"
        controllerManager -> pluginFramework "Executes plugin chain during reconciliation"
        controllerManager -> rhaiProgression "Runs progression tracking (RHOAI)"
        controllerManager -> rhaiNetPolicy "Enforces network isolation (RHOAI)"

        # Relationships - External
        controllerManager -> kubernetes "CRUD operations via K8s API" "HTTPS/443 TLS 1.2+ Bearer Token"
        controllerManager -> jobset "Creates JobSet resources for training orchestration" "K8s API HTTPS"
        controllerManager -> schedulerPlugins "Creates PodGroup for CoScheduling" "K8s API HTTPS"
        controllerManager -> volcano "Creates PodGroup for Volcano scheduling" "K8s API HTTPS"
        certController -> controllerManager "Manages webhook TLS certificates" "K8s Secret"
        prometheus -> controllerManager "Scrapes metrics" "HTTPS/8443 TLS"
        rhodsOperator -> trainer "Deploys via kustomize overlay" "manifests/rhoai/"
        dataCache -> icebergStore "Reads table metadata" "HTTP/S3"
        dataCache -> leaderWorkerSet "Managed by LWS for head-worker topology" "K8s API"

        kubernetes -> webhookServer "Sends admission reviews" "HTTPS/9443 mTLS"
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
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Operator" {
                background #4a90e2
                color #ffffff
            }
            element "Webhook" {
                background #4a90e2
                color #ffffff
            }
            element "Framework" {
                background #6c5ce7
                color #ffffff
            }
            element "RHOAI Feature" {
                background #e17055
                color #ffffff
            }
            element "Optional" {
                background #00b894
                color #ffffff
            }
            element "Init Container" {
                background #fdcb6e
                color #333333
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
        }
    }
}
