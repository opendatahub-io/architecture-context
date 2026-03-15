workspace {
    model {
        user = person "Data Scientist" "Creates and manages distributed AI/ML workloads on Ray clusters"

        codeflareOperator = softwareSystem "CodeFlare Operator" "Manages distributed AI/ML workload orchestration through RayCluster and AppWrapper custom resources" {
            managerPod = container "Manager Pod" "Runs RayCluster and AppWrapper controllers" "Go Operator" {
                rayController = component "RayCluster Controller" "Watches RayCluster CRDs and creates OAuth, mTLS, networking resources" "Go Controller"
                appWrapperController = component "AppWrapper Controller" "Manages AppWrapper CRDs for grouped resource deployment with Kueue" "Go Controller"
                mutatingWebhook = component "Mutating Webhook" "Modifies RayCluster and AppWrapper on CREATE/UPDATE" "Admission Webhook"
                validatingWebhook = component "Validating Webhook" "Validates RayCluster and AppWrapper on CREATE/UPDATE" "Admission Webhook"
            }
            webhookService = container "Webhook Service" "Serves admission webhook requests" "HTTPS/9443 TLS1.2+ mTLS"
            metricsService = container "Metrics Service" "Exposes Prometheus metrics" "HTTP/8080"
        }

        kuberay = softwareSystem "KubeRay Operator" "Provides RayCluster CRD and base Ray cluster management" "External Dependency"
        kueue = softwareSystem "Kueue" "Workload queueing and batch scheduling for AppWrappers" "External Dependency"
        certController = softwareSystem "cert-controller" "Manages TLS certificate rotation for webhooks" "External Dependency"
        k8sAPI = softwareSystem "Kubernetes API Server" "Container orchestration control plane" "Kubernetes"
        odhDashboard = softwareSystem "ODH Dashboard" "User interface for creating RayCluster instances" "Internal ODH"
        odhOperator = softwareSystem "ODH Operator" "Provides DSCInitialization configuration" "Internal ODH"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal ODH"
        openShiftOAuth = softwareSystem "OpenShift OAuth" "User authentication for Ray dashboard" "OpenShift"

        # User interactions
        user -> codeflareOperator "Creates RayCluster and AppWrapper resources via kubectl/ODH Dashboard"
        user -> odhDashboard "Creates RayCluster instances via notebook UI"

        # CodeFlare Operator dependencies
        codeflareOperator -> k8sAPI "CRUD operations, watches resources" "HTTPS/6443 TLS1.3 Bearer Token"
        codeflareOperator -> kuberay "Relies on RayCluster CRD and base cluster lifecycle" "CRD dependency"
        codeflareOperator -> kueue "AppWrapper admission and status updates" "HTTPS/6443 via K8s API"
        codeflareOperator -> odhOperator "Reads DSCInitialization for configuration" "HTTPS/6443 via K8s API"
        codeflareOperator -> openShiftOAuth "Integrates OAuth proxy for Ray dashboard authentication" "OAuth sidecar"
        certController -> codeflareOperator "Manages webhook TLS certificate rotation" "Certificate management"

        # Monitoring
        prometheus -> codeflareOperator "Scrapes metrics endpoint" "HTTP/8080 Bearer Token"

        # ODH integration
        odhDashboard -> codeflareOperator "Creates RayCluster instances" "HTTPS/6443 via K8s API"

        # Kubernetes API interactions
        k8sAPI -> codeflareOperator "Invokes admission webhooks" "HTTPS/9443 TLS1.2+ mTLS"
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

        component managerPod "Components" {
            include *
            autoLayout
        }

        styles {
            element "External Dependency" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Kubernetes" {
                background #326ce5
                color #ffffff
            }
            element "OpenShift" {
                background #ee0000
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
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}
