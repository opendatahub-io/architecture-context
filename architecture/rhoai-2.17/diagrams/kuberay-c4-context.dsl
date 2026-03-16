workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and manages distributed Ray applications for ML training, batch inference, and model serving"
        admin = person "Platform Administrator" "Deploys and configures KubeRay operator and manages cluster resources"

        kuberay = softwareSystem "KubeRay Operator" "Kubernetes operator that simplifies deployment and management of Ray applications on Kubernetes" {
            operator = container "KubeRay Operator" "Manages Ray cluster lifecycle and reconciles CRDs" "Go Operator" {
                reconciler = component "Reconciler Loop" "Watches and reconciles RayCluster, RayJob, RayService CRDs" "Go"
                resourceManager = component "Resource Manager" "Creates and manages Kubernetes resources (Pods, Services, etc.)" "Go"
                metricsExporter = component "Metrics Exporter" "Exposes Prometheus metrics for monitoring" "Go"
            }

            apiserver = container "KubeRay API Server (Optional)" "Provides simplified REST/gRPC APIs for Ray cluster management" "Go Service" {
                restAPI = component "REST API Handler" "HTTP endpoints for cluster/job/service management" "Go HTTP"
                grpcAPI = component "gRPC Service" "gRPC services for programmatic cluster operations" "gRPC"
            }

            rayCluster = container "Ray Cluster (Managed)" "Distributed Ray cluster with head and worker nodes" "Ray Framework" {
                headNode = component "Ray Head Node" "Control plane: GCS, Dashboard, Client Server" "Python/Ray"
                workerNodes = component "Ray Worker Nodes" "Compute nodes for distributed task execution" "Python/Ray"
                autoscaler = component "Ray Autoscaler" "Monitors load and scales workers dynamically" "Python"
            }
        }

        k8s = softwareSystem "Kubernetes API Server" "Container orchestration control plane" "External Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External Monitoring"
        ingressController = softwareSystem "Ingress Controller / OpenShift Router" "External access and load balancing" "External"
        containerRegistry = softwareSystem "Container Registry" "Stores Ray container images (quay.io, registry.access.redhat.com)" "External"
        s3 = softwareSystem "S3 / Object Storage" "Stores training data and model artifacts" "External Storage"
        externalRedis = softwareSystem "External Redis (Optional)" "Alternative GCS backend for high availability" "External"

        # Internal ODH Dependencies
        modelMesh = softwareSystem "Model Mesh" "Model serving infrastructure" "Internal ODH"
        notebookController = softwareSystem "Notebook Controller" "Manages Jupyter notebooks" "Internal ODH"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for platform management" "Internal ODH"

        # Optional External Schedulers
        volcano = softwareSystem "Volcano / Yunikorn (Optional)" "Gang scheduling and batch scheduling" "External"
        certManager = softwareSystem "cert-manager (Optional)" "TLS certificate management for webhooks" "External"

        # User interactions
        user -> kuberay "Creates RayCluster/RayJob/RayService CRs via kubectl/UI"
        user -> rayCluster "Submits Ray jobs via Ray Client API (10001/TCP)"
        user -> rayCluster "Monitors cluster via Ray Dashboard (8265/TCP)"
        admin -> kuberay "Deploys operator and configures RBAC"

        # KubeRay Operator interactions
        operator -> k8s "Watches/reconciles Ray CRDs, manages Pods/Services/Jobs" "HTTPS/443 TLS1.2+"
        operator -> rayCluster "Creates and manages Ray head/worker pods"
        operator -> containerRegistry "Pulls Ray container images" "HTTPS/443"
        operator -> prometheus "Exposes /metrics endpoint" "HTTP/8080"
        operator -> ingressController "Creates Ingress/Route resources for external access"

        # Optional API Server interactions
        apiserver -> k8s "Creates Ray CRDs via Kubernetes API" "HTTPS/443 TLS1.2+"
        user -> apiserver "Creates/manages clusters via REST/gRPC API" "HTTP/8888, gRPC/8887"

        # Ray Cluster interactions
        rayCluster -> s3 "Reads training data and model artifacts" "HTTPS/443 TLS1.2+"
        rayCluster -> externalRedis "Optional: Uses external Redis for HA GCS backend" "TCP/6379 TLS"
        headNode -> workerNodes "Distributes tasks and collects results" "TCP plaintext (default)"
        autoscaler -> workerNodes "Scales workers based on cluster load"

        # Monitoring and Observability
        prometheus -> operator "Scrapes operator metrics" "HTTP/8080"
        prometheus -> rayCluster "Scrapes Ray cluster metrics" "HTTP/8080"

        # External access
        ingressController -> rayCluster "Routes external traffic to Ray Dashboard/Client" "HTTP/8265, TCP/10001"

        # Internal ODH integrations
        rayCluster -> modelMesh "Ray Serve as inference runtime" "gRPC/HTTP"
        notebookController -> rayCluster "Submits Ray jobs from Jupyter notebooks" "TCP/10001"
        odhDashboard -> kuberay "Displays Ray cluster status and metrics" "Kubernetes API"

        # Optional integrations
        operator -> volcano "Uses gang scheduling for Ray pods" "Kubernetes API"
        operator -> certManager "Provisions TLS certificates for webhooks" "Certificate CRDs"
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

        component apiserver "APIServerComponents" {
            include *
            autoLayout
        }

        component rayCluster "RayClusterComponents" {
            include *
            autoLayout
        }

        styles {
            element "External Platform" {
                background #999999
                color #ffffff
            }
            element "External Monitoring" {
                background #9673a6
                color #ffffff
            }
            element "External" {
                background #d6b656
                color #000000
            }
            element "External Storage" {
                background #f5a623
                color #000000
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #3d85c6
                color #ffffff
            }
            element "Component" {
                background #6fa8dc
                color #000000
            }
        }
    }

    configuration {
        scope softwaresystem
    }
}
