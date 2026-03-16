workspace {
    model {
        # People
        dataScientist = person "Data Scientist" "Creates and submits ML training jobs and inference workloads"
        mlEngineer = person "ML Engineer" "Manages workload queues and resource allocation"
        platformAdmin = person "Platform Admin" "Configures cluster-wide resource quotas and policies"

        # Kueue System
        kueue = softwareSystem "Kueue" "Job queueing controller for managing workload admission and resource allocation in Kubernetes clusters" {
            controllerManager = container "Controller Manager" "Manages workload admission, queueing, and resource allocation" "Go Operator" {
                clusterQueueController = component "ClusterQueue Controller" "Manages cluster-wide resource quotas and workload admission"
                localQueueController = component "LocalQueue Controller" "Manages namespace-scoped queues"
                workloadController = component "Workload Controller" "Reconciles workload admission and lifecycle"
                admissionCheckController = component "AdmissionCheck Controller" "Validates workloads against admission requirements"
                resourceFlavorController = component "ResourceFlavor Controller" "Manages resource flavor definitions"
                multiKueueController = component "MultiKueue Controller" "Distributes workloads across multiple clusters"
            }

            webhookServer = container "Webhook Server" "Validates and mutates workload resources on creation" "Go HTTPS Service" {
                mutatingWebhook = component "Mutating Webhook" "Injects queue name and suspends jobs for Kueue management"
                validatingWebhook = component "Validating Webhook" "Validates Kueue CRD configurations"
            }

            visibilityServer = container "Visibility API Server" "Provides visibility into pending workloads" "Go Aggregated API Server" {
                pendingWorkloadsAPI = component "Pending Workloads API" "Exposes pending workload information via aggregated API"
            }

            metricsEndpoint = container "Metrics Endpoint" "Exposes Prometheus metrics for monitoring" "Go HTTP Service"
        }

        # Kubernetes Platform
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External" {
            apiServer = container "API Server" "Kubernetes control plane API" "External"
            scheduler = container "Scheduler" "Pod scheduling" "External"
        }

        # External Dependencies
        istio = softwareSystem "Istio" "Service mesh for traffic management and security" "External"
        certManager = softwareSystem "cert-manager" "Kubernetes certificate management" "External"
        clusterAutoscaler = softwareSystem "Cluster Autoscaler" "Automatic node provisioning and scaling" "External"

        # Internal ODH Components
        trainingOperator = softwareSystem "Training Operator" "Manages Kubeflow training jobs (PyTorch, TensorFlow, MPI, etc.)" "Internal ODH"
        rayOperator = softwareSystem "Ray Operator" "Manages Ray distributed computing workloads" "Internal ODH"
        jobSetOperator = softwareSystem "JobSet Operator" "Manages groups of related Kubernetes jobs" "Internal ODH"

        # External Services
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External Monitoring"
        remoteClusters = softwareSystem "Remote Kubernetes Clusters" "Additional Kubernetes clusters for workload distribution" "External"

        # Relationships - Users to Kueue
        dataScientist -> kueue "Submits training jobs via kubectl/API"
        mlEngineer -> kueue "Manages queues and monitors workload status"
        platformAdmin -> kueue "Configures cluster queues and resource quotas"

        # Relationships - Kueue to Kubernetes
        kueue -> kubernetes "Watches and manages workload CRDs, Jobs, and Pods" "HTTPS/6443, TLS 1.2+, Service Account Token"
        kubernetes -> kueue "Calls admission webhooks during resource creation" "HTTPS/9443, mTLS"
        kubernetes -> kueue "Proxies visibility API requests" "HTTPS/8082, Bearer Token"

        # Relationships - Kueue to External Dependencies
        kueue -> certManager "Requests TLS certificates for webhooks and APIs" "HTTPS, TLS 1.2+"
        kueue -> clusterAutoscaler "Creates ProvisioningRequests for node provisioning" "HTTPS, TLS 1.2+, Service Account Token"
        kueue -> remoteClusters "Distributes workloads across clusters (MultiKueue)" "HTTPS/6443, TLS 1.2+, Kubeconfig Auth"

        # Relationships - Kueue to Internal ODH Components
        kueue -> trainingOperator "Queues and manages ML training jobs" "Webhook + CRD Watch"
        kueue -> rayOperator "Queues and manages Ray workloads" "Webhook + CRD Watch"
        kueue -> jobSetOperator "Queues and manages JobSet workloads" "Webhook + CRD Watch"

        # Relationships - External Services to Kueue
        prometheus -> kueue "Scrapes metrics from controller" "HTTPS/8443, Bearer Token"

        # Container Relationships
        controllerManager -> webhookServer "Serves webhooks"
        controllerManager -> visibilityServer "Serves visibility API"
        controllerManager -> metricsEndpoint "Exposes metrics"

        webhookServer -> apiServer "Validates/queries resources"
        visibilityServer -> apiServer "Queries workload CRDs"
        workloadController -> apiServer "Watches and updates workloads"
        clusterQueueController -> apiServer "Manages cluster queues"
        localQueueController -> apiServer "Manages local queues"
        multiKueueController -> remoteClusters "Distributes workloads"

        # Component Relationships
        mutatingWebhook -> apiServer "Queries for validation"
        validatingWebhook -> apiServer "Queries for validation"
        clusterQueueController -> workloadController "Admits workloads"
        admissionCheckController -> workloadController "Validates workload requirements"
    }

    views {
        systemContext kueue "KueueSystemContext" {
            include *
            autoLayout
            description "System context diagram showing Kueue's role in the Kubernetes ecosystem"
        }

        container kueue "KueueContainers" {
            include *
            autoLayout
            description "Container diagram showing the internal structure of Kueue"
        }

        component controllerManager "ControllerManagerComponents" {
            include *
            autoLayout
            description "Component diagram showing the internal controllers of the Controller Manager"
        }

        component webhookServer "WebhookServerComponents" {
            include *
            autoLayout
            description "Component diagram showing the webhook server components"
        }

        styles {
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "External Monitoring" {
                background #e8761f
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
            element "Component" {
                background #85bbf0
                color #000000
            }
        }

        theme default
    }

    configuration {
        scope softwaresystem
    }
}
