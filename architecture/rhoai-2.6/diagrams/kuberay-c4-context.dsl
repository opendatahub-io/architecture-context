workspace {
    model {
        # People
        dataScientist = person "Data Scientist" "Creates and deploys Ray clusters and jobs for distributed ML workloads"
        mlEngineer = person "ML Engineer" "Deploys Ray Serve applications for model serving"
        platformAdmin = person "Platform Administrator" "Manages KubeRay operator and cluster infrastructure"

        # Main System
        kuberay = softwareSystem "KubeRay" "Kubernetes operator for managing Ray clusters, jobs, and serve deployments" {
            operator = container "KubeRay Operator" "Reconciles Ray CRDs and manages cluster lifecycle" "Go Operator" {
                rayClusterController = component "RayCluster Controller" "Manages Ray cluster head/worker pods and services" "Go Controller"
                rayJobController = component "RayJob Controller" "Automates Ray job submission and cluster lifecycle" "Go Controller"
                rayServiceController = component "RayService Controller" "Manages Ray Serve deployments with HA and zero-downtime upgrades" "Go Controller"
            }

            apiserver = container "KubeRay APIServer" "Provides HTTP and gRPC APIs for KubeRay resource management" "Go API Server" "Optional"
        }

        # External Systems - Required
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform (1.28.3+)" "External" {
            kubeApi = container "Kubernetes API Server" "Central API for cluster state management" "Kubernetes"
        }

        ray = softwareSystem "Ray" "Distributed computing framework for ML workloads (2.7.0+)" "External"

        # External Systems - Optional
        openshift = softwareSystem "OpenShift Routes" "Ingress for Ray dashboard and services on OpenShift" "External Optional"
        volcano = softwareSystem "Volcano Scheduler" "Batch scheduler for gang scheduling Ray pods" "External Optional"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External Optional"

        # Internal ODH/RHOAI Systems
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for Open Data Hub platform" "Internal ODH"
        monitoringStack = softwareSystem "Monitoring Stack" "ODH/RHOAI monitoring and observability" "Internal ODH"
        dataSciencePipelines = softwareSystem "Data Science Pipelines" "Kubeflow Pipelines for ML workflows" "Internal ODH"

        # External Services
        containerRegistry = softwareSystem "Container Registry" "Storage for Ray container images" "External Service"
        objectStorage = softwareSystem "S3/GCS Storage" "Object storage for Ray data and models" "External Service"

        # User Interactions
        dataScientist -> kuberay "Creates RayCluster and RayJob via kubectl"
        mlEngineer -> kuberay "Deploys RayService via kubectl"
        platformAdmin -> kuberay "Configures and monitors operator"
        dataScientist -> apiserver "Manages clusters via API (optional)" "HTTP/gRPC"
        mlEngineer -> apiserver "Deploys services via API (optional)" "HTTP/gRPC"

        # System Interactions - Required
        kuberay -> kubeApi "Watches CRDs and manages Kubernetes resources" "HTTPS/443 TLS1.2+"
        kuberay -> ray "Manages Ray cluster deployments"
        operator -> kubeApi "Reconciles Ray CRs and creates pods/services" "HTTPS/443"
        apiserver -> kubeApi "CRUD operations on Ray resources via K8s API" "HTTPS/443"

        # System Interactions - Optional
        kuberay -> openshift "Creates Routes for Ray dashboard and services" "HTTPS/443"
        kuberay -> volcano "Enables gang scheduling for Ray pods" "via K8s API"
        kuberay -> prometheus "Exports operator metrics" "HTTP/8080"

        # Internal ODH Interactions
        odhDashboard -> kuberay "UI integration for Ray cluster management (planned)" "K8s API"
        kuberay -> monitoringStack "Exports metrics for platform monitoring" "Prometheus/8080"
        dataSciencePipelines -> kuberay "Auto-deploys Ray clusters from pipelines" "K8s API"

        # External Service Interactions
        ray -> containerRegistry "Pulls Ray container images" "HTTPS/443 TLS1.2+"
        ray -> objectStorage "Stores and retrieves ML data and models" "HTTPS/443 TLS1.2+"

        # Component Level
        rayClusterController -> kubeApi "Creates head/worker pods, services, ingresses" "HTTPS/443"
        rayJobController -> kubeApi "Creates RayCluster and submits jobs" "HTTPS/443"
        rayServiceController -> kubeApi "Creates RayCluster and serve deployments" "HTTPS/443"
    }

    views {
        systemContext kuberay "SystemContext" {
            include *
            autoLayout lr
            title "KubeRay System Context Diagram"
            description "Shows KubeRay operator in the context of Kubernetes, Ray, and ODH/RHOAI ecosystem"
        }

        container kuberay "Containers" {
            include *
            autoLayout lr
            title "KubeRay Container Diagram"
            description "Internal structure of KubeRay showing operator and optional APIServer"
        }

        component operator "Components" {
            include *
            autoLayout tb
            title "KubeRay Operator Components"
            description "Controllers within the KubeRay operator"
        }

        dynamic kuberay "RayClusterCreation" "Ray cluster creation workflow" {
            dataScientist -> kuberay "1. kubectl apply RayCluster CR"
            kuberay -> kubeApi "2. Watch event received"
            operator -> kubeApi "3. Create head pod"
            operator -> kubeApi "4. Create worker pods"
            operator -> kubeApi "5. Create ClusterIP service"
            kubeApi -> containerRegistry "6. Pull Ray image"
            autoLayout lr
            title "RayCluster Creation Flow"
        }

        dynamic kuberay "RayJobSubmission" "Ray job submission workflow" {
            dataScientist -> kuberay "1. kubectl apply RayJob CR"
            kuberay -> kubeApi "2. Watch event received"
            operator -> kubeApi "3. Create RayCluster"
            operator -> ray "4. Submit job to Ray head"
            ray -> ray "5. Execute distributed tasks"
            autoLayout lr
            title "RayJob Submission Flow"
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
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "External Service" {
                background #f5a623
                color #ffffff
            }
            element "Optional" {
                background #9b59b6
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                shape RoundedBox
            }
            element "Component" {
                shape Component
            }
        }

        theme default
    }
}
