workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and manages distributed Ray clusters and ML workloads"
        admin = person "Platform Administrator" "Manages KubeRay Operator and cluster policies"

        kuberay = softwareSystem "KubeRay Operator" "Kubernetes operator that manages Ray cluster lifecycle for distributed computing and ML inference" {
            operator = container "KubeRay Operator Controller" "Main controller managing RayCluster, RayJob, RayService CRDs" "Go Operator" {
                rayClusterController = component "RayCluster Controller" "Reconciles RayCluster resources, manages head/worker pods"
                rayJobController = component "RayJob Controller" "Creates clusters and submits batch jobs"
                rayServiceController = component "RayService Controller" "Manages Ray Serve deployments with HA"
                webhook = component "Admission Webhook" "Validates RayCluster CR operations" "HTTPS/9443"
                metricsExporter = component "Metrics Exporter" "Prometheus metrics" "HTTP/8080"
            }

            rayCluster = container "Ray Cluster (Managed)" "Distributed Ray compute cluster with head and worker nodes" "Ray" {
                headPod = component "Ray Head Pod" "Cluster coordination (GCS), dashboard, autoscaling"
                workerPods = component "Ray Worker Pods" "Auto-scaled compute nodes"
                servePod = component "Ray Serve" "ML model serving endpoint" "HTTP/8000"
            }
        }

        k8s = softwareSystem "Kubernetes API Server" "Container orchestration platform" "External"
        openshift = softwareSystem "OpenShift Routes/SCC" "OpenShift-specific features for external access and security" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management for admission webhooks" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        redis = softwareSystem "External Redis" "GCS fault tolerance storage" "External"

        volcano = softwareSystem "Volcano Scheduler" "Gang scheduling for distributed workloads" "Optional External"
        yunikorn = softwareSystem "YuniKorn Scheduler" "Alternative batch scheduler" "Optional External"
        kueue = softwareSystem "Kueue" "Job queuing and resource management" "Optional External"

        registry = softwareSystem "Container Registry" "Stores Ray and application container images" "External"
        storage = softwareSystem "Object Storage (S3/GCS)" "Model artifacts and application data" "External"
        dashboard = softwareSystem "ODH Dashboard" "Optional UI integration for cluster management" "Internal ODH"

        # Relationships - Users
        user -> kuberay "Creates RayCluster/RayJob/RayService via kubectl/API"
        user -> servePod "Sends inference requests" "HTTP/8000"
        admin -> kuberay "Manages operator, monitors clusters"

        # Relationships - Operator Internal
        operator -> k8s "Manages pods, services, jobs, ingresses" "HTTPS/443"
        rayClusterController -> headPod "Creates and manages"
        rayClusterController -> workerPods "Creates and manages"
        rayJobController -> rayClusterController "Creates RayCluster"
        rayJobController -> k8s "Creates submitter K8s Job"
        rayServiceController -> rayClusterController "Creates RayCluster"
        rayServiceController -> servePod "Manages zero-downtime updates"
        webhook -> k8s "Validates CRs via admission webhook" "HTTPS/9443 mTLS"

        # Relationships - Ray Cluster Internal
        workerPods -> headPod "Connect to GCS" "TCP/6379"
        headPod -> k8s "Autoscaler manages worker pods" "HTTPS/443"

        # Relationships - External Dependencies
        kuberay -> openshift "Creates Routes for external access, uses SCC"
        kuberay -> certManager "Webhook certificate provisioning"
        kuberay -> prometheus "Exposes metrics" "HTTP/8080"
        headPod -> redis "Optional GCS fault tolerance" "TCP/6379"

        # Optional Schedulers
        rayCluster -> volcano "Gang scheduling via pod annotations"
        rayCluster -> yunikorn "Batch scheduling via pod annotations"
        rayCluster -> kueue "Job queuing via pod labels"

        # External Services
        headPod -> registry "Pull Ray images" "HTTPS/443"
        headPod -> storage "Fetch application code and data" "HTTPS/443"

        # ODH Integration
        dashboard -> kuberay "Optional cluster management UI"
        prometheus -> operator "Scrapes operator metrics" "HTTP/8080"
        prometheus -> headPod "Scrapes Ray cluster metrics" "HTTP/8080"
    }

    views {
        systemContext kuberay "KubeRaySystemContext" {
            include *
            autoLayout
        }

        container kuberay "KubeRayContainers" {
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
            element "Optional External" {
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
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}
