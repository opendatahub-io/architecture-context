workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages Ray clusters for ML/data processing workloads"
        mlEngineer = person "ML Engineer" "Deploys Ray Serve applications for model inference"

        kuberay = softwareSystem "KubeRay Operator" "Kubernetes operator that manages Ray cluster lifecycle, jobs, and serving workloads" {
            operator = container "kuberay-operator" "Reconciles RayCluster, RayJob, and RayService custom resources" "Go Controller Manager" {
                rayClusterController = component "RayCluster Controller" "Manages Ray cluster lifecycle, head/worker pods, autoscaling" "Go Controller"
                rayJobController = component "RayJob Controller" "Manages batch job submission and cluster lifecycle" "Go Controller"
                rayServiceController = component "RayService Controller" "Manages Ray Serve deployments with zero-downtime upgrades" "Go Controller"
                serviceBuilder = component "Service Builder" "Creates Kubernetes Services and OpenShift Routes" "Utility"
                rbacManager = component "RBAC Manager" "Creates ServiceAccounts, Roles, RoleBindings" "Utility"
            }

            rayHead = container "Ray Head Pod" "Ray cluster coordinator with GCS, Dashboard, and Client API" "Ray Runtime" {
                gcs = component "Global Control Service (GCS)" "Ray cluster coordination and metadata" "Ray Core"
                dashboard = component "Ray Dashboard" "Cluster monitoring and job status UI" "Ray Dashboard"
                clientAPI = component "Ray Client API" "Remote job submission interface" "Ray Client"
            }

            rayWorker = container "Ray Worker Pods" "Distributed compute nodes for Ray tasks" "Ray Runtime"
            rayServe = container "Ray Serve" "ML model inference serving framework" "Ray Serve"
        }

        k8s = softwareSystem "Kubernetes API Server" "Container orchestration platform" "External"
        registry = softwareSystem "Container Registry" "Ray container image storage" "External"
        s3 = softwareSystem "S3/GCS Storage" "Object storage for Ray data, checkpoints, and model artifacts" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        volcano = softwareSystem "Volcano Scheduler" "Optional batch scheduler for gang scheduling" "External"
        externalRedis = softwareSystem "External Redis" "Optional external GCS fault tolerance backend" "External"

        # Relationships - Users
        dataScientist -> kuberay "Creates RayCluster and RayJob via kubectl"
        mlEngineer -> kuberay "Creates RayService for model serving via kubectl"
        dataScientist -> rayHead "Submits jobs, views dashboard" "gRPC/HTTP"
        mlEngineer -> rayServe "Sends inference requests" "HTTP/HTTPS"

        # Relationships - Operator
        kuberay -> k8s "Watches CRDs, manages pods/services/routes" "HTTPS/443"
        operator -> k8s "Reconciles resources" "HTTPS/443"
        operator -> rayClusterController "Delegates RayCluster reconciliation"
        operator -> rayJobController "Delegates RayJob reconciliation"
        operator -> rayServiceController "Delegates RayService reconciliation"
        rayClusterController -> serviceBuilder "Creates services/routes"
        rayClusterController -> rbacManager "Creates RBAC resources"

        # Relationships - Ray Components
        rayHead -> gcs "Runs GCS service"
        rayHead -> dashboard "Runs dashboard UI"
        rayHead -> clientAPI "Runs client API"
        rayWorker -> gcs "Registers with GCS, receives tasks" "Ray Protocol/6379"
        rayServe -> gcs "Registers serve replicas" "Ray Protocol/6379"

        # Relationships - External Services
        k8s -> registry "Pulls Ray container images" "HTTPS/443"
        rayHead -> s3 "Stores/retrieves objects, checkpoints" "HTTPS/443"
        rayWorker -> s3 "Stores/retrieves data and model artifacts" "HTTPS/443"
        rayServe -> s3 "Loads model artifacts" "HTTPS/443"
        prometheus -> operator "Scrapes operator metrics" "HTTP/8080"
        prometheus -> dashboard "Scrapes cluster metrics" "HTTP/8265"
        gcs -> externalRedis "Optional fault tolerance backend" "Redis/6379"
        rayJobController -> volcano "Optional gang scheduling integration" "HTTPS/443"
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

        component rayHead "RayHeadComponents" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
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
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }

        theme default
    }
}
