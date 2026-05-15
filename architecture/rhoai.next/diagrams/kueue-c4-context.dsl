workspace {
    model {
        datascientist = person "Data Scientist" "Submits ML training jobs and inference workloads to Kubernetes clusters"
        admin = person "Platform Admin" "Configures queues, quotas, resource flavors, and admission policies"

        kueue = softwareSystem "Kueue" "Kubernetes-native job queueing system managing admission based on quota, priority, and fair sharing" {
            controller = container "Kueue Controller Manager" "Manages job queueing, quota allocation, admission control, and workload lifecycle" "Go Operator (controller-runtime)"
            scheduler = container "Scheduler" "Makes admission decisions based on cached queue state, quotas, priorities, and fair sharing" "Go (in-process goroutine)"
            webhookServer = container "Webhook Server" "Validates and mutates 10+ job framework resources (36 webhooks)" "Go (9443/TCP TLS)"
            cache = container "In-Memory Cache" "Maintains synchronized state of queue utilization and cohort borrowing" "Go (in-process)"
            queueManager = container "Queue Manager" "Manages queue ordering and workload prioritization" "Go (in-process)"
            provisioningCtrl = container "Provisioning Controller" "Creates ProvisioningRequest objects for cluster autoscaler integration" "Go (admission check)"
            multiKueueCtrl = container "MultiKueue Controller" "Distributes workloads across remote Kueue clusters" "Go (admission check, disabled in RHOAI)"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Core platform for CRD registration, RBAC, and workload management" "External"
        certManager = softwareSystem "cert-manager" "Optional external certificate management for webhook TLS" "External"
        clusterAutoscaler = softwareSystem "Cluster Autoscaler" "Provisions nodes via ProvisioningRequest CRD integration" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        kubeflowTraining = softwareSystem "Kubeflow Training Operator" "Manages PyTorchJob, TFJob, MPIJob, XGBoostJob, PaddleJob lifecycle" "Internal Platform"
        rayOperator = softwareSystem "Ray Operator" "Manages RayJob and RayCluster lifecycle" "Internal Platform"
        jobsetController = softwareSystem "JobSet Controller" "Manages JobSet lifecycle for multi-job workloads" "Internal Platform"
        codeflareOperator = softwareSystem "CodeFlare Operator" "Manages AppWrapper lifecycle for distributed computing" "Internal Platform"
        leaderWorkerSet = softwareSystem "LeaderWorkerSet Controller" "Manages LeaderWorkerSet lifecycle" "Internal Platform"
        remoteKueue = softwareSystem "Remote Kueue Clusters" "Worker clusters for multi-cluster workload distribution" "External"

        # User interactions
        datascientist -> kueue "Submits jobs with queue-name label via kubectl" "HTTPS/443"
        admin -> kueue "Creates ClusterQueues, LocalQueues, ResourceFlavors" "HTTPS/443"

        # Kueue internal
        controller -> cache "Synchronizes queue state"
        scheduler -> cache "Reads state for admission decisions"
        scheduler -> queueManager "Reads queue ordering"
        controller -> webhookServer "Validates incoming resources"
        controller -> provisioningCtrl "Delegates provisioning checks"
        controller -> multiKueueCtrl "Delegates multi-cluster distribution"

        # External dependencies
        kueue -> k8sAPI "CRD watches, status updates, resource management" "HTTPS/443 TLS 1.2+"
        kueue -> certManager "Optional TLS certificate management" "Kubernetes API"
        provisioningCtrl -> clusterAutoscaler "Creates ProvisioningRequest CRs" "HTTPS/443 via K8s API"
        multiKueueCtrl -> remoteKueue "Distributes workloads (when enabled)" "HTTPS/443 TLS 1.2+"
        prometheus -> kueue "Scrapes controller metrics" "HTTPS/8443 TLS"

        # Internal platform integrations (webhook + CRD watch)
        kueue -> kubeflowTraining "Manages job admission lifecycle" "CRD Watch + Webhook"
        kueue -> rayOperator "Manages RayJob/RayCluster admission" "CRD Watch + Webhook"
        kueue -> jobsetController "Manages JobSet admission" "CRD Watch + Webhook"
        kueue -> codeflareOperator "Manages AppWrapper admission" "CRD Watch + Webhook"
        kueue -> leaderWorkerSet "Watches LeaderWorkerSet for admission" "CRD Watch"
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
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
            }
            element "Software System" {
                background #1168BD
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}
