workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and manages distributed ML training jobs via TrainJob CRDs"

        trainer = softwareSystem "Kubeflow Trainer" "Kubernetes-native operator for managing distributed ML training jobs across PyTorch, MPI/OpenMPI, TorchTune, and other frameworks" {
            controllerManager = container "trainer-controller-manager" "Manages TrainJob, TrainingRuntime, and ClusterTrainingRuntime CRDs; creates JobSet workloads; handles progression tracking and NetworkPolicy creation" "Go Operator (controller-runtime)" {
                trainjobController = component "TrainJob Controller" "Reconciles TrainJob resources, resolves runtimes, creates JobSets" "controller-runtime Reconciler"
                runtimeController = component "TrainingRuntime Controller" "Watches TrainingRuntime and ClusterTrainingRuntime changes" "controller-runtime Reconciler"
                webhookServer = component "Validating Webhooks" "3 validating webhooks for TrainJob, TrainingRuntime, ClusterTrainingRuntime" "admission.Webhook"
                progressionTracker = component "RHAI Progression Tracker" "Polls training pod metrics for real-time progress updates" "HTTP Client"
                networkPolicyManager = component "RHAI NetworkPolicy Manager" "Creates NetworkPolicy for pod isolation on training jobs" "controller-runtime Client"
                certController = component "cert-controller" "Automatic webhook certificate rotation (OPA cert-controller)" "cert-controller v0.14.0"
                runtimeFramework = component "Runtime Framework" "Plugin-based architecture for ML framework support (Torch, MPI, TorchTune)" "Plugin Framework"
            }
            dataCache = container "data_cache" "Optional data caching service for training workloads" "Rust Service" "Optional"
        }

        kubernetes = softwareSystem "Kubernetes" "Core platform providing API server, scheduler, and container orchestration" "External" {
            apiServer = container "API Server" "Kubernetes API server for all resource CRUD operations" "HTTPS/443"
            scheduler = container "Scheduler" "Pod scheduling with optional gang-scheduling plugins" "Internal"
        }

        jobset = softwareSystem "JobSet" "Manages sets of Kubernetes Jobs for distributed training workloads (v0.10.1)" "External"
        schedulerPlugins = softwareSystem "Kubernetes Scheduler Plugins" "Coscheduling PodGroup gang-scheduling support (v0.34.1-devel)" "External Optional"
        volcano = softwareSystem "Volcano" "Volcano PodGroup gang-scheduling support (v1.13.1)" "External Optional"
        certManager = softwareSystem "cert-controller (OPA)" "Automatic webhook certificate rotation (v0.14.0)" "External"
        kueue = softwareSystem "Kueue (MultiKueue)" "Multi-cluster workload distribution" "External Optional"

        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator that deploys Trainer component via kustomize" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus / Monitoring Stack" "Metrics collection and monitoring" "Internal RHOAI"
        openshiftImageStreams = softwareSystem "OpenShift ImageStreams" "Training Hub universal workbench images (CPU/CUDA/ROCm)" "Internal RHOAI"

        # Relationships
        user -> trainer "Creates TrainJob via kubectl" "HTTPS/443"
        trainer -> kubernetes "CRUD for CRDs, JobSets, Pods, Secrets, ConfigMaps, NetworkPolicies" "HTTPS/443, ServiceAccount token"
        trainer -> jobset "Creates JobSet resources for workload orchestration" "CRD API"
        trainer -> schedulerPlugins "Creates PodGroup for gang-scheduling" "CRD API" "Optional"
        trainer -> volcano "Creates Volcano PodGroup for gang-scheduling" "CRD API" "Optional"

        rhodsOperator -> trainer "Deploys via kustomize manifests" "Kustomize"
        prometheus -> trainer "Scrapes metrics via PodMonitor" "HTTPS/8443"
        trainer -> openshiftImageStreams "Resolves Training Hub runtime images" "ImageStream API"
        kueue -> trainer "Delegates TrainJob reconciliation via managedBy field" "CRD API" "Optional"

        controllerManager -> apiServer "All resource CRUD, leader election, event recording" "HTTPS/443, TLS 1.2+, ServiceAccount token"
        apiServer -> webhookServer "Admission reviews for TrainJob/TrainingRuntime/ClusterTrainingRuntime" "HTTPS/9443, TLS auto-rotated, client cert"
        progressionTracker -> apiServer "LIST Pods, PATCH TrainJob annotations" "HTTPS/443"
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

        component controllerManager "Components" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Optional" {
                background #bbbbbb
                color #ffffff
                border dashed
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Optional" {
                background #d5e8d4
                border dashed
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}
