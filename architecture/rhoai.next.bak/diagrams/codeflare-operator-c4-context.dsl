workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and submits Ray workloads and accesses Ray Dashboard"
        mlEngineer = person "ML Engineer" "Defines AppWrapper batch jobs for quota-managed training"

        codeflareOperator = softwareSystem "CodeFlare Operator" "Augments RayCluster resources with OAuth, mTLS, NetworkPolicies, and Routes; optionally embeds AppWrapper controller for Kueue integration" {
            rayClusterController = container "RayCluster Controller" "Watches RayCluster CRs and creates security infrastructure (Routes, Services, Secrets, NetworkPolicies)" "Go Controller"
            rayClusterWebhook = container "RayCluster Webhook" "Mutates RayCluster pods to inject oauth-proxy sidecar, mTLS init containers, and TLS env vars; validates immutability" "Admission Webhook"
            appWrapperController = container "AppWrapper Controller" "Manages AppWrapper CRs for Kueue-integrated batch scheduling (embedded library)" "Go Controller"
            appWrapperWebhook = container "AppWrapper Webhook" "Validates and defaults AppWrapper resources" "Admission Webhook"
            configManager = container "Config Manager" "Reads codeflare-operator-config ConfigMap for feature flags" "Go Config"
        }

        kuberay = softwareSystem "KubeRay Operator" "Manages RayCluster lifecycle (creates head/worker pods)" "External"
        openshiftOAuth = softwareSystem "OpenShift OAuth" "Cluster identity provider for user authentication" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress controller providing Routes with TLS termination" "External"
        openshiftServingCert = softwareSystem "OpenShift Serving Cert Service" "Automatic TLS certificate provisioning via service annotations" "External"
        odhOperator = softwareSystem "ODH/RHOAI Operator" "Platform operator providing DSCInitialization CR for namespace discovery" "Internal Platform"
        kueue = softwareSystem "Kueue" "Quota-aware workload scheduling system" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource management and webhook dispatch" "External"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection and alerting" "External"
        certController = softwareSystem "cert-controller" "Webhook certificate rotation library" "Internal Library"

        # Relationships
        dataScientist -> openshiftRouter "Accesses Ray Dashboard via Route" "HTTPS/443"
        dataScientist -> openshiftRouter "Connects Ray Client via Route" "HTTPS/443 mTLS"
        mlEngineer -> k8sAPI "Creates AppWrapper resources" "kubectl"

        kuberay -> k8sAPI "Creates RayCluster CRs"
        codeflareOperator -> k8sAPI "Manages resources (Routes, Services, Secrets, NetworkPolicies)" "HTTPS/443"
        codeflareOperator -> openshiftOAuth "oauth-proxy sidecar delegates authentication" "HTTPS/443"
        codeflareOperator -> openshiftServingCert "Triggers TLS cert provisioning via annotation" "Annotation"
        codeflareOperator -> odhOperator "Reads DSCInitialization for namespace discovery" "CRD Watch"
        codeflareOperator -> kueue "AppWrapper integrates for quota scheduling" "CRD Integration"
        codeflareOperator -> certController "Webhook cert rotation" "Internal Library"

        k8sAPI -> codeflareOperator "Dispatches webhook calls for RayCluster/AppWrapper admission" "HTTPS/9443"
        prometheus -> codeflareOperator "Scrapes operator metrics" "HTTP/8080"

        rayClusterController -> rayClusterWebhook "Webhook validates mutations"
        appWrapperController -> appWrapperWebhook "Webhook validates mutations"
        configManager -> appWrapperController "Enables/disables via appwrapper.enabled flag"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Internal Library" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}
