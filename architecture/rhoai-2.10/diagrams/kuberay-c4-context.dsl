workspace {
    model {
        dataScientist = person "Data Scientist" "Runs distributed ML workloads, training, and inference on Ray clusters"
        admin = person "Platform Admin" "Manages KubeRay operator and Ray cluster infrastructure"

        kuberay = softwareSystem "KubeRay Operator" "Kubernetes operator that manages Ray distributed computing clusters for ML workloads" {
            operator = container "KubeRay Operator" "Reconciles Ray CRs and manages cluster lifecycle" "Go Operator" {
                rayClusterController = component "RayCluster Controller" "Manages Ray cluster infrastructure with autoscaling"
                rayJobController = component "RayJob Controller" "Manages job submission and temporary clusters"
                rayServiceController = component "RayService Controller" "Manages Ray Serve deployments with HA"
                admissionWebhook = component "Admission Webhook" "Validates RayCluster specifications"
                metricsServer = component "Metrics Server" "Exposes Prometheus metrics"
                rbacManager = component "RBAC Manager" "Creates ServiceAccounts and Roles"
                routeManager = component "Route Manager" "Manages OpenShift Routes"
            }

            rayCluster = container "Ray Cluster" "Distributed computing cluster for ML workloads" "Ray Python Framework" {
                headPod = component "Ray Head Pod" "Cluster coordinator with GCS and dashboard"
                workerPods = component "Ray Worker Pods" "Autoscaled workers executing distributed tasks"
            }
        }

        kubernetes = softwareSystem "Kubernetes API Server" "Kubernetes control plane" "External"
        openshift = softwareSystem "OpenShift Routes" "Ingress and routing for external access" "External"
        registry = softwareSystem "Container Registry" "Stores Ray and operator container images (quay.io)" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        redis = softwareSystem "External Redis" "Optional GCS fault tolerance storage" "External Optional"
        volcano = softwareSystem "Volcano Scheduler" "Optional gang scheduling for batch workloads" "External Optional"

        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for managing Ray clusters" "Internal ODH"
        odhMonitoring = softwareSystem "ODH Monitoring" "RHOAI monitoring stack" "Internal ODH"

        # User interactions
        dataScientist -> kuberay "Creates RayCluster, RayJob, RayService CRs via kubectl/UI"
        dataScientist -> odhDashboard "Manages Ray clusters through UI"
        admin -> kuberay "Configures and monitors operator"

        # Core dependencies
        kuberay -> kubernetes "Watches CRs, manages Pods/Services/RBAC" "HTTPS/6443 TLS 1.2+ ServiceAccount Token"
        kuberay -> registry "Pulls Ray and operator images" "HTTPS/443 TLS 1.2+ Pull Credentials"
        kuberay -> openshift "Creates Routes for external access" "Kubernetes API"

        # Optional dependencies
        kuberay -> redis "GCS fault tolerance storage (optional)" "TCP/6379 Optional TLS Redis Password"
        kuberay -> volcano "Gang scheduling integration (optional)" "Kubernetes API"

        # Monitoring
        prometheus -> kuberay "Scrapes operator and Ray cluster metrics" "HTTP/8080 No Auth"
        kuberay -> prometheus "Exposes /metrics endpoints"

        # ODH Integration
        odhDashboard -> kuberay "Manages Ray clusters via Kubernetes API" "HTTPS/6443"
        odhMonitoring -> kuberay "Collects metrics from operator and Ray pods" "HTTP/8080"

        # Internal relationships
        operator -> rayCluster "Creates and manages Ray pods and services"
        rayClusterController -> headPod "Creates head pod with GCS and dashboard"
        rayClusterController -> workerPods "Creates and scales worker pods"
        rayJobController -> rayCluster "Creates temporary cluster for job execution"
        rayServiceController -> rayCluster "Manages cluster for Ray Serve deployment"
        workerPods -> headPod "Connects to GCS for task coordination" "TCP/6379"
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
            element "External Optional" {
                background #cccccc
                color #333333
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
