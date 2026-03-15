workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Deploys and manages distributed Ray clusters and ML workloads"
        admin = person "Platform Administrator" "Installs and configures KubeRay operator"

        kuberay = softwareSystem "KubeRay Operator" "Manages lifecycle of Ray clusters, jobs, and ML serving on Kubernetes" {
            operator = container "KubeRay Controller" "Reconciles Ray CRDs and manages Ray resources" "Go Operator" {
                rayClusterCtrl = component "RayCluster Controller" "Manages Ray cluster lifecycle, autoscaling, fault tolerance"
                rayJobCtrl = component "RayJob Controller" "Creates clusters and submits batch jobs"
                rayServiceCtrl = component "RayService Controller" "Manages Ray Serve deployments with zero-downtime updates"
                webhook = component "Admission Webhook" "Validates RayCluster CR operations"
                metricsExporter = component "Metrics Exporter" "Exposes operator and cluster metrics"
            }
        }

        rayCluster = softwareSystem "Ray Cluster" "Distributed computing cluster with head and worker nodes" "Managed" {
            headPod = container "Ray Head Pod" "Cluster coordinator with GCS, Dashboard, and autoscaler" "Python/Ray"
            workerPods = container "Ray Worker Pods" "Compute nodes that execute tasks" "Python/Ray"
            gcs = container "Global Control Service (GCS)" "Centralized metadata store and coordination service" "Ray Core"
            dashboard = container "Ray Dashboard" "Web UI and job submission API" "Python/FastAPI"
            serve = container "Ray Serve" "ML model serving framework" "Python/Ray Serve"
        }

        k8s = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management" "External"
        externalRedis = softwareSystem "External Redis" "GCS fault tolerance storage" "External"
        volcano = softwareSystem "Volcano Scheduler" "Gang scheduling for distributed workloads" "External"
        yunikorn = softwareSystem "YuniKorn Scheduler" "Batch scheduling and resource management" "External"
        kueue = softwareSystem "Kueue" "Job queuing and multi-tenancy" "External"

        odhDashboard = softwareSystem "ODH Dashboard" "Data science platform UI" "Internal RHOAI"
        openshift = softwareSystem "OpenShift API" "Red Hat Kubernetes distribution" "Internal RHOAI"

        registry = softwareSystem "Container Registry" "Stores Ray and application container images" "External"
        packageIndex = softwareSystem "Ray Package Index" "Ray runtime dependencies and packages" "External"
        s3 = softwareSystem "S3 / Cloud Storage" "Model artifacts and application data" "External"

        # User interactions
        user -> kuberay "Creates RayCluster, RayJob, RayService via kubectl/oc"
        user -> dashboard "Submits jobs, monitors clusters"
        user -> serve "Sends inference requests to deployed models"
        admin -> kuberay "Installs and configures operator"

        # KubeRay to Kubernetes
        kuberay -> k8s "Manages Pods, Services, Jobs, Ingresses, Routes via API" "HTTPS/443 TLS1.2+"
        webhook -> k8s "Receives validation requests from API server" "HTTPS/9443 mTLS"

        # KubeRay creates Ray Clusters
        rayClusterCtrl -> rayCluster "Creates and manages Ray cluster resources"
        rayJobCtrl -> rayCluster "Creates clusters for batch jobs"
        rayServiceCtrl -> rayCluster "Creates clusters for ML serving"

        # Ray Cluster internal
        headPod -> gcs "Coordinates cluster state"
        workerPods -> gcs "Register and communicate via GCS" "TCP/6379"
        headPod -> dashboard "Hosts dashboard and job API"
        headPod -> serve "Runs Ray Serve for ML inference"

        # External dependencies
        kuberay -> prometheus "Exposes metrics" "HTTP/8080"
        kuberay -> certManager "Requests webhook TLS certificate"
        headPod -> externalRedis "Stores GCS state for fault tolerance" "TCP/6379 (optional)"
        headPod -> k8s "Autoscaler creates/deletes worker Pods" "HTTPS/443"

        # Optional schedulers
        kuberay -> volcano "Uses for gang scheduling (optional)" "Pod annotations"
        kuberay -> yunikorn "Uses for batch scheduling (optional)" "Pod annotations"
        kuberay -> kueue "Uses for job queuing (optional)" "Pod labels"

        # RHOAI integrations
        kuberay -> openshift "Creates Routes for external access"
        odhDashboard -> kuberay "Provides UI for cluster management (optional)"

        # External services
        rayCluster -> registry "Pulls Ray and application images" "HTTPS/443"
        rayCluster -> packageIndex "Downloads Ray dependencies" "HTTPS/443"
        rayCluster -> s3 "Reads/writes data and model artifacts" "HTTPS/443"
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

        dynamic kuberay "RayClusterCreation" "RayCluster creation and lifecycle" {
            user -> kuberay "1. Creates RayCluster CR"
            kuberay -> k8s "2. Validates via webhook"
            kuberay -> k8s "3. Creates head Pod"
            kuberay -> k8s "4. Creates worker Pods"
            kuberay -> k8s "5. Creates Services"
            rayCluster -> gcs "6. Workers register with GCS"
            autoLayout
        }

        dynamic kuberay "RayJobExecution" "RayJob batch execution flow" {
            user -> kuberay "1. Creates RayJob CR"
            kuberay -> k8s "2. Creates RayCluster"
            kuberay -> k8s "3. Creates submitter K8s Job"
            k8s -> dashboard "4. Job submits work to Dashboard API"
            dashboard -> gcs "5. Distributes work to workers"
            autoLayout
        }

        dynamic kuberay "RayServiceDeployment" "RayService zero-downtime update" {
            kuberay -> k8s "1. Creates RayCluster v1"
            kuberay -> serve "2. Deploys Serve app"
            user -> serve "3. Sends inference requests"
            kuberay -> k8s "4. Creates RayCluster v2"
            kuberay -> k8s "5. Updates Service to v2"
            kuberay -> k8s "6. Deletes RayCluster v1"
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
            element "Managed" {
                background #9673a6
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Component" {
                background #6c8ebf
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }

        theme default
    }
}
