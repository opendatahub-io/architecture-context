workspace {
    model {
        user = person "Data Scientist" "Creates and manages Ray distributed computing clusters for ML/AI workloads"

        kuberay = softwareSystem "KubeRay Operator" "Kubernetes operator for deploying and managing Ray distributed computing clusters" {
            operator = container "kuberay-operator" "Reconciles Ray custom resources and manages cluster lifecycle" "Go Operator" {
                rayClusterController = component "RayCluster Controller" "Manages Ray cluster head and worker pods, services, autoscaling"
                rayJobController = component "RayJob Controller" "Manages Ray job submission and lifecycle with cluster creation/deletion"
                rayServiceController = component "RayService Controller" "Manages Ray Serve deployments with zero-downtime upgrades"
                webhook = component "Validating Webhook" "Validates RayCluster resource specifications"
            }

            rayCluster = container "Ray Cluster" "Distributed computing cluster for ML/AI workloads" "Ray Runtime" {
                headNode = component "Ray Head Node" "Cluster coordinator with GCS, dashboard, and client endpoint"
                workerNodes = component "Ray Worker Nodes" "Compute workers with autoscaling support"
                gcs = component "Global Control Service (GCS)" "Cluster coordination and metadata"
                dashboard = component "Ray Dashboard" "Cluster monitoring and job management UI"
                serve = component "Ray Serve" "ML model serving with high availability"
            }
        }

        # External Kubernetes/OpenShift Components
        k8sAPI = softwareSystem "Kubernetes API Server" "Container orchestration platform" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management for webhooks" "External"

        # Optional External Components
        volcano = softwareSystem "Volcano Scheduler" "Gang scheduling for distributed training jobs" "External"
        externalRedis = softwareSystem "External Redis" "GCS fault tolerance backend" "External"

        # Storage and Registry
        containerRegistry = softwareSystem "Container Registry" "Stores Ray container images (quay.io/gcr.io)" "External"
        objectStorage = softwareSystem "Object Storage" "Model artifacts and data storage (S3/GCS/Azure Blob)" "External"

        # RHOAI/ODH Platform Components
        openshiftRoutes = softwareSystem "OpenShift Routes" "External access to Ray dashboard and serve endpoints" "Internal RHOAI"
        serviceMesh = softwareSystem "Service Mesh (Istio)" "mTLS and traffic management for Ray services" "Internal RHOAI"
        monitoringStack = softwareSystem "RHOAI Monitoring Stack" "Platform-wide observability" "Internal RHOAI"
        dsPipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration" "Internal RHOAI"
        notebooks = softwareSystem "Notebook Environments" "Interactive development environments" "Internal RHOAI"

        # User interactions
        user -> kuberay "Creates RayCluster, RayJob, RayService via kubectl/UI"
        user -> dashboard "Monitors cluster and job status"
        user -> serve "Sends inference requests"

        # KubeRay to Kubernetes
        operator -> k8sAPI "Manages Ray resources (Pods, Services, Routes, CRDs)" "HTTPS/443 (ServiceAccount Token)"
        k8sAPI -> operator "Watches Ray custom resources"
        k8sAPI -> webhook "Validates RayCluster resources" "mTLS"

        # Controllers manage Ray components
        rayClusterController -> rayCluster "Creates and manages cluster resources"
        rayJobController -> rayCluster "Submits jobs to cluster"
        rayServiceController -> serve "Manages serve deployments"

        # Ray internal architecture
        headNode -> gcs "Coordinates via GCS"
        workerNodes -> gcs "Register and communicate via GCS"
        serve -> workerNodes "Distributes inference tasks"

        # External dependencies
        k8sAPI -> containerRegistry "Pulls Ray container images" "HTTPS/443"
        rayCluster -> objectStorage "Reads/writes model artifacts and data" "HTTPS/443 (Cloud IAM)"
        gcs -> externalRedis "Optional fault tolerance backend" "TCP/6379"

        # Monitoring and observability
        prometheus -> operator "Scrapes operator metrics" "HTTP/8080"
        prometheus -> headNode "Scrapes Ray cluster metrics" "HTTP/8080"
        monitoringStack -> prometheus "Aggregates metrics"

        # Optional integrations
        operator -> volcano "Gang scheduling for distributed training" "Kubernetes API"
        operator -> certManager "Webhook TLS certificates" "Kubernetes API"
        rayCluster -> serviceMesh "mTLS for service-to-service communication"

        # RHOAI platform integrations
        openshiftRoutes -> dashboard "External access to dashboard" "HTTPS/443"
        openshiftRoutes -> serve "External access to model serving" "HTTPS/443"
        dsPipelines -> kuberay "Creates Ray clusters for pipeline steps"
        notebooks -> kuberay "Users create Ray clusters from notebooks"

        # Component relationships within operator
        operator -> rayClusterController "Manages"
        operator -> rayJobController "Manages"
        operator -> rayServiceController "Manages"
        operator -> webhook "Serves"
    }

    views {
        systemContext kuberay "SystemContext" {
            include *
            autoLayout
        }

        container kuberay "Containers" {
            include *
            autoLayout
        }

        component operator "OperatorComponents" {
            include *
            autoLayout
        }

        component rayCluster "RayClusterComponents" {
            include *
            autoLayout
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
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
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
        }

        theme default
    }
}
