workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and submits ML training jobs and batch workloads"
        admin = person "Platform Administrator" "Configures queues, resource quotas, and priorities"

        kueue = softwareSystem "Kueue" "Kubernetes-native job queueing system that manages workload admission based on resource availability and priorities" {
            manager = container "Kueue Manager" "Reconciles ClusterQueues, LocalQueues, Workloads, and manages admission decisions" "Go Operator" {
                queueManager = component "Queue Manager" "Maintains in-memory queue state and workload ordering" "In-Memory Cache"
                scheduler = component "Scheduler Engine" "Evaluates workload admission based on resources and priorities" "Scheduling Algorithm"
                reconcilers = component "CRD Reconcilers" "Watches and reconciles Kueue CRDs and job resources" "Controller Runtime"
            }
            webhook = container "Webhook Server" "Mutates and validates job submissions and Kueue CRDs" "Admission Webhooks (9443/TCP HTTPS)"
            visibility = container "Visibility API Server" "Provides REST API for querying pending workloads" "API Extension (8082/TCP HTTPS)"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        kubeflowTraining = softwareSystem "Kubeflow Training Operator" "Manages distributed ML training jobs (TensorFlow, PyTorch, MPI)" "Internal RHOAI"
        rayOperator = softwareSystem "Ray Operator" "Manages Ray jobs and clusters for distributed computing" "Internal RHOAI"
        codeflare = softwareSystem "CodeFlare Operator" "Manages AppWrapper workloads for batch processing" "Internal RHOAI"
        certManager = softwareSystem "cert-manager" "Automated TLS certificate provisioning" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        clusterAutoscaler = softwareSystem "Cluster Autoscaler" "Dynamic cluster node provisioning" "External"
        remoteClusters = softwareSystem "Remote Kubernetes Clusters" "Additional clusters for multi-cluster workload distribution" "External"

        # User interactions
        user -> kueue "Submits jobs via kubectl/API, queries pending workloads"
        admin -> kueue "Configures ClusterQueues, LocalQueues, ResourceFlavors, AdmissionChecks"

        # Kueue to Kubernetes
        kueue -> kubernetes "Watches and manages jobs, pods, and CRDs via API Server (6443/TCP HTTPS)"

        # Kueue to Job Frameworks
        kueue -> kubeflowTraining "Mutates/validates TFJobs, PyTorchJobs, MPIJobs via webhooks (9443/TCP HTTPS)"
        kueue -> rayOperator "Mutates/validates RayJobs, RayClusters via webhooks (9443/TCP HTTPS)"
        kueue -> codeflare "Watches AppWrapper CRDs for queue management"

        # Kueue to external services
        kueue -> certManager "Obtains TLS certificates for webhook server (optional)"
        prometheus -> kueue "Scrapes workload queue metrics (8080/TCP HTTP)"
        kueue -> clusterAutoscaler "Creates ProvisioningRequests for guaranteed node provisioning (443/TCP HTTPS)"
        kueue -> remoteClusters "Distributes workloads to remote clusters via MultiKueue (6443/TCP HTTPS)"

        # Internal container relationships
        manager -> queueManager "Uses for queue state management"
        manager -> scheduler "Uses for admission decisions"
        manager -> reconcilers "Orchestrates CRD reconciliation"
        user -> visibility "Queries pending workloads via aggregated API"
        visibility -> queueManager "Reads queue state"
    }

    views {
        systemContext kueue "SystemContext" {
            include *
            autoLayout
            title "Kueue System Context - Job Queueing for Kubernetes Workloads"
            description "Shows how Kueue fits into the RHOAI/ODH platform for managing job admission and resource quotas"
        }

        container kueue "Containers" {
            include *
            autoLayout
            title "Kueue Container Diagram"
            description "Internal components of the Kueue job queueing system"
        }

        component manager "Components" {
            include *
            autoLayout
            title "Kueue Manager Components"
            description "Internal components of the Kueue Manager controller"
        }

        styles {
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }

        theme default
    }
}
