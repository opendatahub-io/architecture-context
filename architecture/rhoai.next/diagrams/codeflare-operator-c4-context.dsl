workspace {
    model {
        user = person "Data Scientist" "Creates and manages RayCluster and AppWrapper resources for distributed ML workloads"

        codeflareOperator = softwareSystem "CodeFlare Operator" "Manages RayCluster lifecycle with OAuth proxy injection, mTLS certificate provisioning, and optional AppWrapper batch scheduling" {
            controller = container "RayCluster Controller" "Reconciles RayCluster CRs: creates Routes, OAuth Services, NetworkPolicies, Secrets, ServiceAccounts" "Go (controller-runtime)"
            mutatingWebhook = container "RayCluster Mutating Webhook" "Injects oauth-proxy sidecar, TLS volumes, mTLS init containers into RayCluster pod specs" "Go Webhook Server"
            validatingWebhook = container "RayCluster Validating Webhook" "Enforces immutability of injected OAuth proxy and mTLS resources" "Go Webhook Server"
            certController = container "cert-controller" "Manages webhook TLS certificate rotation" "open-policy-agent/cert-controller"
            appwrapperController = container "AppWrapper Controller" "Optional embedded controller for workload queuing with Kueue integration" "Go (controller-runtime)"
            appwrapperWebhook = container "AppWrapper Webhook" "Validates and defaults AppWrapper resources, performs SubjectAccessReview checks" "Go Webhook Server"
        }

        kuberay = softwareSystem "KubeRay Operator" "Manages Ray cluster lifecycle (upstream)" "External"
        openshiftOAuth = softwareSystem "OpenShift OAuth" "Platform authentication provider" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress controller for Routes" "External"
        odhOperator = softwareSystem "opendatahub-operator" "Platform operator providing DSCInitialization CR" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Quota management and gang scheduling for batch workloads" "External"
        certSigner = softwareSystem "service-serving-cert-signer" "OpenShift component that generates TLS certificates for Services" "External"
        monitoring = softwareSystem "Prometheus (openshift-monitoring)" "Cluster monitoring stack" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Core API for all resource CRUD and webhook registration" "External"

        user -> codeflareOperator "Creates RayCluster / AppWrapper CRs via kubectl"
        codeflareOperator -> kuberay "Watches RayCluster CRs created by KubeRay"
        codeflareOperator -> openshiftOAuth "oauth-proxy delegates authentication" "HTTPS/443"
        codeflareOperator -> odhOperator "Reads DSCInitialization CR for app namespace" "Kubernetes API"
        codeflareOperator -> kueue "AppWrapper integrates for quota reservation" "CRD integration"
        codeflareOperator -> certSigner "Annotation-triggered TLS cert generation for OAuth service"
        codeflareOperator -> k8sAPI "CRD watches, resource CRUD, webhook registration" "HTTPS/443"
        monitoring -> codeflareOperator "Scrapes Prometheus metrics" "HTTP/8080"
        k8sAPI -> codeflareOperator "Webhook admission calls" "HTTPS/9443"
        user -> openshiftRouter "Accesses Ray Dashboard via Route" "HTTPS/443"
        openshiftRouter -> codeflareOperator "Routes traffic to oauth-proxy sidecar" "HTTPS/8443"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
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
