workspace {
    model {
        dataScientist = person "Data Scientist" "Creates RayClusters for distributed ML training and inference"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and operator configuration"

        codeflareOperator = softwareSystem "CodeFlare Operator" "Manages lifecycle, security, and networking for RayCluster and AppWrapper resources" {
            manager = container "Operator Manager" "Reconciles RayCluster resources, injects OAuth proxy, manages mTLS, creates Routes/NetworkPolicies" "Go Operator (controller-runtime)"
            rayclusterWebhook = container "RayCluster Webhook" "Mutates RayCluster pods to inject OAuth proxy sidecar, mTLS init containers; validates immutability of injected resources" "Admission Webhook (9443/TCP)"
            appwrapperController = container "AppWrapper Controller" "Manages AppWrapper CRDs for batch workload queuing with Kueue integration (optional)" "Embedded Controller"
            appwrapperWebhook = container "AppWrapper Webhook" "Validates and defaults AppWrapper resources; performs SubjectAccessReview" "Admission Webhook (9443/TCP)"
        }

        kuberayOperator = softwareSystem "KubeRay Operator" "Creates and manages RayCluster resources" "External"
        opendatahubOperator = softwareSystem "ODH / RHODS Operator" "Platform operator providing DSCInitialization CR" "Internal ODH"
        openshiftOAuth = softwareSystem "OpenShift OAuth Server" "Provides user authentication via OAuth flow" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "Serves Routes for external access to Ray Dashboard and RayClient" "External"
        openshiftMonitoring = softwareSystem "OpenShift Monitoring" "Prometheus metrics scraping via ServiceMonitor" "External"
        certController = softwareSystem "OPA Cert Controller" "Manages webhook certificate rotation" "External"
        kueue = softwareSystem "Kueue" "Quota management for batch workloads (optional)" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for CRUD on all managed resources" "External"
        openshiftIngressConfig = softwareSystem "OpenShift Ingress Config" "Provides cluster domain for Route/Ingress hostnames" "External"

        dataScientist -> codeflareOperator "Creates RayCluster/AppWrapper via kubectl"
        platformAdmin -> codeflareOperator "Configures operator via ConfigMap"

        kuberayOperator -> codeflareOperator "Creates RayCluster CRs that trigger reconciliation"
        codeflareOperator -> k8sAPI "CRUD: Secrets, Services, Routes, NetworkPolicies, CRBs" "HTTPS/443"
        codeflareOperator -> openshiftOAuth "OAuth proxy authenticates users" "HTTPS/443"
        codeflareOperator -> openshiftRouter "Creates Routes for dashboard and client access" "HTTPS/443"
        codeflareOperator -> openshiftIngressConfig "Reads cluster Ingress config for domain" "HTTPS/443"
        opendatahubOperator -> codeflareOperator "Provides DSCInitialization CR for namespace discovery"
        openshiftMonitoring -> codeflareOperator "Scrapes metrics" "HTTP/8080"
        certController -> codeflareOperator "Rotates webhook TLS certificates"
        codeflareOperator -> kueue "AppWrapper quota management (optional)"
        k8sAPI -> codeflareOperator "Webhook admission calls" "HTTPS/9443"
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
