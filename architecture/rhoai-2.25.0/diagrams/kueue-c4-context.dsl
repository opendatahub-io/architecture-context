workspace {
    model {
        dataScientist = person "Data Scientist" "Submits batch jobs and training workloads to the cluster"
        platformAdmin = person "Platform Admin" "Manages cluster queues, resource quotas, and admission policies"

        kueue = softwareSystem "Kueue" "Job queueing controller that manages when Kubernetes jobs should be admitted to start based on resource quotas and priorities" {
            controller = container "kueue-controller-manager" "Manages workload lifecycle and admission decisions" "Go Deployment" {
                workloadReconciler = component "Workload Reconciler" "Manages workload lifecycle and admission decisions" "Controller"
                clusterQueueReconciler = component "ClusterQueue Reconciler" "Manages cluster-level resource quotas" "Controller"
                localQueueReconciler = component "LocalQueue Reconciler" "Manages namespace-scoped queue configurations" "Controller"
                jobIntegrations = component "Job Integrations" "Integrates Batch, Kubeflow, Ray, JobSet, AppWrapper jobs" "Controllers"
                scheduler = component "Scheduler" "Evaluates workload priorities and quota to make admission decisions" "Core Component"
                cache = component "Cache" "In-memory cache of cluster queues, workloads, and resource usage" "Core Component"
            }
            webhookServer = container "Webhook Server" "Mutates and validates workload resources on admission" "Go HTTPS Server"
            metricsService = container "Metrics Service" "Prometheus metrics endpoint for monitoring queue state" "HTTPS Endpoint"
            visibilityServer = container "Visibility Server" "On-demand API for querying pending workloads" "HTTP Server"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Core platform for CRD management and pod orchestration" "External"
        certManager = softwareSystem "cert-manager" "Generates and rotates TLS certificates for webhooks" "External"
        prometheus = softwareSystem "Prometheus" "Scrapes metrics for monitoring queue state and performance" "External"
        kubeflowTrainingOperator = softwareSystem "Kubeflow Training Operator" "Manages TFJob, PyTorchJob, MPIJob, XGBoostJob, PaddleJob" "External Optional"
        rayOperator = softwareSystem "Ray Operator" "Manages RayJob and RayCluster" "External Optional"
        jobSet = softwareSystem "JobSet" "Manages JobSet resources for multi-pod jobs" "External Optional"
        appWrapper = softwareSystem "AppWrapper" "Manages CodeFlare AppWrapper for batch workloads" "External Optional"
        clusterAutoscaler = softwareSystem "Cluster Autoscaler" "Provisions nodes based on pending workloads" "External Optional"
        remoteK8s = softwareSystem "Remote Kubernetes Clusters" "Remote clusters for multi-cluster job dispatching (MultiKueue)" "External Optional"

        %% Relationships
        dataScientist -> kueue "Creates and submits jobs via kubectl"
        platformAdmin -> kueue "Configures cluster queues, resource flavors, and admission policies"

        kueue -> k8sAPI "Watches and reconciles CRDs, Jobs, Pods, Deployments, StatefulSets" "HTTPS/443, TLS 1.2+, ServiceAccount Token"
        k8sAPI -> webhookServer "Calls mutating/validating webhooks on job creation" "HTTPS/9443, TLS 1.2+, mTLS"
        k8sAPI -> visibilityServer "Aggregates visibility API for pending workload queries" "In-process HTTP, K8s RBAC"

        kueue -> certManager "Requests webhook TLS certificates" "HTTPS/443"
        prometheus -> metricsService "Scrapes queue and workload metrics" "HTTPS/8443, TLS 1.2+, Bearer Token"

        kueue -> kubeflowTrainingOperator "Watches and patches TFJob, PyTorchJob, MPIJob" "HTTPS/443, TLS 1.2+"
        kueue -> rayOperator "Watches and patches RayJob, RayCluster" "HTTPS/443, TLS 1.2+"
        kueue -> jobSet "Watches and patches JobSet" "HTTPS/443, TLS 1.2+"
        kueue -> appWrapper "Watches and patches AppWrapper" "HTTPS/443, TLS 1.2+"
        kueue -> clusterAutoscaler "Creates ProvisioningRequest for node provisioning" "HTTPS/443, TLS 1.2+"
        kueue -> remoteK8s "Dispatches jobs to remote clusters (MultiKueue)" "HTTPS/443, TLS 1.2+, Kubeconfig"

        controller -> workloadReconciler "Manages workload admission"
        controller -> clusterQueueReconciler "Manages cluster queue state"
        controller -> localQueueReconciler "Manages local queue state"
        controller -> jobIntegrations "Watches and patches jobs"
        controller -> scheduler "Makes admission decisions"
        scheduler -> cache "Queries queue and resource state"
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

        component controller "Components" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Optional" {
                background #cccccc
                color #333333
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #7ed321
                color #ffffff
            }
            element "Component" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                background #d62728
                color #ffffff
                shape Person
            }
        }

        theme default
    }
}
