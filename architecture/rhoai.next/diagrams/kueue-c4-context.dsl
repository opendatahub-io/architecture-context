workspace {
    model {
        admin = person "Cluster Admin" "Configures ClusterQueues, ResourceFlavors, and quota policies"
        datascientist = person "Data Scientist" "Submits ML training jobs and inference workloads via LocalQueues"

        kueue = softwareSystem "Kueue" "Kubernetes-native job queueing system providing quota management, fair sharing, and priority-based scheduling" {
            controller = container "kueue-controller-manager" "Core controller managing quota admission, scheduling, preemption, and workload lifecycle" "Go Operator (controller-runtime)"
            webhookServer = container "Webhook Server" "Mutating and validating webhooks intercepting workload creation across 14+ frameworks (36 webhooks total)" "HTTPS 9443/TCP"
            metricsServer = container "Metrics Server" "Prometheus metrics for admission, quota, scheduling, and queue metrics" "HTTPS 8443/TCP"
            scheduler = container "Scheduler" "Implements StrictFIFO and BestEffortFIFO queueing strategies with DRF fair sharing" "Go"
            preemptionEngine = container "Preemption Engine" "Evaluates preemption candidates with configurable policies (LowerPriority, Any)" "Go"
            certManager = container "Internal Cert Manager" "Self-signed TLS certificate management for webhook server" "Go"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API server for resource management" "External"
        kubeflowTraining = softwareSystem "Kubeflow Training Operator" "Manages distributed training jobs (PyTorch, TF, MPI, Paddle, XGBoost)" "Internal ODH"
        kuberayOperator = softwareSystem "KubeRay Operator" "Manages Ray clusters and Ray jobs" "Internal ODH"
        jobsetController = softwareSystem "JobSet Controller" "Manages multi-job sets" "Internal ODH"
        codeflareOperator = softwareSystem "CodeFlare Operator" "Manages AppWrapper workloads" "Internal ODH"
        leaderworkersetController = softwareSystem "LeaderWorkerSet Controller" "Manages leader-worker pattern workloads" "External"
        certManagerExternal = softwareSystem "cert-manager" "Optional external certificate management" "External"
        clusterAutoscaler = softwareSystem "Cluster Autoscaler" "Provisions nodes via ProvisioningRequest CRDs" "External"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection and alerting" "External"

        # User interactions
        admin -> kueue "Configures quotas and queues via kubectl"
        datascientist -> kueue "Submits workloads to LocalQueues"

        # Core integrations
        kueue -> kubernetesAPI "Watches CRDs, manages workload lifecycle, leader election" "HTTPS/443 TLS 1.2+ SA Bearer Token"
        kubernetesAPI -> kueue "Webhook calls on workload create/update" "HTTPS/9443 TLS mTLS"

        # Framework integrations
        kueue -> kubeflowTraining "Intercepts and manages training job admission" "Webhook 9443/TCP"
        kueue -> kuberayOperator "Intercepts and manages Ray workload admission" "Webhook 9443/TCP"
        kueue -> jobsetController "Intercepts and manages JobSet admission" "Webhook 9443/TCP"
        kueue -> codeflareOperator "Intercepts and manages AppWrapper admission" "Webhook 9443/TCP"
        kueue -> leaderworkersetController "Intercepts and manages LeaderWorkerSet admission" "Webhook 9443/TCP"

        # External integrations
        kueue -> clusterAutoscaler "Creates ProvisioningRequest CRs for capacity" "CRD API"
        kueue -> certManagerExternal "Optional webhook cert management" "CRD API"
        prometheus -> kueue "Scrapes admission, quota, scheduling metrics" "HTTPS/8443 Bearer Token"
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
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}
