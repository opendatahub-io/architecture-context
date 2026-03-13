workspace {
    model {
        # External Users
        user = person "Data Scientist / ML Engineer" "Creates and uses Jupyter notebooks for ML workflows"

        # Kubeflow Notebook Controllers System
        kubeflow = softwareSystem "Kubeflow Notebook Controllers" "Manages lifecycle of Jupyter notebook instances in Kubernetes for ML workloads" {
            # notebook-controller (Upstream)
            nbController = container "notebook-controller" "Go" "Core notebook lifecycle management and culling"
            nbCuller = container "notebook-controller-culler" "Go" "Monitors and stops idle notebooks based on activity metrics"

            # odh-notebook-controller (ODH/RHOAI Extensions)
            odhController = container "odh-notebook-controller" "Go" "ODH/RHOAI-specific extensions (OAuth, Routes, networking, integrations)"
            odhWebhook = container "notebook-webhook" "Go" "Validates and mutates Notebook CRs during creation/update"
            oauthModule = container "OAuth Module" "Go" "Creates OpenShift OAuth clients for notebook authentication"
            routeModule = container "Route Module" "Go" "Provisions OpenShift Routes for external access"
            networkModule = container "Network Module" "Go" "Creates NetworkPolicies for pod isolation"
            rbacModule = container "RBAC Module" "Go" "Configures Roles and RoleBindings"
            dspaModule = container "DSPA Secret Module" "Go" "Injects Data Science Pipelines configuration"
            feastModule = container "Feast Module" "Go" "Injects Feast feature store configuration"
            runtimeModule = container "Runtime Module" "Go" "Manages notebook image and resource configuration"
            refgrantModule = container "ReferenceGrant Module" "Go" "Creates Gateway API ReferenceGrants"

            # Notebook Infrastructure
            notebook = container "Jupyter Notebook Pod" "Python" "Jupyter notebook server with ML libraries"
        }

        # External Dependencies
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform (OpenShift 4.19+ compatible)" "External"
        istio = softwareSystem "Istio" "Optional service mesh for VirtualService-based networking" "External"
        certManager = softwareSystem "cert-manager" "Certificate provisioning for webhooks" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        # Internal ODH Dependencies
        dspo = softwareSystem "Data Science Pipelines Operator" "Provides pipeline API endpoints and runtime configuration" "ODH"
        oauthServer = softwareSystem "OpenShift OAuth" "Creates and manages OAuth clients for authentication" "ODH"
        routes = softwareSystem "OpenShift Routes" "Exposes notebooks externally on OpenShift" "ODH"
        gatewayAPI = softwareSystem "Gateway API" "Alternative ingress using Kubernetes Gateway API" "ODH"
        imageStreams = softwareSystem "OpenShift ImageStreams" "Container image references for notebook runtimes" "ODH"
        feast = softwareSystem "Feast" "Feature store configuration injected into notebooks" "ODH"

        # Relationships - User Interactions
        user -> kubeflow "Creates and accesses Jupyter notebooks"

        # Relationships - External Dependencies
        kubeflow -> kubernetes "Orchestrates containers and manages resources"
        kubeflow -> istio "Uses for VirtualService-based ingress (optional)"
        kubeflow -> certManager "Gets TLS certificates for webhooks (optional)"
        kubeflow -> prometheus "Exposes metrics for monitoring"

        # Relationships - Internal ODH
        dspaModule -> dspo "Retrieves pipeline API endpoints and credentials"
        oauthModule -> oauthServer "Creates OAuth clients for notebook auth"
        routeModule -> routes "Creates Routes for external access"
        refgrantModule -> gatewayAPI "Creates HTTPRoutes and ReferenceGrants"
        runtimeModule -> imageStreams "References notebook runtime images"
        feastModule -> feast "Retrieves Feast configuration"

        # Internal Kubeflow Relationships
        nbController -> kubernetes "Creates StatefulSets, Services, VirtualServices"
        nbCuller -> notebook "Monitors /metrics endpoint for activity"
        nbCuller -> kubernetes "Stops idle notebooks"

        odhController -> kubernetes "Manages Notebook CRs and related resources"
        odhWebhook -> kubernetes "Validates/mutates Notebook CRs"
        oauthModule -> odhController "Integrates OAuth configuration"
        routeModule -> odhController "Integrates Route configuration"
        networkModule -> odhController "Creates NetworkPolicies"
        rbacModule -> odhController "Configures RBAC"
        dspaModule -> odhController "Injects pipeline configuration"
        feastModule -> odhController "Injects Feast configuration"
        runtimeModule -> odhController "Configures notebook runtime"
        refgrantModule -> odhController "Creates Gateway API resources"

        odhController -> notebook "Provisions and configures"
        nbController -> notebook "Provisions and manages lifecycle"
    }

    views {
        systemContext kubeflow "KubeflowContext" {
            include *
            autoLayout lr
        }

        container kubeflow "KubeflowContainers" {
            include *
            autoLayout lr
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "ODH" {
                background #0066cc
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
