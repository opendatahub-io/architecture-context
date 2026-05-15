workspace {
    model {
        user = person "Data Scientist" "Creates and manages distributed ML training jobs via TrainJob CRs or Python SDK"

        trainer = softwareSystem "Kubeflow Trainer" "Kubernetes operator that manages distributed ML training jobs by translating TrainJob specifications into JobSets with framework-specific configuration" {
            controller = container "trainer-controller-manager" "Reconciles TrainJob, TrainingRuntime, and ClusterTrainingRuntime CRDs; creates JobSets and supporting resources via plugin framework" "Go Operator (controller-runtime)"
            webhookServer = container "Webhook Server" "Validates TrainJob, TrainingRuntime, and ClusterTrainingRuntime resources on create/update" "Go (9443/TCP HTTPS)"
            pluginFramework = container "Plugin Framework" "Extensible plugin system with JobSet, Torch, MPI, PlainML, CoScheduling, and Volcano plugins" "Go"
            rhaiFeatures = container "RHOAI Features" "Progression tracking (polls training pod metrics) and NetworkPolicy creation for pod isolation" "Go"
            dataCacheHead = container "Data Cache Head" "Coordinates distributed data caching; reads Iceberg metadata, partitions data across workers via Arrow Flight gRPC" "Rust"
            dataCacheWorker = container "Data Cache Worker" "Loads and serves data partitions via Arrow Flight gRPC; maintains in-memory Arrow tables" "Rust"
            pythonSDK = container "Python SDK" "Client library for creating and managing TrainJobs programmatically" "Python"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "External"
        jobset = softwareSystem "JobSet Controller" "Reconciles JobSet resources into Jobs and Pods" "External (kubernetes-sigs/jobset v0.10.1)"
        knativeSchedulerPlugins = softwareSystem "Kubernetes Scheduler Plugins" "Gang scheduling via PodGroup (CoScheduling)" "External (Optional)"
        volcano = softwareSystem "Volcano Scheduler" "Gang scheduling via PodGroup (Volcano)" "External (Optional)"
        leaderWorkerSet = softwareSystem "LeaderWorkerSet Controller" "Head/worker topology for data-cache runtimes" "External (Optional)"
        certController = softwareSystem "cert-controller (OPA)" "Webhook certificate rotation" "External"
        kueue = softwareSystem "Kueue (MultiKueue)" "Job queueing and multi-cluster dispatch" "External (Optional)"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection and alerting" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "Platform operator that deploys Trainer via kustomize manifests" "Internal RHOAI"
        imageStreams = softwareSystem "OpenShift ImageStreams" "Pre-built training images for ClusterTrainingRuntimes" "Internal RHOAI"
        containerRegistries = softwareSystem "Container Registries" "quay.io, ghcr.io for training and operator images" "External"
        icebergStorage = softwareSystem "Iceberg Storage" "Iceberg table metadata and data files (S3/GCS/HDFS)" "External (Optional)"

        # User interactions
        user -> trainer "Creates TrainJob CR via kubectl or Python SDK"
        user -> pythonSDK "Uses Python SDK to create/manage TrainJobs"

        # Internal interactions
        controller -> webhookServer "Validates resources"
        controller -> pluginFramework "Delegates object creation to plugins"
        controller -> rhaiFeatures "Progression tracking + NetworkPolicy (RHOAI)"
        dataCacheHead -> dataCacheWorker "Distributes data partitions via Arrow Flight gRPC"

        # External interactions
        controller -> k8sAPI "CRD reconciliation, resource creation (HTTPS/443, SA token)" "HTTPS/443"
        k8sAPI -> webhookServer "Admission review requests (HTTPS/9443, client cert)" "HTTPS/9443"
        controller -> jobset "Creates JobSet CRs that JobSet controller reconciles" "K8s API"
        controller -> knativeSchedulerPlugins "Creates PodGroup for CoScheduling gang scheduling" "K8s API"
        controller -> volcano "Creates PodGroup for Volcano gang scheduling" "K8s API"
        controller -> leaderWorkerSet "Creates LeaderWorkerSet for data-cache topology" "K8s API"
        certController -> controller "Rotates webhook TLS certificates"
        kueue -> trainer "Manages TrainJob via managedBy field" "K8s API"
        prometheus -> controller "Scrapes metrics (HTTPS/8443, self-signed TLS)" "HTTPS/8443"
        rhodsOperator -> trainer "Deploys Trainer manifests via kustomize" "Kustomize"
        imageStreams -> trainer "Provides pre-built training images for runtimes"
        rhaiFeatures -> k8sAPI "Polls training pod metrics (HTTP/28080)" "HTTP/28080"
        dataCacheHead -> icebergStorage "Reads Iceberg table metadata"
        containerRegistries -> k8sAPI "Kubelet pulls training images (HTTPS/443)" "HTTPS/443"
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
            element "External (Optional)" {
                background #bbbbbb
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #4a90e2
                color #ffffff
                shape Person
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
