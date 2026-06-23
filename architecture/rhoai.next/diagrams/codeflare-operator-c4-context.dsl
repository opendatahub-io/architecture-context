workspace {
    model {
        dataScientist = person "Data Scientist" "Creates RayClusters for distributed AI/ML workloads"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and operator configuration"

        codeflareOperator = softwareSystem "CodeFlare Operator" "Manages RayCluster lifecycle with OAuth proxy, mTLS certificates, Routes, and NetworkPolicies for enterprise security" {
            rayClusterController = container "RayCluster Controller" "Reconciles RayCluster CRs to provision OAuth proxy, mTLS certs, Routes, NetworkPolicies" "Go (controller-runtime)"
            rayClusterWebhook = container "RayCluster Webhook" "Injects oauth-proxy sidecar and mTLS init containers; validates immutability of injected resources" "Mutating + Validating Webhook"
            appWrapperController = container "AppWrapper Controller" "Manages AppWrapper CR lifecycle with Kueue integration for workload queuing and gang scheduling" "Go (embedded library)"
            appWrapperWebhook = container "AppWrapper Webhook" "Validates and defaults AppWrapper resources" "Mutating + Validating Webhook"
            certController = container "cert-controller" "Manages webhook TLS certificate rotation" "open-policy-agent/cert-controller"
        }

        kuberayOperator = softwareSystem "KubeRay Operator" "Provisions and manages actual Ray cluster pods from RayCluster CRs" "Internal RHOAI"
        opendatahubOperator = softwareSystem "OpenDataHub Operator" "Platform operator providing DSCInitialization CR for namespace discovery" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Workload queuing and quota management for Kubernetes" "Internal RHOAI"
        openshiftOAuth = softwareSystem "OpenShift OAuth" "Provides user authentication via OAuth flow for Ray Dashboard access" "OpenShift Platform"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress controller providing external Routes for dashboard and client access" "OpenShift Platform"
        openshiftCertSigner = softwareSystem "service-serving-cert-signer" "Provisions TLS certificates for Services annotated with serving-cert" "OpenShift Platform"
        k8sAPI = softwareSystem "Kubernetes API Server" "Core API server for CRD watches, resource CRUD, and webhook invocation" "Kubernetes"
        kubeflowTraining = softwareSystem "Kubeflow Training Operator" "Manages PyTorchJob resources that can be wrapped by AppWrapper" "Internal RHOAI"
        openshiftMonitoring = softwareSystem "OpenShift Monitoring" "Prometheus-based monitoring; scrapes operator metrics" "OpenShift Platform"

        # User interactions
        dataScientist -> codeflareOperator "Creates RayCluster and AppWrapper CRs via kubectl/SDK"
        platformAdmin -> opendatahubOperator "Configures RHOAI platform via DSC/DSCI CRs"

        # Operator dependencies
        codeflareOperator -> kuberayOperator "Watches RayCluster CRs that KubeRay provisions pods for" "CRD Watch"
        codeflareOperator -> opendatahubOperator "Reads DSCInitialization CR for namespace discovery" "CRD Read"
        codeflareOperator -> kueue "AppWrapper controller integrates for quota reservation" "CRD Integration"
        codeflareOperator -> openshiftOAuth "Per-RayCluster ServiceAccount uses OAuth redirect" "OAuth/443"
        codeflareOperator -> openshiftRouter "Creates Routes for dashboard and client access" "Route API"
        codeflareOperator -> openshiftCertSigner "Annotates Services for TLS cert provisioning" "Annotation"
        codeflareOperator -> k8sAPI "Controller-runtime operations, CRD watches, webhook calls" "HTTPS/443"
        codeflareOperator -> kubeflowTraining "AppWrapper can wrap PyTorchJob resources" "CRD Management"
        openshiftMonitoring -> codeflareOperator "Scrapes /metrics endpoint" "HTTP/8080"

        # Internal container relationships
        rayClusterController -> rayClusterWebhook "Webhook intercepts RayCluster creates/updates"
        appWrapperController -> appWrapperWebhook "Webhook intercepts AppWrapper creates/updates"
        certController -> rayClusterWebhook "Manages TLS certificates for webhook endpoint"
        certController -> appWrapperWebhook "Manages TLS certificates for webhook endpoint"
    }

    views {
        systemContext codeflareOperator "SystemContext" {
            include *
            autoLayout
        }

        container codeflareOperator "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "OpenShift Platform" {
                background #999999
                color #ffffff
            }
            element "Kubernetes" {
                background #326ce5
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
