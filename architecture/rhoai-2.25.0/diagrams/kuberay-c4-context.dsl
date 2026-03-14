workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and manages Ray clusters for distributed computing and ML workloads"
        admin = person "Platform Administrator" "Deploys and configures KubeRay operator"

        kuberay = softwareSystem "KubeRay Operator" "Manages lifecycle of Ray clusters, jobs, and services on Kubernetes" {
            operator = container "kuberay-operator" "Main controller managing RayCluster, RayJob, RayService CRDs" "Go Operator"
            rayClusterCtrl = container "RayCluster Controller" "Reconciles RayCluster resources, manages pods and services" "Go Controller"
            rayJobCtrl = container "RayJob Controller" "Creates RayClusters and submits batch jobs" "Go Controller"
            rayServiceCtrl = container "RayService Controller" "Manages Ray Serve deployments with zero-downtime updates" "Go Controller"
            webhook = container "Admission Webhook" "Validates RayCluster CR create/update operations" "Go ValidatingWebhook"
            metrics = container "Metrics Exporter" "Exposes Prometheus metrics" "HTTP Endpoint"
        }

        rayCluster = softwareSystem "Ray Cluster (Managed)" "Distributed computing cluster with head and worker nodes" {
            headPod = container "Ray Head Pod" "Coordinates Ray cluster via GCS, hosts dashboard and job submission API" "Python/Ray"
            workerPods = container "Ray Worker Pods" "Execute distributed tasks, auto-scale based on demand" "Python/Ray"
            serveRuntime = container "Ray Serve Runtime" "ML model serving with HTTP API" "Python/Ray Serve"
        }

        kubernetes = softwareSystem "Kubernetes / OpenShift" "Container orchestration platform" "External Platform"
        certManager = softwareSystem "cert-manager" "TLS certificate management" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        redis = softwareSystem "External Redis" "GCS fault tolerance storage" "External Database"
        volcano = softwareSystem "Volcano Scheduler" "Gang scheduling for distributed workloads" "External"
        kueue = softwareSystem "Kueue" "Job queuing and resource management" "External"
        registry = softwareSystem "Container Registry" "Stores Ray and application container images" "External"
        storage = softwareSystem "Object Storage (S3/GCS/Git)" "Model artifacts and application code storage" "External"
        dashboard = softwareSystem "ODH Dashboard" "UI for managing Ray clusters" "Internal ODH"

        # Relationships
        user -> kuberay "Creates RayCluster, RayJob, RayService CRs via kubectl/UI"
        user -> rayCluster "Submits distributed jobs, queries Ray Dashboard"
        admin -> kuberay "Deploys and configures operator"

        operator -> rayClusterCtrl "Manages"
        operator -> rayJobCtrl "Manages"
        operator -> rayServiceCtrl "Manages"
        operator -> webhook "Exposes"
        operator -> metrics "Exposes"

        rayClusterCtrl -> rayCluster "Creates and manages Ray head/worker pods"
        rayJobCtrl -> rayCluster "Creates RayCluster and submitter jobs"
        rayServiceCtrl -> rayCluster "Manages Ray Serve deployments"

        kuberay -> kubernetes "Creates Pods, Services, Jobs, Ingress/Routes via API" "HTTPS/443 (ServiceAccount token)"
        kubernetes -> webhook "Validates RayCluster CRs" "HTTPS/9443 (mTLS)"
        kuberay -> certManager "Requests webhook TLS certificates" "Certificate CR"
        prometheus -> kuberay "Scrapes metrics" "HTTP/8080"

        rayCluster -> redis "Stores GCS state for fault tolerance" "TCP/6379 (Redis password)"
        rayCluster -> kubernetes "Autoscaling: Creates/deletes worker pods" "HTTPS/443 (ServiceAccount token)"
        rayCluster -> registry "Pulls container images" "HTTPS/443 (Pull secrets)"
        rayCluster -> storage "Fetches application code and data" "HTTPS/443"

        workerPods -> headPod "Registers to GCS, executes tasks" "TCP/6379"
        headPod -> serveRuntime "Deploys ML model serving applications" "Internal"

        dashboard -> kuberay "Optional UI integration for cluster management" "Kubernetes API"
        kuberay -> volcano "Uses gang scheduling" "Pod annotations"
        kuberay -> kueue "Uses job queuing" "Pod labels/annotations"
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

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Platform" {
                background #666666
                color #ffffff
            }
            element "External Database" {
                background #ff9900
                color #ffffff
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
        }
    }
}
