workspace {
    model {
        datascientist = person "Data Scientist" "Submits ML training jobs and manages workloads"
        clusteradmin = person "Cluster Administrator" "Configures cluster-wide resource quotas and queues"

        kueue = softwareSystem "Kueue" "Kubernetes-native job queueing system for resource allocation and admission control" {
            controller = container "Kueue Controller Manager" "Manages job admission, queueing, and resource allocation" "Go Operator" {
                clusterqueueController = component "ClusterQueue Controller" "Manages cluster-level resource quotas" "Go"
                localqueueController = component "LocalQueue Controller" "Maps namespace queues to cluster queues" "Go"
                workloadController = component "Workload Controller" "Coordinates job admission and lifecycle" "Go"
                jobReconcilers = component "Job Framework Reconcilers" "Integrates with Batch, Kubeflow, Ray, JobSet, AppWrapper" "Go"
            }
            webhook = container "Webhook Server" "Validates and mutates job resources" "Go Admission Webhook"
            visibility = container "Visibility API Server" "REST API for querying pending workloads and queue status" "Go API Server"
        }

        kubernetes = softwareSystem "Kubernetes API Server" "Kubernetes control plane" "External"
        certmanager = softwareSystem "cert-manager" "TLS certificate management for webhooks" "External (Optional)"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External (Optional)"

        kubeflow = softwareSystem "Kubeflow Training Operator" "Distributed ML training jobs (MPIJob, PyTorchJob, TFJob, etc.)" "Internal RHOAI"
        codeflare = softwareSystem "CodeFlare AppWrapper" "Workload wrapper for distributed training in RHOAI" "Internal RHOAI"
        ray = softwareSystem "Ray Operator" "Ray jobs and clusters for distributed computing" "Internal RHOAI"
        jobset = softwareSystem "JobSet" "Multi-job workflow coordination" "Internal RHOAI"
        autoscaler = softwareSystem "Cluster Autoscaler" "Dynamic node provisioning based on resource demand" "External"

        %% User interactions
        datascientist -> kueue "Submits jobs to LocalQueue, queries workload status" "kubectl/K8s API"
        clusteradmin -> kueue "Configures ClusterQueues, ResourceFlavors, WorkloadPriorityClasses" "kubectl/K8s API"

        %% Kueue to Kubernetes
        kueue -> kubernetes "Watches and manages CRDs, jobs, pods" "HTTPS/6443, TLS 1.2+, ServiceAccount Token"
        kubernetes -> kueue "Webhook calls for job validation/mutation" "HTTPS/9443, TLS 1.2+, K8s mTLS"

        %% Kueue to cert-manager
        certmanager -> kueue "Provides TLS certificates for webhook and visibility servers" "Cert rotation"

        %% Kueue to Prometheus
        prometheus -> kueue "Scrapes metrics from controller" "HTTP/8080"

        %% Kueue integration with job frameworks
        kueue -> kubeflow "Watches and mutates MPIJob, PyTorchJob, TFJob, XGBoostJob, MXJob, PaddleJob" "HTTPS/6443, TLS 1.2+"
        kueue -> codeflare "Watches AppWrapper workloads (RHOAI-specific)" "HTTPS/6443, TLS 1.2+"
        kueue -> ray "Watches and mutates RayJob, RayCluster" "HTTPS/6443, TLS 1.2+"
        kueue -> jobset "Watches and mutates JobSet resources" "HTTPS/6443, TLS 1.2+"

        %% Kueue to Cluster Autoscaler
        kueue -> autoscaler "Creates ProvisioningRequests for dynamic node provisioning" "HTTPS/6443, TLS 1.2+"
        autoscaler -> kubernetes "Provisions nodes based on ProvisioningRequest" "HTTPS/6443, TLS 1.2+"

        %% Container relationships
        controller -> kubernetes "Watches CRDs and jobs" "gRPC/6443"
        webhook -> kubernetes "Validates/mutates resources" "HTTPS/9443"
        visibility -> kubernetes "Queries queue and workload status" "HTTPS/8082"

        clusterqueueController -> kubernetes "Manages ClusterQueue status" "HTTPS/6443"
        localqueueController -> kubernetes "Manages LocalQueue status" "HTTPS/6443"
        workloadController -> kubernetes "Manages Workload admission and status" "HTTPS/6443"
        jobReconcilers -> kubernetes "Watches and updates job resources" "HTTPS/6443"
    }

    views {
        systemContext kueue "SystemContext" {
            include *
            autoLayout lr
        }

        container kueue "Containers" {
            include *
            autoLayout lr
        }

        component controller "Components" {
            include *
            autoLayout tb
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
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}
