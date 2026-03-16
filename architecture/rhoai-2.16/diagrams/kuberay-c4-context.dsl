workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages Ray clusters for distributed computing and ML workloads"
        mlEngineer = person "ML Engineer" "Deploys Ray Serve applications for ML model serving"

        kuberay = softwareSystem "KubeRay Operator" "Kubernetes operator that manages Ray cluster lifecycle for distributed computing" {
            operator = container "KubeRay Operator" "Reconciles RayCluster, RayJob, RayService CRs" "Go Controller" {
                rayClusterController = component "RayCluster Controller" "Manages Ray cluster head and worker pods" "Go Reconciler"
                rayJobController = component "RayJob Controller" "Creates clusters and submits batch jobs" "Go Reconciler"
                rayServiceController = component "RayService Controller" "Manages Ray Serve deployments with zero-downtime upgrades" "Go Reconciler"
                webhookServer = component "Webhook Server" "Validates RayCluster resources" "Go Validation Webhook"
            }

            rayCluster = container "Ray Cluster" "Distributed Ray runtime environment" "Ray Framework" {
                headPod = component "Ray Head Pod" "GCS, Dashboard, Scheduler, Job Manager" "Ray Head"
                workerPods = component "Ray Worker Pods" "Execute distributed tasks (autoscaling)" "Ray Workers"
            }

            apiServer = container "APIServer (Optional)" "HTTP/gRPC API for KubeRay management" "Go Service" "Community-managed"
        }

        kubernetes = softwareSystem "Kubernetes/OpenShift" "Container orchestration platform" "External"
        prometheus = softwareSystem "Prometheus" "Monitoring and metrics collection" "External"
        odhDashboard = softwareSystem "ODH Dashboard" "User interface for managing data science components" "Internal ODH"
        monitoringStack = softwareSystem "Monitoring Stack" "ODH monitoring infrastructure" "Internal ODH"

        volcano = softwareSystem "Volcano Scheduler" "Gang scheduling for improved resource utilization" "External Optional"
        externalRedis = softwareSystem "External Redis" "GCS fault tolerance storage" "External Optional"
        s3Storage = softwareSystem "S3-Compatible Storage" "Model artifacts and GCS fault tolerance" "External Optional"

        # User interactions
        dataScientist -> kuberay "Creates RayCluster via kubectl/dashboard"
        dataScientist -> odhDashboard "Manages Ray clusters"
        mlEngineer -> kuberay "Deploys RayService for ML inference"
        mlEngineer -> rayCluster "Submits inference requests" "HTTPS/443"

        # Operator interactions
        operator -> kubernetes "Manages pods, services, routes via API" "HTTPS/443"
        operator -> prometheus "Exposes metrics" "HTTP/8080"
        odhDashboard -> kuberay "Creates/manages RayCluster CRs" "Kubernetes API"

        # Ray cluster interactions
        rayClusterController -> headPod "Creates and manages" "Kubernetes API"
        rayClusterController -> workerPods "Creates and manages" "Kubernetes API"
        rayJobController -> headPod "Submits jobs" "HTTP/8265"
        rayServiceController -> headPod "Manages Ray Serve apps" "HTTP/8265"

        workerPods -> headPod "Connects to GCS for coordination" "TCP/6379"
        workerPods -> headPod "Ray Dashboard API calls" "HTTP/8265"

        # Optional dependencies
        headPod -> externalRedis "GCS fault tolerance (optional)" "TCP/6379"
        headPod -> s3Storage "External storage for GCS FT (optional)" "HTTPS/443"
        operator -> volcano "Gang scheduling via annotations (optional)" "Kubernetes API"
        apiServer -> kubernetes "Manages KubeRay CRs (optional)" "HTTPS/443"

        # Monitoring
        monitoringStack -> operator "Collects operator metrics" "HTTP/8080"
        prometheus -> headPod "Scrapes Ray metrics" "HTTP/8080"
        prometheus -> workerPods "Scrapes worker metrics" "HTTP/8080"
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
            element "Software System" {
                background #1168bd
                color #ffffff
            }
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
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Community-managed" {
                background #cccccc
                color #333333
                shape RoundedBox
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }

        theme default
    }
}
