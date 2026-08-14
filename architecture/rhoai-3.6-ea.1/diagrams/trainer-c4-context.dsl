workspace {
    model {
        user = person "Data Scientist" "Creates and manages distributed ML training jobs"

        trainer = softwareSystem "Kubeflow Trainer Operator" "Manages distributed ML training jobs on Kubernetes through CRD-based orchestration of JobSets with pluggable scheduling and runtime framework extensibility" {
            controller = container "Trainer Controller Manager" "Reconciles TrainJob, TrainingRuntime, ClusterTrainingRuntime CRDs; delegates to runtime plugins" "Go controller-runtime Operator"
            webhook = container "Admission Webhooks" "Validates and defaults TrainJob, TrainingRuntime, ClusterTrainingRuntime resources" "HTTPS/443 TLS"
            metricsServer = container "Metrics Server" "Exposes operator metrics" "TCP/8443"
            statusServer = container "Status Server" "Health and readiness endpoints" "TCP/10443"
            runtimePlugins = container "Runtime Plugins" "Flux, MPI framework-specific job configuration" "Go Plugins"
            schedulingPlugins = container "Scheduling Plugins" "CoScheduling, Volcano gang scheduling integration" "Go Plugins"
            progressionMonitor = container "Progression Monitor" "RHOAI-specific training job status tracking" "Go (pkg/rhai/progression)"
            networkPolicyMgr = container "NetworkPolicy Manager" "RHOAI-specific per-TrainJob network isolation" "Go (pkg/rhai/networkpolicy)"
            datasetInitializer = container "Dataset Initializer" "Downloads datasets for training jobs" "Python (HuggingFace Hub, OpenDAL)"
            modelInitializer = container "Model Initializer" "Downloads models for training jobs" "Python (HuggingFace Hub, OpenDAL)"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane" "External"
        jobset = softwareSystem "JobSet Controller" "Manages replicated distributed training jobs via JobSet CRDs" "Internal Platform"
        coscheduling = softwareSystem "Kubernetes Scheduler Plugins (CoScheduling)" "Gang scheduling via scheduler-plugins PodGroups" "Internal Platform"
        volcano = softwareSystem "Volcano Scheduler" "Gang scheduling via Volcano PodGroups" "Internal Platform"
        openshift = softwareSystem "OpenShift APIServer" "Cluster TLS security profile configuration" "External"
        huggingface = softwareSystem "HuggingFace Hub" "ML model and dataset registry" "External"
        opendal = softwareSystem "OpenDAL Storage" "Data retrieval abstraction layer" "External"
        certController = softwareSystem "cert-controller" "Automatic webhook certificate rotation" "External"

        user -> trainer "Creates TrainJob CRs via kubectl" "HTTPS/6443"
        trainer -> k8sAPI "Manages Kubernetes resources" "HTTPS+WSS/6443 TLS 1.2+ ServiceAccount token"
        trainer -> jobset "Creates and reconciles JobSet CRDs" "Kubernetes API"
        trainer -> coscheduling "Creates PodGroup CRDs for gang scheduling" "Kubernetes API"
        trainer -> volcano "Creates PodGroup CRDs for gang scheduling" "Kubernetes API"
        trainer -> openshift "Reads cluster TLS security profile" "Kubernetes API"
        trainer -> huggingface "Downloads models and datasets" "HTTPS/443"
        trainer -> opendal "Retrieves datasets" "HTTPS/443"
        certController -> trainer "Manages webhook TLS certificates" "Kubernetes API"

        controller -> webhook "Registers admission handlers"
        controller -> runtimePlugins "Delegates job creation"
        controller -> schedulingPlugins "Delegates gang scheduling"
        controller -> progressionMonitor "Tracks training status"
        controller -> networkPolicyMgr "Creates network isolation"
        runtimePlugins -> k8sAPI "Creates ConfigMaps, Secrets for frameworks"
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
            element "Person" {
                background #4a90e2
                color #ffffff
                shape person
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
