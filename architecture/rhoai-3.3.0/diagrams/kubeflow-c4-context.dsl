workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and uses Jupyter notebooks for ML development"

        odhNotebookController = softwareSystem "ODH Notebook Controller" "Kubernetes operator that extends Kubeflow Notebook functionality with OpenShift integration, Gateway API routing, and RBAC-based authentication" {
            controller = container "OpenshiftNotebookReconciler" "Reconciles Notebook CRs and creates supporting resources" "Go Operator"
            webhook = container "NotebookWebhook" "Mutating webhook that injects kube-rbac-proxy sidecar" "Go Webhook Server"
            httpRouteManager = container "HTTPRoute Manager" "Manages Gateway API HTTPRoutes for notebook access" "Go Controller"
            rbacManager = container "RBAC Manager" "Manages ServiceAccounts, Roles, and RoleBindings" "Go Controller"
        }

        kubeflowNotebookController = softwareSystem "Kubeflow Notebook Controller" "Creates Notebook StatefulSets and base Services" "External - Kubeflow"
        gatewayAPI = softwareSystem "Gateway API" "Provides HTTPRoute and Gateway CRDs for routing" "External - Kubernetes"
        serviceCA = softwareSystem "OpenShift Service CA Operator" "Provisions TLS certificates for webhooks and services" "External - OpenShift"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Core Kubernetes control plane" "External - Kubernetes"

        dataScientificGateway = softwareSystem "Data Science Gateway" "Routes external traffic to notebooks via Gateway API" "Internal ODH"
        dspOperator = softwareSystem "Data Science Pipelines Operator" "Manages Data Science Pipelines and provides API access" "Internal ODH"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for creating and managing notebooks" "Internal ODH"
        trustedCABundle = softwareSystem "Trusted CA Bundle" "Provides CA certificates for secure connections" "Internal ODH"

        s3Storage = softwareSystem "S3 Storage" "Model artifact storage and data storage" "External"
        imageRegistry = softwareSystem "Image Registry" "Container image storage and distribution" "External"

        # Relationships
        dataScientist -> odhDashboard "Creates notebooks via web UI"
        dataScientist -> dataScientificGateway "Accesses notebooks via HTTPS"

        odhDashboard -> kubeflowNotebookController "Creates Notebook CRs" "Kubernetes API"

        odhNotebookController -> kubeflowNotebookController "Watches Notebook CRs created by" "CRD Watch"
        odhNotebookController -> gatewayAPI "Creates HTTPRoutes and ReferenceGrants" "Kubernetes API"
        odhNotebookController -> serviceCA "Requests TLS certificates via annotations" "Kubernetes API"
        odhNotebookController -> kubernetesAPI "Creates and manages Kubernetes resources" "HTTPS/443"
        odhNotebookController -> dspOperator "Watches DSPA CRs and provisions pipeline access" "CRD Watch"
        odhNotebookController -> trustedCABundle "Mounts CA certificates" "ConfigMap"

        dataScientificGateway -> odhNotebookController "Routes to notebook services via HTTPRoute" "Gateway API"

        controller -> webhook "Coordinates with webhook for sidecar injection"
        controller -> httpRouteManager "Manages HTTPRoute creation"
        controller -> rbacManager "Manages RBAC resources"

        webhook -> kubernetesAPI "Mutates Notebook pods" "Webhook Admission"

        # External dependencies for notebooks
        odhNotebookController -> s3Storage "Notebooks access model artifacts" "HTTPS/443"
        odhNotebookController -> imageRegistry "Pulls container images" "HTTPS/443"
    }

    views {
        systemContext odhNotebookController "SystemContext" {
            include *
            autoLayout
        }

        container odhNotebookController "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External - Kubeflow" {
                background #999999
                color #ffffff
            }
            element "External - Kubernetes" {
                background #326CE5
                color #ffffff
            }
            element "External - OpenShift" {
                background #EE0000
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
            }
            element "External" {
                background #f5a623
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}
