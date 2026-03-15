workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and manages Ray clusters for distributed computing and ML workloads"

        kuberay = softwareSystem "KubeRay Operator" "Manages lifecycle of Ray clusters on Kubernetes" {
            operator = container "KubeRay Operator" "Manages RayCluster, RayJob, and RayService resources" "Go Operator" {
                rayClusterController = component "RayCluster Controller" "Reconciles RayCluster resources, manages head and worker pods"
                rayJobController = component "RayJob Controller" "Reconciles RayJob resources, manages job submission"
                rayServiceController = component "RayService Controller" "Reconciles RayService resources, manages Ray Serve deployments"
                networkPolicyController = component "NetworkPolicy Controller" "Creates and manages NetworkPolicy resources"
                authController = component "Authentication Controller" "Manages OpenShift OAuth integration"
                mtlsController = component "mTLS Controller" "Manages cert-manager Certificates and Issuers"
            }
            webhook = container "Webhook Server" "Validates and mutates RayCluster resources" "Go Admission Controller" {
                validatingWebhook = component "Validating Webhook" "Validates RayCluster on CREATE/UPDATE"
                mutatingWebhook = component "Mutating Webhook" "Mutates RayCluster with defaults"
            }
        }

        rayCluster = softwareSystem "Ray Cluster" "Distributed computing cluster for ML workloads" {
            headPod = container "Ray Head Pod" "Manages cluster state and GCS" "Python Ray"
            workerPods = container "Ray Worker Pods" "Execute distributed tasks" "Python Ray"
        }

        k8s = softwareSystem "Kubernetes API Server" "Orchestration platform" "External"
        certManager = softwareSystem "cert-manager" "Certificate management for mTLS" "External - Optional"
        gatewayAPI = softwareSystem "Gateway API" "Ingress routing configuration" "External - Optional"
        volcano = softwareSystem "Volcano Scheduler" "Gang scheduling for Ray pods" "External - Optional"
        kueue = softwareSystem "Kueue" "Job queueing and quota management" "External - Optional"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        openshiftSvcCA = softwareSystem "OpenShift Service CA" "Webhook certificate provisioning" "External - OpenShift"

        // User interactions
        user -> kuberay "Creates RayCluster, RayJob, RayService via kubectl"
        user -> rayCluster "Submits ML workloads to Ray cluster"

        // Operator interactions
        kuberay -> k8s "Watches and manages CRDs and Kubernetes resources" "HTTPS/6443, TLS 1.2+, Bearer Token"
        webhook -> k8s "Validates/mutates RayCluster resources" "HTTPS/9443, TLS 1.2+, mTLS"

        // Operator manages Ray cluster
        kuberay -> rayCluster "Creates and manages Ray head and worker pods" "HTTP/8265, TCP/6379, TCP/10001"

        // External integrations
        kuberay -> certManager "Requests and manages TLS certificates" "HTTPS/6443 via K8s API"
        kuberay -> gatewayAPI "Creates HTTPRoutes for ingress" "HTTPS/6443 via K8s API"
        kuberay -> volcano "Uses gang scheduling annotations" "HTTPS/6443 via K8s API"
        kuberay -> kueue "Manages job queues" "HTTPS/6443 via K8s API"
        prometheus -> kuberay "Scrapes operator metrics" "HTTP/8080"
        openshiftSvcCA -> webhook "Provisions TLS certificates" "Certificate injection"

        // Ray cluster internal
        rayCluster -> workerPods "Distributes tasks to workers" "TCP/Dynamic, Optional mTLS"
        workerPods -> headPod "Connects to GCS" "TCP/6379, Optional mTLS"
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

        component webhook "KubeRayWebhookComponents" {
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
            element "External - OpenShift" {
                background #ee0000
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #7ed321
                color #ffffff
            }
            element "Component" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}
