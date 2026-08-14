workspace {
    model {
        user = person "Data Scientist" "Creates and manages Jupyter notebook workbenches"

        workbenchesOperator = softwareSystem "Workbenches Operator" "Kubernetes operator that reconciles Workbenches CR to deploy Kubeflow Notebook Controller, admission webhooks, and supporting infrastructure" {
            reconciler = container "WorkbenchesReconciler" "Watches Workbenches CR and applies kustomize manifests via server-side apply" "Go controller-runtime"
            hwWebhook = container "Hardware Profile Webhook" "Mutating admission webhook that injects resource limits from HardwareProfile CRs into notebook pods" "Go Webhook Handler"
            connWebhook = container "Connection Notebook Webhook" "Mutating admission webhook that injects data connection metadata from Secrets" "Go Webhook Handler"
            convWebhook = container "CRD Conversion Webhook" "Handles notebooks.kubeflow.org CRD version conversion" "Go Webhook Handler"
            tlsEnsurer = container "TLS Ensurer" "Reconciles serving certificates and watches OpenShift TLS security profile changes" "Go Service"
            metricsEndpoint = container "Metrics Endpoint" "Exposes Prometheus metrics with TokenReview + SAR authentication" "HTTPS :8443"
        }

        platformOrchestrator = softwareSystem "Platform Orchestrator (DSC/DSCI)" "Projects configuration fields into Workbenches CR spec" "Internal RHOAI"
        certManager = softwareSystem "cert-manager / service-ca" "Provisions and rotates TLS certificates for webhook serving" "Platform Service"
        kubeAPI = softwareSystem "Kubernetes API Server" "Cluster API server for resource operations and admission webhook forwarding" "Platform Infrastructure"
        notebookController = softwareSystem "Kubeflow Notebook Controller" "Manages notebook pod lifecycle (deployed by this operator)" "Managed Operand"
        openshiftAPIServer = softwareSystem "OpenShift APIServer" "Source of cluster-wide TLS security profile" "Platform Infrastructure"

        # Relationships
        user -> kubeAPI "Creates Notebook CR via kubectl/Dashboard"
        kubeAPI -> workbenchesOperator "Forwards admission requests" "HTTPS/443→9443 TLS"

        platformOrchestrator -> kubeAPI "Creates/Updates Workbenches CR with gatewayDomain, mlflowEnabled, platform"
        workbenchesOperator -> kubeAPI "CRUD on managed resources via kustomize SSA" "HTTPS/6443 TLS 1.2+"
        workbenchesOperator -> notebookController "Deploys and manages lifecycle"
        certManager -> workbenchesOperator "Provisions webhook TLS certificate"
        openshiftAPIServer -> workbenchesOperator "Provides TLS security profile (watched)"

        reconciler -> kubeAPI "Server-side apply manifests" "HTTPS/6443"
        hwWebhook -> kubeAPI "Reads HardwareProfile CRs" "HTTPS/6443"
        connWebhook -> kubeAPI "Reads data connection Secrets" "HTTPS/6443"
        tlsEnsurer -> openshiftAPIServer "Watches TLS profile changes"
    }

    views {
        systemContext workbenchesOperator "SystemContext" {
            include *
            autoLayout
        }

        container workbenchesOperator "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Platform Service" {
                background #999999
                color #ffffff
            }
            element "Platform Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Managed Operand" {
                background #7ed321
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
