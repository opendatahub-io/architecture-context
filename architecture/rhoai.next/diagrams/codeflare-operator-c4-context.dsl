workspace {
    model {
        dataScientist = person "Data Scientist" "Creates RayClusters and submits distributed training/inference jobs"
        mlEngineer = person "ML Engineer" "Manages batch workloads via AppWrappers with quota-aware scheduling"

        codeflareOperator = softwareSystem "CodeFlare Operator" "Manages RayCluster OAuth/mTLS infrastructure, Routes, NetworkPolicies, and optionally AppWrapper workload scheduling" {
            manager = container "Operator Manager" "controller-runtime based operator process" "Go"
            rayClusterController = container "RayCluster Controller" "Watches RayCluster CRs, reconciles OAuth Routes, Services, ServiceAccounts, ClusterRoleBindings, Secrets, NetworkPolicies, CA certificates" "Go Controller"
            rayClusterWebhook = container "RayCluster Webhook" "Mutating: injects oauth-proxy sidecar, TLS init containers. Validating: enforces immutability of injected resources" "Webhook Server"
            appWrapperController = container "AppWrapper Controller" "Embedded controller for quota-aware workload scheduling via Kueue integration" "Go Controller"
            appWrapperWebhook = container "AppWrapper Webhook" "Validates and defaults AppWrapper CRs, performs SubjectAccessReview authorization" "Webhook Server"
            certController = container "cert-controller" "Automated webhook certificate rotation" "Embedded Library"
        }

        kuberayOperator = softwareSystem "KubeRay Operator" "Creates and manages RayCluster custom resources" "Internal ODH"
        openshiftOAuth = softwareSystem "OpenShift OAuth Server" "Platform OAuth identity provider for user authentication" "External Platform"
        openshiftIngress = softwareSystem "OpenShift Ingress Controller" "HAProxy-based ingress serving Routes for external access" "External Platform"
        servingCertSigner = softwareSystem "OpenShift serving-cert-signer" "Auto-provisions TLS certificates for Services via annotation" "External Platform"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for all resource CRUD operations" "External Platform"
        openshiftConfig = softwareSystem "OpenShift Config API" "Cluster configuration including Ingress domain" "External Platform"
        prometheus = softwareSystem "OpenShift Monitoring" "Prometheus-based metrics collection" "External Platform"
        odhOperator = softwareSystem "opendatahub-operator" "Platform operator providing DSCInitialization for namespace discovery" "Internal ODH"
        kueue = softwareSystem "Kueue" "Quota-aware workload scheduling system" "Internal ODH"
        trainingOperator = softwareSystem "Training Operator" "Manages PyTorchJob resources for distributed training" "Internal ODH"

        # User interactions
        dataScientist -> kuberayOperator "Creates RayCluster via kubectl/dashboard"
        mlEngineer -> codeflareOperator "Creates AppWrapper CRs for batch workloads"

        # Core operator flows
        codeflareOperator -> k8sAPI "CRUD on Secrets, Services, Routes, NetworkPolicies, CRDs (HTTPS/443, SA token)" "HTTPS/443"
        codeflareOperator -> openshiftConfig "Reads cluster Ingress domain for Route host generation (HTTPS/443)" "HTTPS/443"
        kuberayOperator -> k8sAPI "Creates RayCluster CRs watched by CodeFlare Operator"
        k8sAPI -> codeflareOperator "Webhook callbacks for RayCluster and AppWrapper mutations/validations (HTTPS/9443)" "HTTPS/9443"

        # Platform integrations
        codeflareOperator -> openshiftOAuth "oauth-proxy sidecar delegates user authentication (HTTPS/443)" "HTTPS/443"
        codeflareOperator -> openshiftIngress "Routes created per RayCluster served by Ingress Controller (HTTPS/443)" "HTTPS/443"
        servingCertSigner -> codeflareOperator "Auto-provisions TLS certs for OAuth proxy services"
        prometheus -> codeflareOperator "Scrapes operator metrics via ServiceMonitor (HTTP/8080)" "HTTP/8080"
        codeflareOperator -> odhOperator "Reads DSCInitialization CR for namespace discovery"
        codeflareOperator -> kueue "AppWrapper controller integrates for quota-aware scheduling"
        codeflareOperator -> trainingOperator "AppWrapper can wrap PyTorchJob resources"

        # Data scientist access
        dataScientist -> openshiftIngress "Accesses Ray Dashboard via Route (HTTPS/443, OAuth)" "HTTPS/443"
        dataScientist -> openshiftIngress "Connects Ray client via Route (HTTPS/443, mTLS passthrough)" "HTTPS/443"
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
            element "External Platform" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
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
        }
    }
}
