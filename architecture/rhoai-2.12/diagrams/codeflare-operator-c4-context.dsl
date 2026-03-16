workspace {
    model {
        datascientist = person "Data Scientist" "Submits distributed ML workloads using Ray"
        platformadmin = person "Platform Administrator" "Manages CodeFlare operator deployment and configuration"

        codeflareOperator = softwareSystem "CodeFlare Operator" "Manages RayCluster lifecycle with OAuth, mTLS, and workload queue integration" {
            manager = container "Operator Manager" "Reconciles RayCluster and AppWrapper CRDs" "Go Operator" {
                rayController = component "RayCluster Controller" "Creates services, secrets, network policies, ingress/routes for Ray clusters"
                appWrapperController = component "AppWrapper Controller" "Manages workload queueing with Kueue integration (optional)"
                certManager = component "Certificate Manager" "Manages webhook TLS and mTLS CA certificates"
            }

            webhookServer = container "Webhook Server" "Validates and mutates RayCluster and AppWrapper resources" "Go Service" {
                mutatingWebhook = component "Mutating Webhook" "Injects OAuth proxy and mTLS init containers"
                validatingWebhook = component "Validating Webhook" "Validates CR specifications"
            }
        }

        kuberay = softwareSystem "KubeRay Operator" "Provides RayCluster CRD and manages Ray cluster lifecycle" "External"
        kueue = softwareSystem "Kueue" "Workload queue management and resource quotas" "External ODH Fork"
        certController = softwareSystem "cert-manager / OCP cert-controller" "Automatic certificate rotation for webhooks" "External"
        istio = softwareSystem "Istio Service Mesh" "Optional service mesh for enhanced security" "External Optional"

        odhOperator = softwareSystem "OpenDataHub Operator" "ODH/RHOAI platform orchestration" "Internal ODH"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal ODH"
        openShiftOAuth = softwareSystem "OpenShift OAuth" "Authentication for Ray dashboard access" "OpenShift"
        openShiftRoutes = softwareSystem "OpenShift Routes API" "External ingress for Ray dashboard" "OpenShift"

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane" "Infrastructure"
        s3Storage = softwareSystem "S3 Storage" "Model and data artifact storage" "External"

        // User interactions
        datascientist -> codeflareOperator "Creates RayCluster and AppWrapper via kubectl/oc"
        datascientist -> codeflareOperator "Accesses Ray dashboard via browser" "HTTPS/443"
        platformadmin -> codeflareOperator "Configures via ConfigMap and monitors"

        // CodeFlare to external dependencies
        codeflareOperator -> kuberay "Watches and mutates RayCluster CRDs" "In-cluster API"
        codeflareOperator -> kueue "Creates Kueue Workload CRs for AppWrapper scheduling" "In-cluster API"
        codeflareOperator -> certController "Uses for webhook certificate rotation" "Certificate provisioning"
        codeflareOperator -> istio "Optional service mesh integration" "Service mesh"

        // CodeFlare to internal ODH/RHOAI
        codeflareOperator -> odhOperator "Watches DSCInitialization for platform detection" "CRD watch"
        codeflareOperator -> prometheus "Exports metrics via ServiceMonitor" "HTTP/8080"
        codeflareOperator -> openShiftOAuth "Validates OAuth tokens for dashboard access" "HTTPS/443"
        codeflareOperator -> openShiftRoutes "Creates Routes for external dashboard ingress" "OpenShift API"

        // CodeFlare to infrastructure
        codeflareOperator -> k8sAPI "Watches CRDs and manages resources" "HTTPS/443"

        // Ray to storage
        kuberay -> s3Storage "Ray workloads fetch data and models" "HTTPS/443"

        // Component relationships
        rayController -> k8sAPI "Creates Services, Secrets, NetworkPolicies, Ingress/Routes"
        appWrapperController -> kueue "Creates and monitors Workload CRs"
        certManager -> certController "Requests webhook certificates"
        mutatingWebhook -> k8sAPI "Injects sidecars and init containers"
        validatingWebhook -> k8sAPI "Validates CR specifications"
    }

    views {
        systemContext codeflareOperator "CodeFlareSystemContext" {
            include *
            autoLayout lr
        }

        container codeflareOperator "CodeFlareContainers" {
            include *
            autoLayout lr
        }

        component manager "OperatorManagerComponents" {
            include *
            autoLayout lr
        }

        component webhookServer "WebhookServerComponents" {
            include *
            autoLayout lr
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External ODH Fork" {
                background #7ed321
                color #000000
            }
            element "External Optional" {
                background #cccccc
                color #000000
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "OpenShift" {
                background #ee0000
                color #ffffff
            }
            element "Infrastructure" {
                background #326ce5
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                shape RoundedBox
            }
            element "Component" {
                shape Component
            }
            element "Person" {
                shape Person
            }
        }
    }
}
