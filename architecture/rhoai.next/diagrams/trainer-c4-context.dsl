workspace {
    model {
        user = person "Data Scientist" "Creates and manages distributed ML training jobs via TrainJob CRs"

        trainer = softwareSystem "Kubeflow Trainer" "Kubernetes operator that manages distributed ML training jobs on OpenShift" {
            controllerManager = container "trainer-controller-manager" "Reconciles TrainJob, TrainingRuntime, and ClusterTrainingRuntime CRDs; creates JobSet resources" "Go Operator (controller-runtime)"
            webhookServer = container "Webhook Server" "Validates TrainJob, TrainingRuntime, and ClusterTrainingRuntime resources" "Go HTTPS Service :9443"
            torchPlugin = container "Torch Plugin" "Enforces PyTorch distributed training policies, injects PET env vars, configures torchrun/TorchTune" "Go Plugin"
            mpiPlugin = container "MPI Plugin" "Generates SSH keys (ECDSA P-521), creates hostfile ConfigMaps, configures OpenMPI" "Go Plugin"
            coschedulingPlugin = container "CoScheduling Plugin" "Creates scheduler-plugins PodGroups for gang scheduling" "Go Plugin"
            volcanoPlugin = container "Volcano Plugin" "Creates Volcano PodGroups for gang scheduling with queue support" "Go Plugin"
            jobsetPlugin = container "JobSet Plugin" "Builds and manages JobSet resources, maps TrainJob status" "Go Plugin"
            rhaiProgression = container "RHAI Progression Tracker" "HTTP metrics polling, training progress annotation updates" "Go (RHOAI extension)"
            rhaiNetPolicy = container "RHAI NetworkPolicy Manager" "Creates per-TrainJob NetworkPolicies for pod isolation" "Go (RHOAI extension)"
            datasetInitializer = container "dataset-initializer" "Downloads and pre-processes training datasets from storage URIs" "Python Init Container"
            modelInitializer = container "model-initializer" "Downloads pre-trained models from storage URIs" "Python Init Container"
            dataCache = container "data-cache" "Distributed data caching for training datasets" "Rust Sidecar"
        }

        jobset = softwareSystem "JobSet Controller" "Manages replicated jobs for distributed training topology" "External Dependency"
        schedulerPlugins = softwareSystem "scheduler-plugins (CoScheduling)" "PodGroup CRD for gang scheduling" "Optional External"
        volcano = softwareSystem "Volcano Scheduler" "PodGroup CRD for gang scheduling with queue and network topology" "Optional External"
        certController = softwareSystem "cert-controller" "Self-signed certificate management for webhook server" "External Dependency"
        openshiftAPI = softwareSystem "OpenShift APIServer" "Provides cluster TLS security profile configuration" "Platform"
        k8sAPI = softwareSystem "Kubernetes API Server" "Kubernetes control plane" "Platform"
        rhodsOperator = softwareSystem "rhods-operator / opendatahub-operator" "Platform operator that deploys trainer manifests" "Internal Platform"
        prometheus = softwareSystem "Prometheus" "Collects controller metrics via PodMonitor" "Monitoring"
        objectStorage = softwareSystem "Object Storage (S3/GCS)" "Model artifact and dataset storage" "External Service"

        # User interactions
        user -> trainer "Creates TrainJob CRs via kubectl/API"
        user -> k8sAPI "Authenticates via kubeconfig"

        # Trainer → External dependencies
        trainer -> jobset "Creates JobSet resources for distributed training topology" "Kubernetes API / TLS 1.2+"
        trainer -> schedulerPlugins "Creates PodGroups for gang scheduling" "Kubernetes API / TLS 1.2+"
        trainer -> volcano "Creates PodGroups for gang scheduling" "Kubernetes API / TLS 1.2+"
        trainer -> certController "Manages webhook TLS certificates" "In-process"
        trainer -> openshiftAPI "Reads cluster TLS security profile" "HTTPS/443 / SA token"
        trainer -> k8sAPI "CRD reconciliation, resource CRUD" "HTTPS/443 / SA token"
        trainer -> objectStorage "Downloads datasets and models" "HTTPS / Secret credentials"

        # Inbound
        rhodsOperator -> trainer "Deploys trainer manifests via kustomize"
        prometheus -> trainer "Scrapes metrics" "HTTPS/8443 / TLS"
        k8sAPI -> trainer "Webhook validation calls" "HTTPS/9443 / Client cert"

        # Internal container relationships
        controllerManager -> webhookServer "Serves validating webhooks"
        controllerManager -> torchPlugin "Delegates PyTorch ML policy"
        controllerManager -> mpiPlugin "Delegates MPI ML policy"
        controllerManager -> coschedulingPlugin "Delegates CoScheduling gang policy"
        controllerManager -> volcanoPlugin "Delegates Volcano gang policy"
        controllerManager -> jobsetPlugin "Builds JobSet apply configurations"
        controllerManager -> rhaiProgression "Polls training pod metrics (RHOAI)"
        controllerManager -> rhaiNetPolicy "Manages per-TrainJob NetworkPolicies (RHOAI)"
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
            element "External Dependency" {
                background #999999
                color #ffffff
            }
            element "Optional External" {
                background #bbbbbb
                color #ffffff
            }
            element "Platform" {
                background #6c8ebf
                color #ffffff
            }
            element "Internal Platform" {
                background #82b366
                color #ffffff
            }
            element "Monitoring" {
                background #e6522c
                color #ffffff
            }
            element "External Service" {
                background #d6b656
                color #ffffff
            }
            element "Person" {
                background #08427b
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
