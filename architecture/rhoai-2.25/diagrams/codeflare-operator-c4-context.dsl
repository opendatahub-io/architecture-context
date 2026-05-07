workspace {
    model {
        datascientist = person "Data Scientist" "Creates RayClusters for distributed ML training and inference"
        mlEngineer = person "ML Engineer" "Submits batch workloads via AppWrappers for quota-aware scheduling"

        codeflareOperator = softwareSystem "CodeFlare Operator" "Enhances RayClusters with OAuth authentication, mTLS encryption, network policies, and ingress on OpenShift" {
            manager = container "Controller Manager" "controller-runtime based operator process managing RayCluster reconciliation and optional AppWrapper scheduling" "Go Operator"
            rayClusterController = container "RayCluster Controller" "Reconciles RayCluster resources to create OAuth Routes, Services, Secrets, CA certificates, NetworkPolicies, and ClusterRoleBindings" "Go Controller"
            rayClusterWebhook = container "RayCluster Webhook" "Mutating webhook injects oauth-proxy sidecar and mTLS init containers; validating webhook enforces immutability" "Admission Webhook (9443/TCP TLS)"
            appWrapperController = container "AppWrapper Controller" "Embedded controller managing AppWrapper CRD lifecycle with Kueue integration (optional, disabled by default)" "Go Controller"
            appWrapperWebhook = container "AppWrapper Webhook" "Validates and defaults AppWrapper resources with SubjectAccessReview-based authorization" "Admission Webhook (9443/TCP TLS)"
            certController = container "cert-controller" "Manages webhook TLS certificate rotation via open-policy-agent cert-controller library" "Embedded Library"
        }

        kuberay = softwareSystem "KubeRay Operator" "Manages Ray cluster lifecycle on Kubernetes" "Internal Platform"
        odhOperator = softwareSystem "opendatahub-operator / rhods-operator" "Platform operator providing DSCInitialization CR for namespace discovery" "Internal Platform"
        openshiftOAuth = softwareSystem "OpenShift OAuth Server" "OpenShift identity provider for user authentication" "External - OpenShift"
        openshiftRouter = softwareSystem "OpenShift Ingress Controller" "Routes external traffic to cluster services via Routes" "External - OpenShift"
        openshiftCertSigner = softwareSystem "OpenShift serving-cert-signer" "Generates TLS certificates for annotated services" "External - OpenShift"
        kueue = softwareSystem "Kueue" "Batch workload scheduling with resource quotas (optional)" "Internal Platform"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management and admission" "External - Kubernetes"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection and alerting" "External - Monitoring"
        trainingOperator = softwareSystem "Training Operator (kubeflow.org)" "Manages PyTorchJob resources (AppWrapper can wrap these)" "Internal Platform"

        # User interactions
        datascientist -> kuberay "Creates RayCluster via kubectl"
        datascientist -> openshiftRouter "Accesses Ray Dashboard via browser (HTTPS/443)"
        mlEngineer -> codeflareOperator "Creates AppWrapper via kubectl"

        # Core operator flows
        kuberay -> k8sAPI "Creates RayCluster CR"
        k8sAPI -> rayClusterWebhook "Admission webhook call (9443/TCP TLS)"
        rayClusterController -> k8sAPI "Watches RayClusters, creates Routes/Services/Secrets/NetworkPolicies (HTTPS/443)"
        appWrapperController -> k8sAPI "Manages AppWrapper lifecycle (HTTPS/443)"
        appWrapperController -> kueue "Integrates for quota-aware scheduling"

        # Platform integrations
        codeflareOperator -> odhOperator "Reads DSCInitialization CR for applications namespace"
        codeflareOperator -> openshiftOAuth "oauth-proxy delegates user authentication (HTTPS/443)"
        codeflareOperator -> openshiftCertSigner "Annotation-triggered TLS cert generation for OAuth proxy"
        openshiftRouter -> codeflareOperator "Routes dashboard and client traffic to RayCluster pods"
        prometheus -> codeflareOperator "Scrapes metrics (HTTP/8080)"
        codeflareOperator -> trainingOperator "AppWrapper wraps PyTorchJob resources"

        # Internal
        manager -> rayClusterController "Manages"
        manager -> appWrapperController "Manages (when enabled)"
        manager -> certController "Certificate rotation"
        rayClusterController -> rayClusterWebhook "Webhook support"
        appWrapperController -> appWrapperWebhook "Webhook support"
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
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "External - OpenShift" {
                background #999999
                color #ffffff
            }
            element "External - Kubernetes" {
                background #999999
                color #ffffff
            }
            element "External - Monitoring" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
        }
    }
}
