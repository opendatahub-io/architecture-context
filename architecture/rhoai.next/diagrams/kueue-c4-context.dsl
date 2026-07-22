workspace {
    model {
        // People
        dataScientist = person "Data Scientist" "Submits ML training jobs and batch workloads"
        platformAdmin = person "Platform Admin" "Configures ClusterQueues, ResourceFlavors, and quotas"
        securityTeam = person "Security / SRE" "Monitors alerts and reviews RBAC"

        // Kueue System
        kueue = softwareSystem "Kueue" "Kubernetes-native job queueing system managing quota and admission control for batch workloads" {
            controllerManager = container "Kueue Controller Manager" "controller-runtime based operator managing job queueing, quota admission, workload scheduling, webhook validation, and metrics" "Go Operator" {
                cqController = component "ClusterQueue Controller" "Manages ClusterQueue lifecycle and resource allocation cache"
                lqController = component "LocalQueue Controller" "Manages LocalQueue lifecycle and workload queue ordering"
                wlController = component "Workload Controller" "Manages Workload lifecycle, admission state, and job synchronization"
                scheduler = component "Scheduler" "Dequeues workloads and makes admission decisions against quota cache"
                cache = component "Cache" "In-memory real-time view of resource allocation across ClusterQueues and Cohorts"
                queueManager = component "Queue Manager" "Maintains ordered workload queues per LocalQueue/ClusterQueue"
                provisioningCtrl = component "Provisioning Controller" "Manages ProvisioningRequest admission checks with Cluster Autoscaler"
                multiKueueCtrl = component "MultiKueue Controller" "Federates workloads to remote Kueue clusters"
                tasController = component "TAS Controller" "Topology-Aware Scheduling: assigns topology domains to pods"
                topologyUngater = component "TopologyUngater" "Removes scheduling gates after topology assignment"
            }
            webhookServer = container "Webhook Server" "Mutating and validating admission webhooks for all supported job types and Kueue CRDs" "Go (controller-runtime webhook)" {
                tags "Webhook"
            }
            visibilityAPI = container "Visibility API Server" "On-demand pending workloads API (extension API server)" "Go" {
                tags "API"
            }
            metricsEndpoint = container "Metrics Endpoint" "Prometheus metrics at /metrics with bearer token auth" "Go (controller-runtime)" {
                tags "Monitoring"
            }
        }

        // External Systems
        k8sAPI = softwareSystem "Kubernetes API Server" "Control plane for cluster resource management" {
            tags "External"
        }
        clusterAutoscaler = softwareSystem "Cluster Autoscaler" "Provisions node capacity via ProvisioningRequest API" {
            tags "External"
        }
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting (RHOAI monitoring stack)" {
            tags "Monitoring"
        }
        certManager = softwareSystem "cert-manager" "Optional external certificate management for webhook TLS" {
            tags "External"
        }

        // Internal Platform Systems
        kubeflowTraining = softwareSystem "Kubeflow Training Operator" "Manages distributed training jobs (PyTorchJob, TFJob, MPIJob, PaddleJob, XGBoostJob)" {
            tags "Internal RHOAI"
        }
        rayOperator = softwareSystem "Ray Operator" "Manages RayJob and RayCluster workloads" {
            tags "Internal RHOAI"
        }
        codeflare = softwareSystem "CodeFlare Operator" "Manages AppWrapper workloads" {
            tags "Internal RHOAI"
        }
        jobsetController = softwareSystem "JobSet Controller" "Manages JobSet workloads" {
            tags "Internal RHOAI"
        }

        // Remote clusters (MultiKueue)
        remoteKueue = softwareSystem "Remote Kueue Clusters" "Worker clusters for multi-cluster workload federation (disabled in RHOAI)" {
            tags "External" "Disabled"
        }

        // Relationships - People
        dataScientist -> kueue "Submits jobs with queue-name labels via kubectl/API"
        platformAdmin -> kueue "Configures ClusterQueues, LocalQueues, ResourceFlavors, Cohorts"
        securityTeam -> prometheus "Reviews alerts: KueuePodDown, ResourceReservationExceedsQuota"

        // Relationships - Kueue to External
        kueue -> k8sAPI "Watches and manages CRDs, Pods, Jobs, Secrets, ConfigMaps, Nodes" "HTTPS/443, ServiceAccount token"
        kueue -> clusterAutoscaler "Creates ProvisioningRequests for capacity checks" "HTTPS/443, ServiceAccount token"
        kueue -> remoteKueue "Federates Workloads to remote clusters (MultiKueue=false)" "HTTPS/443, kubeconfig credentials"

        // Relationships - External to Kueue
        k8sAPI -> webhookServer "Sends admission review requests" "HTTPS/9443, TLS client auth"
        prometheus -> metricsEndpoint "Scrapes /metrics via ServiceMonitor" "HTTPS/8443, Bearer Token"
        certManager -> kueue "Provisions webhook TLS certificates (optional)" "Kubernetes Secret"

        // Relationships - Internal platform
        kubeflowTraining -> k8sAPI "Creates training job CRs"
        rayOperator -> k8sAPI "Creates RayJob/RayCluster CRs"
        codeflare -> k8sAPI "Creates AppWrapper CRs"
        jobsetController -> k8sAPI "Creates JobSet CRs"

        // Internal container relationships
        controllerManager -> webhookServer "Manages webhook lifecycle"
        controllerManager -> visibilityAPI "Serves pending workload queries"
        controllerManager -> metricsEndpoint "Exposes controller metrics"
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

        component controllerManager "Components" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438DD5
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
            element "Monitoring" {
                background #f5a623
                color #ffffff
            }
            element "Disabled" {
                background #cccccc
                color #666666
                border dashed
            }
            element "Person" {
                shape person
                background #08427B
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "Component" {
                background #85BBF0
                color #000000
            }
            element "Webhook" {
                background #ff9800
                color #ffffff
            }
            element "API" {
                background #4caf50
                color #ffffff
            }
        }
    }
}
