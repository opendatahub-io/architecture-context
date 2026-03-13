workspace {
    model {
        # External Users
        user = person "Data Scientist / ML Engineer" "Runs distributed computing and ML training jobs on Ray clusters"

        # KubeRay System
        kuberay = softwareSystem "KubeRay Operator" "Kubernetes operator that manages Ray clusters for distributed computing and ML workloads" {
            operator = container "Ray Operator" "Go" "Reconciles RayCluster, RayJob, and RayService CRDs"
            rcController = container "RayCluster Controller" "Go" "Manages Ray cluster lifecycle, autoscaling, and fault tolerance"
            rjController = container "RayJob Controller" "Go" "Creates clusters and submits batch jobs"
            rsController = container "RayService Controller" "Go" "Manages zero-downtime serving deployments"
            authController = container "Authentication Controller" "Go" "Manages ServiceAccounts and RBAC for Ray clusters"
            netController = container "NetworkPolicy Controller" "Go" "Creates NetworkPolicies for cluster isolation"
            mtlsController = container "mTLS Controller" "Go" "Manages mutual TLS certificates for Ray communication"

            rayHead = container "Ray Head Pod" "Python/Go" "Ray head node with GCS and Dashboard"
            rayWorker = container "Ray Worker Pods" "Python/Go" "Ray worker nodes with Raylet and Object Store"
        }

        # External Dependencies
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        ray = softwareSystem "Ray" "Distributed computing runtime (v2.x)" "External"
        redis = softwareSystem "Redis" "External GCS fault tolerance storage (v6.x+, optional)" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring (v2.x, optional)" "External"
        kueue = softwareSystem "Kueue" "Job queuing and resource management (v0.5+, optional)" "External"
        volcano = softwareSystem "Volcano" "Batch scheduling and job queuing (v1.8+, optional)" "External"

        # Storage & Registry
        s3 = softwareSystem "S3 Storage" "Training datasets and checkpoints" "External"
        registry = softwareSystem "Container Registry" "Ray container images" "External"
        pypi = softwareSystem "PyPI" "Python package repository" "External"

        # Internal ODH Dependencies
        dashboard = softwareSystem "ODH Dashboard" "UI for creating and managing Ray clusters" "ODH"
        notebooks = softwareSystem "Notebooks" "Submit jobs to Ray clusters from workbenches" "ODH"
        dsp = softwareSystem "Data Science Pipelines" "Execute distributed training as pipeline steps" "ODH"
        modelRegistry = softwareSystem "Model Registry" "Register models trained on Ray clusters" "ODH"

        # Relationships - User Interactions
        user -> kuberay "Creates Ray clusters and submits distributed jobs"

        # Relationships - External Dependencies
        kuberay -> kubernetes "Orchestrates Ray cluster resources (Pods, Services)"
        rayHead -> ray "Runs Ray runtime with GCS and Dashboard"
        rayWorker -> ray "Runs Ray worker runtime with Raylet"
        rayHead -> redis "Uses for GCS persistence (optional)"
        kuberay -> prometheus "Exposes metrics for monitoring"
        kuberay -> kueue "Integrates for job queuing (optional)"
        kuberay -> volcano "Integrates for batch scheduling (optional)"

        # Relationships - Storage & Registry
        rayWorker -> s3 "Reads datasets and writes checkpoints"
        rayHead -> registry "Pulls Ray container images"
        rayWorker -> registry "Pulls Ray container images"
        rayHead -> pypi "Installs Python dependencies"

        # Relationships - Internal ODH
        dashboard -> kuberay "Manages Ray clusters via UI"
        notebooks -> rayHead "Submits jobs to Ray Dashboard API"
        dsp -> rayHead "Executes distributed training jobs"
        modelRegistry -> rayWorker "Registers trained models"

        # Internal KubeRay Relationships
        operator -> kubernetes "Watches and reconciles Ray CRDs"
        rcController -> operator "Integrates cluster management"
        rjController -> operator "Integrates batch job management"
        rsController -> operator "Integrates serving management"
        authController -> operator "Integrates authentication"
        netController -> operator "Integrates network isolation"
        mtlsController -> operator "Integrates mTLS certificates"

        rcController -> rayHead "Creates and manages Ray head pod"
        rcController -> rayWorker "Creates and autoscales Ray worker pods"
        authController -> rayHead "Configures ServiceAccounts and RBAC"
        netController -> rayHead "Creates NetworkPolicies"
        mtlsController -> rayHead "Provisions mTLS certificates"

        rayWorker -> rayHead "Connects to GCS for cluster coordination"
    }

    views {
        systemContext kuberay "KubeRayContext" {
            include *
            autoLayout lr
        }

        container kuberay "KubeRayContainers" {
            include *
            autoLayout lr
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "ODH" {
                background #0066cc
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
