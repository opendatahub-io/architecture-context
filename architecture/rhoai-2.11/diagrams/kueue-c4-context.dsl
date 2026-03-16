workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Submits batch workloads for training, inference, or data processing"
        pipeline = person "CI/CD Pipeline" "Automates job submission for ML workflows"

        kueue = softwareSystem "Kueue" "Job queueing and resource management system for Kubernetes batch workloads" {
            controller = container "Kueue Controller Manager" "Manages workload admission, queueing, and resource allocation" "Go Operator" {
                admissionCheckCtrl = component "AdmissionCheck Controller" "Validates admission checks for workloads"
                clusterQueueCtrl = component "ClusterQueue Controller" "Manages cluster-wide resource quotas"
                localQueueCtrl = component "LocalQueue Controller" "Manages namespace-scoped queues"
                workloadCtrl = component "Workload Controller" "Reconciles workload admission state"
                resourceFlavorCtrl = component "ResourceFlavor Controller" "Manages resource flavor definitions"
            }
            webhook = container "Webhook Server" "Validates and mutates workload resources" "Go Service (port 9443)"
            visibilityAPI = container "Visibility Server" "Provides extended APIs for pending workload visibility" "Go Service (port 8082)"
            metricsExporter = container "Metrics Exporter" "Exposes Prometheus metrics for monitoring" "Prometheus Exporter (ports 8080/8443)"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Kubernetes control plane API" "External"
        certController = softwareSystem "cert-controller" "Certificate management for webhook TLS" "External (v0.10.1)"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        trainingOperator = softwareSystem "Kubeflow Training Operator" "Manages distributed ML training jobs (TFJob, PyTorchJob, MPIJob)" "Internal RHOAI"
        rayOperator = softwareSystem "Ray Operator" "Manages Ray clusters and jobs for distributed computing" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Serverless ML inference platform" "Internal RHOAI"
        clusterAutoscaler = softwareSystem "Cluster Autoscaler" "Auto-scales Kubernetes cluster nodes based on demand" "External"
        cloudProvider = softwareSystem "Cloud Provider API" "Cloud infrastructure management (AWS/GCP/Azure)" "External"

        # User interactions
        user -> kueue "Creates and submits batch jobs (Job, JobSet, TFJob, PyTorchJob, RayJob) via kubectl/API"
        pipeline -> kueue "Automates job submission and lifecycle management"

        # Kueue internal interactions
        controller -> webhook "Configures webhook endpoints"
        controller -> visibilityAPI "Provides workload state data"
        controller -> metricsExporter "Emits metrics"

        # Kueue to Kubernetes API
        kueue -> k8sAPI "Watches and reconciles CRDs, Jobs, Pods, ConfigMaps" "HTTPS/443, TLS 1.2+, ServiceAccount token"
        webhook -> k8sAPI "Called by API Server for validation/mutation" "HTTPS/9443, mTLS"

        # Kueue to training frameworks
        kueue -> trainingOperator "Queues and manages training jobs (TFJob, PyTorchJob, MPIJob)" "Watch CRDs via API Server"
        kueue -> rayOperator "Queues and manages Ray workloads (RayJob, RayCluster)" "Watch CRDs via API Server"
        kueue -> kserve "Queues inference serving workloads (optional)" "Watch Pods via API Server"

        # Kueue to infrastructure
        kueue -> clusterAutoscaler "Triggers node provisioning via ProvisioningRequest API" "HTTPS/443, TLS 1.2+"
        clusterAutoscaler -> cloudProvider "Provisions EC2/GCE/VMSS instances" "HTTPS/443, Cloud credentials"

        # Monitoring
        prometheus -> kueue "Scrapes queue metrics (depths, admission rates)" "HTTP/8080 or HTTPS/8443"

        # Certificate management
        certController -> webhook "Provisions and rotates TLS certificates for webhook server"

        # User interactions with training frameworks (indirectly queued by Kueue)
        user -> trainingOperator "Creates training jobs (TFJob, PyTorchJob)" "Queued by Kueue"
        user -> rayOperator "Creates Ray clusters and jobs" "Queued by Kueue"
    }

    views {
        systemContext kueue "KueueSystemContext" {
            include *
            autoLayout lr
        }

        container kueue "KueueContainers" {
            include *
            autoLayout lr
        }

        component controller "KueueControllerComponents" {
            include *
            autoLayout lr
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #1168bd
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                background #08427b
                shape person
                color #ffffff
            }
        }

        theme default
    }
}
