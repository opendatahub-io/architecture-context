workspace {
    model {
        user = person "Data Scientist" "Creates and manages distributed AI/ML workloads"
        notebookUser = person "Notebook User" "Interacts with Ray clusters from Jupyter notebooks"

        codeflareOperator = softwareSystem "CodeFlare Operator" "Manages distributed AI/ML workload orchestration through RayCluster and AppWrapper custom resources" {
            manager = container "Manager Pod" "Operator controller running reconciliation loops" "Go 1.25" {
                rayController = component "RayCluster Controller" "Watches RayCluster CRDs and creates supporting resources" "Controller"
                appWrapperController = component "AppWrapper Controller" "Manages AppWrapper CRDs for grouped resource deployment" "Controller"
                webhookServer = component "Webhook Server" "Validates and mutates RayCluster and AppWrapper resources" "AdmissionWebhook"
                metricsServer = component "Metrics Server" "Exposes Prometheus metrics" "HTTP Service"
                certController = component "Cert Controller" "Manages certificate rotation for webhook TLS" "Controller"
            }
        }

        kuberay = softwareSystem "KubeRay Operator" "Provides RayCluster CRD and base Ray cluster management" "External"
        kueue = softwareSystem "Kueue" "Workload queueing and batch scheduling system" "External"
        certManager = softwareSystem "cert-controller" "Certificate management and rotation" "External"
        k8s = softwareSystem "Kubernetes" "Container orchestration platform" "Platform"
        openshift = softwareSystem "OpenShift" "Enterprise Kubernetes with OAuth and Routes" "Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal ODH"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for creating and managing data science resources" "Internal ODH"
        odhOperator = softwareSystem "ODH Operator" "Platform operator managing ODH components" "Internal ODH"
        s3 = softwareSystem "S3 Storage" "Object storage for model artifacts and data" "External"

        # User relationships
        user -> codeflareOperator "Creates RayCluster and AppWrapper CRs via kubectl/oc"
        notebookUser -> codeflareOperator "Connects to Ray clusters from notebooks"
        user -> odhDashboard "Creates RayCluster instances via UI"

        # Operator relationships
        codeflareOperator -> k8s "Watches resources, creates/updates objects" "HTTPS/6443"
        codeflareOperator -> kuberay "Relies on for RayCluster CRD and base cluster management" "CRD dependency"
        codeflareOperator -> kueue "Integrates for AppWrapper batch scheduling" "HTTPS/6443"
        codeflareOperator -> certManager "Uses for webhook TLS certificate rotation" "In-process"
        codeflareOperator -> openshift "Creates Routes and integrates OAuth proxy" "HTTPS/6443"
        codeflareOperator -> odhOperator "Reads DSCInitialization for configuration" "HTTPS/6443"

        # Monitoring
        prometheus -> codeflareOperator "Scrapes metrics" "HTTP/8080"

        # Dashboard integration
        odhDashboard -> codeflareOperator "Triggers RayCluster creation" "Via K8s API"

        # Ray cluster relationships
        notebookUser -> openshift "Accesses Ray dashboard" "HTTPS/443 via Route"
        notebookUser -> codeflareOperator "Connects to Ray client API" "gRPC/10001 via Route"

        # External dependencies
        codeflareOperator -> s3 "Ray clusters access for data/models" "HTTPS/443"
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

        component manager "Components" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Platform" {
                background #666666
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Person" {
                shape person
                background #08427b
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
        }
    }
}
