workspace {
    model {
        platformAdmin = person "Platform Admin" "Manages RHOAI platform components"
        dataScientist = person "Data Scientist" "Creates TrainJobs for distributed training"

        trainerOperator = softwareSystem "Trainer Operator" "Module operator that deploys and manages Kubeflow Trainer v2 resources on RHOAI/ODH" {
            controller = container "Trainer Controller" "Reconciles Trainer CR, renders kustomize manifests, deploys resources via SSA" "Go (controller-runtime)"
            manifestPipeline = container "Manifest Renderer" "Copies templates, applies RELATED_IMAGE overrides to params.env, renders kustomize overlays" "Kustomize + SSA"
            dependencyChecker = container "Dependency Checker" "Validates JobSet Operator and CRD availability before provisioning" "Go"
            gcCollector = container "GC Collector" "Label-based garbage collection via discovery API for cleanup" "Go (odh-platform-utilities)"
            driftWatcher = container "Drift Watcher" "Watches downstream resources with part-of=trainer label, re-reconciles on drift" "Go (controller-runtime)"
        }

        rhodsOperator = softwareSystem "rhods-operator / opendatahub-operator" "Platform orchestrator that creates Trainer CR" "Internal RHOAI"

        kubeflowTrainer = softwareSystem "Kubeflow Trainer v2" "Upstream ML training controller managing TrainJob lifecycle and JobSets" "Deployed by trainer-operator"

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane API" "Infrastructure"
        jobSetOperator = softwareSystem "JobSet Operator" "Manages JobSet resources for batch workloads" "External (OLM)"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Infrastructure"
        openShift = softwareSystem "OpenShift Platform" "Container platform (ClusterVersion, ImageStreams, OLM)" "Infrastructure"
        odhPlatformUtils = softwareSystem "odh-platform-utilities" "Shared library for ODH module operators" "Internal ODH"

        # Relationships - External
        rhodsOperator -> trainerOperator "Creates/deletes Trainer CR (default-trainer)" "HTTPS/443 via K8s API"
        platformAdmin -> rhodsOperator "Configures RHOAI components"
        dataScientist -> kubeflowTrainer "Creates TrainJobs for distributed training" "kubectl / HTTPS"

        # Relationships - Internal
        controller -> manifestPipeline "Triggers manifest rendering"
        controller -> dependencyChecker "Checks prerequisites before provisioning"
        controller -> gcCollector "Initiates cleanup on Removed/Deleted"
        controller -> driftWatcher "Monitors managed resources for drift"

        # Relationships - External systems
        trainerOperator -> k8sAPI "CRUD on managed resources (SSA Apply)" "HTTPS/443 TLS 1.2+"
        trainerOperator -> kubeflowTrainer "Deploys controller, CRDs, webhooks, RBAC" "SSA via K8s API"
        trainerOperator -> jobSetOperator "Validates installation before provisioning" "HTTPS/443 via K8s API"
        trainerOperator -> openShift "Reads ClusterVersion, manages ImageStreams" "HTTPS/443 via K8s API"
        prometheus -> trainerOperator "Scrapes controller metrics" "HTTP/8080"

        # Library dependency
        trainerOperator -> odhPlatformUtils "Uses PlatformObject, conditions, GC, kustomize rendering" "Go module"
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
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "External (OLM)" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #9b59b6
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Deployed by trainer-operator" {
                background #27ae60
                color #ffffff
            }
        }
    }
}
