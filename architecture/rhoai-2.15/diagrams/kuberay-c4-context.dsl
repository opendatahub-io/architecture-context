workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and manages distributed Ray workloads for ML training, inference, and batch processing"

        odhDashboard = person "ODH Dashboard User" "Manages Ray clusters through OpenShift Data Hub UI"

        kuberay = softwareSystem "KubeRay Operator" "Kubernetes operator that manages the lifecycle of Ray distributed computing clusters, jobs, and services" {
            operator = container "KubeRay Operator" "Main controller managing Ray CRDs and Kubernetes resources" "Go, controller-runtime" {
                rayClusterController = component "RayCluster Controller" "Manages lifecycle of Ray clusters including head and worker pods" "Go Reconciler"
                rayJobController = component "RayJob Controller" "Manages Ray job submission and execution on Ray clusters" "Go Reconciler"
                rayServiceController = component "RayService Controller" "Manages Ray Serve deployments with zero-downtime upgrades" "Go Reconciler"
            }

            rayCluster = container "Ray Cluster (Managed)" "Distributed Ray computing cluster" "Ray 2.9.0+" {
                rayHead = component "Ray Head Pod" "Ray cluster head node running GCS, dashboard, and client server" "Python/Ray"
                rayWorkers = component "Ray Worker Pods" "Ray cluster worker nodes for distributed computation" "Python/Ray"
                autoscaler = component "Autoscaler Sidecar" "Optional Ray autoscaler for dynamic worker scaling" "Python"
            }
        }

        k8s = softwareSystem "Kubernetes API Server" "Container orchestration platform (1.25+)" "External"
        prometheus = softwareSystem "Prometheus" "Monitoring and metrics collection" "Internal ODH"
        odhOperator = softwareSystem "ODH Operator" "OpenShift Data Hub operator managing component lifecycle" "Internal ODH"

        externalRedis = softwareSystem "External Redis" "External Redis for GCS fault tolerance" "External (Optional)"
        containerRegistry = softwareSystem "Container Registry" "Storage for Ray container images" "External"
        volcano = softwareSystem "Volcano Scheduler" "Gang scheduling for distributed workloads" "External (Optional)"

        serviceCA = softwareSystem "OpenShift Service CA" "TLS certificate management" "Internal ODH (Optional)"
        pipelines = softwareSystem "Data Science Pipelines" "Kubeflow Pipelines for ML workflow orchestration" "Internal ODH (Optional)"

        # User interactions
        user -> kuberay "Creates RayCluster, RayJob, RayService via kubectl/oc"
        odhDashboard -> kuberay "Manages Ray clusters via UI"

        # Operator interactions
        kuberay -> k8s "Watches CRDs, manages pods/services/RBAC" "HTTPS/443, ServiceAccount Token"
        kuberay -> prometheus "Exposes metrics" "HTTP/8080"
        odhOperator -> kuberay "Installs and manages deployment" "CRD Management"

        # Ray Cluster interactions
        operator -> rayCluster "Creates and manages lifecycle"
        rayClusterController -> rayHead "Creates and configures"
        rayClusterController -> rayWorkers "Creates and scales"
        rayJobController -> rayHead "Submits jobs via Dashboard API" "HTTP/8265"
        rayServiceController -> rayHead "Deploys Serve applications via Dashboard API" "HTTP/8265"

        rayWorkers -> rayHead "Register with GCS, execute tasks" "Redis Protocol/6379"
        autoscaler -> rayHead "Query metrics" "Redis Protocol/6379"
        autoscaler -> k8s "Scale worker replicas" "HTTPS/443"

        # External dependencies
        rayHead -> externalRedis "Persist GCS state (optional)" "Redis Protocol/6379, Optional TLS, Password"
        k8s -> containerRegistry "Pull Ray images" "HTTPS/443, Pull Secrets"
        kuberay -> volcano "Gang scheduling (optional)" "HTTPS/443, CRD API"
        serviceCA -> kuberay "Provide TLS certificates (optional)" "TLS Cert Provisioning"

        # Integration points
        pipelines -> kuberay "Orchestrate Ray jobs (optional)" "Kubernetes API"

        # User access to Ray services
        user -> rayHead "Access Ray Dashboard, submit jobs, query status" "HTTP/8265, gRPC/10001"
        user -> rayCluster "Send inference requests to Ray Serve" "HTTP/8000"
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

        component operator "KubeRayOperatorComponents" {
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
            element "External (Optional)" {
                background #cccccc
                color #000000
                stroke #999999
                strokeWidth 2
            }
            element "Internal ODH (Optional)" {
                background #d5e8d4
                color #000000
                stroke #82b366
                strokeWidth 2
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
    }
}
