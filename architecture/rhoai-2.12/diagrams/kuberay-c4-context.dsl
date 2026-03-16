workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and manages Ray clusters for distributed ML/AI workloads"
        admin = person "Platform Administrator" "Deploys and manages KubeRay operator"

        kuberay = softwareSystem "KubeRay Operator" "Kubernetes operator for deploying and managing Ray clusters on Kubernetes for distributed ML/AI workloads" {
            operator = container "KubeRay Operator" "Manages Ray cluster lifecycle, autoscaling, and high availability" "Go Operator" {
                rayClusterController = component "RayCluster Controller" "Reconciles RayCluster CRs, manages head/worker pods, services" "Go Controller"
                rayJobController = component "RayJob Controller" "Manages batch job execution on Ray clusters" "Go Controller"
                rayServiceController = component "RayService Controller" "Manages Ray Serve deployments with HA and zero-downtime updates" "Go Controller"
                webhook = component "Validating Webhook" "Validates RayCluster CR CREATE/UPDATE operations" "Admission Webhook"
            }

            rayCluster = container "Ray Cluster" "Distributed compute cluster for ML/AI workloads" "Ray Runtime" {
                headPod = component "Ray Head Pod" "GCS server, dashboard, client interface" "Ray Head"
                workerPods = component "Ray Worker Pods" "Execute distributed tasks" "Ray Workers"
                headService = component "Head Service" "ClusterIP exposing GCS, dashboard, client ports" "Kubernetes Service"
                serveService = component "Serve Service" "HTTP endpoints for Ray Serve" "Kubernetes Service"
            }
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        openshift = softwareSystem "OpenShift" "Red Hat Kubernetes platform with Routes and SCCs" "External"
        volcano = softwareSystem "Volcano Scheduler" "Gang scheduling and batch job scheduling" "External - Optional"
        certManager = softwareSystem "cert-manager" "TLS certificate management for webhooks" "External - Optional"
        containerRegistry = softwareSystem "Container Registry" "Stores Ray container images" "External"
        externalStorage = softwareSystem "External Storage" "Redis/S3 for GCS fault tolerance" "External - Optional"
        prometheus = softwareSystem "Prometheus" "Monitoring and metrics collection" "External"

        # User interactions
        user -> kuberay "Creates RayCluster, RayJob, RayService CRs via kubectl/oc"
        user -> rayCluster "Submits jobs, monitors via Ray Dashboard"
        admin -> kuberay "Deploys and configures operator"

        # KubeRay dependencies
        kuberay -> kubernetes "Manages pods, services, ingress, RBAC" "HTTPS/443 TLS 1.3"
        kuberay -> openshift "Creates Routes, uses SCCs" "HTTPS/443 TLS 1.3"
        kuberay -> volcano "Gang scheduling for Ray pods (optional)" "Kubernetes API"
        kuberay -> certManager "TLS certificate provisioning (optional)" "Kubernetes API"
        kuberay -> containerRegistry "Pulls Ray container images" "HTTPS/443 TLS 1.2+"

        # Ray Cluster dependencies
        rayCluster -> externalStorage "Stores GCS state for fault tolerance (optional)" "HTTPS/443 TLS 1.2+"
        prometheus -> kuberay "Scrapes operator metrics" "HTTP/8080"
        prometheus -> rayCluster "Scrapes Ray cluster metrics" "HTTP/8080"

        # Internal relationships
        operator -> rayCluster "Creates and manages" "Kubernetes API"
        rayClusterController -> headPod "Creates and monitors"
        rayClusterController -> workerPods "Creates and scales"
        rayJobController -> rayCluster "Creates ephemeral clusters for jobs"
        rayServiceController -> serveService "Manages with zero-downtime updates"
        workerPods -> headPod "Connects to GCS" "TCP/6379"
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
            element "External - Optional" {
                background #cccccc
                color #333333
            }
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
        }

        themes default
    }
}
