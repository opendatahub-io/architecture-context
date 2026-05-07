workspace {
    model {
        # People
        dataScientist = person "Data Scientist" "Submits ML training jobs and inference workloads"
        platformAdmin = person "Platform Admin" "Configures queues, quotas, and resource flavors"
        sre = person "SRE / Ops" "Monitors queue health and workload admission"

        # Main system
        kueue = softwareSystem "Kueue" "Kubernetes-native job queueing system managing workload admission based on quota, priority, and fair sharing policies" {
            controllerManager = container "kueue-controller-manager" "Main controller managing queues, workloads, admission, scheduling, and job framework integrations" "Go Operator (controller-runtime)"
            webhookServer = container "Webhook Server" "Mutating (15) and validating (18) admission webhooks for Kueue CRDs and job types" "HTTPS 9443/TCP"
            scheduler = container "Scheduler" "Evaluates pending workloads against ClusterQueue quotas, flavors, and fair sharing policies" "In-process goroutine"
            cache = container "In-Memory Cache" "Maintains snapshot of ClusterQueue quotas, ResourceFlavors, and admitted workloads" "pkg/cache"
            queueManager = container "Queue Manager" "Manages pending workload queues ordered by priority" "pkg/queue"
            certManager = container "Internal Cert Management" "Self-signed certificate generation and rotation for webhook and metrics TLS" "pkg/util/cert"

            # Internal relationships
            controllerManager -> cache "Updates quota snapshots"
            controllerManager -> queueManager "Enqueues workloads"
            scheduler -> cache "Queries available quota"
            scheduler -> queueManager "Pulls pending workloads"
            scheduler -> controllerManager "Admits/preempts workloads"
            controllerManager -> webhookServer "Serves webhook endpoints"
            certManager -> webhookServer "Provides TLS certificates"
        }

        # External systems - Kubernetes
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API server for CRD operations, leader election, and webhook dispatch" "External"

        # External systems - Job frameworks
        batchJobs = softwareSystem "Kubernetes batch/Job" "Native Kubernetes Job workloads" "Job Framework"
        kubeflowTraining = softwareSystem "Kubeflow Training Operator" "PyTorchJob, TFJob, MPIJob, PaddleJob, XGBoostJob training workloads" "Job Framework"
        kuberay = softwareSystem "KubeRay" "RayJob and RayCluster workloads" "Job Framework"
        jobset = softwareSystem "JobSet" "Multi-job workload sets" "Job Framework"
        codeflare = softwareSystem "CodeFlare AppWrapper" "CodeFlare distributed workloads" "Job Framework"
        leaderworkerset = softwareSystem "LeaderWorkerSet" "Leader-worker distributed workloads" "Job Framework"

        # External systems - Platform
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting (RHOAI PrometheusRule with 4 alerts)" "External"
        certManagerExt = softwareSystem "cert-manager" "Optional external certificate management (alternative to internal)" "External"
        clusterAutoscaler = softwareSystem "cluster-autoscaler" "Cluster capacity provisioning via ProvisioningRequest CRD" "External"
        workerClusters = softwareSystem "MultiKueue Worker Clusters" "Remote Kubernetes clusters for multi-cluster workload distribution" "External"

        # People -> System relationships
        dataScientist -> kueue "Submits jobs with queue-name label" "kubectl / Job CR"
        platformAdmin -> kueue "Creates ClusterQueues, LocalQueues, ResourceFlavors" "kubectl / YAML"
        sre -> prometheus "Monitors queue health and alerts" "Grafana / AlertManager"

        # System -> System relationships
        kueue -> k8sAPI "CRD CRUD, leader election, event recording, discovery" "HTTPS/443 TLS 1.2+ SA token"
        k8sAPI -> kueue "Dispatches admission webhook calls" "HTTPS/9443 TLS API Server cert"

        kueue -> batchJobs "Watches, suspends/resumes Jobs, creates Workloads" "CRD Watch + Webhook"
        kueue -> kubeflowTraining "Watches and manages training job lifecycle" "CRD Watch + Webhook"
        kueue -> kuberay "Watches and manages Ray job lifecycle" "CRD Watch + Webhook"
        kueue -> jobset "Watches and manages JobSet lifecycle" "CRD Watch + Webhook"
        kueue -> codeflare "Watches and manages AppWrapper lifecycle" "CRD Watch + Webhook"
        kueue -> leaderworkerset "Watches LeaderWorkerSet lifecycle" "CRD Watch + Webhook"

        prometheus -> kueue "Scrapes /metrics endpoint" "HTTPS/8443 TLS Bearer Token"
        kueue -> clusterAutoscaler "Creates ProvisioningRequests for capacity" "CRD-mediated via K8s API"
        kueue -> workerClusters "Syncs workloads to remote clusters (optional)" "HTTPS/443 TLS 1.2+ kubeconfig"
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
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Job Framework" {
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
