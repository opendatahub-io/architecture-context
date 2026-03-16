workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and manages Ray clusters for distributed computing and model serving"
        ci = person "CI/CD Pipeline" "Automates deployment of Ray jobs and services"

        kuberay = softwareSystem "KubeRay" "Kubernetes operator for managing Ray distributed computing clusters" {
            operator = container "kuberay-operator" "Reconciles RayCluster, RayJob, and RayService CRDs" "Go Operator" {
                rayClusterController = component "RayCluster Controller" "Manages Ray cluster lifecycle, autoscaling, and fault tolerance"
                rayJobController = component "RayJob Controller" "Manages batch job submission and automatic cluster cleanup"
                rayServiceController = component "RayService Controller" "Manages Ray Serve deployments with zero-downtime upgrades"
            }

            apiserver = container "kuberay-apiserver" "gRPC/HTTP API for simplified resource management" "Go Service (Optional)" {
                tags "Optional"
            }

            rayHead = container "Ray Head Pod" "Ray cluster head node with GCS, Dashboard, and Client Server" "Python/Ray Runtime" {
                gcs = component "Global Control Service" "Cluster coordination and state management" "Redis Protocol"
                dashboard = component "Ray Dashboard" "Web UI and REST API for cluster management" "HTTP/HTTPS"
                clientServer = component "Ray Client Server" "Remote job submission endpoint" "Ray Protocol"
                serveProxy = component "Ray Serve Proxy" "HTTP endpoint for model inference" "HTTP/HTTPS"
            }

            rayWorkers = container "Ray Worker Pods" "Distributed compute nodes that execute Ray tasks" "Python/Ray Runtime"

            autoscaler = container "Ray Autoscaler" "Dynamically scales worker pods based on workload" "Python Sidecar"
        }

        kubernetes = softwareSystem "Kubernetes API" "Container orchestration platform" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        registry = softwareSystem "Container Registry" "Stores Ray container images" "External"
        redis = softwareSystem "External Redis" "Optional storage for GCS fault tolerance" "External" {
            tags "Optional"
        }

        openshift = softwareSystem "OpenShift Platform" "Enterprise Kubernetes with Routes and SCC" "External ODH/RHOAI" {
            routes = container "OpenShift Routes" "External access to Ray services"
            oauth = container "OpenShift OAuth" "Authentication for Ray Dashboard"
            scc = container "SecurityContextConstraints" "Pod security enforcement"
        }

        storage = softwareSystem "Cloud Object Storage" "S3, GCS, or Azure Blob storage for Ray applications" "External"
        pypi = softwareSystem "PyPI/Conda" "Python package repositories" "External"

        # Relationships - User interactions
        user -> kubernetes "Creates RayCluster, RayJob, RayService resources via kubectl/oc"
        user -> dashboard "Monitors cluster status, submits jobs" "HTTPS/8265 (via Route/Ingress)"
        user -> serveProxy "Sends inference requests" "HTTPS/8000 (via Route/Ingress)"
        user -> clientServer "Submits remote jobs" "Ray Protocol/10001 (via Route/Ingress)"

        ci -> kubernetes "Automates RayJob and RayService deployments" "HTTPS/6443"

        # Relationships - Operator to Kubernetes
        operator -> kubernetes "Watches CRDs, manages Pods, Services, Ingresses, Routes, Jobs" "HTTPS/6443"
        autoscaler -> kubernetes "Scales worker pods dynamically" "HTTPS/6443"

        # Relationships - Operator to Ray infrastructure
        rayClusterController -> rayHead "Creates and manages head pod"
        rayClusterController -> rayWorkers "Creates and manages worker pods"
        rayClusterController -> autoscaler "Deploys autoscaler sidecar"

        rayJobController -> rayClusterController "Creates temporary RayCluster for jobs"
        rayJobController -> dashboard "Submits jobs via Dashboard API" "HTTP/8265"

        rayServiceController -> rayClusterController "Creates RayCluster for serving"
        rayServiceController -> serveProxy "Manages Ray Serve deployments and health checks" "HTTP/8000"

        # Relationships - Ray cluster internal
        rayWorkers -> gcs "Registers with GCS, coordinates tasks" "Redis/6379"
        autoscaler -> gcs "Queries cluster state for scaling decisions" "Redis/6379"
        dashboard -> gcs "Queries cluster state for UI" "Redis/6379"
        serveProxy -> gcs "Coordinates Ray Serve replicas" "Redis/6379"

        # Relationships - External dependencies
        kubernetes -> registry "Pulls Ray container images" "HTTPS/443"
        operator -> prometheus "Exposes operator metrics" "HTTP/8080"
        prometheus -> operator "Scrapes metrics"

        gcs -> redis "Persists cluster state for HA (optional)" "Redis/6379"

        rayWorkers -> storage "Accesses model artifacts and data" "HTTPS/443"
        rayWorkers -> pypi "Downloads Python packages (user workloads)" "HTTPS/443"

        # Relationships - OpenShift integration
        operator -> routes "Creates Routes for external access"
        rayHead -> oauth "Optional OAuth authentication for Dashboard"
        operator -> scc "Runs with run-as-ray-user SCC (UID 1000)"

        # Optional API server
        apiserver -> rayClusterController "Manages RayCluster resources via gRPC/HTTP" "gRPC/8887"
        apiserver -> rayJobController "Manages RayJob resources" "gRPC/8887"
        apiserver -> rayServiceController "Manages RayService resources" "gRPC/8887"
        user -> apiserver "Simplified cluster management (alternative to kubectl)" "gRPC/8887 or HTTP/8888"
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

        component rayHead "RayHeadComponents" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #1168bd
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "External ODH/RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Optional" {
                opacity 60
                stroke #999999
            }
        }

        theme default
    }
}
