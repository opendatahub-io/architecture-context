workspace {
    model {
        user = person "Data Scientist" "Submits ML training jobs and workloads to Kubernetes"

        kueue = softwareSystem "Kueue" "Kubernetes-native job queueing system managing workload admission based on quota, priority, and fair sharing" {
            controllerManager = container "kueue-controller-manager" "Single binary hosting all controllers, scheduler, webhooks, and visibility API" "Go (controller-runtime)"
            webhookServer = container "Webhook Server" "Mutating and validating admission webhooks for all supported job types and CRDs" "HTTPS/9443"
            admissionScheduler = container "Admission Scheduler" "Periodic scheduling loop that assigns ResourceFlavors and quotas to pending workloads" "Go"
            inMemoryCache = container "In-Memory Cache" "Live snapshot of ClusterQueue quotas, flavor assignments, and workload states" "Go"
            multiKueueController = container "MultiKueue Controller" "Federated scheduling - distributes workloads to remote worker clusters" "Go"
            provisioningController = container "Provisioning Controller" "Creates ProvisioningRequests for cluster autoscaler integration" "Go"
            tasController = container "TAS Controller" "Topology-Aware Scheduling with topology ungater for hardware-aware pod placement" "Go"
            visibilityAPI = container "Visibility API" "Aggregated API for querying pending workload status" "Go"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform and API server" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate lifecycle management" "External"
        clusterAutoscaler = softwareSystem "Cluster Autoscaler" "Automatic node provisioning based on ProvisioningRequests" "External"
        remoteK8sClusters = softwareSystem "Remote Kubernetes Clusters" "Worker clusters for MultiKueue workload distribution" "External"

        kubeflowTraining = softwareSystem "Kubeflow Training Operator" "Manages PyTorchJob, TFJob, XGBoostJob, PaddleJob workloads" "Internal RHOAI"
        kubeflowMPI = softwareSystem "Kubeflow MPI Operator" "Manages MPIJob workloads" "Internal RHOAI"
        kuberay = softwareSystem "KubeRay Operator" "Manages RayCluster and RayJob workloads" "Internal RHOAI"
        jobsetController = softwareSystem "JobSet Controller" "Manages JobSet workloads" "Internal RHOAI"
        codeflare = softwareSystem "CodeFlare AppWrapper" "Manages AppWrapper workloads" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting" "Monitoring"

        # User interactions
        user -> kueue "Submits jobs via kubectl" "HTTPS/6443"
        user -> kubernetes "Creates Job, PyTorchJob, RayJob CRs" "HTTPS/6443"

        # Kueue internal flows
        controllerManager -> webhookServer "Hosts"
        controllerManager -> admissionScheduler "Hosts"
        admissionScheduler -> inMemoryCache "Reads quota/flavor state"
        controllerManager -> multiKueueController "Hosts"
        controllerManager -> provisioningController "Hosts"
        controllerManager -> tasController "Hosts"
        controllerManager -> visibilityAPI "Hosts"

        # Kueue to Kubernetes
        kueue -> kubernetes "All controller operations: CRD CRUD, job management, RBAC" "HTTPS/6443"
        kubernetes -> kueue "Admission webhook calls" "HTTPS/9443"

        # Kueue to external systems
        kueue -> certManager "TLS certificate provisioning and rotation" "HTTPS/6443"
        kueue -> clusterAutoscaler "ProvisioningRequest for node provisioning" "CRD via API"
        kueue -> remoteK8sClusters "MultiKueue workload distribution" "HTTPS/6443"

        # Kueue integration with job frameworks
        kueue -> kubeflowTraining "Watches and manages PyTorchJob, TFJob, etc." "CRD Watch + Webhook"
        kueue -> kubeflowMPI "Watches and manages MPIJob" "CRD Watch + Webhook"
        kueue -> kuberay "Watches and manages RayCluster, RayJob" "CRD Watch + Webhook"
        kueue -> jobsetController "Watches and manages JobSet" "CRD Watch + Webhook"
        kueue -> codeflare "Watches and manages AppWrapper" "CRD Watch + Webhook"

        # Monitoring
        prometheus -> kueue "Scrapes metrics" "HTTPS/8443"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Monitoring" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
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
