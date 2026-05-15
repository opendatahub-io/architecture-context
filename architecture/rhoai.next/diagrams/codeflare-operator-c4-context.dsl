workspace {
    model {
        user = person "Data Scientist" "Creates RayClusters and submits distributed compute workloads"
        admin = person "Platform Admin" "Manages RHOAI platform and monitors operator health"

        codeflareOperator = softwareSystem "CodeFlare Operator" "Kubernetes operator managing RayCluster lifecycle with OAuth proxy injection, mTLS certificate generation, and optional AppWrapper controller for batch workload scheduling" {
            manager = container "Operator Manager" "controller-runtime-based operator binary" "Go"
            rayclusterController = container "RayCluster Controller" "Reconciles RayCluster CRs — creates OAuth Routes, Services, Secrets, CA certs, NetworkPolicies, ClusterRoleBindings" "Go Controller"
            rayclusterWebhook = container "RayCluster Webhook" "Mutating: injects OAuth proxy sidecar + mTLS init containers; Validating: enforces immutability" "Admission Webhook"
            appwrapperController = container "AppWrapper Controller (embedded)" "Optional controller for quota-aware batch workload scheduling via Kueue integration" "Go Controller"
            appwrapperWebhook = container "AppWrapper Webhook" "Optional admission control with SubjectAccessReview-based authorization" "Admission Webhook"
        }

        kuberayOperator = softwareSystem "KubeRay Operator" "Creates and manages RayCluster pods and services" "Internal Platform"
        openshiftOAuth = softwareSystem "OpenShift OAuth" "OpenShift authentication provider for user identity" "Platform"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress controller routing external traffic via Routes" "Platform"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource management and webhook invocation" "Platform"
        kueue = softwareSystem "Kueue" "Quota-aware workload admission controller" "Internal Platform"
        odhOperator = softwareSystem "ODH/RHOAI Operator" "Platform operator providing DSCInitialization for namespace discovery" "Internal Platform"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection and alerting" "Platform"
        certController = softwareSystem "cert-controller (OPA)" "Webhook certificate rotation library" "Library"

        # Relationships
        user -> codeflareOperator "Creates RayCluster / AppWrapper CRs via kubectl"
        admin -> prometheus "Monitors operator metrics"

        codeflareOperator -> kuberayOperator "Watches RayClusters created by KubeRay" "K8s API / CRD Watch"
        codeflareOperator -> openshiftOAuth "OAuth proxy delegates user authentication" "HTTPS/443"
        codeflareOperator -> openshiftRouter "Creates Routes for dashboard and client access" "K8s API"
        codeflareOperator -> k8sAPI "Manages Secrets, Services, NetworkPolicies, RBAC" "HTTPS/443"
        codeflareOperator -> kueue "AppWrapper controller integrates for quota scheduling" "K8s API / CRD"
        codeflareOperator -> odhOperator "Reads DSCInitialization for namespace discovery" "K8s API / CRD Watch"
        codeflareOperator -> certController "Uses for webhook TLS cert rotation" "Library"
        prometheus -> codeflareOperator "Scrapes /metrics endpoint" "HTTP/8080"

        # Internal container relationships
        manager -> rayclusterController "Manages"
        manager -> rayclusterWebhook "Serves"
        manager -> appwrapperController "Manages (optional)"
        manager -> appwrapperWebhook "Serves (optional)"
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
                background #438DD5
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Platform" {
                background #999999
                color #ffffff
            }
            element "Library" {
                background #d6b656
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427B
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}
