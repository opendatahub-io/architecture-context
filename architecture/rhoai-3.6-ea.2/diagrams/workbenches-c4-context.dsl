workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages interactive workspaces (JupyterLab, RStudio, VS Code)"
        platformAdmin = person "Platform Admin" "Manages WorkspaceKinds and platform configuration"

        workbenches = softwareSystem "Workbenches" "Manages interactive development workspaces on Kubernetes (Kubeflow Notebooks v2)" {
            controller = container "workspaces-controller" "Reconciles Workspace and WorkspaceKind CRDs into StatefulSets, Services, routing, and RBAC" "Go Operator (controller-runtime)" "Component"
            webhook = container "Webhook Server" "Validates Workspace and WorkspaceKind CREATE/UPDATE/DELETE operations" "Go (admission webhook, :9443)" "Component"
            backend = container "workspaces-backend" "REST API for workspace management with TokenReview auth and SubjectAccessReview authz" "Go REST API (:4000)" "Component"
            frontend = container "workspaces-frontend" "Web UI for workspace management" "React/TypeScript SPA (nginx :8080)" "Component"
        }

        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for all resource operations" "External"
        gateway = softwareSystem "data-science-gateway" "Platform Gateway for centralized ingress routing" "Internal RHOAI"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Auth enforcement sidecar for workspace traffic" "Internal RHOAI"
        istio = softwareSystem "Istio" "Optional service mesh for traffic management" "External"
        openShiftAPI = softwareSystem "OpenShift API Config" "Cluster TLS security profile configuration" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        # User interactions
        dataScientist -> frontend "Manages workspaces via browser"
        platformAdmin -> backend "Manages WorkspaceKinds via API"
        frontend -> backend "REST API calls (/api/v1/*)" "HTTP/4000"

        # Backend interactions
        backend -> k8sAPI "TokenReview, SubjectAccessReview, CRUD Workspaces/Secrets/PVCs" "HTTPS/6443"

        # Controller interactions
        controller -> k8sAPI "CRUD StatefulSets, Services, HTTPRoutes, ReferenceGrants" "HTTPS/6443"
        controller -> openShiftAPI "Reads TLS security profile" "HTTPS/6443"
        k8sAPI -> webhook "Admission requests for Workspace/WorkspaceKind" "HTTPS/9443"
        webhook -> k8sAPI "Reads WorkspaceKind for validation context" "HTTPS/6443"

        # Infrastructure interactions
        controller -> gateway "Creates per-workspace HTTPRoutes" "Kubernetes API"
        controller -> kubeRBACProxy "Injects sidecar into workspace StatefulSets" "Container injection"
        controller -> istio "Creates VirtualServices (Istio mode)" "Kubernetes API"
        prometheus -> controller "Scrapes metrics" "HTTPS/8443"
    }

    views {
        systemContext workbenches "SystemContext" {
            include *
            autoLayout
        }

        container workbenches "Containers" {
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
            element "Component" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}
