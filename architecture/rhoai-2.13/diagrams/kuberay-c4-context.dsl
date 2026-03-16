workspace {
    model {
        # People
        dataScientist = person "Data Scientist" "Creates and manages Ray clusters for distributed ML workloads"
        mlEngineer = person "ML Engineer" "Deploys Ray Serve applications for model inference"
        externalClient = person "External Client" "Consumes ML inference APIs"

        # KubeRay System
        kuberay = softwareSystem "KubeRay Operator" "Manages Ray cluster lifecycle on Kubernetes/OpenShift for distributed ML and AI workloads" {
            operator = container "KubeRay Operator" "Reconciles RayCluster, RayJob, RayService CRDs" "Go Operator" {
                tags "Operator"
            }
            webhook = container "Validating Webhook" "Validates RayCluster resource specifications" "Go Service" {
                tags "Webhook"
            }
            rayHead = container "Ray Head Pod" "GCS server, dashboard, and scheduler for Ray cluster" "Python/Ray" {
                tags "RayCluster"
            }
            rayWorker = container "Ray Worker Pods" "Execute distributed tasks in Ray cluster" "Python/Ray" {
                tags "RayCluster"
            }
            autoscaler = container "Ray Autoscaler" "Automatically scales worker pods based on workload" "Python Sidecar" {
                tags "Autoscaler"
            }
        }

        # External Systems - Kubernetes Platform
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" {
            tags "External" "Platform"
        }

        # External Systems - Dependencies
        certManager = softwareSystem "cert-manager" "TLS certificate management for webhooks and clusters" {
            tags "External" "Security"
        }
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" {
            tags "External" "Monitoring"
        }
        istio = softwareSystem "Service Mesh (Istio)" "mTLS and traffic management for Ray services" {
            tags "External" "Optional"
        }
        volcano = softwareSystem "Volcano Scheduler" "Gang scheduling for batch workloads" {
            tags "External" "Optional"
        }

        # External Systems - Storage
        redis = softwareSystem "External Redis" "GCS fault tolerance and state persistence" {
            tags "External" "Storage" "Optional"
        }
        s3 = softwareSystem "S3 / Object Storage" "Model artifacts, checkpointing, and object spilling" {
            tags "External" "Storage"
        }

        # Internal RHOAI/ODH Systems
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for creating and managing Ray clusters" {
            tags "Internal" "ODH"
        }
        registry = softwareSystem "Container Registry" "Stores Ray container images" {
            tags "External" "Infrastructure"
        }

        # User Interactions
        dataScientist -> kuberay "Creates RayCluster and RayJob CRs via kubectl/Dashboard"
        mlEngineer -> kuberay "Deploys RayService for model serving"
        externalClient -> kuberay "Sends inference requests to Ray Serve endpoints" "HTTPS/443"

        # KubeRay Internal Interactions
        operator -> webhook "Validates CRs before creation/update" "HTTPS/9443, mTLS"
        operator -> rayHead "Creates and manages Ray head pods"
        operator -> rayWorker "Creates and manages Ray worker pods"
        autoscaler -> rayHead "Monitors cluster state for scaling decisions" "HTTP/8265"
        rayWorker -> rayHead "Connects to GCS for task coordination" "TCP/6379"

        # KubeRay to External Platform
        kuberay -> kubernetes "Manages pods, services, and CRDs" "HTTPS/6443"
        operator -> kubernetes "Watches CRs and reconciles resources" "HTTPS/6443, ServiceAccount Token"
        autoscaler -> kubernetes "Scales worker pods via API" "HTTPS/6443, ServiceAccount Token"

        # KubeRay to External Dependencies
        kuberay -> certManager "Provisions TLS certificates for webhooks" "Kubernetes API"
        kuberay -> prometheus "Exposes operator and Ray cluster metrics" "HTTP/8080"
        kuberay -> istio "Uses for mTLS and traffic routing" "Optional"
        kuberay -> volcano "Uses for gang scheduling" "Optional"

        # KubeRay to External Storage
        rayHead -> redis "Stores GCS state for fault tolerance" "TCP/6379, Optional TLS, Password"
        rayHead -> s3 "Loads models and checkpoints" "HTTPS/443, AWS IAM"
        rayWorker -> s3 "Loads data and models" "HTTPS/443, AWS IAM"

        # KubeRay to Internal ODH
        odhDashboard -> kuberay "Provides UI for cluster management" "Kubernetes API"

        # Infrastructure
        operator -> registry "Pulls Ray container images" "HTTPS/443, Pull Secrets"
    }

    views {
        systemContext kuberay "KubeRaySystemContext" {
            include *
            autoLayout lr
            title "KubeRay Operator - System Context"
            description "System context diagram showing KubeRay's role in the RHOAI ecosystem for distributed ML workloads"
        }

        container kuberay "KubeRayContainers" {
            include *
            autoLayout lr
            title "KubeRay Operator - Container Diagram"
            description "Container diagram showing internal components of the KubeRay operator and Ray cluster"
        }

        styles {
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "ODH" {
                background #7ed321
                color #ffffff
            }
            element "Optional" {
                border dashed
            }
            element "Operator" {
                background #4a90e2
                color #ffffff
            }
            element "Webhook" {
                background #4a90e2
                color #ffffff
            }
            element "RayCluster" {
                background #e67e22
                color #ffffff
            }
            element "Autoscaler" {
                background #9b59b6
                color #ffffff
            }
            element "Platform" {
                background #34495e
                color #ffffff
            }
            element "Security" {
                background #e74c3c
                color #ffffff
            }
            element "Monitoring" {
                background #3498db
                color #ffffff
            }
            element "Storage" {
                background #f39c12
                color #ffffff
            }
            element "Infrastructure" {
                background #95a5a6
                color #ffffff
            }
        }

        theme default
    }
}
