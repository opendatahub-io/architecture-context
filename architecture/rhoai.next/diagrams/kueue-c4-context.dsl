workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Submits ML training jobs and batch workloads to Kubernetes"
        admin = person "Platform Admin" "Configures quotas, queues, and resource policies"

        kueue = softwareSystem "Kueue" "Kubernetes-native job queueing system managing workload admission based on quota, priority, and fair sharing" {
            controllerManager = container "kueue-controller-manager" "Single binary hosting all controllers, webhooks, scheduler, and visibility API" "Go (controller-runtime)"
            admissionScheduler = container "Admission Scheduler" "Periodic scheduling loop that assigns resource flavors and quotas to pending workloads" "Go"
            webhookServer = container "Webhook Server" "Mutating and validating admission webhooks for all supported job types and CRDs" "Go (9443/TCP HTTPS)"
            quotaCache = container "In-Memory Quota Cache" "Live snapshot of ClusterQueue quotas, flavor assignments, and workload states" "Go"
            multiKueueController = container "MultiKueue Controller" "Distributes workloads across multiple worker clusters" "Go"
            tasController = container "TAS Controller" "Topology-Aware Scheduling for hardware-aware pod placement" "Go"
            provisioningController = container "Provisioning Controller" "Integrates with cluster autoscaler via ProvisioningRequest CRDs" "Go"
        }

        kueuectl = softwareSystem "kueuectl" "kubectl plugin for interacting with Kueue resources" "CLI Tool"

        k8sApi = softwareSystem "Kubernetes API Server" "Cluster API server for all resource operations" "External"
        remoteK8s = softwareSystem "Remote Kubernetes Clusters" "Worker clusters for multi-cluster workload distribution" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management for webhook server" "External"
        clusterAutoscaler = softwareSystem "Cluster Autoscaler" "Provisions nodes based on ProvisioningRequests" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        kubeflowTraining = softwareSystem "Kubeflow Training Operator" "Manages PyTorchJob, TFJob, XGBoostJob, PaddleJob" "Internal Platform"
        kubeflowMPI = softwareSystem "Kubeflow MPI Operator" "Manages MPIJob workloads" "Internal Platform"
        kuberay = softwareSystem "KubeRay Operator" "Manages RayCluster and RayJob workloads" "Internal Platform"
        jobset = softwareSystem "JobSet Controller" "Manages JobSet workloads" "Internal Platform"
        appwrapper = softwareSystem "CodeFlare AppWrapper" "Manages AppWrapper workloads" "Internal Platform"
        leaderworkerset = softwareSystem "LeaderWorkerSet Controller" "Manages LeaderWorkerSet workloads" "Internal Platform"

        # Relationships
        user -> kueue "Submits Jobs, PyTorchJobs, RayJobs via kubectl"
        admin -> kueue "Configures ClusterQueues, LocalQueues, ResourceFlavors"
        user -> kueuectl "Interacts with Kueue resources via CLI"

        kueue -> k8sApi "All CRD CRUD, job management, watches" "HTTPS/6443 TLS 1.2+ ServiceAccount Token"
        k8sApi -> kueue "Admission webhook calls" "HTTPS/9443 TLS API Server client cert"

        kueue -> remoteK8s "MultiKueue: create/sync/delete remote workloads" "HTTPS/6443 TLS 1.2+ kubeconfig"
        certManager -> kueue "Provisions TLS certificates" "Certificate CRD"
        clusterAutoscaler -> k8sApi "Watches ProvisioningRequests, provisions nodes" "HTTPS/6443"
        kueue -> k8sApi "Creates ProvisioningRequest CRDs" "HTTPS/6443"
        prometheus -> kueue "Scrapes /metrics endpoint" "HTTPS/8443 Bearer Token"

        kueue -> kubeflowTraining "Watches and manages PyTorchJob/TFJob/XGBoostJob/PaddleJob CRDs" "via K8s API"
        kueue -> kubeflowMPI "Watches and manages MPIJob CRDs" "via K8s API"
        kueue -> kuberay "Watches and manages RayCluster/RayJob CRDs" "via K8s API"
        kueue -> jobset "Watches and manages JobSet CRDs" "via K8s API"
        kueue -> appwrapper "Watches and manages AppWrapper CRDs" "via K8s API"
        kueue -> leaderworkerset "Watches and manages LeaderWorkerSet CRDs" "via K8s API"
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
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
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
