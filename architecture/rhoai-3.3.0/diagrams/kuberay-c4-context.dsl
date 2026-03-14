workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and manages Ray clusters for distributed computing and ML workloads"
        externalClient = person "External Client" "Consumes model serving endpoints via Ray Serve"

        kuberay = softwareSystem "KubeRay Operator" "Kubernetes operator that manages Ray cluster lifecycle, jobs, and services for distributed computing" {
            operator = container "kuberay-operator" "Main operator deployment managing Ray CRDs" "Go Operator" {
                rayClusterController = component "RayCluster Controller" "Manages Ray cluster lifecycle and autoscaling"
                rayJobController = component "RayJob Controller" "Manages batch job execution"
                rayServiceController = component "RayService Controller" "Manages Ray Serve deployments with HA"
                networkPolicyController = component "NetworkPolicy Controller" "Creates network isolation policies"
                authController = component "Authentication Controller" "Manages mTLS certificates and OAuth"
            }

            webhook = container "Webhook Server" "Validates and mutates RayCluster resources" "Go Service" {
                mutatingWebhook = component "Mutating Webhook" "Adds defaults and security configurations"
                validatingWebhook = component "Validating Webhook" "Validates resource specifications"
            }

            rayCluster = container "Ray Cluster (Managed)" "Distributed Ray cluster for computation" "Ray Framework" {
                rayHead = component "Ray Head Pod" "Cluster coordinator with GCS, dashboard, and client server"
                rayWorkers = component "Ray Worker Pods" "Distributed compute workers with autoscaling"
            }
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management" "External"
        redis = softwareSystem "External Redis" "GCS fault tolerance storage" "External"
        objectStorage = softwareSystem "Object Storage (S3/GCS)" "Ray working directory and data storage" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        gatewayAPI = softwareSystem "Gateway API" "Advanced ingress and routing with authentication" "External"
        openShiftRoute = softwareSystem "OpenShift Route API" "OpenShift ingress integration" "External"

        odhDashboard = softwareSystem "ODH Dashboard" "Display Ray cluster resources and status" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Model metadata and versioning" "Internal ODH"
        dsPipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration" "Internal ODH"

        # User interactions
        user -> kuberay "Creates RayCluster, RayJob, RayService resources via kubectl/OpenShift console"
        externalClient -> kuberay "Sends inference requests to Ray Serve endpoints" "HTTPS/443"

        # Core operator interactions
        kuberay -> kubernetes "Manages pods, services, ingresses, network policies" "HTTPS/443"
        kuberay -> certManager "Provisions TLS certificates for mTLS" "HTTPS/443"
        kuberay -> redis "Stores GCS state for fault tolerance" "Redis/6379"
        kuberay -> objectStorage "Accesses Ray working directory and data" "HTTPS/443"
        kuberay -> gatewayAPI "Creates HTTPRoutes with authentication" "HTTPS/443"
        kuberay -> openShiftRoute "Creates Routes for ingress" "HTTPS/443"

        prometheus -> kuberay "Scrapes operator and Ray cluster metrics" "HTTP/8080"

        # Internal ODH integrations
        odhDashboard -> kuberay "Displays Ray cluster status and resources"
        modelRegistry -> kuberay "May use Ray for distributed model training"
        dsPipelines -> kuberay "Executes Ray jobs in pipeline steps"

        # Ray cluster interactions
        rayCluster -> redis "Optional GCS HA storage" "Redis/6379"
        rayCluster -> objectStorage "Loads data and saves results" "HTTPS/443"
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

        component webhook "WebhookComponents" {
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
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #5a9fd4
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}
