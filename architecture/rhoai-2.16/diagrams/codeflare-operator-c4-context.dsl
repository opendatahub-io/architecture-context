workspace {
    model {
        user = person "Data Scientist" "Creates and manages distributed ML/AI workloads using Ray clusters"

        codeflare = softwareSystem "CodeFlare Operator" "Manages lifecycle of CodeFlare distributed workload stack including RayCluster and AppWrapper resources" {
            controller = container "Controller Manager" "Manages RayCluster and AppWrapper lifecycle, injects security features" "Go Operator" {
                rayController = component "RayCluster Controller" "Reconciles RayCluster resources, injects OAuth proxy, creates network policies and routes" "Go Controller"
                appWrapperController = component "AppWrapper Controller" "Manages AppWrapper resources for batch job scheduling (conditionally enabled)" "Go Controller"
                mutatingWebhook = component "Mutating Webhook" "Mutates RayCluster and AppWrapper resources on CREATE operations" "Go Admission Webhook"
                validatingWebhook = component "Validating Webhook" "Validates RayCluster and AppWrapper resources on CREATE/UPDATE operations" "Go Admission Webhook"
            }
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics" "HTTP Server (port 8080)"
            healthServer = container "Health Server" "Provides liveness and readiness probes" "HTTP Server (port 8081)"
        }

        rayCluster = softwareSystem "RayCluster Resources" "Distributed Ray clusters for ML/AI workloads created and managed per user request" "User Workload" {
            rayHead = container "Ray Head Pod" "Ray cluster head node with dashboard and client API" "Python Ray"
            rayWorkers = container "Ray Worker Pods" "Ray cluster worker nodes for distributed computation" "Python Ray"
            oauthProxy = container "OAuth Proxy Sidecar" "Secures Ray dashboard with OpenShift OAuth authentication (OpenShift only)" "oauth-proxy"
        }

        kuberay = softwareSystem "KubeRay Operator" "Provides RayCluster CRD and base reconciliation logic" "External Operator" {
            tags "External"
        }

        kueue = softwareSystem "Kueue" "Provides workload queuing and resource management for AppWrapper" "External Operator" {
            tags "External" "Conditional"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "Infrastructure" {
            apiServer = container "Kubernetes API Server" "Provides Kubernetes API and admission control" "K8s Control Plane"
            tags "External"
        }

        openshift = softwareSystem "OpenShift Platform" "Enterprise Kubernetes platform with additional security features" "Infrastructure" {
            oauthServer = container "OAuth Server" "Authenticates users for OpenShift resources" "OpenShift Authentication"
            router = container "OpenShift Router" "Provides external ingress routing with TLS termination" "HAProxy"
            tags "External" "Optional"
        }

        certController = softwareSystem "cert-controller" "Manages webhook TLS certificate rotation" "Certificate Manager" {
            tags "External"
        }

        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Monitoring" {
            tags "Internal ODH"
        }

        odhOperator = softwareSystem "opendatahub-operator" "Manages ODH/RHOAI platform components" "Platform Operator" {
            tags "Internal ODH"
        }

        # User relationships
        user -> codeflare "Creates RayCluster and AppWrapper CRs via kubectl/oc" "HTTPS/6443 (Kubernetes API)"
        user -> rayCluster "Accesses Ray dashboard and submits workloads" "HTTPS/443 (Route) or mTLS/10001 (Ray client)"

        # CodeFlare to Ray resources
        controller -> rayCluster "Creates and manages Ray pods, services, routes, network policies" "HTTPS/6443 (Kubernetes API)"
        rayController -> oauthProxy "Injects as sidecar (OpenShift only)" "Pod Spec Mutation"
        rayController -> rayHead "Creates NetworkPolicies for isolation" "Kubernetes API"
        rayController -> rayWorkers "Creates NetworkPolicies for isolation" "Kubernetes API"

        # CodeFlare dependencies
        controller -> kuberay "Coordinates RayCluster reconciliation" "HTTPS/6443 (Kubernetes API)"
        appWrapperController -> kueue "Creates Workload CRs for scheduling" "HTTPS/6443 (Kubernetes API)"
        controller -> kubernetes "Watches CRDs, creates resources" "HTTPS/6443 (ServiceAccount Token)"
        mutatingWebhook -> kubernetes "Receives admission requests" "HTTPS/9443 (mTLS)"
        validatingWebhook -> kubernetes "Receives admission requests" "HTTPS/9443 (mTLS)"
        controller -> certController "Uses for webhook certificate management" "Certificate provisioning"
        controller -> odhOperator "Reads DSCInitialization for namespace discovery" "HTTPS/6443 (Kubernetes API)"
        metricsServer -> prometheus "Scraped for metrics" "HTTP/8080"

        # Ray cluster dependencies
        oauthProxy -> oauthServer "Authenticates dashboard users (OpenShift only)" "HTTPS/443 (OAuth2)"
        rayCluster -> router "Exposes dashboard and client port externally (OpenShift)" "HTTPS/443, mTLS/10001"
        rayHead -> rayWorkers "Distributes workload tasks" "mTLS (when enabled) or TCP"

        # OpenShift integration
        user -> router "Accesses Ray dashboard via browser" "HTTPS/443"
        router -> oauthProxy "Routes dashboard traffic with TLS termination" "HTTPS/8443"
        oauthProxy -> rayHead "Proxies authenticated requests" "HTTP/8265"
    }

    views {
        systemContext codeflare "SystemContext" {
            include *
            autoLayout
        }

        container codeflare "CodeFlareContainers" {
            include *
            autoLayout
        }

        container rayCluster "RayClusterContainers" {
            include *
            autoLayout
        }

        component controller "ControllerComponents" {
            include *
            autoLayout
        }

        dynamic codeflare "CreateRayCluster" "User creates a RayCluster resource" {
            user -> apiServer "1. POST RayCluster CR (kubectl apply)"
            apiServer -> mutatingWebhook "2. Admission webhook mutation"
            apiServer -> validatingWebhook "3. Admission webhook validation"
            apiServer -> rayController "4. Watch event (RayCluster CREATE)"
            rayController -> apiServer "5. Create OAuth proxy deployment"
            rayController -> apiServer "6. Create NetworkPolicies"
            rayController -> apiServer "7. Create Routes/Ingress"
            rayController -> apiServer "8. Create Secrets (OAuth, TLS, CA)"
            rayController -> kuberay "9. Coordinate with KubeRay operator"
            kuberay -> apiServer "10. Create Ray head and worker pods"
            autoLayout
        }

        dynamic rayCluster "AccessDashboard" "User accesses Ray dashboard on OpenShift" {
            user -> router "1. HTTPS request to dashboard route"
            router -> oauthProxy "2. Route to OAuth proxy with TLS termination"
            oauthProxy -> oauthServer "3. OAuth authentication flow"
            oauthServer -> oauthProxy "4. Return OAuth token"
            oauthProxy -> rayHead "5. Proxy request to Ray dashboard (HTTP)"
            rayHead -> oauthProxy "6. Dashboard response"
            oauthProxy -> router "7. HTTPS response"
            router -> user "8. Display dashboard"
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
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Optional" {
                border dashed
            }
            element "Conditional" {
                border dashed
            }
            element "User Workload" {
                background #f5a623
                color #000000
            }
            element "Infrastructure" {
                background #666666
                color #ffffff
            }
        }
    }
}
