workspace {
    model {
        # People
        dataScientist = person "Data Scientist" "Submits batch jobs and training workloads for ML model development"
        mlEngineer = person "ML Engineer" "Manages queue configurations and resource quotas"
        clusterAdmin = person "Cluster Administrator" "Configures ClusterQueues, ResourceFlavors, and admission policies"

        # Kueue System
        kueue = softwareSystem "Kueue" "Job queueing controller that manages when Kubernetes jobs should be admitted based on resource quotas and priorities" {
            controller = container "Kueue Controller Manager" "Reconciles workloads, queues, and resource flavors; makes admission decisions" "Go 1.24" {
                workloadReconciler = component "Workload Reconciler" "Manages workload lifecycle from queued to admitted to finished" "Controller"
                clusterQueueReconciler = component "ClusterQueue Reconciler" "Manages cluster-level resource quotas" "Controller"
                localQueueReconciler = component "LocalQueue Reconciler" "Manages namespace-scoped queue configurations" "Controller"
                scheduler = component "Scheduler Engine" "Evaluates workload priorities and quota to make admission decisions" "Core"
                cache = component "In-Memory Cache" "Caches ClusterQueues, workloads, and resource usage for fast lookups" "Core"
                jobIntegrations = component "Job Integrations Framework" "Integrates with Batch, Kubeflow, Ray, JobSet, AppWrapper" "Controllers"
            }

            webhook = container "Webhook Server" "Validates and mutates workload resources on admission" "Go Admission Webhook" {
                mutatingWebhook = component "Mutating Webhook" "Injects queue annotations and suspends jobs" "Webhook Handler"
                validatingWebhook = component "Validating Webhook" "Validates Kueue CRD specifications" "Webhook Handler"
            }

            visibilityAPI = container "Visibility API Server" "On-demand API for querying pending workloads without polling CRDs" "Go HTTP API" {
                clusterQueueAPI = component "ClusterQueue API" "Lists pending workloads in ClusterQueue" "API Handler"
                localQueueAPI = component "LocalQueue API" "Lists pending workloads in LocalQueue" "API Handler"
            }
        }

        # External Systems (Dependencies)
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform providing CRD management and pod scheduling" "External"
        certManager = softwareSystem "cert-manager" "Automates TLS certificate issuance and rotation for webhooks" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring system" "External"

        # External Operators (Optional Dependencies)
        kubeflowOperator = softwareSystem "Kubeflow Training Operator" "Manages distributed ML training jobs (TFJob, PyTorchJob, MPIJob, etc.)" "External Optional"
        rayOperator = softwareSystem "Ray Operator" "Manages Ray distributed computing workloads (RayJob, RayCluster)" "External Optional"
        jobSetOperator = softwareSystem "JobSet Operator" "Manages sets of jobs as a single unit" "External Optional"
        appWrapperOperator = softwareSystem "AppWrapper Operator" "CodeFlare AppWrapper for gang-scheduled workloads" "External Optional"
        clusterAutoscaler = softwareSystem "Cluster Autoscaler" "Provisions nodes based on pending pod requirements" "External Optional"

        # Remote Systems (MultiKueue)
        remoteCluster = softwareSystem "Remote Kubernetes Clusters" "Remote clusters for multi-cluster job dispatching" "External Optional"

        # Relationships - Users to Kueue
        dataScientist -> kueue "Submits jobs (Batch, Kubeflow, Ray) via kubectl"
        mlEngineer -> kueue "Creates LocalQueues and monitors workload state"
        clusterAdmin -> kueue "Configures ClusterQueues, ResourceFlavors, and Cohorts"

        # Relationships - Kueue to External Systems
        kueue -> kubernetes "Watches and patches Jobs, Pods, CRDs via REST API (HTTPS/443, TLS 1.2+, Bearer Token)"
        kueue -> certManager "Requests TLS certificates for webhooks via Certificate CR (HTTPS/443)"
        kueue -> prometheus "Exposes queue and workload metrics (HTTPS/8443, TLS 1.2+, Bearer Token)"

        # Relationships - Kueue to Optional External Systems
        kueue -> kubeflowOperator "Patches TFJob, PyTorchJob, MPIJob, XGBoostJob, PaddleJob (HTTPS/443)" "Optional"
        kueue -> rayOperator "Patches RayJob and RayCluster for admission control (HTTPS/443)" "Optional"
        kueue -> jobSetOperator "Patches JobSet resources for quota management (HTTPS/443)" "Optional"
        kueue -> appWrapperOperator "Patches AppWrapper for gang-scheduled workloads (HTTPS/443)" "Optional"
        kueue -> clusterAutoscaler "Creates ProvisioningRequest CRs to trigger node provisioning (HTTPS/443)" "Optional"
        kueue -> remoteCluster "Dispatches jobs to remote clusters via MultiKueue (HTTPS/443, Kubeconfig auth)" "Optional"

        # Relationships - External Systems to Kueue
        kubernetes -> webhook "Calls mutating/validating webhooks on resource admission (HTTPS/9443, TLS 1.2+, mTLS)"
        prometheus -> kueue "Scrapes metrics endpoint (HTTPS/8443, TLS 1.2+, Bearer Token)"
        certManager -> webhook "Provisions TLS certificates for webhook server"

        # Internal Kueue Relationships
        controller -> webhook "Registers webhook configurations"
        controller -> visibilityAPI "Provides data for visibility queries"
        workloadReconciler -> scheduler "Requests admission decisions"
        scheduler -> cache "Queries ClusterQueue quota and priorities"
        jobIntegrations -> kubernetes "Patches job resources to admit/suspend workloads"
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

        component controller "ControllerComponents" {
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
                background #d0021b
                color #ffffff
                shape person
            }
        }
    }
}
