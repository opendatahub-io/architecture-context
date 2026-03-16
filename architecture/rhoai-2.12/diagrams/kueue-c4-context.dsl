workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Submits batch workloads and ML training jobs to Kubernetes cluster"
        admin = person "Cluster Administrator" "Configures resource quotas, queues, and priorities"

        kueue = softwareSystem "Kueue" "Job queueing and resource management system for Kubernetes batch workloads" {
            controller = container "kueue-controller-manager" "Manages workload admission, queueing, and resource allocation" "Go Operator" {
                admissionController = component "Admission Controller" "Evaluates workloads against ClusterQueue quotas and priorities"
                webhookServer = component "Webhook Server" "Intercepts job creation and creates Workload CRDs"
                visibilityServer = component "Visibility Server" "Provides REST API for queue visibility"
                metricsExporter = component "Metrics Exporter" "Exposes Prometheus metrics"
            }
        }

        k8s = softwareSystem "Kubernetes API Server" "Container orchestration control plane" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management" "External"
        prometheus = softwareSystem "Prometheus" "Monitoring and alerting platform" "External"
        autoscaler = softwareSystem "Cluster Autoscaler" "Automatic node provisioning based on workload demand" "External"

        kubeflowTraining = softwareSystem "Kubeflow Training Operator" "Distributed ML training job orchestration (TFJob, PyTorchJob, etc.)" "Internal ODH/RHOAI"
        rayOperator = softwareSystem "Ray Operator" "Ray distributed computing framework" "Internal ODH/RHOAI"

        # User interactions
        user -> kueue "Submits Jobs, TFJobs, PyTorchJobs, RayJobs via kubectl/API"
        admin -> kueue "Configures ClusterQueues, ResourceFlavors, WorkloadPriorityClasses"
        user -> kueue "Queries pending workload status via Visibility API"

        # Kueue to external systems
        kueue -> k8s "Watches and manages Jobs, Pods, Workload CRDs" "HTTPS/6443 (ServiceAccount token)"
        kueue -> certManager "Requests TLS certificates for webhooks" "Kubernetes API"
        kueue -> autoscaler "Creates ProvisioningRequests for node scaling" "HTTPS/6443 (autoscaling.x-k8s.io API)"
        prometheus -> kueue "Scrapes queue metrics and resource usage" "HTTP/8080 or HTTPS/8443"

        # Integration with ODH/RHOAI components
        k8s -> kueue "Calls admission webhooks on job creation" "HTTPS/9443 (mTLS)"
        kubeflowTraining -> kueue "TFJob, PyTorchJob intercepted by mutating webhook" "via K8s API Server"
        rayOperator -> kueue "RayJob, RayCluster intercepted by mutating webhook" "via K8s API Server"

        # Component relationships
        webhookServer -> admissionController "Creates Workload CRDs from intercepted jobs"
        admissionController -> visibilityServer "Provides queue position data"
        admissionController -> metricsExporter "Exposes queue metrics"
    }

    views {
        systemContext kueue "KueueSystemContext" {
            include *
            autoLayout
        }

        container kueue "KueueContainers" {
            include *
            autoLayout
        }

        component controller "KueueControllerComponents" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH/RHOAI" {
                background #7ed321
                color #000000
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }

        theme default
    }
}
