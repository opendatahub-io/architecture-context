workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages distributed ML training jobs via TrainJob CRDs"
        platformAdmin = person "Platform Admin" "Configures ClusterTrainingRuntime templates for training frameworks"

        trainer = softwareSystem "Kubeflow Trainer" "Kubernetes-native operator for managing distributed ML training jobs across PyTorch, MPI, TorchTune frameworks" {
            controllerManager = container "trainer-controller-manager" "Manages TrainJob lifecycle; reconciles TrainJob → JobSet; handles progression tracking and NetworkPolicy creation" "Go Operator (controller-runtime)" "Primary"
            webhookServer = container "Webhook Server" "Validates TrainJob, TrainingRuntime, ClusterTrainingRuntime CRDs on create/update" "Go Service (embedded in controller)" "Secondary"
            runtimeFramework = container "Runtime Framework" "Plugin-based architecture for ML policy enforcement (Torch, MPI), pod group scheduling, and JobSet construction" "Go Plugins" "Secondary"
            certController = container "Cert Controller" "Automatic webhook certificate rotation using OPA cert-controller library" "Go Library" "Secondary"
            progressionTracker = container "RHAI Progression Tracker" "Polls real-time training metrics from training pods via HTTP" "Go Service (RHAI extension)" "Secondary"
        }

        kubernetes = softwareSystem "Kubernetes" "Core platform providing API server, scheduler, and kubelet" "External"
        jobset = softwareSystem "JobSet Controller" "Manages sets of Kubernetes Jobs for distributed training workloads" "External"
        schedulerPlugins = softwareSystem "Kubernetes Scheduler Plugins" "Coscheduling PodGroup gang-scheduling support" "External"
        volcano = softwareSystem "Volcano Scheduler" "Volcano PodGroup gang-scheduling support" "External"
        prometheus = softwareSystem "Prometheus / Monitoring Stack" "Metrics collection and monitoring" "Internal Platform"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator; deploys Trainer via kustomize overlays" "Internal Platform"
        kueue = softwareSystem "Kueue (MultiKueue)" "Multi-cluster workload distribution via managedBy delegation" "External"

        # Relationships - External
        dataScientist -> trainer "Creates TrainJob CRDs via kubectl" "HTTPS/443"
        platformAdmin -> trainer "Configures ClusterTrainingRuntime templates" "HTTPS/443"

        # Relationships - Internal
        controllerManager -> webhookServer "Validates CRDs"
        controllerManager -> runtimeFramework "Resolves runtime plugins"
        controllerManager -> certController "Provisions TLS certificates"
        controllerManager -> progressionTracker "Triggers metrics polling"

        # Relationships - Dependencies
        trainer -> kubernetes "CRUD for all resources (CRDs, JobSets, Pods, Secrets, ConfigMaps, NetworkPolicies)" "HTTPS/443 TLS 1.2+ ServiceAccount token"
        trainer -> jobset "Creates JobSet CRs for workload orchestration" "CRD Watch"
        trainer -> schedulerPlugins "Creates PodGroup CRs for gang-scheduling" "CRD Create (optional)"
        trainer -> volcano "Creates Volcano PodGroup CRs for gang-scheduling" "CRD Create (optional)"
        progressionTracker -> kubernetes "Polls training pod metrics endpoint" "HTTP/28080 plaintext"
        prometheus -> trainer "Scrapes controller metrics" "HTTPS/8443 TLS 1.2+"
        rhodsOperator -> trainer "Deploys component via kustomize manifests" "Kustomize"
        trainer -> kueue "Delegates reconciliation for multi-cluster distribution" "CRD management (optional)"
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
            element "Primary" {
                background #4a90e2
                color #ffffff
            }
            element "Secondary" {
                background #74b9e2
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }
    }
}
