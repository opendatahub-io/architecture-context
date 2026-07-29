workspace {
    model {
        admin = person "Platform Admin" "Configures quotas, queues, and resource flavors"
        datascientist = person "Data Scientist" "Submits batch ML workloads (Jobs, PyTorchJobs, RayJobs)"

        kueue = softwareSystem "Kueue" "Kubernetes-native job queueing system for quota management and fair sharing of batch workloads" {
            controllerManager = container "kueue-controller-manager" "Reconciles Workloads against ClusterQueue quotas, manages admission and scheduling" "Go Operator (controller-runtime)"
            webhookServer = container "Webhook Server" "17 mutating + 18 validating admission webhooks enforcing quota semantics at admission time" "Go (9443/TCP TLS)"
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics with RBAC-gated authentication" "Go (8443/TCP HTTPS)"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API server for resource management" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        batchJob = softwareSystem "Kubernetes batch/Job" "Native Kubernetes batch jobs" "Framework"
        jobSet = softwareSystem "JobSet" "Multi-job workload orchestration" "Framework"
        kubeflow = softwareSystem "Kubeflow Training Operator" "ML training jobs (PyTorchJob, TFJob, MPIJob, XGBoostJob, PaddleJob)" "Framework"
        ray = softwareSystem "KubeRay" "Ray distributed computing jobs (RayJob, RayCluster)" "Framework"
        appwrapper = softwareSystem "CodeFlare AppWrapper" "Grouped workload scheduling" "Framework"
        leaderworkerset = softwareSystem "LeaderWorkerSet" "Leader-worker topology workloads" "Framework"
        certController = softwareSystem "OPA Cert Controller" "Internal TLS certificate management for webhooks" "Internal"

        # Relationships
        admin -> kueue "Creates ClusterQueues, LocalQueues, ResourceFlavors via kubectl"
        datascientist -> kubernetesAPI "Submits workloads (Jobs, PyTorchJobs, RayJobs)" "kubectl / SDK"

        kubernetesAPI -> kueue "Routes admission requests to webhooks" "HTTPS/443 → 9443"
        kueue -> kubernetesAPI "Watches and manages resources across all namespaces" "HTTPS/6443, SA token"

        kueue -> batchJob "Suspends/unsuspends Jobs based on quota" "Kubernetes API"
        kueue -> jobSet "Manages JobSet admission and scheduling" "Kubernetes API"
        kueue -> kubeflow "Manages Kubeflow training job admission" "Kubernetes API"
        kueue -> ray "Manages Ray job/cluster admission" "Kubernetes API"
        kueue -> appwrapper "Manages AppWrapper admission" "Kubernetes API"
        kueue -> leaderworkerset "Manages LeaderWorkerSet admission" "Kubernetes API"

        prometheus -> kueue "Scrapes metrics" "HTTPS/8443, RBAC-gated"
        certController -> kueue "Provisions webhook TLS certificates" "Internal"
    }

    views {
        systemContext kueue "SystemContext" {
            include *
            autoLayout
        }

        container kueue "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Framework" {
                background #7ed321
                color #ffffff
            }
            element "Internal" {
                background #4a90e2
                color #ffffff
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
        }
    }
}
