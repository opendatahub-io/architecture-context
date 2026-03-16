workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Creates and manages distributed Ray workloads on Kubernetes"
        ciSystem = softwareSystem "CI/CD Pipeline" "Automates Ray job submissions and cluster management" "External"

        kuberay = softwareSystem "KubeRay" "Kubernetes operator for managing Ray distributed computing clusters with autoscaling and fault tolerance" {
            operator = container "KubeRay Operator" "Reconciles RayCluster, RayJob, and RayService CRDs; manages Ray cluster lifecycle" "Go Operator" {
                reconciler = component "CRD Reconciler" "Watches and reconciles Ray CRs" "Controller Runtime"
                podManager = component "Pod Manager" "Creates and manages Ray head/worker pods" "Kubernetes Client"
                serviceManager = component "Service Manager" "Manages Kubernetes Services and Routes" "Kubernetes Client"
            }

            apiServer = container "KubeRay API Server" "Provides simplified REST and gRPC APIs for managing Ray resources" "Go gRPC/HTTP Server" "Optional"

            rayCluster = container "Ray Cluster" "Distributed Ray workload execution environment" "Ray Framework" {
                headPod = component "Ray Head Pod" "Ray control plane: GCS, dashboard, client server" "Ray Head"
                workerPods = component "Ray Worker Pods" "Ray compute nodes executing distributed workloads" "Ray Workers"
                autoscaler = component "Ray Autoscaler" "Automatically scales worker pods based on resource demands" "Sidecar Container"
            }
        }

        k8s = softwareSystem "Kubernetes API Server" "Orchestration platform for Ray clusters" "External Dependency"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External Optional"
        redis = softwareSystem "External Redis" "GCS fault tolerance storage for production clusters" "External Optional"
        s3 = softwareSystem "S3/Cloud Storage" "Model artifacts and checkpoint storage" "External Optional"
        registry = softwareSystem "Container Registry" "Ray operator and workload container images" "External"
        routes = softwareSystem "OpenShift Route API" "External access to Ray services" "Internal RHOAI"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning" "Internal Optional"

        # User interactions
        dataScientist -> kuberay "Creates RayCluster, RayJob, RayService via kubectl/UI"
        dataScientist -> rayCluster "Submits jobs, monitors dashboard, queries Serve endpoints"
        ciSystem -> kuberay "Automates Ray job submissions and deployments"

        # Component relationships
        dataScientist -> k8s "Creates Ray CRs via kubectl"
        operator -> k8s "Watches CRDs, manages pods/services/ingresses" "HTTPS/6443, ServiceAccount Token"
        apiServer -> k8s "Manages Ray resources programmatically" "HTTPS/6443, ServiceAccount Token"
        apiServer -> operator "Triggers reconciliation via CR updates"

        operator -> rayCluster "Creates and manages Ray clusters"
        reconciler -> podManager "Delegates pod lifecycle operations"
        reconciler -> serviceManager "Delegates service/route creation"
        podManager -> k8s "Creates/updates/deletes pods"
        serviceManager -> k8s "Creates/updates/deletes services and routes"

        headPod -> workerPods "GCS coordination and task distribution" "Ray Protocol/6379"
        autoscaler -> podManager "Requests worker pod scaling"

        # External integrations
        prometheus -> operator "Scrapes operator metrics" "HTTP/8080"
        prometheus -> headPod "Scrapes Ray cluster metrics" "HTTP/8265"

        operator -> registry "Pulls Ray operator image" "HTTPS/443"
        rayCluster -> registry "Pulls Ray workload images" "HTTPS/443"

        headPod -> redis "GCS fault tolerance persistence" "Redis/6379, Optional TLS"
        rayCluster -> s3 "Stores checkpoints and artifacts" "HTTPS/443, Cloud IAM"

        operator -> routes "Creates OpenShift Routes for external access" "CRD API"
        operator -> certManager "Requests TLS certificates" "CRD API, Optional"
    }

    views {
        systemContext kuberay "KubeRay-SystemContext" {
            include *
            autoLayout lr
        }

        container kuberay "KubeRay-Containers" {
            include *
            autoLayout lr
        }

        component operator "KubeRay-Operator-Components" {
            include *
            autoLayout lr
        }

        component rayCluster "RayCluster-Components" {
            include *
            autoLayout tb
        }

        styles {
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #7ed321
                color #000000
            }
            element "Component" {
                background #f5a623
                color #000000
            }
            element "External Dependency" {
                background #999999
                color #ffffff
            }
            element "External Optional" {
                background #cccccc
                color #000000
            }
            element "Internal RHOAI" {
                background #50e3c2
                color #000000
            }
            element "Internal Optional" {
                background #b8e986
                color #000000
            }
            element "Optional" {
                border dashed
            }
        }

        theme default
    }
}
