workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys distributed ML training jobs via TrainJob CRDs"
        platformAdmin = person "Platform Admin" "Configures ClusterTrainingRuntime templates for supported training frameworks"

        trainer = softwareSystem "Kubeflow Trainer" "Kubernetes-native operator for managing distributed ML training jobs across PyTorch, MPI/OpenMPI, TorchTune, and other frameworks" {
            controllerManager = container "trainer-controller-manager" "Manages TrainJob, TrainingRuntime, and ClusterTrainingRuntime CRDs; creates JobSet workloads; handles RHAI progression tracking and NetworkPolicy creation" "Go Operator (controller-runtime)" {
                trainjobController = component "TrainJob Controller" "Reconciles TrainJob CRs by resolving runtimes, building JobSets, managing lifecycle" "controller-runtime Reconciler"
                runtimeController = component "TrainingRuntime Controller" "Reconciles TrainingRuntime and ClusterTrainingRuntime CRs" "controller-runtime Reconciler"
                webhookServer = component "Webhook Server" "Validates TrainJob, TrainingRuntime, ClusterTrainingRuntime on create/update" "admission webhook, 9443/TCP"
                progressionTracker = component "Progression Tracker (RHAI)" "Polls training pod metrics for real-time progress reporting" "HTTP client, 28080/TCP"
                networkPolicyMgr = component "NetworkPolicy Manager (RHAI)" "Creates pod isolation NetworkPolicies for training jobs" "Kubernetes client"
                certManager = component "Certificate Manager" "Manages webhook TLS cert rotation via cert-controller (OPA)" "cert-controller"
                runtimeFramework = component "Runtime Framework" "Plugin-based architecture for ML policy enforcement (Torch, MPI, Coscheduling)" "Plugin Framework"
            }
            dataCache = container "data_cache" "Optional Rust-based data caching service for training workloads" "Rust Service" "Optional"
        }

        kubernetes = softwareSystem "Kubernetes" "Core platform providing API server, scheduler, and container orchestration" "External"
        jobset = softwareSystem "JobSet Controller" "Manages sets of Kubernetes Jobs for distributed training workloads" "External"
        certController = softwareSystem "cert-controller (OPA)" "Automatic webhook certificate rotation" "External"
        schedulerPlugins = softwareSystem "Kubernetes Scheduler Plugins" "Coscheduling PodGroup gang-scheduling support" "External, Optional"
        volcano = softwareSystem "Volcano Scheduler" "Volcano PodGroup gang-scheduling support" "External, Optional"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator that deploys Trainer via kustomize" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"
        kueue = softwareSystem "Kueue (MultiKueue)" "Multi-cluster workload distribution" "External, Optional"
        imageStreams = softwareSystem "OpenShift ImageStreams" "Image resolution for Training Hub universal workbench images" "Internal RHOAI"

        # User relationships
        dataScientist -> trainer "Creates TrainJob CRDs via kubectl" "HTTPS/443"
        platformAdmin -> trainer "Configures ClusterTrainingRuntime templates" "HTTPS/443"

        # Trainer → External dependencies
        trainer -> kubernetes "CRUD for all managed resources (CRDs, JobSets, Pods, Secrets, ConfigMaps, NetworkPolicies)" "HTTPS/443, ServiceAccount token"
        trainer -> jobset "Creates JobSet CRs for workload orchestration" "CRD (jobset.x-k8s.io/v1alpha2)"
        trainer -> certController "Webhook certificate auto-rotation" "In-process library"
        trainer -> schedulerPlugins "Creates PodGroup CRs for gang-scheduling" "CRD (scheduling.x-k8s.io)" "Optional"
        trainer -> volcano "Creates Volcano PodGroup CRs for gang-scheduling" "CRD (scheduling.volcano.sh)" "Optional"
        trainer -> kueue "Delegates TrainJob reconciliation for multi-cluster" "managedBy annotation" "Optional"

        # Internal RHOAI relationships
        rhodsOperator -> trainer "Deploys Trainer component via kustomize manifests" "Kustomize"
        prometheus -> trainer "Scrapes controller metrics via PodMonitor" "HTTPS/8443"
        trainer -> imageStreams "Resolves Training Hub workbench images" "OpenShift API"

        # Kubernetes → Trainer (webhook)
        kubernetes -> trainer "Calls validating webhooks on CRD create/update" "HTTPS/9443, API server client cert"
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
            element "External, Optional" {
                background #bbbbbb
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Optional" {
                background #9b59b6
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}
