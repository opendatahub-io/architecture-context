workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Submits training jobs and inference workloads to Kubernetes"
        admin = person "Cluster Admin" "Configures resource quotas, queues, and scheduling policies"

        kueue = softwareSystem "Kueue" "Kubernetes-native job queueing system managing admission, scheduling, preemption, and quota enforcement" {
            controllerManager = container "Kueue Controller Manager" "controller-runtime based operator with core controllers, scheduler, webhook server, and job framework plugins" "Go Operator"
            webhookServer = container "Webhook Server" "Validates and mutates job and queue CRDs on creation/update" "Go (port 9443/TCP TLS)"
            scheduler = container "Scheduler" "Continuous scheduling loop evaluating pending workloads against quotas, flavors, priorities, and preemption" "Go (in-process Runnable)"
            jobFramework = container "Job Framework" "Plugin architecture integrating batch/v1 Jobs, JobSets, Kubeflow jobs, Ray jobs, AppWrappers, Pods" "Go Plugins"
            multiKueue = container "MultiKueue Subsystem" "Multi-cluster workload federation with remote cluster client management" "Go (feature-gated, disabled in RHOAI)"
            provisioningCtrl = container "Provisioning Controller" "Creates ProvisioningRequest CRs for cluster autoscaler integration" "Go Controller"
            tasCtrl = container "TAS Controllers" "Topology-Aware Scheduling for pod placement within topology domains" "Go Controllers"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Central API for cluster resource management" "External"
        trainingOperator = softwareSystem "Training Operator (Kubeflow)" "Manages PyTorchJob, TFJob, MPIJob, PaddleJob, XGBoostJob CRDs" "Internal RHOAI"
        rayOperator = softwareSystem "KubeRay Operator" "Manages RayJob and RayCluster CRDs" "Internal RHOAI"
        jobsetController = softwareSystem "JobSet Controller" "Manages JobSet CRDs for multi-job coordination" "Internal RHOAI"
        codeflare = softwareSystem "CodeFlare Operator" "Manages AppWrapper CRDs for batch workload grouping" "Internal RHOAI"
        certManager = softwareSystem "cert-manager" "External certificate management (optional alternative to internal certs)" "External"
        clusterAutoscaler = softwareSystem "Cluster Autoscaler" "Reads ProvisioningRequests and provisions nodes via cloud APIs" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting" "Internal RHOAI"
        rhoaiOperator = softwareSystem "RHOAI Operator" "Platform operator that deploys Kueue via kustomize manifests" "Internal RHOAI"
        remoteCluster = softwareSystem "Remote Worker Cluster" "Target cluster for MultiKueue workload federation" "External"

        # User interactions
        user -> kueue "Submits jobs (kubectl create)" "HTTPS/6443"
        admin -> kueue "Configures ClusterQueues, LocalQueues, ResourceFlavors" "HTTPS/6443"

        # Kueue → Kubernetes
        kueue -> k8sAPI "All controller reconciliation, CRD CRUD, webhook registration, watch resources" "HTTPS/6443 TLS 1.2+ SA token"

        # Platform deploys Kueue
        rhoaiOperator -> kueue "Deploys via kustomize manifests" "Kustomize"

        # Job framework integrations
        kueue -> trainingOperator "Watches/manages Kubeflow training job CRDs" "HTTPS/6443"
        kueue -> rayOperator "Watches/manages RayJob and RayCluster CRDs" "HTTPS/6443"
        kueue -> jobsetController "Watches/manages JobSet CRDs" "HTTPS/6443"
        kueue -> codeflare "Watches/manages AppWrapper CRDs" "HTTPS/6443"

        # External integrations
        kueue -> certManager "TLS certificate management (optional)" "HTTPS"
        kueue -> clusterAutoscaler "Creates ProvisioningRequest CRs" "HTTPS/6443"
        kueue -> remoteCluster "MultiKueue workload federation (disabled in RHOAI)" "HTTPS/6443 TLS 1.2+"

        # Monitoring
        prometheus -> kueue "Scrapes metrics" "HTTPS/8443 Bearer Token"
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
                background #08427b
                color #ffffff
            }
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
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
