workspace {
    model {
        user = person "Data Scientist" "Creates and manages Jupyter notebooks for ML development"

        odhNotebookController = softwareSystem "ODH Notebook Controller" "Kubernetes operator that extends Kubeflow Notebook functionality with OpenShift integration, Gateway API routing, and RBAC-based authentication" {
            controller = container "OpenshiftNotebookReconciler" "Main reconciliation loop for Notebook CRs" "Go Controller"
            webhook = container "NotebookWebhook" "Injects kube-rbac-proxy sidecar for authentication" "Go Mutating Webhook"
            httpRouteMgr = container "HTTPRoute Manager" "Creates Gateway API HTTPRoutes for notebook access" "Go Controller"
            rbacMgr = container "RBAC Manager" "Creates ServiceAccounts, Roles, and RoleBindings" "Go Controller"
            networkPolMgr = container "NetworkPolicy Manager" "Creates NetworkPolicies for traffic isolation" "Go Controller"
            dspaIntegration = container "DSPA Integration" "Provisions Data Science Pipeline secrets and RBAC" "Go Controller"
        }

        kubeflowNotebookController = softwareSystem "Kubeflow Notebook Controller" "Creates Notebook StatefulSets and base Services" "External - Required"
        gatewayAPI = softwareSystem "Gateway API" "Provides HTTPRoute and Gateway CRDs for routing" "External - Required"
        k8sAPI = softwareSystem "Kubernetes API Server" "Core Kubernetes APIs" "External - Required"
        serviceCA = softwareSystem "OpenShift Service CA Operator" "Provisions TLS certificates for webhooks and services" "External - Required"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Sidecar proxy for RBAC-based authentication" "External - Required"

        dsGateway = softwareSystem "Data Science Gateway" "Routes external traffic to notebooks via Gateway API" "Internal ODH"
        dsPipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration platform" "Internal ODH"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for managing ODH components" "Internal ODH"
        trustedCA = softwareSystem "Trusted CA Bundle" "Provides CA certificates for secure connections" "Internal ODH"

        imageRegistry = softwareSystem "Image Registry" "Container image storage" "External Service"
        oauthServer = softwareSystem "OpenShift OAuth" "Authentication and authorization server" "External Service"
        proxyServer = softwareSystem "OpenShift Proxy" "Cluster-wide proxy configuration" "External Service"

        # User interactions
        user -> odhDashboard "Creates Notebook CRs via UI"
        user -> k8sAPI "Creates Notebook CRs via kubectl"
        user -> dsGateway "Accesses notebooks via HTTPS" "HTTPS/443"

        # Main component interactions
        odhNotebookController -> k8sAPI "Watches Notebooks, creates resources" "HTTPS/443"
        odhNotebookController -> gatewayAPI "Creates HTTPRoutes and ReferenceGrants" "CRD API"
        odhNotebookController -> serviceCA "Requests TLS certificates via annotations" "Annotation"
        odhNotebookController -> kubeflowNotebookController "Watches Notebook CRs created by" "CRD Watch"

        # Internal component interactions
        controller -> webhook "Triggers mutation for new Notebooks"
        controller -> httpRouteMgr "Creates HTTPRoutes for external access"
        controller -> rbacMgr "Creates RBAC for notebooks"
        controller -> networkPolMgr "Creates NetworkPolicies for isolation"
        controller -> dspaIntegration "Provisions pipeline access"

        webhook -> kubeRBACProxy "Injects as sidecar container" "Pod Mutation"

        # ODH integrations
        httpRouteMgr -> dsGateway "Configures routing" "HTTPRoute CRD"
        dspaIntegration -> dsPipelines "Fetches pipeline metadata, provisions secrets" "gRPC/8888"
        odhDashboard -> odhNotebookController "Creates Notebook CRs"
        odhNotebookController -> trustedCA "Mounts CA bundle" "ConfigMap"

        # External service interactions
        odhNotebookController -> imageRegistry "Pulls container images" "HTTPS/443"
        odhNotebookController -> oauthServer "Validates OAuth tokens" "HTTPS/443"
        odhNotebookController -> proxyServer "Applies proxy configuration" "HTTPS/443"

        dsGateway -> kubeRBACProxy "Routes authenticated requests" "HTTPS/8443"
        dsGateway -> oauthServer "Validates user tokens" "HTTPS/443"

        kubeRBACProxy -> k8sAPI "Performs SubjectAccessReviews" "HTTPS/443"
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
            element "External - Required" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "External Service" {
                background #f5a623
                color #000000
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #6fa8dc
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }

        theme default
    }
}
