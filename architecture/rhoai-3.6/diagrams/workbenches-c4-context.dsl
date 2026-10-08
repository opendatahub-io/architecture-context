workspace {
    model {
        datascientist = person "Data Scientist" "Creates and manages interactive development workspaces (JupyterLab, RStudio, VS Code)"
        admin = person "Platform Admin" "Manages WorkspaceKind templates and cluster configuration"

        workbenches = softwareSystem "Workbenches (Kubeflow Notebooks v2)" "Manages interactive development workspaces on Kubernetes via CRDs, REST API, and web frontend" {
            controller = container "workspaces-controller" "Reconciles Workspace and WorkspaceKind CRDs into StatefulSets, Services, networking, and RBAC resources" "Go (controller-runtime)" "Operator"
            webhook = container "Admission Webhooks" "Validates Workspace and WorkspaceKind mutations; CRD version conversion" "Go (controller-runtime)" "Webhook"
            backend = container "workspaces-backend" "REST API with per-request authn/authz via TokenReview and SubjectAccessReview" "Go (httprouter)" "API Server"
            frontend = container "workspaces-frontend" "Web UI for workspace management" "React 18, PatternFly 6" "SPA"
        }

        k8sapi = softwareSystem "Kubernetes API Server" "Cluster API for resource operations, authentication, and authorization" "External"
        istio = softwareSystem "Istio" "Service mesh for VirtualService-based workspace routing (conditional)" "External"
        gatewayapi = softwareSystem "Kubernetes Gateway API" "HTTPRoute-based workspace routing (conditional)" "External"
        openshiftapi = softwareSystem "OpenShift APIServer" "Provides cluster TLS security profile configuration" "External"
        metricsapi = softwareSystem "Kubernetes Metrics API" "Pod resource usage metrics" "External"
        certmanager = softwareSystem "cert-manager" "TLS certificate management for webhook server" "External"

        # User interactions
        datascientist -> frontend "Creates/manages workspaces via browser" "HTTPS/443"
        admin -> frontend "Manages WorkspaceKind templates" "HTTPS/443"

        # Frontend to backend
        frontend -> backend "API calls" "HTTP(S)/4000, Bearer token"

        # Backend to Kubernetes
        backend -> k8sapi "TokenReview, SubjectAccessReview, CRUD operations" "HTTPS/6443"
        backend -> metricsapi "Read pod metrics" "HTTPS/6443"

        # Controller to Kubernetes
        controller -> k8sapi "Watch CRDs, create StatefulSets/Services/RBAC" "HTTPS/6443"
        controller -> openshiftapi "Read/watch TLS security profile" "HTTPS/6443"

        # Conditional networking
        controller -> istio "Create/manage VirtualServices" "HTTPS/6443"
        controller -> gatewayapi "Create/manage HTTPRoutes and ReferenceGrants" "HTTPS/6443"

        # Kubernetes to webhooks
        k8sapi -> webhook "Admission validation and CRD conversion" "HTTPS/9443"

        # Certificate management
        certmanager -> webhook "Provisions TLS certificates" "Kubernetes Secret"
    }

    views {
        systemContext workbenches "SystemContext" {
            include *
            autoLayout
            description "System context showing workbenches in the broader Kubernetes/OpenShift ecosystem"
        }

        container workbenches "Containers" {
            include *
            autoLayout
            description "Internal container structure of the workbenches component"
        }

        styles {
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #999999
                color #ffffff
            }
            element "External" {
                background #999999
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Operator" {
                shape Hexagon
                background #4a90e2
            }
            element "API Server" {
                background #7ed321
            }
            element "SPA" {
                shape WebBrowser
                background #f5a623
            }
            element "Webhook" {
                background #e74c3c
            }
        }
    }
}
