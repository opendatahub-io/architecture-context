workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages distributed ML training jobs"
        platformAdmin = person "Platform Admin" "Configures ClusterTrainingRuntimes and monitors training workloads"

        trainer = softwareSystem "Kubeflow Trainer v2" "Kubernetes operator managing distributed ML training jobs via TrainJob CRD and pluggable runtime framework" {
            controller = container "trainer-controller-manager" "Reconciles TrainJob CRs into JobSet workloads with ML-framework-specific configuration" "Go (controller-runtime)"
            webhooks = container "Validation Webhooks" "Validates TrainJob, TrainingRuntime, and ClusterTrainingRuntime on create/update" "Go (9443/TCP HTTPS)"
            torchPlugin = container "Torch Plugin" "Configures PyTorch distributed (torchrun/torchtune) env vars, rendezvous, process-per-node" "Go Plugin"
            mpiPlugin = container "MPI Plugin" "Configures MPI with SSH keys, hostfiles, launcher/worker topology" "Go Plugin"
            coschedulingPlugin = container "Coscheduling Plugin" "Creates scheduler-plugins PodGroup for gang-scheduling" "Go Plugin"
            volcanoPlugin = container "Volcano Plugin" "Creates Volcano PodGroup for gang-scheduling with network topology" "Go Plugin"
            rhaiProgression = container "RHAI Progression Tracking" "Polls training pod /metrics for real-time progress (steps, epochs, loss)" "Go (RHOAI Extension)"
            rhaiNetpol = container "RHAI NetworkPolicy Manager" "Creates per-TrainJob NetworkPolicies for pod isolation" "Go (RHOAI Extension)"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform and API server" "External"
        jobsetController = softwareSystem "JobSet Controller" "Manages JobSet resources - replicated Jobs with network subdomain" "External"
        certController = softwareSystem "cert-controller (OPA)" "Webhook certificate generation and rotation" "External"
        schedulerPlugins = softwareSystem "Scheduler Plugins (Coscheduling)" "Gang-scheduling via PodGroup CRD" "External Optional"
        volcano = softwareSystem "Volcano" "Gang-scheduling with network topology support" "External Optional"
        prometheus = softwareSystem "OpenShift Monitoring" "Prometheus metrics collection and alerting" "Internal Platform"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator that deploys component manifests" "Internal Platform"
        kueue = softwareSystem "Kueue (MultiKueue)" "Multi-cluster job queuing and scheduling" "External Optional"

        # User interactions
        dataScientist -> trainer "Creates TrainJob CRs via kubectl/Dashboard" "HTTPS/443"
        platformAdmin -> trainer "Configures ClusterTrainingRuntimes" "HTTPS/443"

        # Core dependencies
        trainer -> kubernetes "CRUD: TrainJob, JobSet, PodGroup, NetworkPolicy, Secret, ConfigMap" "HTTPS/443, SA Token"
        trainer -> jobsetController "Creates and watches JobSet resources" "Kubernetes API"
        trainer -> certController "Webhook certificate provisioning" "Kubernetes Secret"

        # Optional scheduling
        trainer -> schedulerPlugins "Creates PodGroup for gang-scheduling" "Kubernetes API"
        trainer -> volcano "Creates Volcano PodGroup" "Kubernetes API"

        # Monitoring
        prometheus -> trainer "Scrapes controller metrics via PodMonitor" "HTTPS/8443"

        # Platform
        rhodsOperator -> trainer "Deploys trainer manifests via kustomize" "Kustomize"

        # Multi-cluster
        trainer -> kueue "Supports managedBy for multi-cluster training" "Kubernetes API"

        # Internal container relationships
        controller -> webhooks "Delegates validation" "Internal"
        controller -> torchPlugin "PyTorch configuration" "Plugin Interface"
        controller -> mpiPlugin "MPI configuration" "Plugin Interface"
        controller -> coschedulingPlugin "Coscheduling PodGroup" "Plugin Interface"
        controller -> volcanoPlugin "Volcano PodGroup" "Plugin Interface"
        controller -> rhaiProgression "Training progress polling" "Internal (RHOAI)"
        controller -> rhaiNetpol "NetworkPolicy creation" "Internal (RHOAI)"
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
            element "External Optional" {
                background #bbbbbb
                color #ffffff
                border dashed
            }
            element "Internal Platform" {
                background #7ed321
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
            element "Container" {
                background #6baed6
                color #ffffff
            }
        }
    }
}
