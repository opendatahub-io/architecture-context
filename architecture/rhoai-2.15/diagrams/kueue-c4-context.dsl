workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Submits training jobs and batch workloads"
        admin = person "Cluster Administrator" "Manages queues, quotas, and resource policies"

        kueue = softwareSystem "Kueue" "Job queueing and admission control system for Kubernetes workloads" {
            controller = container "Controller Manager" "Manages workload lifecycle, queue state, and admission decisions" "Go Operator" {
                scheduler = component "Scheduler" "Decides which workloads to admit based on quota and policies" "In-Process Service"
                cache = component "Cache" "Maintains cluster queue state and resource usage" "In-Memory Store"
                queueMgr = component "Queue Manager" "Manages workload queues and ordering (FIFO strategies)" "In-Process Service"
                admissionCheck = component "Admission Check Controllers" "Pre-admission validation (provisioning, multikueue)" "Controllers"
            }
            webhook = container "Webhook Server" "Validates and mutates job resources on admission" "Go HTTP Server"
            visibility = container "Visibility Server" "On-demand API for querying pending workloads" "Go HTTP/gRPC Server"
        }

        k8s = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management" "External"

        kubeflowTraining = softwareSystem "KubeFlow Training Operator" "Manages ML training jobs (PyTorch, TensorFlow, MPI)" "Internal ODH"
        rayOperator = softwareSystem "Ray Operator" "Manages Ray workloads" "Internal ODH"
        jobsetOperator = softwareSystem "JobSet Operator" "Manages multi-pod batch jobs" "Internal ODH"
        autoscaler = softwareSystem "Cluster Autoscaler" "Dynamic node provisioning" "External"
        remoteCluster = softwareSystem "Remote Kubernetes Clusters" "Multi-cluster workload distribution targets" "External"

        %% User interactions
        user -> kueue "Creates jobs via kubectl/API" "HTTPS/6443 (Kubernetes API)"
        admin -> kueue "Configures queues, quotas, and policies via CRDs" "HTTPS/6443 (Kubernetes API)"
        user -> kueue "Queries pending workload status" "HTTPS/8082 (Visibility API)"

        %% Kueue dependencies
        kueue -> k8s "Watches and manages CRDs, Jobs, Pods" "HTTPS/6443 (ServiceAccount Token)"
        k8s -> webhook "Calls admission webhooks for job validation/mutation" "HTTPS/9443 (mTLS)"
        k8s -> visibility "Proxies visibility API requests" "HTTPS/8082 (RBAC)"

        kueue -> kubeflowTraining "Queues and manages ML training jobs" "CRD Watch + Webhook"
        kueue -> rayOperator "Queues and manages Ray workloads" "CRD Watch + Webhook"
        kueue -> jobsetOperator "Queues and manages JobSet workloads" "CRD Watch + Webhook"

        kueue -> autoscaler "Creates ProvisioningRequests for capacity" "ProvisioningRequest API"
        kueue -> remoteCluster "Distributes workloads across clusters (MultiKueue)" "HTTPS/6443 (Kubeconfig)"

        %% Monitoring
        prometheus -> kueue "Scrapes metrics" "HTTP/8080"

        %% Certificate management
        certManager -> webhook "Provisions and rotates TLS certificates" "Certificate API"

        %% Internal relationships
        controller -> scheduler "Triggers admission decisions" "In-Process"
        scheduler -> cache "Queries cluster queue state" "In-Process"
        controller -> queueMgr "Manages workload queues" "In-Process"
        controller -> admissionCheck "Executes pre-admission checks" "In-Process"
        visibility -> queueMgr "Queries pending workloads" "In-Process"
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
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Software System" {
                background #4a90e2
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
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }

        theme default
    }
}
