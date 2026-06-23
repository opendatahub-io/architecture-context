workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs distributed ML training jobs using TrainJob CRs"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform components via rhods-operator"

        trainerOperator = softwareSystem "Trainer Operator" "Kubernetes operator managing Kubeflow Trainer v2 component lifecycle for distributed ML training on RHOAI" {
            controllerManager = container "Controller Manager" "Watches Trainer CR, renders kustomize manifests, deploys upstream trainer controller, ClusterTrainingRuntimes, and ImageStreams via server-side apply" "Go (controller-runtime, kubebuilder v4)"
            kustomizeRenderer = container "Kustomize Renderer" "Renders upstream trainer manifests with RHOAI image overrides from RELATED_IMAGE_* env vars" "odh-platform-utilities"
            dependencyChecker = container "Dependency Checker" "Verifies JobSet CRD, JobSetOperator CR, and OLM conditions before provisioning" "Go"
            garbageCollector = container "Garbage Collector" "Cleans up labeled resources on Trainer CR deletion/removal; special handling for ClusterTrainingRuntimes" "odh-platform-utilities/gc"
        }

        kubeflowTrainer = softwareSystem "Kubeflow Trainer Controller" "Upstream controller that reconciles TrainJob CRs into JobSet workloads for distributed training (managed deployment)" "Managed"
        clusterTrainingRuntimes = softwareSystem "ClusterTrainingRuntimes" "15 pre-configured distributed training templates for PyTorch with CUDA 12.8/13.0, ROCm 6.4, and CPU variants" "Managed CRs"
        trainingHubImageStreams = softwareSystem "Training Hub ImageStreams" "OpenShift ImageStream resources exposing training workbench images in the RHOAI dashboard (3 accelerator variants)" "Managed CRs"

        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator that creates Trainer CR to activate this component" "Internal RHOAI"
        jobSetOperator = softwareSystem "JobSet Operator" "Manages JobSet CRD; required dependency for distributed training workloads" "External Dependency"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API server for all resource CRUD operations" "Infrastructure"
        olm = softwareSystem "Operator Lifecycle Manager" "Manages operator installation; used to verify JobSet Operator status" "Infrastructure"
        openShiftAPI = softwareSystem "OpenShift API" "Provides cluster type detection via ClusterVersion resources" "Infrastructure"
        prometheus = softwareSystem "Prometheus" "Monitoring system that scrapes operator metrics" "Infrastructure"

        # Relationships - Platform Admin
        platformAdmin -> rhodsOperator "Configures RHOAI platform"
        rhodsOperator -> trainerOperator "Creates Trainer CR (default-trainer)" "Kubernetes API / HTTPS 443"

        # Relationships - Trainer Operator internal
        controllerManager -> kustomizeRenderer "Renders manifests"
        controllerManager -> dependencyChecker "Checks prerequisites"
        controllerManager -> garbageCollector "Cleanup on removal"

        # Relationships - Trainer Operator to managed systems
        trainerOperator -> kubeflowTrainer "Deploys and manages upstream controller" "Server-side apply / HTTPS 443"
        trainerOperator -> clusterTrainingRuntimes "Creates/updates 15 runtime variants" "Server-side apply / HTTPS 443"
        trainerOperator -> trainingHubImageStreams "Creates ImageStreams (OpenShift only)" "Server-side apply / HTTPS 443"
        trainerOperator -> kubernetesAPI "All resource CRUD, watches, dependency checks" "HTTPS/443, TLS 1.2+, SA Bearer Token"

        # Relationships - Dependencies
        trainerOperator -> jobSetOperator "Verifies CRD and CR availability" "API check"
        trainerOperator -> olm "Checks JobSet Operator installation status" "API read"
        trainerOperator -> openShiftAPI "Detects OpenShift vs vanilla Kubernetes" "API read"

        # Relationships - Data Scientist
        dataScientist -> kubernetesAPI "Creates TrainJob CR" "kubectl / HTTPS 443"
        kubeflowTrainer -> kubernetesAPI "Creates JobSet from TrainJob" "HTTPS/443, SA Bearer Token"

        # Relationships - Monitoring
        prometheus -> trainerOperator "Scrapes /metrics" "HTTP/8080, NetworkPolicy restricted"
    }

    views {
        systemContext trainerOperator "SystemContext" {
            include *
            autoLayout
        }

        container trainerOperator "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Managed" {
                background #7ed321
                color #000000
            }
            element "Managed CRs" {
                background #7ed321
                color #000000
            }
            element "Internal RHOAI" {
                background #438dd5
                color #ffffff
            }
            element "External Dependency" {
                background #999999
                color #ffffff
            }
            element "Infrastructure" {
                background #666666
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
