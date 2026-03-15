workspace {
    model {
        user = person "Data Scientist" "Submits batch jobs and ML training workloads for execution"
        admin = person "Platform Admin" "Manages queues, quotas, and resource flavors"

        kueue = softwareSystem "Kueue" "Job queueing controller that manages when Kubernetes jobs should be admitted to start based on resource quotas and priorities" {
            controller = container "kueue-controller-manager" "Reconciles workloads, queues, and resource flavors; makes admission decisions" "Go Operator" {
                workloadReconciler = component "Workload Reconciler" "Manages workload lifecycle and admission"
                clusterqueueReconciler = component "ClusterQueue Reconciler" "Manages cluster-level resource quotas"
                localqueueReconciler = component "LocalQueue Reconciler" "Manages namespace-scoped queue configurations"
                scheduler = component "Scheduler" "Evaluates workload priorities and quota to make admission decisions"
                cache = component "In-Memory Cache" "Caches cluster queues, workloads, and resource usage"
                jobIntegrations = component "Job Integrations" "Framework integrating Batch, Kubeflow, Ray, JobSet, AppWrapper jobs"
            }
            webhook = container "Webhook Server" "Mutates and validates job resources on admission" "Go Service (in-process)"
            visibilityAPI = container "Visibility API Server" "Provides on-demand API for querying pending workloads" "Go Service (in-process)"
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics for monitoring" "Go Service (in-process)"
        }

        k8s = softwareSystem "Kubernetes API Server" "Core platform for CRD management and pod orchestration" "External"
        certManager = softwareSystem "cert-manager" "Generates and rotates TLS certificates for webhooks" "External"
        prometheus = softwareSystem "Prometheus" "Scrapes metrics for monitoring queue state and performance" "External"
        clusterAutoscaler = softwareSystem "Cluster Autoscaler" "Provisions nodes based on pending workload resource requests" "External"
        cloudProvider = softwareSystem "Cloud Provider API" "Scales node pools (AWS/GCP/Azure)" "External"

        kubeflowOperator = softwareSystem "Kubeflow Training Operator" "Manages TFJob, PyTorchJob, MPIJob training workloads" "External (Optional)"
        rayOperator = softwareSystem "Ray Operator" "Manages RayJob and RayCluster workloads" "External (Optional)"
        jobSet = softwareSystem "JobSet" "Manages JobSet resources" "External (Optional)"
        appWrapper = softwareSystem "AppWrapper" "Manages CodeFlare AppWrapper workloads" "External (Optional)"

        remoteCluster = softwareSystem "Remote Kubernetes Cluster" "Remote cluster for MultiKueue job dispatching" "External (Optional)"

        # User interactions
        user -> kueue "Submits jobs via kubectl, queries queue status"
        admin -> kueue "Configures ClusterQueues, LocalQueues, ResourceFlavors, AdmissionChecks"

        # Kueue core flows
        kueue -> k8s "Watches and reconciles CRDs, Jobs, Pods" "HTTPS/443, TLS 1.2+, ServiceAccount Token"
        k8s -> kueue "Calls admission webhooks for job mutations/validations" "HTTPS/9443, mTLS"
        kueue -> certManager "Requests webhook TLS certificates" "HTTPS/443, TLS 1.2+, ServiceAccount Token"
        prometheus -> kueue "Scrapes metrics" "HTTPS/8443, TLS 1.2+, ServiceAccount Bearer Token"

        # Autoscaling integration
        kueue -> clusterAutoscaler "Creates ProvisioningRequest CRDs for pending workloads" "HTTPS/443, TLS 1.2+, ServiceAccount Token"
        clusterAutoscaler -> cloudProvider "Provisions node pools" "HTTPS/443, TLS 1.2+, Cloud credentials"

        # Job integrations
        kueue -> kubeflowOperator "Manages admission for TFJob, PyTorchJob, etc." "HTTPS/443, TLS 1.2+, ServiceAccount Token"
        kueue -> rayOperator "Manages admission for RayJob, RayCluster" "HTTPS/443, TLS 1.2+, ServiceAccount Token"
        kueue -> jobSet "Manages admission for JobSet" "HTTPS/443, TLS 1.2+, ServiceAccount Token"
        kueue -> appWrapper "Manages admission for AppWrapper" "HTTPS/443, TLS 1.2+, ServiceAccount Token"

        # Multi-cluster
        kueue -> remoteCluster "Dispatches jobs to remote clusters (MultiKueue)" "HTTPS/443, TLS 1.2+, Kubeconfig credentials"

        # Internal component relationships
        controller -> webhook "Uses for admission control"
        controller -> visibilityAPI "Exposes via aggregated API"
        controller -> metricsServer "Exposes for Prometheus"
        workloadReconciler -> scheduler "Requests admission evaluation"
        scheduler -> cache "Checks quota and resource availability"
        scheduler -> clusterqueueReconciler "Validates quota"
        workloadReconciler -> jobIntegrations "Manages job lifecycle"
    }

    views {
        systemContext kueue "SystemContext" {
            include *
            autoLayout
            description "System context diagram for Kueue showing external dependencies and integrations"
        }

        container kueue "Containers" {
            include *
            autoLayout
            description "Container diagram showing internal components of Kueue"
        }

        component controller "Components" {
            include *
            autoLayout
            description "Component diagram showing internal structure of kueue-controller-manager"
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External (Optional)" {
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
                background #08427b
                color #ffffff
                shape person
            }
        }

        theme default
    }
}
