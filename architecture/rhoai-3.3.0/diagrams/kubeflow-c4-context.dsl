workspace {
    model {
        user = person "Data Scientist" "Creates and accesses Jupyter notebook instances for data science workloads"

        odhNotebookController = softwareSystem "ODH Notebook Controller" "Kubernetes operator that extends Kubeflow Notebook with OpenShift integration, Gateway API routing, and RBAC-based authentication" {
            controller = container "Notebook Controller" "Reconciles Notebook CRs and creates supporting resources" "Go Operator (Kubebuilder)" {
                reconciler = component "OpenshiftNotebookReconciler" "Main reconciliation loop" "Go Controller"
                httprouteMgr = component "HTTPRoute Manager" "Creates Gateway API routes" "Go"
                refGrantMgr = component "ReferenceGrant Manager" "Manages cross-namespace permissions" "Go"
                netpolMgr = component "NetworkPolicy Manager" "Creates network isolation policies" "Go"
                rbacMgr = component "RBAC Manager" "Creates ServiceAccounts, Roles, RoleBindings" "Go"
                dspaIntegration = component "DSPA Integration" "Provisions pipeline secrets and RBAC" "Go"
            }

            webhook = container "Mutating Webhook" "Injects kube-rbac-proxy sidecar into notebook pods" "Go HTTPS Service" {
                mutator = component "Notebook Mutator" "Modifies notebook pod spec" "Go Webhook Handler"
                proxyConfig = component "kube-rbac-proxy Config Generator" "Generates sidecar configuration" "Go"
            }

            metricsService = container "Metrics Service" "Exposes Prometheus metrics and health endpoints" "HTTP Service"
        }

        # External Systems
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Core Kubernetes control plane" "External"
        gateway = softwareSystem "Data Science Gateway" "Gateway API ingress for notebook access" "External Gateway API"
        kubeflowController = softwareSystem "Kubeflow Notebook Controller" "Creates Notebook StatefulSets and base Services" "External Operator"
        serviceCA = softwareSystem "OpenShift Service CA Operator" "Provisions and rotates TLS certificates" "External Operator"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "RBAC-based authentication proxy sidecar" "External Sidecar"

        # Internal ODH Systems
        odhDashboard = softwareSystem "ODH Dashboard" "User interface for creating and managing notebooks" "Internal ODH"
        dspo = softwareSystem "Data Science Pipelines Operator" "Manages pipeline infrastructure and DSPA CRs" "Internal ODH"
        dspAPI = softwareSystem "Data Science Pipelines API" "Pipeline execution and metadata service" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Model metadata and versioning" "Internal ODH"
        trustedCA = softwareSystem "Trusted CA Bundle" "Cluster CA certificates ConfigMap" "Internal ODH"

        # External Services
        imageRegistry = softwareSystem "Image Registry" "Container image storage" "External Service"
        s3Storage = softwareSystem "S3 Storage" "Object storage for notebooks and models" "External Service"
        openshiftProxy = softwareSystem "OpenShift Proxy" "Cluster-wide HTTP/HTTPS proxy" "External Service"

        # User interactions
        user -> odhDashboard "Creates notebooks via UI"
        user -> gateway "Accesses notebook instances via browser" "HTTPS/443"

        # ODH Dashboard interaction
        odhDashboard -> kubernetesAPI "Creates Notebook CRs" "HTTPS/443"

        # Controller interactions
        controller -> kubernetesAPI "Watches Notebook CRs, creates HTTPRoutes, ReferenceGrants, NetworkPolicies, RBAC objects" "HTTPS/443 (ServiceAccount Token)"
        controller -> dspo "Watches DSPA CRs for pipeline integration" "CRD Watch"
        controller -> trustedCA "Mounts CA certificates" "ConfigMap Mount"

        # Webhook interactions
        kubernetesAPI -> webhook "Validates/mutates Notebook CREATE/UPDATE" "HTTPS/443 (mTLS)"
        webhook -> kubernetesAPI "Returns mutated pod spec with sidecar" "HTTPS/443"

        # Gateway routing
        gateway -> kubeRBACProxy "Routes authenticated requests" "HTTPS/8443"
        gateway -> kubeflowController "Routes unauthenticated requests" "HTTP/80"

        # kube-rbac-proxy authentication
        kubeRBACProxy -> kubernetesAPI "Performs SubjectAccessReview" "HTTPS/443 (ServiceAccount Token)"

        # Kubeflow Notebook Controller
        kubernetesAPI -> kubeflowController "Notifies of Notebook CR events" "Watch"
        kubeflowController -> kubernetesAPI "Creates StatefulSets, Services" "HTTPS/443"

        # Service CA
        serviceCA -> kubernetesAPI "Provisions TLS certificates via annotation" "Certificate Injection"

        # Notebook egress
        kubeflowController -> imageRegistry "Pulls container images" "HTTPS/443"
        kubeflowController -> dspAPI "Accesses pipelines (optional)" "HTTPS/8888 (Bearer Token)"
        kubeflowController -> s3Storage "Reads/writes data and models (optional)" "HTTPS/443"
        kubeflowController -> openshiftProxy "Routes external traffic via proxy (optional)" "HTTPS/443"

        # Metrics
        odhNotebookController -> kubernetesAPI "Exposes metrics for Prometheus" "HTTP/8080"

        # Component relationships
        reconciler -> httprouteMgr "Creates HTTPRoutes"
        reconciler -> refGrantMgr "Creates ReferenceGrants"
        reconciler -> netpolMgr "Creates NetworkPolicies"
        reconciler -> rbacMgr "Creates RBAC objects"
        reconciler -> dspaIntegration "Integrates with pipelines"
        mutator -> proxyConfig "Generates sidecar config"
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

        component controller "ControllerComponents" {
            include *
            autoLayout
        }

        component webhook "WebhookComponents" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Operator" {
                background #8B4513
                color #ffffff
            }
            element "External Gateway API" {
                background #4169E1
                color #ffffff
            }
            element "External Sidecar" {
                background #FF8C00
                color #ffffff
            }
            element "External Service" {
                background #696969
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
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
                shape Person
            }
        }

        theme default
    }
}
