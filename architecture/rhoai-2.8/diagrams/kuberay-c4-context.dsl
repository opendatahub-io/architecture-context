workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Deploys and manages Ray clusters for distributed computing workloads"
        admin = person "Platform Administrator" "Manages KubeRay operator and platform infrastructure"

        kuberay = softwareSystem "KubeRay" "Kubernetes operator for managing Ray distributed computing clusters" {
            operator = container "KubeRay Operator" "Manages RayCluster, RayJob, and RayService lifecycle" "Go Operator" {
                rayClusterCtrl = component "RayCluster Controller" "Reconciles RayCluster CRs and manages Ray infrastructure" "Controller"
                rayJobCtrl = component "RayJob Controller" "Manages batch job execution on Ray clusters" "Controller"
                rayServiceCtrl = component "RayService Controller" "Manages Ray Serve deployments with HA" "Controller"
            }
            apiserver = container "KubeRay APIServer" "Optional simplified gRPC/HTTP API for resource management" "Go gRPC/HTTP Server"
            cli = container "KubeRay CLI" "Command-line interface for managing Ray resources" "CLI Tool"
            pythonClient = container "Python Client" "Python SDK for programmatic cluster management" "Python Library"
        }

        rayCluster = softwareSystem "Ray Cluster" "Distributed computing runtime managed by KubeRay" {
            rayHead = container "Ray Head Node" "Coordinates cluster, runs GCS, dashboard, and scheduler" "Python/C++"
            rayWorkers = container "Ray Worker Nodes" "Execute distributed tasks and actors" "Python/C++"
            dashboard = container "Ray Dashboard" "Web UI for monitoring cluster state" "Web Application"
        }

        # External Dependencies
        kubernetes = softwareSystem "Kubernetes API" "Container orchestration platform" "External"
        openshift = softwareSystem "OpenShift Platform" "Enterprise Kubernetes with Routes and SCC" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        grafana = softwareSystem "Grafana" "Metrics visualization and dashboards" "External"
        certManager = softwareSystem "cert-manager" "Automated TLS certificate management" "External"
        registry = softwareSystem "Container Registry" "Stores Ray operator and workload images" "External"
        s3storage = softwareSystem "S3/GCS Storage" "Object storage for Ray data and GCS fault tolerance" "External"
        externalRedis = softwareSystem "External Redis" "Optional backend for Ray GCS fault tolerance" "External"
        volcano = softwareSystem "Volcano Scheduler" "Optional gang scheduling for Ray clusters" "External"

        # Internal ODH Dependencies
        monitoring = softwareSystem "ODH Monitoring Stack" "RHOAI monitoring infrastructure" "Internal ODH"

        # User Interactions
        user -> kuberay "Creates and manages Ray clusters, jobs, and services via kubectl or API"
        user -> rayCluster "Submits jobs and queries cluster via Ray Client"
        user -> dashboard "Monitors cluster health and performance"
        admin -> kuberay "Deploys and configures KubeRay operator"

        # KubeRay to Kubernetes
        operator -> kubernetes "Creates and manages Pods, Services, Ingresses, Jobs via API" "HTTPS/443"
        apiserver -> kubernetes "Manages Ray CRDs via Kubernetes API" "HTTPS/443"

        # KubeRay to Ray Cluster
        operator -> rayCluster "Provisions and manages Ray infrastructure"
        apiserver -> rayHead "Submits jobs via Ray Dashboard API" "HTTP/8265"

        # KubeRay to External Dependencies
        operator -> openshift "Creates Routes for dashboard and services" "HTTPS/443"
        operator -> certManager "Requests TLS certificates for Ray services" "HTTPS/443"
        rayHead -> registry "Pulls Ray container images" "HTTPS/443"
        rayWorkers -> registry "Pulls Ray container images" "HTTPS/443"

        # Ray Cluster Internal
        rayWorkers -> rayHead "Connects to GCS for coordination" "TCP/6379"
        dashboard -> rayHead "Queries cluster state" "HTTP/8080"

        # Ray Cluster to External Storage
        rayHead -> s3storage "Stores checkpoints and data" "HTTPS/443"
        rayHead -> externalRedis "Optional GCS fault tolerance backend" "TCP/6379"

        # Monitoring
        prometheus -> operator "Scrapes operator metrics" "HTTP/8080"
        prometheus -> rayHead "Scrapes Ray cluster metrics" "HTTP/8080"
        grafana -> prometheus "Queries metrics data" "HTTP/9090"
        operator -> monitoring "Exposes ServiceMonitor for ODH monitoring" "CRD"

        # Optional Integrations
        operator -> volcano "Gang scheduling integration" "HTTPS/443"
    }

    views {
        systemContext kuberay "SystemContext" {
            include *
            autoLayout
        }

        container kuberay "KubeRayContainers" {
            include *
            autoLayout
        }

        container rayCluster "RayClusterContainers" {
            include *
            autoLayout
        }

        component operator "OperatorComponents" {
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
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}
