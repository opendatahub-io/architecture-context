workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages RayClusters for distributed ML training and inference"
        mlEngineer = person "ML Engineer" "Submits batch AI/ML jobs via AppWrapper resources"

        codeflareOperator = softwareSystem "CodeFlare Operator" "Manages RayCluster OAuth/mTLS infrastructure, Routes, NetworkPolicies, and optionally AppWrapper scheduling" {
            manager = container "Operator Manager" "controller-runtime based operator process" "Go"
            rcController = container "RayCluster Controller" "Reconciles OAuth proxy, mTLS certs, Routes, NetworkPolicies per RayCluster" "Go Controller"
            rcWebhook = container "RayCluster Webhook" "Mutates RayCluster pods to inject oauth-proxy sidecar and TLS init containers; validates immutability" "Mutating/Validating Webhook"
            awController = container "AppWrapper Controller" "Embedded controller for quota-aware workload scheduling via Kueue" "Go Controller (optional)"
            awWebhook = container "AppWrapper Webhook" "Validates and defaults AppWrapper CRs with SubjectAccessReview" "Mutating/Validating Webhook"
            certController = container "cert-controller" "Rotates webhook serving certificates and updates CA bundles" "Embedded Library"
        }

        kuberayOperator = softwareSystem "KubeRay Operator" "Manages RayCluster CRD lifecycle (creates Ray head/worker pods)" "External Operator"
        openshiftOAuth = softwareSystem "OpenShift OAuth Server" "Built-in OpenShift authentication server for OAuth delegation" "Platform"
        openshiftIngress = softwareSystem "OpenShift Ingress Controller" "HAProxy-based ingress serving OpenShift Routes" "Platform"
        servingCertSigner = softwareSystem "OpenShift serving-cert-signer" "Auto-provisions TLS certificates for Services via annotation" "Platform"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Core Kubernetes API for resource management" "Platform"
        openshiftMonitoring = softwareSystem "OpenShift Monitoring" "Prometheus-based monitoring and metrics collection" "Platform"
        odhOperator = softwareSystem "opendatahub-operator" "Manages DSCInitialization and ODH/RHOAI platform configuration" "Internal ODH"
        kueue = softwareSystem "Kueue" "Quota-aware workload scheduling system" "External (optional)"
        trainingOperator = softwareSystem "Training Operator" "Manages PyTorchJob and other training workloads" "External (optional)"

        # User interactions
        dataScientist -> codeflareOperator "Creates RayCluster CR via kubectl/dashboard"
        mlEngineer -> codeflareOperator "Creates AppWrapper CR for batch jobs"

        # Operator dependencies
        codeflareOperator -> kuberayOperator "Watches RayCluster CRs created by KubeRay" "K8s API Watch"
        codeflareOperator -> openshiftOAuth "Delegates user authentication via oauth-proxy sidecar" "HTTPS/443"
        codeflareOperator -> openshiftIngress "Creates Routes for dashboard (reencrypt) and client (passthrough)" "HTTPS/443"
        codeflareOperator -> servingCertSigner "Triggers TLS cert provisioning via service annotation" "K8s API"
        codeflareOperator -> kubernetesAPI "CRUD on Secrets, Services, Routes, NetworkPolicies, RBAC" "HTTPS/443"
        codeflareOperator -> odhOperator "Reads DSCInitialization for applications namespace" "K8s API"
        codeflareOperator -> kueue "Integrates AppWrapper with Kueue for quota scheduling" "K8s API"
        codeflareOperator -> trainingOperator "AppWrapper wraps PyTorchJob resources" "K8s API"
        openshiftMonitoring -> codeflareOperator "Scrapes Prometheus metrics" "HTTP/8080"

        # Internal container relationships
        manager -> rcController "Manages"
        manager -> rcWebhook "Manages"
        manager -> awController "Manages (optional)"
        manager -> awWebhook "Manages (optional)"
        manager -> certController "Embeds"
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
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "External Operator" {
                background #999999
                color #ffffff
            }
            element "Platform" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "External (optional)" {
                background #bbbbbb
                color #ffffff
            }
        }
    }
}
