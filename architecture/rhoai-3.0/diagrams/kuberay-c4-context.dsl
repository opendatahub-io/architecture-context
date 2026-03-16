workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Deploys and manages Ray clusters for distributed computing and ML workloads"
        admin = person "Platform Administrator" "Manages KubeRay operator and platform configuration"

        kuberay = softwareSystem "KubeRay Operator" "Kubernetes operator managing Ray cluster lifecycle" {
            operator = container "KubeRay Operator" "Manages RayCluster, RayJob, RayService CRDs" "Go Operator" {
                rayClusterController = component "RayCluster Controller" "Reconciles RayCluster resources" "Go Controller"
                rayJobController = component "RayJob Controller" "Reconciles RayJob resources" "Go Controller"
                rayServiceController = component "RayService Controller" "Reconciles RayService resources" "Go Controller"
                networkPolicyController = component "NetworkPolicy Controller" "Creates NetworkPolicies for Ray clusters" "Go Controller"
                authController = component "Authentication Controller" "Manages OpenShift OAuth and Gateway API" "Go Controller"
                mtlsController = component "mTLS Controller" "Manages cert-manager certificates" "Go Controller"
            }
            webhook = container "Webhook Server" "Validates and mutates RayCluster resources" "Go HTTPS Server" {
                validatingWebhook = component "Validating Webhook" "Validates RayCluster CREATE/UPDATE" "Admission Controller"
                mutatingWebhook = component "Mutating Webhook" "Mutates RayCluster resources" "Admission Controller"
            }
            metrics = container "Metrics Endpoint" "Exposes Prometheus metrics" "HTTP Endpoint"
        }

        rayCluster = softwareSystem "Ray Cluster" "Distributed computing cluster managed by KubeRay" {
            rayHead = container "Ray Head Node" "Coordinates Ray cluster (GCS, Dashboard, Client server)" "Ray Runtime"
            rayWorkers = container "Ray Worker Nodes" "Execute distributed tasks" "Ray Runtime"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External Platform"
        certManager = softwareSystem "cert-manager" "Certificate management for Kubernetes" "Optional External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal ODH"
        openShiftServiceCA = softwareSystem "OpenShift Service CA" "Automatic certificate provisioning for services" "OpenShift Feature"
        openShiftRouteAPI = softwareSystem "OpenShift Route API" "Ingress routing for OpenShift" "Optional External"
        gatewayAPI = softwareSystem "Gateway API" "Advanced ingress and traffic management" "Optional External"
        volcano = softwareSystem "Volcano Scheduler" "Gang scheduling for batch workloads" "Optional External"
        yunikorn = softwareSystem "Yunikorn Scheduler" "Advanced batch scheduling" "Optional External"
        kueue = softwareSystem "Kueue" "Job queueing and quota management" "Optional External"

        # User relationships
        user -> kuberay "Creates RayCluster, RayJob, RayService via kubectl/oc"
        admin -> kuberay "Deploys and configures operator"

        # KubeRay operator relationships
        kuberay -> kubernetes "Watches CRDs, manages Kubernetes resources (Pods, Services, etc.)" "HTTPS/6443 TLS 1.2+"
        kuberay -> rayCluster "Creates and manages Ray clusters" "HTTP/8265, TCP/6379, TCP/10001"
        kuberay -> certManager "Requests TLS certificates for Ray cluster mTLS" "Kubernetes API/6443"
        kuberay -> openShiftRouteAPI "Creates Routes for Ray cluster ingress" "Kubernetes API/6443"
        kuberay -> gatewayAPI "Creates HTTPRoutes for advanced routing" "Kubernetes API/6443"
        kuberay -> volcano "Adds gang scheduling annotations to Ray pods" "Kubernetes API/6443"
        kuberay -> kueue "Integrates RayJobs with job queue" "Kubernetes API/6443"

        kubernetes -> webhook "Invokes admission webhooks on RayCluster CREATE/UPDATE" "HTTPS/9443 mTLS"
        prometheus -> metrics "Scrapes operator metrics" "HTTP/8080"
        openShiftServiceCA -> webhook "Provisions TLS certificates for webhook server" "Certificate Injection"
        certManager -> rayCluster "Provisions mTLS certificates for Ray internal communication" "Secret Injection"

        # Ray cluster internal
        rayWorkers -> rayHead "Connects to GCS for cluster coordination" "TCP/6379 Optional mTLS"

        # Deployment relationships
        deploymentEnvironment "Production" {
            deploymentNode "OpenShift Cluster" {
                deploymentNode "opendatahub Namespace" {
                    operatorInstance = containerInstance operator
                    webhookInstance = containerInstance webhook
                    metricsInstance = containerInstance metrics
                }
                deploymentNode "{user-namespace} Namespace" {
                    rayHeadInstance = containerInstance rayHead
                    rayWorkersInstance = containerInstance rayWorkers
                }
            }
        }
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

        deployment rayCluster "Production" "RayClusterDeployment" {
            include *
            autoLayout
        }

        styles {
            element "External Platform" {
                background #999999
                color #ffffff
            }
            element "Optional External" {
                background #cccccc
                color #000000
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "OpenShift Feature" {
                background #ee0000
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
        }
    }
}
