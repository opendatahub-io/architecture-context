workspace {
    model {
        user = person "Data Scientist" "Creates and deploys Ray clusters for distributed ML workloads"
        admin = person "Cluster Admin" "Manages OpenShift/Kubernetes cluster and operator configuration"

        codeflareOperator = softwareSystem "CodeFlare Operator" "Manages lifecycle and security of RayCluster and AppWrapper resources with OAuth, mTLS, and network isolation" {
            manager = container "Operator Manager" "Reconciles RayCluster CRs, manages OAuth proxy injection, mTLS certificates, Routes, NetworkPolicies, and RBAC" "Go (controller-runtime)"
            rcWebhook = container "RayCluster Webhook" "Mutating: injects OAuth proxy sidecar, mTLS init containers. Validating: enforces immutability of injected resources" "Admission Webhook (9443/TCP)"
            awController = container "AppWrapper Controller" "Manages AppWrapper CRDs for batch workload queuing with Kueue integration (optional, embedded)" "Go (controller-runtime)"
            awWebhook = container "AppWrapper Webhook" "Validates and defaults AppWrapper resources, performs SubjectAccessReview" "Admission Webhook (9443/TCP)"
        }

        kuberayOperator = softwareSystem "KubeRay Operator" "Manages Ray cluster lifecycle on Kubernetes" "Internal Platform"
        odhOperator = softwareSystem "opendatahub-operator / rhods-operator" "Manages RHOAI/ODH platform components, provides DSCInitialization CR" "Internal Platform"
        kueue = softwareSystem "Kueue" "Kubernetes-native job queueing and quota management" "Internal Platform"

        openshiftOAuth = softwareSystem "OpenShift OAuth Server" "Provides OAuth authentication for OpenShift users" "OpenShift Platform"
        openshiftRouter = softwareSystem "OpenShift Router" "Serves Routes for external access to Ray Dashboard and RayClient" "OpenShift Platform"
        openshiftMonitoring = softwareSystem "OpenShift Monitoring (Prometheus)" "Scrapes operator and application metrics" "OpenShift Platform"
        certController = softwareSystem "cert-controller (OPA)" "Manages webhook certificate rotation" "OpenShift Platform"
        servingCertSigner = softwareSystem "OpenShift Serving Cert Signer" "Generates TLS certificates for Services via annotations" "OpenShift Platform"

        k8sAPI = softwareSystem "Kubernetes API Server" "Central API for all cluster resource operations" "Infrastructure"

        user -> codeflareOperator "Creates RayCluster and AppWrapper CRs via kubectl/SDK"
        admin -> codeflareOperator "Configures operator via ConfigMap and DSCInitialization"

        codeflareOperator -> k8sAPI "CRUD on Secrets, Services, Routes, NetworkPolicies, ClusterRoleBindings" "HTTPS/443"
        codeflareOperator -> kuberayOperator "Watches RayCluster CRs created by KubeRay" "CRD Watch"
        codeflareOperator -> odhOperator "Reads DSCInitialization CR for namespace discovery" "CRD Watch"
        codeflareOperator -> kueue "AppWrapper integrates with Kueue for quota management" "CRD Integration"
        codeflareOperator -> openshiftOAuth "OAuth proxy sidecar authenticates users" "HTTPS/443"
        codeflareOperator -> servingCertSigner "Requests TLS certs for OAuth service" "Annotation-triggered"

        k8sAPI -> codeflareOperator "Webhook admission calls for RayCluster and AppWrapper" "HTTPS/9443"
        openshiftRouter -> codeflareOperator "Serves Routes for Ray Dashboard (reencrypt) and RayClient (passthrough)" "HTTPS/443"
        openshiftMonitoring -> codeflareOperator "Scrapes metrics via ServiceMonitor" "HTTP/8080"
        certController -> codeflareOperator "Rotates webhook TLS certificates" "Secret management"
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
            element "OpenShift Platform" {
                background #f5a623
                color #ffffff
            }
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}
