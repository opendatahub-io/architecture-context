workspace {
    model {
        # People
        dataScientist = person "Data Scientist" "Develops and deploys distributed ML workloads using Ray"
        mlEngineer = person "ML Engineer" "Manages Ray cluster deployments and model serving"
        externalClient = person "External Client" "Consumes model predictions via Ray Serve"

        # KubeRay System
        kuberay = softwareSystem "KubeRay Operator" "Manages Ray cluster lifecycle on Kubernetes for distributed computing" {
            operator = container "KubeRay Operator" "Kubernetes operator managing Ray CRDs" "Go, controller-runtime v0.22.1" {
                rayClusterCtrl = component "RayCluster Controller" "Manages cluster lifecycle and autoscaling"
                rayJobCtrl = component "RayJob Controller" "Manages batch job execution"
                rayServiceCtrl = component "RayService Controller" "Manages Ray Serve with HA"
                authCtrl = component "Authentication Controller" "Manages mTLS and OAuth"
                webhooks = component "Admission Webhooks" "Validates and mutates RayCluster CRs"
            }

            rayCluster = container "Ray Cluster" "Distributed compute cluster" "Ray Framework" {
                rayHead = component "Ray Head Pod" "Cluster coordinator with GCS, dashboard, client server"
                rayWorkers = component "Ray Worker Pods" "Autoscaled worker nodes for distributed computation"
            }

            rayService = container "Ray Serve" "Model serving platform" "Ray Serve" {
                serveSvc = component "Serve Service" "HTTP endpoint for model predictions"
            }
        }

        # External Systems (Required)
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform (1.30+)" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management for mTLS" "External, Optional"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External, Optional"
        redis = softwareSystem "External Redis" "GCS fault tolerance external storage" "External, Optional"

        # External Systems (Gateway/Networking)
        gatewayAPI = softwareSystem "Gateway API" "Advanced ingress and routing with authentication" "External, Optional"
        openshiftRoute = softwareSystem "OpenShift Route API" "OpenShift ingress integration" "External, Optional"

        # Cloud Services
        objectStorage = softwareSystem "Object Storage (S3/GCS)" "Model artifacts and working directory storage" "External"
        containerRegistry = softwareSystem "Container Registry" "Ray container images" "External"

        # Internal RHOAI Dependencies
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for RHOAI components" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Model metadata and versioning" "Internal RHOAI"
        dataSciencePipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration" "Internal RHOAI"

        # Relationships - Users
        dataScientist -> kuberay "Creates RayCluster/RayJob via kubectl/SDK"
        mlEngineer -> kuberay "Manages Ray deployments and monitors clusters"
        externalClient -> rayService "Requests model predictions via HTTPS"

        # Relationships - Core Dependencies
        kuberay -> kubernetes "Manages resources and deploys workloads" "HTTPS/443, TLS 1.2+, SA Token"
        kuberay -> certManager "Requests TLS certificates for mTLS" "HTTPS/443, TLS 1.2+, SA Token"
        kuberay -> gatewayAPI "Creates HTTPRoutes for advanced routing" "HTTPS/443, TLS 1.2+, SA Token"
        kuberay -> openshiftRoute "Creates OpenShift Routes for ingress" "HTTPS/443, TLS 1.2+, SA Token"

        # Relationships - Ray Cluster
        operator -> rayCluster "Creates and manages Ray pods" "Kubernetes API"
        rayCluster -> redis "Stores GCS state for fault tolerance" "Redis/6379, Optional TLS, Password"
        rayCluster -> objectStorage "Accesses model artifacts and data" "HTTPS/443, TLS 1.2+, Cloud IAM"
        rayCluster -> containerRegistry "Pulls Ray container images" "HTTPS/443, TLS 1.2+, Pull Secrets"

        # Relationships - Monitoring
        prometheus -> operator "Scrapes operator metrics" "HTTP/8080"
        prometheus -> rayCluster "Scrapes Ray cluster metrics" "HTTP/8265"

        # Relationships - Internal RHOAI
        odhDashboard -> kuberay "Displays Ray cluster resources and status" "Kubernetes API"
        modelRegistry -> rayCluster "Uses Ray for distributed model training" "gRPC/10001, Optional mTLS"
        dataSciencePipelines -> kuberay "Executes Ray jobs in pipeline steps" "Kubernetes API"

        # Internal Component Relationships
        rayClusterCtrl -> rayHead "Creates and configures head pod"
        rayClusterCtrl -> rayWorkers "Creates and autoscales worker pods"
        rayJobCtrl -> rayHead "Submits batch jobs" "gRPC/10001, Optional mTLS"
        rayServiceCtrl -> serveSvc "Manages zero-downtime upgrades"
        authCtrl -> certManager "Manages mTLS certificates"
        rayWorkers -> rayHead "Connects to GCS" "Redis/6379, Optional mTLS"
        serveSvc -> rayWorkers "Invokes model predictions" "Ray Protocol, Optional mTLS"
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

        theme default
    }
}
