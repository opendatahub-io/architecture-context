workspace {
    model {
        // Users
        dataScientist = person "Data Scientist" "Submits ML training jobs and inference workloads"
        mlEngineer = person "ML Engineer" "Submits distributed training jobs (PyTorch, TensorFlow, MPI, Ray)"
        platformAdmin = person "Platform Administrator" "Configures queues, resource quotas, and admission policies"

        // Kueue System
        kueue = softwareSystem "Kueue" "Kubernetes-native job queueing and resource management system for fair resource sharing and multi-tenant workload scheduling" {
            controllerManager = container "Controller Manager" "Reconciles queue and workload resources, manages job admission" "Go Operator" {
                clusterQueueController = component "ClusterQueue Controller" "Manages cluster-wide resource quotas and queueing policies"
                localQueueController = component "LocalQueue Controller" "Manages namespace-scoped queues"
                workloadController = component "Workload Controller" "Admits or suspends workloads based on resource availability"
                resourceFlavorController = component "ResourceFlavor Controller" "Manages resource types (e.g., GPU models, node types)"
                admissionCheckController = component "AdmissionCheck Controller" "Validates workloads before admission"
            }
            webhookServer = container "Webhook Server" "Validates and mutates job resources" "Go Admission Webhook" {
                batchJobWebhook = component "Batch Job Webhook" "Mutates/validates Batch jobs"
                kubeflowWebhook = component "Kubeflow Job Webhook" "Mutates/validates TFJob, PyTorchJob, MPIJob"
                rayWebhook = component "Ray Webhook" "Mutates/validates RayJob, RayCluster"
                jobsetWebhook = component "JobSet Webhook" "Mutates/validates JobSet resources"
                podWebhook = component "Pod Webhook" "Mutates/validates plain Pods (optional)"
            }
            visibilityServer = container "Visibility API Server" "Provides API for querying pending workloads" "Go API Server"
        }

        // External Systems - Required
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Core Kubernetes API for resource management" "External"

        // External Systems - Optional
        certManager = softwareSystem "cert-manager" "TLS certificate management for webhooks" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "Metrics collection and monitoring" "External"
        clusterAutoscaler = softwareSystem "cluster-autoscaler" "Auto-scales cluster nodes based on workload demand" "External"

        // Internal ODH/RHOAI Systems
        trainingOperator = softwareSystem "Training Operator (Kubeflow)" "Manages distributed ML training jobs (TensorFlow, PyTorch, MPI, XGBoost, MXNet, PaddlePaddle)" "Internal RHOAI"
        kuberayOperator = softwareSystem "KubeRay Operator" "Manages Ray clusters and Ray jobs" "Internal RHOAI"
        codeflareOperator = softwareSystem "CodeFlare Operator" "Manages AppWrapper workloads for multi-job orchestration" "Internal RHOAI"

        // Multi-cluster
        remoteKubernetes = softwareSystem "Remote Kubernetes Clusters" "Remote clusters for multi-cluster job distribution (MultiKueue)" "External"

        // Relationships - User interactions
        dataScientist -> kueue "Submits Batch jobs via kubectl"
        mlEngineer -> kueue "Submits distributed training jobs (PyTorchJob, TFJob, MPIJob, RayJob)"
        platformAdmin -> kueue "Configures ClusterQueues, LocalQueues, ResourceFlavors, AdmissionChecks"
        dataScientist -> visibilityServer "Queries pending workloads via visibility API"

        // Kueue to Kubernetes
        kueue -> kubernetesAPI "Watches and reconciles CRDs, Jobs, Pods" "HTTPS/6443 TLS1.2+"
        webhookServer -> kubernetesAPI "Validates job submissions via admission webhook" "HTTPS/9443 TLS1.2+ mTLS"
        visibilityServer -> kubernetesAPI "Queries workload status" "HTTPS/8082 TLS1.2+"
        controllerManager -> kubernetesAPI "Creates/updates Workloads, manages job suspension/admission" "HTTPS/6443 TLS1.2+"

        // Kueue to ODH/RHOAI components
        kueue -> trainingOperator "Queues and admits TFJob, PyTorchJob, MPIJob, XGBoostJob, MXJob, PaddleJob" "CRD Watch/Webhook"
        kueue -> kuberayOperator "Queues and admits RayJob, RayCluster" "CRD Watch/Webhook"
        kueue -> codeflareOperator "Queues and admits AppWrapper workloads" "CRD Watch"

        // Kueue to external systems
        kueue -> certManager "Requests TLS certificates for webhook server" "HTTPS/443"
        prometheusOperator -> kueue "Scrapes Prometheus metrics" "HTTPS/8443 TLS1.2+ Bearer Token"
        kueue -> clusterAutoscaler "Creates ProvisioningRequests to auto-provision nodes" "K8s API"
        kueue -> remoteKubernetes "Distributes jobs to remote clusters (MultiKueue)" "HTTPS/6443 TLS1.2+ Kubeconfig"

        // Required dependency
        kueue -> kubernetes "Deployed on Kubernetes" "Platform"
    }

    views {
        systemContext kueue "KueueSystemContext" {
            include *
            autoLayout
            title "Kueue System Context Diagram"
            description "Shows how Kueue integrates with Kubernetes, ODH/RHOAI components, and external systems for job queueing and resource management"
        }

        container kueue "KueueContainers" {
            include *
            autoLayout
            title "Kueue Container Diagram"
            description "Internal components of the Kueue system: Controller Manager, Webhook Server, and Visibility API Server"
        }

        component controllerManager "ControllerManagerComponents" {
            include *
            autoLayout
            title "Controller Manager Components"
            description "Core controllers within the Kueue Controller Manager"
        }

        component webhookServer "WebhookServerComponents" {
            include *
            autoLayout
            title "Webhook Server Components"
            description "Job framework integrations via admission webhooks"
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
            element "Software System" {
                background #4a90e2
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
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }
    }

    configuration {
        scope softwaresystem
    }
}
